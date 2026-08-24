import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/features/csv_export/csv_export.dart';
import 'package:gst_calculator/features/history/data/models/history_entry.dart';

void main() {
  group('CsvExport', () {
    final entries = [
      HistoryEntry(
        id: '1',
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
      ),
      HistoryEntry(
        id: '2',
        amountText: '500',
        rate: 5.0,
        isInclusive: true,
        isIntraState: false,
        baseAmount: 476.19,
        cgst: 0.0,
        sgst: 0.0,
        igst: 23.81,
        totalAmount: 500.0,
        timestamp: 1723737600000,
      ),
    ];

    group('buildHistoryCsv', () {
      test('contains header row', () {
        final csv = CsvExport.buildHistoryCsv(entries);
        expect(csv, contains('Date,Time,Amount,GST Rate %'));
        expect(csv, contains('Tax Type,Transaction Type'));
        expect(csv, contains('Base Amount,CGST,SGST,IGST,Total Amount'));
      });

      test('contains data rows for each entry', () {
        final csv = CsvExport.buildHistoryCsv(entries);
        final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
        // Header + 2 data rows
        expect(lines.length, 3);
      });

      test('formats rates correctly', () {
        final csv = CsvExport.buildHistoryCsv(entries);
        expect(csv, contains('18.0'));
        expect(csv, contains('5.0'));
      });

      test('formats tax type labels', () {
        final csv = CsvExport.buildHistoryCsv(entries);
        expect(csv, contains('Exclusive'));
        expect(csv, contains('Inclusive'));
      });

      test('formats transaction type labels', () {
        final csv = CsvExport.buildHistoryCsv(entries);
        expect(csv, contains('Intra-State'));
        expect(csv, contains('Inter-State'));
      });

      test('handles empty list', () {
        final csv = CsvExport.buildHistoryCsv([]);
        final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
        // Only header row
        expect(lines.length, 1);
      });

      test('escapes values containing commas', () {
        final entryWithComma = HistoryEntry(
          id: '3',
          amountText: '1,000',
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
        final csv = CsvExport.buildHistoryCsv([entryWithComma]);
        // The amount "1,000" should be quoted
        expect(csv, contains('"1,000"'));
      });
    });
  });
}
