import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gst_calculator/app.dart';
import 'package:gst_calculator/core/theme/app_tokens.dart';
import 'package:gst_calculator/core/theme/app_theme.dart';
import 'package:gst_calculator/core/widgets/brand_chip.dart';
import 'package:gst_calculator/features/calculator/presentation/widgets/calculation_mode_toggle.dart';
import 'package:gst_calculator/features/calculator/presentation/widgets/gst_slab_selector.dart';

final _captured = <FlutterErrorDetails>[];

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

Finder _chipOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(BrandChip));

void main() {
  testWidgets('Rate pills: identical geometry, label never jumps on select', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: GstSlabSelector()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // All five slab pills (plus Custom) share one height.
    final heights = <double>[];
    for (final label in ['3%', '5%', '12%', '18%', '28%', 'Custom']) {
      heights.add(tester.getSize(_chipOf(label)).height);
    }
    for (final h in heights.skip(1)) {
      expect(h, closeTo(heights.first, 0.01),
          reason: 'every pill must have identical height');
    }

    // 18% is the default selected slab, so the check icon is already present.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final eighteenBefore = tester.getTopLeft(find.text('18%'));

    // Selecting 5% must not move either label or change either pill's
    // dimensions: the check icon lives in a reserved slot, so geometry is
    // state-stable in both directions (check moves off 18%, onto 5%).
    final fiveBefore = tester.getTopLeft(find.text('5%'));
    final fiveChipBefore = tester.getSize(_chipOf('5%'));
    final eighteenChipBefore = tester.getSize(_chipOf('18%'));

    await tester.tap(find.text('5%'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.getTopLeft(find.text('5%')), fiveBefore,
        reason: 'selecting a slab must not shift its label');
    expect(tester.getSize(_chipOf('5%')), fiveChipBefore,
        reason: 'selected pill must keep identical dimensions');
    expect(tester.getTopLeft(find.text('18%')), eighteenBefore,
        reason: 'deselecting must not shift the label');
    expect(tester.getSize(_chipOf('18%')), eighteenChipBefore,
        reason: 'unselected pill must keep identical dimensions');

    expect(_captured, isEmpty);
  });

  testWidgets('Segmented controls: equal segments, vertically centered, '
      'no displacement on selection', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: CalculationModeToggle()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The track is the segment's nearest Container ancestor that has the
    // track padding (3) and the rounded input-background decoration.
    Finder trackOf(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.padding == const EdgeInsets.all(3) &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(AppRadius.md),
      ),
    );

    // Calculation-mode control: both segments align on the same center and
    // sit vertically centered inside the track.
    final trackRect = tester.getRect(trackOf('Add GST'));
    for (final label in ['Add GST', 'Remove GST']) {
      final c = tester.getCenter(find.text(label));
      expect(
        c.dy,
        closeTo(trackRect.center.dy, 2.0),
        reason: "'$label' must be vertically centered in its track",
      );
    }
    expect(
      tester.getCenter(find.text('Add GST')).dy,
      tester.getCenter(find.text('Remove GST')).dy,
      reason: 'both segments must share one vertical center',
    );

    // Transaction control: icons differ but the label centers still match.
    final txTrack = tester.getRect(trackOf('Intra-State'));
    for (final label in ['Intra-State', 'Inter-State']) {
      final c = tester.getCenter(find.text(label));
      expect(c.dy, closeTo(txTrack.center.dy, 2.0),
          reason: "'$label' must be vertically centered");
    }

    // Selecting a segment must not move either label vertically.
    final addBefore = tester.getCenter(find.text('Add GST')).dy;
    final intraBefore = tester.getCenter(find.text('Intra-State')).dy;
    await tester.tap(find.text('Remove GST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inter-State'));
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.text('Add GST')).dy,
      closeTo(addBefore, 0.5),
      reason: 'selected segment must not displace the other segment',
    );
    expect(
      tester.getCenter(find.text('Intra-State')).dy,
      closeTo(intraBefore, 0.5),
      reason: 'selected segment must not displace the other segment',
    );

    expect(_captured, isEmpty);
  });

  testWidgets('Segmented control: the whole segment is tappable, '
      'not just the label', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();
    expect(find.text('₹1,180.00'), findsOneWidget); // exclusive total

    // Tap the 'Remove GST' segment in the empty area near its bottom edge —
    // far away from the label, which sits centered. The whole segment must
    // be a valid touch target, not just the icon + text row.
    final track = tester.getRect(
      find.ancestor(
        of: find.text('Add GST'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.padding == const EdgeInsets.all(3) &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    // Right half of the track = the 'Remove GST' segment; bottom edge is
    // empty space, never the label.
    final tapPoint = Offset(track.right - track.width * 0.25, track.bottom - 6);
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    // Toggled to inclusive: ₹1,000 incl. 18% keeps the total at ₹1,000.00.
    expect(find.text('₹1,000.00'), findsOneWidget);
    expect(find.text('₹1,180.00'), findsNothing);
    // Flush the auto-save debounce so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(_captured, isEmpty);
  });

  testWidgets('Quick-add amounts: deliberate 2×2 grid, identical geometry', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    // All four quick-add pills exist.
    for (final label in ['+₹100', '+₹500', '+₹1000', '+₹5000']) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label pill');
    }

    // Every pill shares identical dimensions — the second row must be the
    // same component, not an accidental different-sized wrap.
    final sizes = <Size>[];
    for (final label in ['+₹100', '+₹500', '+₹1000', '+₹5000']) {
      sizes.add(tester.getSize(_chipOf(label)));
    }
    for (final s in sizes.skip(1)) {
      expect(s.height, closeTo(sizes.first.height, 0.01),
          reason: 'all quick-add pills must share one height');
      expect(s.width, closeTo(sizes.first.width, 0.01),
          reason: 'all quick-add pills must share one width');
    }

    // Two intentional rows: the first row shares a top edge, the second row
    // sits below it on its own edge.
    final row1Top = tester.getTopLeft(find.text('+₹100')).dy;
    final row2Top = tester.getTopLeft(find.text('+₹1000')).dy;
    expect(tester.getTopLeft(find.text('+₹500')).dy, closeTo(row1Top, 0.5),
        reason: '+₹500 must sit on the same row as +₹100');
    expect(tester.getTopLeft(find.text('+₹5000')).dy, closeTo(row2Top, 0.5),
        reason: '+₹5000 must sit on the same row as +₹1000');
    expect(row2Top, greaterThan(row1Top),
        reason: 'second quick-add row must sit below the first');

    // Tapping a pill adds to the amount (100 + 18% exclusive = ₹118 total).
    await tester.tap(find.text('+₹100'));
    await tester.pumpAndSettle();
    expect(find.text('₹118.00'), findsOneWidget);
    expect(find.text('₹100.00'), findsOneWidget); // base row

    expect(_captured, isEmpty);
  });

  testWidgets('History: header actions are disabled when empty, '
      'enabled when entries exist', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No calculations yet'), findsOneWidget);

    IconButton exportBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.file_download_outlined),
        matching: find.byType(IconButton),
      ),
    );
    IconButton clearBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.delete_sweep_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(exportBtn.onPressed, isNull,
        reason: 'export must be disabled with empty history');
    expect(clearBtn.onPressed, isNull,
        reason: 'clear must be disabled with empty history');

    // Produce one calculation so history has an entry.
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700)); // auto-save debounce
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    exportBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.file_download_outlined),
        matching: find.byType(IconButton),
      ),
    );
    clearBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.delete_sweep_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(exportBtn.onPressed, isNotNull,
        reason: 'export must be enabled once history exists');
    expect(clearBtn.onPressed, isNotNull,
        reason: 'clear must be enabled once history exists');

    expect(_captured, isEmpty);
  });
}
