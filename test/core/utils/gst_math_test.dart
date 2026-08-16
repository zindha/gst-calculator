import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/gst_math.dart';

void main() {
  group('GstMath.calculate - Exclusive (GST added on top)', () {
    test('18% GST on ₹1,000 exclusive gives ₹180 GST, ₹1,180 total', () {
      final result = GstMath.calculate(
        amount: 1000,
        rate: 18,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(1000, 0.01));
      expect(result.cgst + result.sgst + result.igst, closeTo(180, 0.01));
      expect(result.totalAmount, closeTo(1180, 0.01));
    });

    test('5% GST on ₹500 exclusive gives ₹25 GST, ₹525 total', () {
      final result = GstMath.calculate(
        amount: 500,
        rate: 5,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(500, 0.01));
      expect(result.totalAmount, closeTo(525, 0.01));
    });

    test('28% GST on ₹2,000 exclusive gives ₹560 GST, ₹2,560 total', () {
      final result = GstMath.calculate(
        amount: 2000,
        rate: 28,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(2000, 0.01));
      expect(result.totalAmount, closeTo(2560, 0.01));
    });

    test('0% GST on ₹1,000 exclusive gives zero tax', () {
      final result = GstMath.calculate(
        amount: 1000,
        rate: 0,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(1000, 0.01));
      expect(result.cgst + result.sgst + result.igst, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(1000, 0.01));
    });
  });

  group('GstMath.calculate - Inclusive (GST included)', () {
    test('₹1,180 inclusive at 18% gives base of ₹1,000, GST of ₹180', () {
      final result = GstMath.calculate(
        amount: 1180,
        rate: 18,
        isInclusive: true,
      );

      expect(result.baseAmount, closeTo(1000, 0.01));
      expect(result.cgst + result.sgst + result.igst, closeTo(180, 0.01));
      expect(result.totalAmount, closeTo(1180, 0.01));
    });

    test('₹525 inclusive at 5% gives base of ₹500, GST of ₹25', () {
      final result = GstMath.calculate(
        amount: 525,
        rate: 5,
        isInclusive: true,
      );

      expect(result.baseAmount, closeTo(500, 0.01));
      expect(result.totalAmount, closeTo(525, 0.01));
    });

    test('₹118 inclusive at 18% gives base of ₹100, GST of ₹18', () {
      final result = GstMath.calculate(
        amount: 118,
        rate: 18,
        isInclusive: true,
      );

      expect(result.baseAmount, closeTo(100, 0.01));
      expect(result.totalAmount, closeTo(118, 0.01));
    });
  });

  group('GstMath.calculate - Intra-State (CGST + SGST)', () {
    test('18% on ₹1,000 intra-state splits equally as 9% CGST + 9% SGST', () {
      final result = GstMath.calculate(
        amount: 1000,
        rate: 18,
        isInclusive: false,
        isIntraState: true,
      );

      expect(result.cgst, closeTo(90, 0.01));
      expect(result.sgst, closeTo(90, 0.01));
      expect(result.igst, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(1180, 0.01));
    });
  });

  group('GstMath.calculate - Inter-State (IGST only)', () {
    test('18% on ₹1,000 inter-state applies full IGST of ₹180', () {
      final result = GstMath.calculate(
        amount: 1000,
        rate: 18,
        isInclusive: false,
        isIntraState: false,
      );

      expect(result.cgst, closeTo(0, 0.01));
      expect(result.sgst, closeTo(0, 0.01));
      expect(result.igst, closeTo(180, 0.01));
      expect(result.totalAmount, closeTo(1180, 0.01));
    });

    test('12% on ₹2,500 inter-state gives IGST of ₹300', () {
      final result = GstMath.calculate(
        amount: 2500,
        rate: 12,
        isInclusive: false,
        isIntraState: false,
      );

      expect(result.igst, closeTo(300, 0.01));
      expect(result.totalAmount, closeTo(2800, 0.01));
    });
  });

  group('GstMath.calculate - Edge cases', () {
    test('Amount of 0 returns zeros', () {
      final result = GstMath.calculate(
        amount: 0,
        rate: 18,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(0, 0.01));
    });

    test('Throws on negative amount', () {
      expect(
        () => GstMath.calculate(amount: -100, rate: 18),
        throwsArgumentError,
      );
    });

    test('Throws on rate > 100', () {
      expect(
        () => GstMath.calculate(amount: 100, rate: 101),
        throwsArgumentError,
      );
    });

    test('Throws on negative rate', () {
      expect(
        () => GstMath.calculate(amount: 100, rate: -5),
        throwsArgumentError,
      );
    });

    test('Small amounts with decimal rates work correctly', () {
      final result = GstMath.calculate(
        amount: 99.99,
        rate: 0.25,
        isInclusive: false,
      );

      expect(result.baseAmount, closeTo(99.99, 0.01));
      expect(result.cgst + result.sgst + result.igst, closeTo(0.25, 0.01));
      expect(result.totalAmount, closeTo(100.24, 0.01));
    });
  });
}
