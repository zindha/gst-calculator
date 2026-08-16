import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/gst_math.dart';
import 'package:gst_calculator/core/utils/money.dart';

/// All reconciled values are 2-dp doubles, so exact equality is the correct
/// assertion (never closeTo on reconciled fields).
///
/// Note on floating point: two-term sums (base + gst, cgst + sgst) are exact
/// in IEEE-754 because the subtraction that derives the remainder is exact
/// (Sterbenz). Three-term sums (base + cgst + sgst) can be off by 1 ulp, so
/// they are asserted through [Money.round2] — the 2-decimal domain a user
/// actually adds up. This is a test-technique detail: the displayed paise
/// values always sum exactly to the displayed total.
void main() {
  group('Money.round2', () {
    test('rounds to paise, half away from zero', () {
      expect(Money.round2(84.7457627118644), 84.75);
      expect(Money.round2(15.2542372881356), 15.25);
      expect(Money.round2(7.6271186440678), 7.63);
      expect(Money.round2(0.125), 0.13); // 12.5 paise rounds up
      expect(Money.round2(-0.125), -0.13); // negative half rounds away
      // 1.005 is not exactly representable in IEEE-754 (it is 1.00499…), so
      // it rounds down to 1.00 — document the FP reality rather than fight it.
      expect(Money.round2(1.005), 1.00);
      expect(Money.round2(2.004), 2.00);
      expect(Money.round2(0.0), 0.0);
      expect(Money.round2(999999999.999), 1000000000.00);
    });
  });

  group('Money.reconcile - Exclusive (base + GST)', () {
    test('₹1,000 @ 18% intra-state: clean whole-paise split', () {
      final r = GstMath.calculate(
        amount: 1000,
        rate: 18,
        isInclusive: false,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.base, 1000.00);
      expect(b.gst, 180.00);
      expect(b.cgst, 90.00);
      expect(b.sgst, 90.00);
      expect(b.total, 1180.00);
      expect(b.base + b.gst, b.total);
      expect(b.cgst + b.sgst, b.gst);
    });

    test('₹100 @ 18% intra-state', () {
      final r = GstMath.calculate(
        amount: 100,
        rate: 18,
        isInclusive: false,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.base, 100.00);
      expect(b.gst, 18.00);
      expect(b.cgst, 9.00);
      expect(b.sgst, 9.00);
      expect(b.total, 118.00);
      expect(Money.round2(b.base + b.cgst + b.sgst), 118.00);
    });

    test('₹99.99 @ 0.25% intra-state: fractional rate reconciles', () {
      final r = GstMath.calculate(
        amount: 99.99,
        rate: 0.25,
        isInclusive: false,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.base, 99.99);
      expect(b.total, 100.24); // round2(99.99 * 1.0025)
      expect(b.base + b.gst, b.total);
      expect(b.cgst + b.sgst, b.gst);
      expect(b.cgst, greaterThanOrEqualTo(0));
      expect(b.sgst, greaterThanOrEqualTo(0));
    });

    test('tiny amount where GST rounds to one paisa', () {
      final r = GstMath.calculate(
        amount: 0.03,
        rate: 18,
        isInclusive: false,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.base, 0.03);
      expect(b.total, 0.04); // round2(0.0354)
      expect(b.base + b.gst, b.total);
      expect(b.cgst + b.sgst, b.gst);
    });
  });

  group('Money.reconcile - Inclusive (gross includes GST)', () {
    test('₹100 @ 18% intra-state reconciles exactly (reported regression)', () {
      final r = GstMath.calculate(
        amount: 100,
        rate: 18,
        isInclusive: true,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      // The headline total never changes: round2 of the exact gross.
      expect(b.total, 100.00);
      // base = round2(100 / 1.18).
      expect(b.base, 84.75);
      // gst = total - base, so base + gst == total exactly.
      expect(b.gst, 15.25);
      // CGST keeps its own rounding; SGST absorbs the paisa remainder.
      expect(b.cgst, 7.63);
      expect(b.sgst, 7.62);
      // The user-visible check: 84.75 + 7.63 + 7.62 == 100.00.
      expect(Money.round2(b.base + b.cgst + b.sgst), 100.00);
      expect(b.cgst + b.sgst, b.gst);
    });

    test('₹1,180 @ 18% intra-state: base ₹1,000, GST ₹180', () {
      final r = GstMath.calculate(
        amount: 1180,
        rate: 18,
        isInclusive: true,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.total, 1180.00);
      expect(b.base, 1000.00);
      expect(b.gst, 180.00);
      expect(b.cgst, 90.00);
      expect(b.sgst, 90.00);
      expect(Money.round2(b.base + b.cgst + b.sgst), 1180.00);
    });

    test('₹99.99 @ 0.25% inclusive: parts sum exactly', () {
      final r = GstMath.calculate(
        amount: 99.99,
        rate: 0.25,
        isInclusive: true,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.total, 99.99);
      expect(b.base + b.gst, 99.99);
      expect(b.cgst + b.sgst, b.gst);
      expect(Money.round2(b.base + b.cgst + b.sgst), 99.99);
      expect(b.cgst, greaterThanOrEqualTo(0));
      expect(b.sgst, greaterThanOrEqualTo(0));
    });

    test('₹525 @ 5% inclusive', () {
      final r = GstMath.calculate(
        amount: 525,
        rate: 5,
        isInclusive: true,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.total, 525.00);
      expect(b.base, 500.00);
      expect(b.gst, 25.00);
      expect(Money.round2(b.base + b.cgst + b.sgst), 525.00);
    });
  });

  group('Money.reconcile - Inter-state (IGST)', () {
    test('IGST carries the full GST and reconciles with the total', () {
      for (final (amount, rate, inclusive) in [
        (100.0, 18.0, true),
        (100.0, 18.0, false),
        (1000.0, 12.0, false),
        (99.99, 0.25, true),
        (2500.0, 12.0, false),
      ]) {
        final r = GstMath.calculate(
          amount: amount,
          rate: rate,
          isInclusive: inclusive,
          isIntraState: false,
        );
        final b = Money.reconcileResult(r, isIntraState: false);
        expect(b.cgst, 0.0, reason: 'inter-state has no CGST');
        expect(b.sgst, 0.0, reason: 'inter-state has no SGST');
        expect(b.igst, b.gst);
        expect(b.base + b.igst, b.total);
      }
    });
  });

  group('Money.reconcile - 0% rate', () {
    test('no GST, base equals total, no split', () {
      final r = GstMath.calculate(
        amount: 1000,
        rate: 0,
        isInclusive: false,
        isIntraState: true,
      );
      final b = Money.reconcileResult(r, isIntraState: true);
      expect(b.gst, 0.0);
      expect(b.cgst, 0.0);
      expect(b.sgst, 0.0);
      expect(b.base, 1000.00);
      expect(b.total, 1000.00);
    });
  });

  group('Property: displayed components always sum to displayed total', () {
    const amounts = [
      0.01, 0.03, 0.05, 0.99, 1.00, 1.5, 9.99, 10.00, 50.00, 99.99, 100.00,
      100.01, 118.00, 525.00, 892.86, 1000.00, 9999.99, 100000.00,
      999999999.99,
    ];
    const rates = [0.0, 0.25, 1.5, 3.0, 5.0, 12.0, 12.5, 18.0, 28.0, 50.0, 99.99];

    for (final amount in amounts) {
      for (final rate in rates) {
        test('amount $amount @ $rate% (exclusive, intra)', () {
          _assertInvariants(
            GstMath.calculate(
              amount: amount,
              rate: rate,
              isInclusive: false,
              isIntraState: true,
            ),
            isIntraState: true,
          );
        });
        test('amount $amount @ $rate% (inclusive, intra)', () {
          _assertInvariants(
            GstMath.calculate(
              amount: amount,
              rate: rate,
              isInclusive: true,
              isIntraState: true,
            ),
            isIntraState: true,
          );
        });
        test('amount $amount @ $rate% (exclusive, inter)', () {
          _assertInvariants(
            GstMath.calculate(
              amount: amount,
              rate: rate,
              isInclusive: false,
              isIntraState: false,
            ),
            isIntraState: false,
          );
        });
        test('amount $amount @ $rate% (inclusive, inter)', () {
          _assertInvariants(
            GstMath.calculate(
              amount: amount,
              rate: rate,
              isInclusive: true,
              isIntraState: false,
            ),
            isIntraState: false,
          );
        });
      }
    }
  });
}

/// The monetary presentation invariant, verified on the exact 2-dp values the
/// UI shows (not raw doubles):
///   - base + gst == total
///   - cgst + sgst == gst (intra) / base + igst == total (inter)
///   - every component is non-negative
///   - the displayed total is round2 of the exact total (headline never moves)
///   - the displayed base is round2 of the exact base
void _assertInvariants(GstResult result, {required bool isIntraState}) {
  final b = Money.reconcileResult(result, isIntraState: isIntraState);

  expect(b.base + b.gst, b.total, reason: 'base + gst must equal total');
  expect(b.total, Money.round2(result.totalAmount),
      reason: 'displayed total is round2 of the exact total');
  expect(b.base, Money.round2(result.baseAmount),
      reason: 'displayed base is round2 of the exact base');
  expect(b.base, greaterThanOrEqualTo(0));
  expect(b.gst, greaterThanOrEqualTo(0));
  expect(b.total, greaterThanOrEqualTo(0));

  if (isIntraState) {
    expect(b.cgst + b.sgst, b.gst,
        reason: 'cgst + sgst must equal displayed gst');
    expect(b.igst, 0.0);
    expect(b.cgst, greaterThanOrEqualTo(0));
    expect(b.sgst, greaterThanOrEqualTo(0));
  } else {
    expect(b.igst, b.gst);
    expect(b.cgst, 0.0);
    expect(b.sgst, 0.0);
  }

  // Full user-visible check: base + tax components == total, in the 2-decimal
  // domain users add up (three-term FP sums can be 1 ulp off; see file doc).
  expect(Money.round2(b.base + b.cgst + b.sgst + b.igst), b.total);
}
