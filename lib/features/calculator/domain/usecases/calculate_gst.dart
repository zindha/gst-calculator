import '../../../../core/utils/gst_math.dart';
import '../entities/gst_calculation_type.dart';
import '../entities/gst_transaction_type.dart';

/// Use case that encapsulates the GST calculation logic.
///
/// Takes raw input values and returns a [GstResult].
class CalculateGstUseCase {
  /// Calculates GST based on the provided parameters.
  ///
  /// [amount] - The parsed double value of the input amount.
  /// [rate] - The GST rate percentage to apply.
  /// [calculationType] - Whether the amount is exclusive or inclusive.
  /// [transactionType] - Whether the transaction is intra-state or inter-state.
  ///
  /// Returns a [GstResult] or `null` if the amount is invalid (<= 0).
  GstResult? execute({
    required double amount,
    required double rate,
    required GstCalculationType calculationType,
    required GstTransactionType transactionType,
  }) {
    if (amount <= 0) return null;

    try {
      return GstMath.calculate(
        amount: amount,
        rate: rate,
        isInclusive: calculationType == GstCalculationType.inclusive,
        isIntraState: transactionType == GstTransactionType.intraState,
      );
    } catch (_) {
      return null;
    }
  }
}
