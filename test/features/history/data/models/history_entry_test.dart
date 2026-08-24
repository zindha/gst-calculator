import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/features/history/data/models/history_entry.dart';

void main() {
  group('HistoryEntry', () {
    final entry = HistoryEntry(
      id: 'test-1',
      amountText: '1000',
      rate: 18.0,
      isInclusive: false,
      isIntraState: true,
      baseAmount: 1000.0,
      cgst: 90.0,
      sgst: 90.0,
      igst: 0.0,
      totalAmount: 1180.0,
      timestamp: 1723651200000,
    );

    group('summary', () {
      test('exclusive shows total amount', () {
        final s = entry.summary;
        expect(s, contains('₹1,180.00'));
        // formatRate renders whole-number slabs without a decimal (18, not
        // 18.0) — same convention as every other rate label in the app.
        expect(s, contains('@ 18%'));
      });

      test('inclusive shows base amount', () {
        final inclusive = HistoryEntry(
          id: 'test-2',
          amountText: '1180',
          rate: 18.0,
          isInclusive: true,
          isIntraState: true,
          baseAmount: 1000.0,
          cgst: 90.0,
          sgst: 90.0,
          igst: 0.0,
          totalAmount: 1180.0,
          timestamp: 1723651200000,
        );
        final s = inclusive.summary;
        expect(s, contains('₹1,000.00'));
        expect(s, contains('gross'));
      });
    });

    group('toJson / fromJson', () {
      test('round-trips through JSON', () {
        final json = entry.toJson();
        final restored = HistoryEntry.fromJson(json);

        expect(restored.id, entry.id);
        expect(restored.amountText, entry.amountText);
        expect(restored.rate, entry.rate);
        expect(restored.isInclusive, entry.isInclusive);
        expect(restored.isIntraState, entry.isIntraState);
        expect(restored.baseAmount, entry.baseAmount);
        expect(restored.cgst, entry.cgst);
        expect(restored.sgst, entry.sgst);
        expect(restored.igst, entry.igst);
        expect(restored.totalAmount, entry.totalAmount);
        expect(restored.timestamp, entry.timestamp);
      });

      test('JSON contains all expected keys', () {
        final json = entry.toJson();
        expect(json.keys, containsAll([
          'id', 'amountText', 'rate', 'isInclusive', 'isIntraState',
          'baseAmount', 'cgst', 'sgst', 'igst', 'totalAmount', 'timestamp',
        ]));
      });

      test('handles fractional rate in JSON', () {
        final fractional = HistoryEntry(
          id: 'f-1',
          amountText: '500',
          rate: 0.25,
          isInclusive: false,
          isIntraState: false,
          baseAmount: 500.0,
          cgst: 0.0,
          sgst: 0.0,
          igst: 1.25,
          totalAmount: 501.25,
          timestamp: 1723651200000,
        );
        final json = fractional.toJson();
        final restored = HistoryEntry.fromJson(json);
        expect(restored.rate, 0.25);
        expect(restored.igst, 1.25);
      });
    });
  });
}
