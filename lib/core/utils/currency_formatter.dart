import 'package:intl/intl.dart';

/// Utility for formatting currency values in Indian Rupee (₹) format.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formatter for Indian locale with ₹ symbol.
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    locale: 'en_IN',
  );

  /// Formats the given [amount] as Indian Rupee currency string.
  ///
  /// Example: `format(1000.5)` returns `₹1,000.50`
  static String format(double amount) => _currencyFormat.format(amount);
}
