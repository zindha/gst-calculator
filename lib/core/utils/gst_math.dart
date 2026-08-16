import '../constants/gst_rates.dart';

/// Represents the complete result of a GST calculation.
class GstResult {
  /// The base/net amount before GST.
  final double baseAmount;

  /// The CGST amount (half of total GST for intra-state).
  final double cgst;

  /// The SGST amount (half of total GST for intra-state).
  final double sgst;

  /// The IGST amount (full GST for inter-state).
  final double igst;

  /// The total amount including GST.
  final double totalAmount;

  /// The effective GST rate applied.
  final double rate;

  /// Whether the original amount was inclusive of GST.
  final bool isInclusive;

  const GstResult({
    required this.baseAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
    required this.rate,
    this.isInclusive = false,
  });

  @override
  String toString() =>
      'GstResult(base: $baseAmount, cgst: $cgst, sgst: $sgst, igst: $igst, total: $totalAmount, rate: $rate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GstResult &&
          baseAmount == other.baseAmount &&
          cgst == other.cgst &&
          sgst == other.sgst &&
          igst == other.igst &&
          totalAmount == other.totalAmount &&
          rate == other.rate;

  @override
  int get hashCode =>
      baseAmount.hashCode ^
      cgst.hashCode ^
      sgst.hashCode ^
      igst.hashCode ^
      totalAmount.hashCode ^
      rate.hashCode;
}

/// Core GST mathematical engine.
///
/// Handles all GST calculations including:
/// - Exclusive calculation (GST added on top of base amount)
/// - Inclusive calculation (GST extracted from total amount)
/// - Intra-state tax splitting (CGST + SGST)
/// - Inter-state tax (IGST only)
class GstMath {
  GstMath._();

  /// Calculates GST based on the given parameters.
  ///
  /// [amount] - The input amount (base for exclusive, total for inclusive).
  /// [rate] - The GST rate percentage (e.g., 18.0 for 18%).
  /// [isInclusive] - Whether [amount] already includes GST.
  /// [isIntraState] - Whether to split into CGST/SGST (true) or use IGST (false).
  ///
  /// Returns a [GstResult] with all computed values.
  static GstResult calculate({
    required double amount,
    required double rate,
    bool isInclusive = false,
    bool isIntraState = true,
  }) {
    if (amount < 0) {
      throw ArgumentError('Amount cannot be negative: $amount');
    }
    if (rate < 0 || rate > 100) {
      throw ArgumentError('Rate must be between 0 and 100: $rate');
    }

    final double factor = rate / GstRates.percentageFactor;
    final double baseAmount;
    final double totalGst;

    if (isInclusive) {
      // Amount includes GST: Total = Base + (Base * rate/100)
      // Base = Total / (1 + rate/100)
      baseAmount = amount / (1.0 + factor);
      totalGst = amount - baseAmount;
    } else {
      // Amount is exclusive of GST: GST = Base * rate/100
      baseAmount = amount;
      totalGst = amount * factor;
    }

    final double halfGst = totalGst / 2.0;

    return GstResult(
      baseAmount: baseAmount,
      cgst: isIntraState ? halfGst : 0.0,
      sgst: isIntraState ? halfGst : 0.0,
      igst: isIntraState ? 0.0 : totalGst,
      totalAmount: isInclusive ? amount : (baseAmount + totalGst),
      rate: rate,
      isInclusive: isInclusive,
    );
  }
}
