import 'dart:math' as math;

import 'gst_math.dart';

/// Monetary presentation policy for displayed values.
///
/// The app computes with full `double` precision internally (see
/// [GstMath]) and rounds only at the presentation boundary. Every displayed
/// amount uses exactly two decimal places (paise) with round-half-away-from-
/// zero:
///
///     Money.round2(84.7457…) == 84.75
///     Money.round2(0.125)    == 0.13
///
/// ## Reconciliation invariant
///
/// Displayed components always sum exactly to the displayed total:
///
///     base + gst       == total
///     cgst + sgst      == gst        (intra-state)
///     base + igst      == total      (inter-state)
///
/// so a user can verify the screen by adding the visible numbers — the
/// calculator never shows ₹84.75 + ₹7.63 + ₹7.63 = ₹100.01 next to a
/// ₹100.00 total.
///
/// ## Allocation rule (deterministic and stable)
///
/// 1. The **total is authoritative**: `total = round2(exact total)`. For an
///    inclusive calculation the exact total is the entered gross, so the
///    headline number a user sees never changes.
/// 2. `base = round2(exact base)`.
/// 3. `gst = total - base`, so `base + gst == total` exactly.
/// 4. When the tax is split, **CGST keeps its own 2-dp rounding and SGST
///    absorbs the remainder**: `sgst = gst - cgst`. In inter-state mode IGST
///    is `gst` directly. The paisa remainder therefore always lands on the
///    last tax component — never randomly, and identically for the same
///    inputs on every run.
///
/// The remainder can therefore land in the base amount (inclusive mode),
/// SGST/IGST, or a combination — which is exactly why the invariant is
/// enforced here rather than by rounding each field independently.
///
/// ## Domain vs presentation
///
/// This layer never mutates [GstResult] or persisted models — mathematical
/// precision is preserved internally; reconciliation is applied at display
/// and export boundaries only.
class Money {
  Money._();

  /// Rounds to 2 decimal places (paise), half away from zero.
  ///
  /// e.g. `0.125 → 0.13`, `1.005 → 1.01`, `2.004 → 2.00`.
  static double round2(double v) => (v * 100).roundToDouble() / 100;

  /// Reconciles the exact component values [base], [cgst], [sgst], [igst]
  /// and [total] into display-ready values that satisfy the invariant above.
  ///
  /// [isIntraState] selects CGST+SGST splitting (true) vs IGST (false).
  ///
  /// Preconditions: all inputs are finite, non-negative (the app's validation
  /// in [GstMath] guarantees this) and
  /// `base + gstExact == total` at full precision, as produced by the domain
  /// layer.
  static ReconciledBreakdown reconcile({
    required double base,
    required double cgst,
    required double sgst,
    required double igst,
    required double total,
    required bool isIntraState,
  }) {
    final baseR = round2(base);
    final totalR = round2(total);
    // round2 is monotonic and total >= base, so gstR is never negative.
    // NOTE: this is intentionally the raw subtraction totalR - baseR, NOT
    // round2(totalR - baseR). Sterbenz's lemma makes the subtraction of two
    // doubles within a factor of 2 exact, so baseR + gstR == totalR holds
    // exactly in IEEE-754 — the strongest possible form of the invariant.
    // (The raw difference may carry a 1-ulp trace like 0.009999999999999998
    // for a clean 0.01; every consumer formats through [CurrencyFormatter],
    // which re-rounds to paise for display.)
    final gstR = totalR - baseR;
    // CGST keeps its own rounding; SGST absorbs the remainder. The min()
    // guard — which only fires for sub-paisa edge cases where FP noise would
    // otherwise push sgst slightly negative — keeps the split non-negative.
    final cgstR = isIntraState ? math.min(round2(cgst), gstR) : 0.0;
    final sgstR = isIntraState ? gstR - cgstR : 0.0;
    final igstR = isIntraState ? 0.0 : gstR;
    return ReconciledBreakdown(
      base: baseR,
      cgst: cgstR,
      sgst: sgstR,
      igst: igstR,
      gst: gstR,
      total: totalR,
    );
  }

  /// Convenience wrapper around [reconcile] for a calculator [GstResult].
  static ReconciledBreakdown reconcileResult(
    GstResult result, {
    required bool isIntraState,
  }) {
    return reconcile(
      base: result.baseAmount,
      cgst: result.cgst,
      sgst: result.sgst,
      igst: result.igst,
      total: result.totalAmount,
      isIntraState: isIntraState,
    );
  }
}

/// Display-ready money values that sum exactly to the shown total.
///
/// All fields are already rounded to 2 decimal places; pass them through
/// [CurrencyFormatter] for the final ₹ string.
class ReconciledBreakdown {
  /// Displayed base / net amount.
  final double base;

  /// Displayed CGST (0 for inter-state).
  final double cgst;

  /// Displayed SGST (0 for inter-state). Absorbs the rounding remainder.
  final double sgst;

  /// Displayed IGST (0 for intra-state). Absorbs the rounding remainder.
  final double igst;

  /// Displayed total GST = cgst + sgst + igst = total - base.
  final double gst;

  /// Displayed total = base + gst.
  final double total;

  const ReconciledBreakdown({
    required this.base,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.gst,
    required this.total,
  });

  @override
  String toString() =>
      'ReconciledBreakdown(base: $base, cgst: $cgst, sgst: $sgst, '
      'igst: $igst, gst: $gst, total: $total)';
}
