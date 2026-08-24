import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gst_calculator/app.dart';
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
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    final eighteenBefore = tester.getTopLeft(find.text('18%'));

    // Selecting 5% must not move either label or change either pill's
    // dimensions: the check icon lives in a reserved slot, so geometry is
    // state-stable in both directions (check moves off 18%, onto 5%).
    final fiveBefore = tester.getTopLeft(find.text('5%'));
    final fiveChipBefore = tester.getSize(_chipOf('5%'));
    final eighteenChipBefore = tester.getSize(_chipOf('18%'));

    await tester.tap(find.text('5%'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.check), findsOneWidget);
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

  testWidgets('Mode chips: vertically aligned, selection changes, '
      'no displacement', (tester) async {
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

    // Both pairs of labels share the same vertical center (same row).
    expect(
      tester.getCenter(find.text('Add GST')).dy,
      closeTo(tester.getCenter(find.text('Remove GST')).dy, 0.5),
      reason: 'Add/Remove GST must share one vertical center',
    );
    expect(
      tester.getCenter(find.text('Intra-State')).dy,
      closeTo(tester.getCenter(find.text('Inter-State')).dy, 0.5),
      reason: 'Intra/Inter-State must share one vertical center',
    );

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

  testWidgets('Mode chips: tapping toggles calculation type', (tester) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();
    expect(find.text('₹1,180.00'), findsOneWidget); // exclusive total

    // Tap 'Remove GST' — toggles to inclusive: ₹1,000 incl. 18%.
    await tester.tap(find.text('Remove GST'));
    await tester.pumpAndSettle();

    expect(find.text('₹1,000.00'), findsOneWidget);
    expect(find.text('₹1,180.00'), findsNothing);
    // Flush the auto-save debounce so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(_captured, isEmpty);
  });

  testWidgets('Quick-add amounts: one deliberate row of four text actions', (
    tester,
  ) async {
    _usePhoneView(tester);
    SharedPreferences.setMockInitialValues({});
    _installCapture();
    await _finishOnboarding(tester);

    // All four quick-add actions exist with Indian-formatted labels.
    for (final label in ['₹100', '₹500', '₹1,000', '₹5,000']) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    // One intentional row: all four share the same vertical center and a
    // near-identical top edge (labels may differ by a fraction of a pixel
    // when a wide label is scale-guarded, but a wrapped row would differ by
    // the full row height).
    final rowCenter = tester.getCenter(find.text('₹100')).dy;
    final rowTop = tester.getTopLeft(find.text('₹100')).dy;
    for (final label in ['₹500', '₹1,000', '₹5,000']) {
      expect(tester.getCenter(find.text(label)).dy,
          closeTo(rowCenter, 0.5),
          reason: '$label must align on the same row as ₹100');
      expect(tester.getTopLeft(find.text(label)).dy, closeTo(rowTop, 2.0),
          reason: '$label must sit on the same row as ₹100');
    }

    // Tapping an action adds to the amount (100 + 18% exclusive = ₹118 total).
    await tester.tap(find.text('₹100'));
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
        of: find.byIcon(LucideIcons.download),
        matching: find.byType(IconButton),
      ),
    );
    IconButton clearBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(LucideIcons.trash),
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
        of: find.byIcon(LucideIcons.download),
        matching: find.byType(IconButton),
      ),
    );
    clearBtn = tester.widget(
      find.ancestor(
        of: find.byIcon(LucideIcons.trash),
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
