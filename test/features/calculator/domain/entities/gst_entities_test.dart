import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/features/calculator/domain/entities/gst_calculation_type.dart';
import 'package:gst_calculator/features/calculator/domain/entities/gst_transaction_type.dart';

void main() {
  group('GstCalculationType', () {
    test('exclusive label is "Exclusive (+GST)"', () {
      expect(GstCalculationType.exclusive.label, 'Exclusive (+GST)');
    });

    test('inclusive label is "Inclusive (-GST)"', () {
      expect(GstCalculationType.inclusive.label, 'Inclusive (-GST)');
    });

    test('exclusive shortLabel is "+GST"', () {
      expect(GstCalculationType.exclusive.shortLabel, '+GST');
    });

    test('inclusive shortLabel is "-GST"', () {
      expect(GstCalculationType.inclusive.shortLabel, '-GST');
    });

    test('has exactly 2 values', () {
      expect(GstCalculationType.values.length, 2);
    });
  });

  group('GstTransactionType', () {
    test('intraState label contains "CGST" and "SGST"', () {
      expect(GstTransactionType.intraState.label, contains('CGST'));
      expect(GstTransactionType.intraState.label, contains('SGST'));
    });

    test('interState label contains "IGST"', () {
      expect(GstTransactionType.interState.label, contains('IGST'));
    });

    test('intraState shortLabel is "Intra-State"', () {
      expect(GstTransactionType.intraState.shortLabel, 'Intra-State');
    });

    test('interState shortLabel is "Inter-State"', () {
      expect(GstTransactionType.interState.shortLabel, 'Inter-State');
    });

    test('has exactly 2 values', () {
      expect(GstTransactionType.values.length, 2);
    });
  });
}
