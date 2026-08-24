import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rate_formatter.dart';

/// A single saved GST calculation entry.
class HistoryEntry {
  /// Unique identifier for this entry.
  final String id;

  /// The input amount text as typed by the user.
  final String amountText;

  /// The effective GST rate percentage applied.
  final double rate;

  /// Whether the calculation was exclusive (false) or inclusive (true).
  final bool isInclusive;

  /// Whether the transaction was intra-state (true) or inter-state (false).
  final bool isIntraState;

  /// The computed base/net amount.
  final double baseAmount;

  /// The computed CGST amount.
  final double cgst;

  /// The computed SGST amount.
  final double sgst;

  /// The computed IGST amount.
  final double igst;

  /// The total amount (gross).
  final double totalAmount;

  /// Timestamp in milliseconds since epoch.
  final int timestamp;

  const HistoryEntry({
    required this.id,
    required this.amountText,
    required this.rate,
    required this.isInclusive,
    required this.isIntraState,
    required this.baseAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
    required this.timestamp,
  });

  /// Creates a summary string for display.
  String get summary {
    final amt = amountText;
    // formatRate renders 18.0 as '18' and 0.25 as '0.25' — the same
    // convention as every other rate label in the app.
    if (isInclusive) {
      return '₹$amt (gross) @ ${formatRate(rate)}% → Base: ${CurrencyFormatter.format(baseAmount)}';
    }
    return '₹$amt @ ${formatRate(rate)}% → Total: ${CurrencyFormatter.format(totalAmount)}';
  }

  // ── Serialisation ───────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'amountText': amountText,
    'rate': rate,
    'isInclusive': isInclusive,
    'isIntraState': isIntraState,
    'baseAmount': baseAmount,
    'cgst': cgst,
    'sgst': sgst,
    'igst': igst,
    'totalAmount': totalAmount,
    'timestamp': timestamp,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    amountText: json['amountText'] as String,
    rate: (json['rate'] as num).toDouble(),
    isInclusive: json['isInclusive'] as bool,
    isIntraState: json['isIntraState'] as bool,
    baseAmount: (json['baseAmount'] as num).toDouble(),
    cgst: (json['cgst'] as num).toDouble(),
    sgst: (json['sgst'] as num).toDouble(),
    igst: (json['igst'] as num).toDouble(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    timestamp: json['timestamp'] as int,
  );
}
