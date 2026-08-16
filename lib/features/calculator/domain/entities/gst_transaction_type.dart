/// Defines whether the transaction is within the same state or across states.
enum GstTransactionType {
  /// Transaction within the same state.
  /// Tax is split equally into CGST and SGST.
  intraState,

  /// Transaction across different states.
  /// Tax is applied as IGST only.
  interState;

  /// Returns a human-readable label for this transaction type.
  String get label {
    return switch (this) {
      GstTransactionType.intraState => 'Intra-State (CGST + SGST)',
      GstTransactionType.interState => 'Inter-State (IGST)',
    };
  }

  /// Returns a short label for UI display.
  String get shortLabel {
    return switch (this) {
      GstTransactionType.intraState => 'Intra-State',
      GstTransactionType.interState => 'Inter-State',
    };
  }
}
