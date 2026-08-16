import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/rate_formatter.dart';
import 'package:gst_calculator/features/calculator/presentation/providers/gst_calculator_notifier.dart';
import 'package:gst_calculator/features/history/data/models/history_entry.dart';
import 'package:gst_calculator/features/history/presentation/providers/history_provider.dart';
import 'package:gst_calculator/features/settings/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns a stable [GstCalculatorNotifier] for [container].
///
/// `gstCalculatorProvider` watches `settingsProvider`, whose async load only
/// completes after pumping. A notifier reference taken before that load
/// settles goes stale when the provider rebuilds, silently discarding any
/// mutations made through it — so the settings provider is built and settled
/// first, and only then is the calculator notifier read.
Future<GstCalculatorNotifier> _stableNotifier(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(settingsProvider); // trigger the async settings load
  for (var i = 0; i < 4; i++) {
    await tester.pump(); // flush the settings load chain
  }
  return container.read(gstCalculatorProvider.notifier);
}

/// Advances the fake clock past the 600ms auto-save debounce, flushes the
/// queued store write, then re-reads the persisted store so assertions see
/// exactly what was written. The re-read keeps assertions on persisted
/// behaviour (one entry, final state, no duplicates) rather than transient
/// in-memory state.
Future<void> _settle(WidgetTester tester, ProviderContainer container) async {
  await tester.pump(const Duration(milliseconds: 700)); // debounce fires
  await tester.pump();
  await tester.pump();
  await container.read(historyProvider.notifier).reload();
}

void main() {
  testWidgets('rapid typing coalesces into a single history entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await _stableNotifier(tester, container);
    // Four keystrokes of one editing session, all inside the debounce window.
    notifier.updateAmount('1');
    notifier.updateAmount('12');
    notifier.updateAmount('123');
    notifier.updateAmount('1000');
    await _settle(tester, container);

    final entries = container.read(historyProvider);
    expect(entries, hasLength(1), reason: 'typing must coalesce to one entry');
    expect(entries.single.amountText, '1000');
    expect(entries.single.rate, 18.0);
  });

  testWidgets('slab changes within the debounce window produce one entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await _stableNotifier(tester, container);
    notifier.updateAmount('1000');
    notifier.selectSlab(5.0);
    notifier.selectSlab(12.0);
    notifier.selectSlab(28.0);
    await _settle(tester, container);

    final entries = container.read(historyProvider);
    expect(entries, hasLength(1), reason: 'slab churn must coalesce');
    expect(entries.single.rate, 28.0, reason: 'final slab wins');
    expect(entries.single.amountText, '1000');
  });

  testWidgets('identical recalculation does not write a duplicate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await _stableNotifier(tester, container);
    notifier.updateAmount('1000');
    await _settle(tester, container);
    expect(container.read(historyProvider), hasLength(1));

    // Same settled calculation again — dedup must skip the write.
    notifier.updateAmount('1000');
    await _settle(tester, container);
    expect(container.read(historyProvider), hasLength(1));

    // A genuinely different calculation is a new entry.
    notifier.updateAmount('2000');
    await _settle(tester, container);
    final entries = container.read(historyProvider);
    expect(entries, hasLength(2));
    expect(entries.first.amountText, '2000');
  });

  testWidgets('loadFromHistory restores without creating a duplicate entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entry = HistoryEntry(
      id: 'h1',
      amountText: '500',
      rate: 12.0,
      isInclusive: true,
      isIntraState: false,
      baseAmount: 446.43,
      cgst: 0,
      sgst: 0,
      igst: 53.57,
      totalAmount: 500,
      timestamp: 1234,
    );
    final notifier = await _stableNotifier(tester, container);
    notifier.loadFromHistory(entry);
    await _settle(tester, container);

    // The calculator shows the restored state…
    final state = container.read(gstCalculatorProvider);
    expect(state.amountText, '500');
    expect(state.isCustomSlab, false, reason: '12% is a standard slab');
    expect(state.selectedSlab, 12.0);
    expect(state.calculationType.name, 'inclusive');
    expect(state.transactionType.name, 'interState');
    // …but no new history entry was written for it.
    expect(container.read(historyProvider), isEmpty);
  });

  testWidgets('custom fractional rate restores and auto-saves correctly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entry = HistoryEntry(
      id: 'h2',
      amountText: '99.99',
      rate: 0.25,
      isInclusive: false,
      isIntraState: true,
      baseAmount: 99.99,
      cgst: 0.12,
      sgst: 0.13,
      igst: 0,
      totalAmount: 100.24,
      timestamp: 5678,
    );
    final notifier = await _stableNotifier(tester, container);
    notifier.loadFromHistory(entry);
    await _settle(tester, container);
    expect(container.read(historyProvider), isEmpty);

    // Editing the restored calculation saves a NEW entry with the same
    // fractional rate — a legitimate new calculation.
    notifier.updateAmount('200');
    await _settle(tester, container);
    final entries = container.read(historyProvider);
    expect(entries, hasLength(1));
    expect(entries.single.rate, 0.25);
  });

  testWidgets('clearAll resets state and does not re-save', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await _stableNotifier(tester, container);
    notifier.updateAmount('1000');
    await _settle(tester, container);
    expect(container.read(historyProvider), hasLength(1));

    notifier.clearAll();
    await _settle(tester, container);

    final state = container.read(gstCalculatorProvider);
    expect(state.amountText, isEmpty);
    expect(state.result, isNull);
    // The pending timer was cancelled and the dedup reference cleared: no
    // new entry, and history still holds only the pre-clear entry.
    expect(container.read(historyProvider), hasLength(1));
  });

  group('formatRate', () {
    test('integer rates render without decimals', () {
      expect(formatRate(3.0), '3');
      expect(formatRate(5.0), '5');
      expect(formatRate(12.0), '12');
      expect(formatRate(18.0), '18');
      expect(formatRate(28.0), '28');
      expect(formatRate(0.0), '0');
    });

    test('fractional rates keep up to two decimals, trailing zeros stripped', () {
      expect(formatRate(0.25), '0.25');
      expect(formatRate(1.5), '1.5');
      expect(formatRate(12.5), '12.5');
      expect(formatRate(99.99), '99.99');
    });
  });
}
