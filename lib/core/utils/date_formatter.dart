import 'package:intl/intl.dart';

/// Utility for formatting dates consistently across the app.
class DateFormatter {
  DateFormatter._();

  /// `dd/MM/yyyy`, e.g. `14/08/2026`.
  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  /// `HH:mm`, e.g. `09:05`.
  static final DateFormat _time = DateFormat('HH:mm');

  /// `dd/MM/yyyy HH:mm`, e.g. `14/08/2026 09:05`.
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  /// Formats [date] as `dd/MM/yyyy`.
  static String date(DateTime date) => _date.format(date);

  /// Formats [date] as `HH:mm`.
  static String time(DateTime date) => _time.format(date);

  /// Formats [date] as `dd/MM/yyyy HH:mm`.
  static String dateTime(DateTime date) => _dateTime.format(date);
}
