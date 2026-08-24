import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats whole amounts with ₹ symbol and Indian grouping', () {
      expect(CurrencyFormatter.format(1000), '₹1,000.00');
      expect(CurrencyFormatter.format(100000), '₹1,00,000.00');
      expect(CurrencyFormatter.format(10000000), '₹1,00,00,000.00');
    });

    test('formats decimal amounts', () {
      expect(CurrencyFormatter.format(1000.5), '₹1,000.50');
      expect(CurrencyFormatter.format(99.99), '₹99.99');
      expect(CurrencyFormatter.format(0.5), '₹0.50');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.format(0), '₹0.00');
    });

    test('formats negative amounts', () {
      expect(CurrencyFormatter.format(-1000), '-₹1,000.00');
      expect(CurrencyFormatter.format(-0.5), '-₹0.50');
    });

    test('formats large amounts with Indian lakh/crore grouping', () {
      // ₹1,50,000 = 1.5 lakh
      expect(CurrencyFormatter.format(150000), '₹1,50,000.00');
      // ₹1,00,00,000 = 1 crore
      expect(CurrencyFormatter.format(10000000), '₹1,00,00,000.00');
    });

    test('formats typical GST calculation results', () {
      // 18% on 1000 = 1180
      expect(CurrencyFormatter.format(1180), '₹1,180.00');
      // 5% on 500 = 525
      expect(CurrencyFormatter.format(525), '₹525.00');
      // 28% on 2000 = 2560
      expect(CurrencyFormatter.format(2560), '₹2,560.00');
    });
  });
}
