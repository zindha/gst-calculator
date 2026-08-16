/// Standard Indian GST slab rates as defined by the government.
class GstRates {
  GstRates._();

  /// Standard GST slabs available for selection.
  static const List<double> standardSlabs = [3.0, 5.0, 12.0, 18.0, 28.0];

  /// The default pre-selected GST slab percentage.
  static const double defaultSlab = 18.0;

  /// Minimum allowed custom slab percentage.
  static const double minCustomSlab = 0.0;

  /// Maximum allowed custom slab percentage.
  static const double maxCustomSlab = 100.0;

  /// The factor to convert percentage to decimal (divide by 100).
  static const double percentageFactor = 100.0;
}
