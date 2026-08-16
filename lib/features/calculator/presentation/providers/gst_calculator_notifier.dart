import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/gst_rates.dart';
import '../../../../core/utils/gst_math.dart';
import '../../../history/data/models/history_entry.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_calculator_state.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../../domain/usecases/calculate_gst.dart';

/// Provider for the GST calculator notifier.
final gstCalculatorProvider =
    NotifierProvider<GstCalculatorNotifier, GstCalculatorState>(
      GstCalculatorNotifier.new,
    );

/// Riverpod notifier that manages the GST calculator state.
class GstCalculatorNotifier extends Notifier<GstCalculatorState> {
  /// How long to wait after the last change before writing a history entry.
  ///
  /// Rapid changes within one editing session (typing `1` → `10` → `100` →
  /// `1000`, or toggling a slab) all coalesce into a single write of the
  /// final settled state — history gets one meaningful entry per calculation,
  /// not one per keystroke.
  static const Duration _autoSaveDebounce = Duration(milliseconds: 600);

  /// The most recently persisted entry, used to skip redundant identical
  /// writes of the same settled calculation.
  HistoryEntry? _lastSaved;

  /// Pending debounced history write, if any.
  Timer? _historyDebounce;

  /// While true, `_recalculate` does not schedule a history write. Used to
  /// keep `loadFromHistory` from duplicating the restored entry.
  bool _suppressAutoSave = false;

  @override
  GstCalculatorState build() {
    // Cancel any pending write when the notifier goes away so disposal never
    // leaves a timer or callback alive.
    ref.onDispose(() {
      _historyDebounce?.cancel();
      _historyDebounce = null;
    });

    // Load defaults from settings
    final settings = ref.watch(settingsProvider);
    return GstCalculatorState(
      amountText: '',
      selectedSlab: settings.defaultSlab,
      isCustomSlab: false,
      customSlabValue: 0,
      calculationType: settings.defaultCalculationType,
      transactionType: settings.defaultTransactionType,
    );
  }

  // ── Mutations ───────────────────────────────────────────────────────

  void updateAmount(String text) {
    if (text.isNotEmpty && !RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
      return;
    }
    state = state.copyWith(amountText: text);
    _recalculate();
  }

  void selectSlab(double slab) {
    state = state.copyWith(
      selectedSlab: slab,
      isCustomSlab: false,
      customSlabValue: 0,
      clearResult: true,
    );
    _recalculate();
  }

  void setCustomSlab(double value) {
    state = state.copyWith(
      isCustomSlab: true,
      customSlabValue: value,
      clearResult: true,
    );
    _recalculate();
  }

  void toggleCalculationType() {
    final newType =
        state.calculationType == GstCalculationType.exclusive
            ? GstCalculationType.inclusive
            : GstCalculationType.exclusive;
    state = state.copyWith(calculationType: newType, clearResult: true);
    _recalculate();
  }

  void toggleTransactionType() {
    final newType =
        state.transactionType == GstTransactionType.intraState
            ? GstTransactionType.interState
            : GstTransactionType.intraState;
    state = state.copyWith(transactionType: newType);
    _recalculate();
  }

  void clearAll() {
    // Cancel any pending write and forget the dedup reference so a fresh
    // calculation of the same value is treated as new, not re-saved as a
    // stale duplicate of the cleared state.
    _historyDebounce?.cancel();
    _historyDebounce = null;
    _lastSaved = null;

    final settings = ref.read(settingsProvider);
    state = GstCalculatorState(
      amountText: '',
      selectedSlab: settings.defaultSlab,
      isCustomSlab: false,
      customSlabValue: 0,
      calculationType: settings.defaultCalculationType,
      transactionType: settings.defaultTransactionType,
    );
  }

  void quickAddAmount(double amount) {
    final currentAmount = double.tryParse(state.amountText) ?? 0;
    final newAmount = currentAmount + amount;
    updateAmount(newAmount.toStringAsFixed(2));
  }

  /// Loads a [HistoryEntry] into the calculator state.
  ///
  /// Restoring an entry must not immediately write a duplicate of it back to
  /// history, so auto-save is suppressed for this recalculation and the
  /// restored entry becomes the dedup reference.
  void loadFromHistory(HistoryEntry entry) {
    _historyDebounce?.cancel();
    _historyDebounce = null;

    final isStandardSlab = GstRates.standardSlabs.contains(entry.rate);
    state = GstCalculatorState(
      amountText: entry.amountText,
      selectedSlab: entry.rate,
      isCustomSlab: !isStandardSlab,
      customSlabValue: isStandardSlab ? 0 : entry.rate,
      calculationType:
          entry.isInclusive
              ? GstCalculationType.inclusive
              : GstCalculationType.exclusive,
      transactionType:
          entry.isIntraState
              ? GstTransactionType.intraState
              : GstTransactionType.interState,
      result: null,
    );

    _lastSaved = entry;
    _suppressAutoSave = true;
    try {
      _recalculate();
    } finally {
      _suppressAutoSave = false;
    }
  }

  // ── Internal ────────────────────────────────────────────────────────

  void _recalculate() {
    final amount = double.tryParse(state.amountText);
    if (amount == null || amount <= 0) {
      // The input is no longer a valid calculation; drop any pending write so
      // a stale intermediate state is never persisted after the user cleared
      // the amount.
      _historyDebounce?.cancel();
      _historyDebounce = null;
      state = state.copyWith(result: null, clearResult: true);
      return;
    }

    final result = CalculateGstUseCase().execute(
      amount: amount,
      rate: state.effectiveRate,
      calculationType: state.calculationType,
      transactionType: state.transactionType,
    );

    state = state.copyWith(result: result);

    // Auto-save to history when a new result is computed.
    if (result != null) {
      _scheduleAutoSave(result);
    }
  }

  /// Debounces the history write: cancels any pending save and schedules the
  /// latest result, so the final settled state is what gets persisted.
  void _scheduleAutoSave(GstResult result) {
    if (_suppressAutoSave) return;
    _historyDebounce?.cancel();
    _historyDebounce = Timer(_autoSaveDebounce, () {
      _historyDebounce = null;
      _autoSave(result);
    });
  }

  /// Saves the current result to history, de-duplicating consecutive saves of
  /// the identical calculation.
  void _autoSave(GstResult result) {
    final now = DateTime.now();
    final entry = HistoryEntry(
      id: '${now.millisecondsSinceEpoch}_${result.baseAmount}',
      amountText: state.amountText,
      rate: state.effectiveRate,
      isInclusive: state.calculationType == GstCalculationType.inclusive,
      isIntraState: state.transactionType == GstTransactionType.intraState,
      baseAmount: result.baseAmount,
      cgst: result.cgst,
      sgst: result.sgst,
      igst: result.igst,
      totalAmount: result.totalAmount,
      timestamp: now.millisecondsSinceEpoch,
    );

    // Skip if it matches the last-saved entry: same amount, rate, and mode
    // means the same settled calculation — no redundant write. A deliberate
    // change to any of these is a different calculation and is saved.
    if (_lastSaved != null &&
        _lastSaved!.amountText == entry.amountText &&
        _lastSaved!.rate == entry.rate &&
        _lastSaved!.isInclusive == entry.isInclusive &&
        _lastSaved!.isIntraState == entry.isIntraState) {
      return;
    }

    _lastSaved = entry;
    ref.read(historyProvider.notifier).addEntry(entry);
  }
}
