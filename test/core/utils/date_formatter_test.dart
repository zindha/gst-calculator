import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 8, 14, 9, 5);
    final midnight = DateTime(2026, 1, 1, 0, 0);
    final endOfDay = DateTime(2026, 12, 31, 23, 59);

    group('date', () {
      test('formats dd/MM/yyyy', () {
        expect(DateFormatter.date(testDate), '14/08/2026');
      });

      test('pads single-digit day and month', () {
        expect(DateFormatter.date(midnight), '01/01/2026');
      });

      test('handles end of year', () {
        expect(DateFormatter.date(endOfDay), '31/12/2026');
      });
    });

    group('time', () {
      test('formats HH:mm', () {
        expect(DateFormatter.time(testDate), '09:05');
      });

      test('pads single-digit hour and minute', () {
        expect(DateFormatter.time(midnight), '00:00');
      });

      test('handles end of day', () {
        expect(DateFormatter.time(endOfDay), '23:59');
      });
    });

    group('dateTime', () {
      test('combines date and time', () {
        expect(DateFormatter.dateTime(testDate), '14/08/2026 09:05');
      });

      test('midnight', () {
        expect(DateFormatter.dateTime(midnight), '01/01/2026 00:00');
      });
    });
  });
}
