/// Formats a GST rate for display.
///
/// Integer rates render without decimals (`18.0` → `18`), fractional rates
/// with up to two decimals and trailing zeros stripped (`0.25` → `0.25`,
/// `1.5` → `1.5`, `12.50` → `12.5`). This is the single rate formatter for
/// the app (plan 010's 0%/0.25% slabs reuse it) — do not introduce another.
String formatRate(double rate) {
  final text = rate.toStringAsFixed(2);
  final trimmed = text.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
