/// Utility for formatting dates consistently across the app.
///
/// Implemented without `intl` so formatting can never depend on locale data
/// being initialized. `intl` only bundles date symbols for `en_US`/`en_GB`,
/// while the app sets `Intl.defaultLocale = 'en_IN'` in `main.dart`; calling
/// `DateFormat` under that locale throws `LocaleDataException` unless
/// `initializeDateFormatting()` has run. That exception was thrown while
/// building every History list item on the real app, which rendered the
/// History screen as a solid gray block in release builds.
///
/// All patterns here are purely numeric (`dd/MM/yyyy`, `HH:mm`), so manual
/// zero-padding produces byte-identical output to `DateFormat` and is
/// immune to locale, device language, and initialization state.
class DateFormatter {
  DateFormatter._();

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// `dd/MM/yyyy`, e.g. `14/08/2026`.
  static String date(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  /// `HH:mm`, e.g. `09:05`.
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// `dd/MM/yyyy HH:mm`, e.g. `14/08/2026 09:05`.
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';
}
