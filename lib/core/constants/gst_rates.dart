/// Standard Indian GST slab rates as defined by the government.
class GstRates {
  GstRates._();

  /// Standard GST slabs available for selection.
  ///
  /// The full Indian slab structure: 0% (nil-rated goods), 0.25% (rough
  /// diamonds / precious stones), 3% (gold, cut & polished diamonds),
  /// 5%, 12%, 18%, 28%.
  static const List<double> standardSlabs = [
    0.0, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0,
  ];

  /// The default pre-selected GST slab percentage.
  static const double defaultSlab = 18.0;

  /// Minimum allowed custom slab percentage.
  static const double minCustomSlab = 0.0;

  /// Maximum allowed custom slab percentage.
  static const double maxCustomSlab = 100.0;

  /// The factor to convert percentage to decimal (divide by 100).
  static const double percentageFactor = 100.0;
}
