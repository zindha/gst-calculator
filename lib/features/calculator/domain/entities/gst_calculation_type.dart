/// Defines whether the input amount includes GST or not.
enum GstCalculationType {
  /// GST is calculated on top of the base amount.
  /// Formula: Total = Base + (Base * Rate%)
  exclusive,

  /// GST is extracted from the total amount.
  /// Formula: Base = Total / (1 + Rate%)
  inclusive;

  /// Returns a human-readable label for this calculation type.
  String get label {
    return switch (this) {
      GstCalculationType.exclusive => 'Exclusive (+GST)',
      GstCalculationType.inclusive => 'Inclusive (-GST)',
    };
  }

  /// Returns a short label for UI display.
  String get shortLabel {
    return switch (this) {
      GstCalculationType.exclusive => '+GST',
      GstCalculationType.inclusive => '-GST',
    };
  }
}
