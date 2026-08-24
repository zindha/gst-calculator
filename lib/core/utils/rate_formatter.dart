/// Formats a GST rate for display.
///
/// Integer rates render without decimals (`18.0` → `18`), fractional rates
/// with trailing zeros stripped (`0.25` → `0.25`, `1.5` → `1.5`,
/// `12.50` → `12.5`, `0.125` → `0.125`). Three decimals are kept so the
/// split labels of the 0.25% slab render exactly (`CGST @ 0.125%`, not a
/// rounded `0.13%`). This is the single rate formatter for the app — do not
/// introduce another.
String formatRate(double rate) {
  final text = rate.toStringAsFixed(3);
  final trimmed = text.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
