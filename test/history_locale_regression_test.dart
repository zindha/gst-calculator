import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gst_calculator/core/theme/app_theme.dart';
import 'package:gst_calculator/core/utils/date_formatter.dart';
import 'package:gst_calculator/features/history/data/models/history_entry.dart';
import 'package:gst_calculator/features/history/presentation/widgets/history_list_item.dart';

/// Mirrors `main.dart`, which sets `Intl.defaultLocale = 'en_IN'` before
/// `runApp`. `intl` only bundles date symbols for en_US/en_GB, so any date
/// formatting through `DateFormat` under this locale throws
/// `LocaleDataException` unless `initializeDateFormatting()` has run — which
/// used to gray out the entire History screen on real devices. These tests
/// guard the locale-proof `DateFormatter` that replaced it.
void _useAppLocale() {
  Intl.defaultLocale = 'en_IN';
}

HistoryEntry makeEntry(String id) => HistoryEntry(
  id: id,
  amountText: '1000',
  rate: 18,
  isInclusive: false,
  isIntraState: true,
  baseAmount: 1000,
  cgst: 90,
  sgst: 90,
  igst: 0,
  totalAmount: 1180,
  timestamp: DateTime(2026, 8, 14, 9, 5).millisecondsSinceEpoch,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DateFormatter is locale-proof under en_IN', () {
    _useAppLocale();
    final dt = DateTime(2026, 8, 14, 9, 5);
    expect(DateFormatter.date(dt), '14/08/2026');
    expect(DateFormatter.time(dt), '09:05');
    expect(DateFormatter.dateTime(dt), '14/08/2026 09:05');
  });

  testWidgets('history items render under en_IN without any build error',
      (tester) async {
    _useAppLocale();
    SharedPreferences.setMockInitialValues({});

    final errors = <FlutterErrorDetails>[];
    final recorder = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, i) =>
                  HistoryListItem(entry: makeEntry('e$i'), onTap: () {}),
            ),
          ),
        ),
      ),
    );
    FlutterError.onError = recorder;

    expect(errors, isEmpty, reason: 'item builds must not throw under en_IN');
    expect(find.text('₹1000 @ 18%'), findsNWidgets(3));
    expect(find.textContaining('14/08/2026'), findsNWidgets(3));
  });
}
