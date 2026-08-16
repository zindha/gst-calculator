import '../../../../core/utils/gst_math.dart';
import 'gst_calculation_type.dart';
import 'gst_transaction_type.dart';

/// Represents the complete state of the GST calculator.
///
/// This immutable model holds all input values and the computed result.
class GstCalculatorState {
  /// The base/total amount entered by the user as a string (to allow decimal input).
  final String amountText;

  /// The selected GST slab rate percentage.
  final double selectedSlab;

  /// Whether a custom slab rate is being used.
  final bool isCustomSlab;

  /// The custom slab value entered by the user.
  final double customSlabValue;

  /// Whether the input amount includes GST or not.
  final GstCalculationType calculationType;

  /// Whether the transaction is intra-state or inter-state.
  final GstTransactionType transactionType;

  /// The computed GST result, or null if no valid calculation can be made.
  final GstResult? result;

  const GstCalculatorState({
    required this.amountText,
    required this.selectedSlab,
    required this.isCustomSlab,
    required this.customSlabValue,
    required this.calculationType,
    required this.transactionType,
    this.result,
  });

  /// Creates the initial/default state of the calculator.
  factory GstCalculatorState.initial() {
    return const GstCalculatorState(
      amountText: '',
      selectedSlab: 18.0,
      isCustomSlab: false,
      customSlabValue: 0,
      calculationType: GstCalculationType.exclusive,
      transactionType: GstTransactionType.intraState,
    );
  }

  /// Returns the effective GST rate to use for calculations.
  double get effectiveRate => isCustomSlab ? customSlabValue : selectedSlab;

  /// Returns a copy with the given fields replaced.
  GstCalculatorState copyWith({
    String? amountText,
    double? selectedSlab,
    bool? isCustomSlab,
    double? customSlabValue,
    GstCalculationType? calculationType,
    GstTransactionType? transactionType,
    GstResult? result,
    bool clearResult = false,
  }) {
    return GstCalculatorState(
      amountText: amountText ?? this.amountText,
      selectedSlab: selectedSlab ?? this.selectedSlab,
      isCustomSlab: isCustomSlab ?? this.isCustomSlab,
      customSlabValue: customSlabValue ?? this.customSlabValue,
      calculationType: calculationType ?? this.calculationType,
      transactionType: transactionType ?? this.transactionType,
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  String toString() =>
      'GstCalculatorState(amount: $amountText, slab: ${isCustomSlab ? customSlabValue : selectedSlab}, '
      'type: $calculationType, transaction: $transactionType, result: $result)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GstCalculatorState &&
          amountText == other.amountText &&
          selectedSlab == other.selectedSlab &&
          isCustomSlab == other.isCustomSlab &&
          customSlabValue == other.customSlabValue &&
          calculationType == other.calculationType &&
          transactionType == other.transactionType &&
          result == other.result;

  @override
  int get hashCode =>
      amountText.hashCode ^
      selectedSlab.hashCode ^
      isCustomSlab.hashCode ^
      customSlabValue.hashCode ^
      calculationType.hashCode ^
      transactionType.hashCode ^
      result.hashCode;
}
