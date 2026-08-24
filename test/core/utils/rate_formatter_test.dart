import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/rate_formatter.dart';

void main() {
  group('formatRate', () {
    test('integer rates render without decimals', () {
      expect(formatRate(0), '0');
      expect(formatRate(3), '3');
      expect(formatRate(5), '5');
      expect(formatRate(12), '12');
      expect(formatRate(18), '18');
      expect(formatRate(28), '28');
    });

    test('fractional rates keep up to three decimals, trailing zeros stripped', () {
      expect(formatRate(0.25), '0.25');
      expect(formatRate(1.5), '1.5');
      expect(formatRate(12.5), '12.5');
      expect(formatRate(7.25), '7.25');
      // Half-rate split label of the 0.25% slab renders exactly, not rounded.
      expect(formatRate(0.125), '0.125');
    });

    test('rates with trailing zeros after decimal are stripped', () {
      expect(formatRate(12.50), '12.5');
      expect(formatRate(5.10), '5.1');
      expect(formatRate(18.00), '18');
    });

    test('zero rate', () {
      expect(formatRate(0), '0');
      expect(formatRate(0.0), '0');
    });

    test('maximum rate', () {
      expect(formatRate(100), '100');
      expect(formatRate(100.0), '100');
    });
  });
}
