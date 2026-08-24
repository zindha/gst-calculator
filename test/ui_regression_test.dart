import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gst_calculator/app.dart';
import 'package:gst_calculator/core/theme/app_theme.dart';
import 'package:gst_calculator/core/theme/color_presets.dart';
import 'package:gst_calculator/core/theme/theme_extensions.dart';

// ── Harness ──────────────────────────────────────────────────────────────

final _captured = <FlutterErrorDetails>[];
final _shares = <MethodCall>[];

void _installCapture() {
  _captured.clear();
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    _captured.add(details);
    original?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = original;
  });
}

/// Mocks the platform channels used by share_plus and cross_file so plugin
/// calls resolve deterministically in tests. The path_provider mock is
/// required even though the app no longer depends on it directly — sharing a
/// CSV with `XFile.fromData` writes a real temp file, so cross_file resolves
/// the temporary directory through the path_provider channel.
Future<void> _installPluginMocks() async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (call) async {
      _shares.add(call);
      return null;
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => '/tmp', // path_provider expects a plain path String
  );

  addTearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });
}

void _usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0; // 360x780 logical
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
  File('/tmp/regression_dump.txt').writeAsStringSync(sb.toString());
}

String _reason() => _captured.map((d) => d.toString()).join('\n---\n');

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'Calculator: modes, slabs, transaction type, custom rate, copy & share',
    (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      _installCapture();
      await _installPluginMocks();
      await _finishOnboarding(tester);

      // Default: exclusive + 18% + intra-state.
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();
      // Flush the 600ms auto-save debounce so the history write lands
      // deterministically before the test proceeds.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('₹1,180.00'), findsOneWidget); // total
      expect(find.text('₹1,000.00'), findsOneWidget); // base
      expect(find.text('CGST @ 9%'), findsOneWidget);
      expect(find.text('SGST @ 9%'), findsOneWidget);

      // Terminology: exclusive mode uses the same 'Base Amount' label as
      // inclusive mode — no 'Net Amount (Base)' variant.
      expect(find.text('Base Amount'), findsOneWidget);
      expect(find.text('Net Amount (Base)'), findsNothing);
      // Quiet mode confirmation line replaces the loud pill stamps.
      expect(find.text('+GST · CGST + SGST'), findsOneWidget);

      // Switch slab to 12%.
      await tester.tap(find.text('12%'));
      await tester.pumpAndSettle();
      expect(find.text('₹1,120.00'), findsOneWidget);

      // Switch transaction to inter-state → IGST only.
      await tester.tap(find.text('Inter-State'));
      await tester.pumpAndSettle();
      expect(find.text('IGST @ 12%'), findsOneWidget);
      // IGST appears both as the breakdown row and the total GST row.
      expect(find.text('₹120.00'), findsWidgets);
      expect(find.text('₹1,120.00'), findsOneWidget); // total unchanged

      // Switch to inclusive mode: 1000 incl. 12% → base 892.86.
      await tester.tap(find.text('Remove GST'));
      await tester.pumpAndSettle();
      expect(find.text('Base Amount'), findsOneWidget);
      expect(find.text('₹892.86'), findsOneWidget);
      expect(find.text('₹107.14'), findsWidgets); // GST row + IGST row

      // Custom rate via the dialog.
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.text('Custom GST Rate'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Rate (%)'), '25');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      // Custom chip label uses the shared rate formatter: integer rates
      // render without decimals (plan 002 rate-display fix).
      expect(find.text('25%'), findsOneWidget); // custom chip label

      // Copy + Share (scroll the result surface into view first).
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(find.text('Copied to clipboard'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      // Let the floating snackbar fully leave the tree before tapping Share —
      // the snackbar sits over the quick-action row and would otherwise
      // absorb the tap.
      await tester.pumpAndSettle();

      _shares.clear();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(_shares, isNotEmpty, reason: 'Share button should hit share_plus');
      expect(_shares.single.method, 'share');
      expect(
        _shares.single.arguments.toString(),
        contains('GST Calculation Summary'),
      );

      // Clear all resets to the empty state.
      await tester.tap(find.byTooltip('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Your result appears here'), findsOneWidget);

      _dump('calculator interactions');
      expect(_captured, isEmpty, reason: _reason());
    },
  );

  testWidgets('Settings: theme, defaults and clear history', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _installPluginMocks();
    await _finishOnboarding(tester);

    // Seed history so the clear action is enabled. The auto-save debounce
    // must elapse first or the Clear Calculation History tile stays disabled
    // (it requires at least one stored entry).
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Theme picker → Dark. The brand primary must be the icon-derived royal
    // blue in dark mode — the accent picker is gone, so this is the fixed
    // identity, never a user-selected color.
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final settingsCtx = tester.element(find.text('Settings').first);
    expect(Theme.of(settingsCtx).brightness, Brightness.dark);
    expect(
      Theme.of(settingsCtx).colorScheme.primary,
      BrandColors.primaryLight,
      reason: 'dark theme must use the icon-derived royal blue primary',
    );
    expect(
      Theme.of(settingsCtx).gstColors.cgstColor,
      GSTColorScheme.dark.cgstColor,
      reason: 'GST semantic colors must never follow theme changes',
    );

    // No accent customization anywhere: the custom accent feature is removed.
    expect(find.text('Accent Color'), findsNothing);
    expect(find.text('Custom Accent'), findsNothing);
    expect(find.text('Choose Accent Color'), findsNothing);
    expect(find.text('Reset'), findsNothing);

    // Defaults: 12% slab, inclusive, inter-state.
    await tester.ensureVisible(find.text('Default GST Rate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default GST Rate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12%'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Default Tax Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default Tax Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inclusive (-GST)'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Default Transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default Transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inter-State (IGST)'));
    await tester.pumpAndSettle();

    // Clear history: cancel first, then confirm.
    await tester.ensureVisible(find.text('Clear Calculation History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Calculation History'));
    await tester.pumpAndSettle();
    expect(find.text('Clear History'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('entries stored'), findsOneWidget);

    await tester.tap(find.text('Clear Calculation History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete All'));
    await tester.pumpAndSettle();
    expect(find.text('0 entries stored'), findsOneWidget);

    // The new defaults now drive the calculator.
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();
    expect(find.text('Base Amount'), findsOneWidget); // inclusive
    expect(find.text('IGST @ 12%'), findsOneWidget); // inter-state + 12%
    // Flush the debounce so no timer is left pending at the end of the test.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    _dump('settings interactions');
    expect(_captured, isEmpty, reason: _reason());
  });

  testWidgets('History: reload calculation, CSV export and clear all', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _installPluginMocks();
    await _finishOnboarding(tester);

    // Produce one history entry. The auto-save debounce must elapse before
    // the entry appears on the History tab.
    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹2000'), findsWidgets);

    // Tapping the entry reloads the calculation into the calculator.
    await tester.tap(find.textContaining('₹2000').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Loaded'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('₹2,360.00'), findsOneWidget); // 2000 + 18% reloaded
    // Flush any debounce re-armed by the reload/Calculate flow so no timer
    // is left pending before the export + clear steps.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // CSV export goes through share_plus with a temp .csv file. The export
    // writes a real temp file first, so the tap + I/O run inside runAsync.
    _shares.clear();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Export as CSV'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(_shares, isNotEmpty, reason: 'CSV export should hit share_plus');
    expect(_shares.single.arguments.toString(), contains('.csv'));
    expect(_shares.single.arguments.toString(), contains('gst_calculations'));

    // Clear all via the header action + confirm dialog.
    await tester.tap(find.byTooltip('Clear all history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear All History'), findsOneWidget);
    await tester.tap(find.text('Delete All'));
    await tester.pumpAndSettle();
    expect(find.text('No calculations yet'), findsOneWidget);

    _dump('history interactions');
    expect(_captured, isEmpty, reason: _reason());
  });

  testWidgets('Onboarding: walk through all slides to Get Started', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({}); // onboarding not done
    _installCapture();

    await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Instant GST Math'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Reverse & Recall'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your Way'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Calculate'), findsOneWidget); // main shell reached

    _dump('onboarding walkthrough');
    expect(_captured, isEmpty, reason: _reason());
  });

  testWidgets('Calculator: inclusive breakdown reconciles exactly', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _installPluginMocks();
    await _finishOnboarding(tester);

    // ₹100 inclusive @ 18% — the reported regression: the displayed parts
    // must sum exactly to the displayed total (84.75 + 7.63 + 7.62 = 100.00).
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove GST'));
    await tester.pumpAndSettle();

    expect(find.text('₹100.00'), findsOneWidget); // headline total
    expect(find.text('₹84.75'), findsOneWidget); // base
    expect(find.text('₹7.63'), findsOneWidget); // CGST
    expect(find.text('₹7.62'), findsOneWidget); // SGST
    expect(find.text('₹15.25'), findsOneWidget); // GST = cgst + sgst

    _dump('inclusive reconciliation');
    expect(_captured, isEmpty, reason: _reason());
  });

  // ── Brand pass: icon-derived default identity ─────────────────────────

  test('Brand: no-accent default uses the icon-derived brand palette', () {
    // The brand navy is the default light primary; the royal blue light-
    // variant is the default dark primary (white text, AA).
    final light = buildLightTheme().colorScheme;
    expect(light.primary, BrandColors.primary);
    expect(light.onPrimary, Colors.white);
    expect(light.secondary, BrandColors.highlight);
    expect(light.onSecondary, BrandColors.onHighlight);

    final dark = buildDarkTheme().colorScheme;
    expect(dark.primary, BrandColors.primaryLight);
    expect(dark.onPrimary, Colors.white);
    expect(dark.secondary, BrandColors.highlight);
    expect(dark.onSecondary, BrandColors.onHighlight);

    // Brand pairings must keep WCAG AA contrast.
    expect(
      _contrastRatio(light.primary, light.onPrimary),
      greaterThanOrEqualTo(4.5),
      reason: 'light brand primary onPrimary contrast',
    );
    expect(
      _contrastRatio(dark.primary, dark.onPrimary),
      greaterThanOrEqualTo(4.5),
      reason: 'dark brand primary onPrimary contrast',
    );

    // GST semantic colors never follow the brand either.
    expect(
      buildLightTheme().gstColors.cgstColor,
      GSTColorScheme.light.cgstColor,
      reason: 'brand must not change GST colors (light)',
    );
    expect(
      buildDarkTheme().gstColors.cgstColor,
      GSTColorScheme.dark.cgstColor,
      reason: 'brand must not change GST colors (dark)',
    );
  });

  // ── Premium UI pass: 3-tab dock, no accent picker, fixed brand ────────

  testWidgets('Navigation: three destinations, Invoice tab removed', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    // The dock holds exactly Calculate / History / Settings — no Invoice.
    expect(find.text('Calculate'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Invoices'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
    expect(find.byIcon(Icons.description_rounded), findsNothing);

    // Every destination is reachable and selects correctly.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No calculations yet'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('GST Calculator'), findsOneWidget);

    _dump('three-tab navigation');
    expect(_captured, isEmpty, reason: _reason());
  });

  testWidgets('Calculator: no invoice entry points in the primary flow', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _installPluginMocks();
    await _finishOnboarding(tester);

    // Empty state: no invoice affordance anywhere on the Calculate screen.
    expect(find.textContaining('Invoice'), findsNothing);
    expect(find.textContaining('Generate'), findsNothing);
    expect(find.byTooltip('Generate Invoice'), findsNothing);
    expect(find.byTooltip('Create Invoice'), findsNothing);

    // The receipt glyph appears only as the decorative empty-state
    // illustration — never as an action button or entry point.
    final receiptIcon = find.byIcon(LucideIcons.receipt);
    expect(receiptIcon, findsOneWidget);
    expect(
      find.descendant(
        of: receiptIcon,
        matching: find.byType(InkWell),
      ),
      findsNothing,
      reason: 'receipt illustration must not be tappable',
    );
    expect(
      find.ancestor(
        of: receiptIcon,
        matching: find.byType(InkWell),
      ),
      findsNothing,
      reason: 'receipt illustration must not sit inside a tap target',
    );

    // Produce a result: the quick-action row must expose exactly Copy and
    // Share — no Generate Invoice button appears next to the result.
    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700)); // flush auto-save
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.textContaining('Invoice'), findsNothing);
    expect(find.textContaining('Generate'), findsNothing);
    // No invoice/pdf action icons anywhere on the result surface.
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
    expect(find.byIcon(Icons.description_rounded), findsNothing);

    _dump('calculator no-invoice');
    expect(_captured, isEmpty, reason: _reason());
  });

  testWidgets('Settings: no accent customization remains', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // No accent row, no reset affordance, and no swatch dialog anywhere —
    // the brand identity is fixed, so the app never asks for an accent.
    expect(find.text('Accent Color'), findsNothing);
    expect(find.text('Custom Accent'), findsNothing);
    expect(find.text('Reset'), findsNothing);
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Accent Color'), findsNothing);

    _dump('settings accent removal');
    expect(_captured, isEmpty, reason: _reason());
  });

  test('Legacy saved accent is ignored: brand default always applies', () {
    // A user who previously picked a custom accent has it persisted under
    // 'accent_color'. The app no longer reads it — the theme builders take
    // no accent input at all, so the icon-derived brand palette is the only
    // possible identity.
    final light = buildLightTheme().colorScheme;
    final dark = buildDarkTheme().colorScheme;
    expect(light.primary, BrandColors.primary, reason: 'light brand navy');
    expect(dark.primary, BrandColors.primaryLight, reason: 'dark royal blue');
    expect(
      _contrastRatio(light.primary, light.onPrimary),
      greaterThanOrEqualTo(4.5),
      reason: 'light brand primary contrast',
    );
    expect(
      _contrastRatio(dark.primary, dark.onPrimary),
      greaterThanOrEqualTo(4.5),
      reason: 'dark brand primary contrast',
    );
  });
}

/// WCAG contrast ratio between two colors (>= 4.5 is AA for normal text).
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
