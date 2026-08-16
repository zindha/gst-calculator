import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gst_calculator/app.dart';
import 'package:gst_calculator/features/history/presentation/screens/history_screen.dart';
import 'package:gst_calculator/features/settings/presentation/screens/settings_screen.dart';

final _captured = <FlutterErrorDetails>[];

void _installCapture() {
  _captured.clear();
  // Keep a reference to the binding's own handler: overflows are captured for
  // the `_dump` diagnostics AND passed through so the framework still records
  // the exception and can report it properly if an `expect` fails while the
  // override is installed. The override must be restored before the next test
  // runs, otherwise the test binding's error tracking trips its own assertion.
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    _captured.add(details);
    original?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = original;
  });
}

Future<void> _finishOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
  await tester.pumpAndSettle();
  if (tester.any(find.text('Skip'))) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }
}

void _dump(String tag) {
  final sb = StringBuffer();
  sb.writeln('=== $tag ===');
  for (final d in _captured) {
    sb.writeln('CAPTURED: ${d.toString()}');
  }
  final e =
      WidgetsBinding.instance is TestWidgetsFlutterBinding
          ? (WidgetsBinding.instance as TestWidgetsFlutterBinding)
              .takeException()
          : null;
  if (e != null) sb.writeln('TAKEN: $e');
  File('/tmp/overflow_dump.txt').writeAsStringSync(sb.toString());
}

void main() {
  testWidgets('Calculator: no overflow, correct totals, all tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0; // 360x780 logical
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);
    _dump('after onboarding');

    await tester.enterText(find.byType(TextField).first, '10000');
    await tester.pumpAndSettle();
    _dump('after enterText');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );

    // Default: exclusive + 18% + intra-state -> total ₹11,800.00
    expect(find.text('₹11,800.00'), findsOneWidget);
    expect(find.text('₹900.00'), findsNWidgets(2)); // CGST + SGST
    expect(find.text('₹10,000.00'), findsOneWidget); // base

    expect(find.text('Add GST'), findsOneWidget);
    expect(find.text('Remove GST'), findsOneWidget);

    await tester.tap(find.text('Remove GST'));
    await tester.pumpAndSettle();
    _dump('after remove gst');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );

    await tester.tap(find.text('5%'));
    await tester.pumpAndSettle();
    _dump('after 5%');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );

    await tester.tap(find.byTooltip('Clear all'));
    await tester.pumpAndSettle();
    _dump('after clear');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );

    for (final label in ['History', 'Settings']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      _dump('after tab $label');
      expect(
        _captured,
        isEmpty,
        reason: _captured.map((d) => d.toString()).join('\n---\n'),
      );
    }
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
  });

  testWidgets('Small phone + large text scale: no overflow', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);
    await tester.enterText(find.byType(TextField).first, '999999');
    await tester.pumpAndSettle();
    // Flush the auto-save debounce so no timer is pending at test end.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Scroll to the bottom to render the result + quick actions.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    _dump('small phone end');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
  });

  testWidgets('Small phone + 2.0x text scale: no overflow', (tester) async {
    // Plan 005: the calculator clamps scaling at the platform maximum (2.0x)
    // so a user with a large system font gets real scaling, not 1.3x. Guard
    // the max scale with the longest plausible amount + a long result.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);
    await tester.enterText(find.byType(TextField).first, '99999999.99');
    await tester.pumpAndSettle();
    // Flush the auto-save debounce so no timer is pending at test end.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Scroll through the hero, result card and quick actions.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share'));
    await tester.pumpAndSettle();
    _dump('small phone 2.0x end');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
  });

  testWidgets('Dark theme renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Calculate'))).brightness,
      Brightness.dark,
    );

    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pumpAndSettle();
    // Flush the auto-save debounce so no timer is pending at test end.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    _dump('dark theme');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
    expect(find.text('₹5,900.00'), findsOneWidget); // 5000 + 18%

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
  });

  testWidgets('Small phone + large text: History and Settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0; // 360x640 logical
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    // A calculation auto-saves to history, giving the History list content.
    await tester.enterText(find.byType(TextField).first, '999999');
    await tester.pumpAndSettle();
    // The auto-save debounce must elapse before the entry is persisted and
    // visible on the History tab.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // ── History tab: entry rendered + list scrollable, no overflow. ──
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹999999'), findsOneWidget);
    final historyList = find.descendant(
      of: find.byType(HistoryScreen),
      matching: find.byType(ListView),
    );
    await tester.drag(historyList, const Offset(0, -400));
    await tester.pumpAndSettle();
    _dump('history list');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );

    // ── Settings tab: every section renders and scrolls without overflow
    // at large text scale. ──
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear Calculation History'));
    await tester.pumpAndSettle();
    final settingsList = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    await tester.drag(settingsList, const Offset(0, -400));
    await tester.pumpAndSettle();
    _dump('settings large text');
    expect(
      _captured,
      isEmpty,
      reason: _captured.map((d) => d.toString()).join('\n---\n'),
    );
  });
}
