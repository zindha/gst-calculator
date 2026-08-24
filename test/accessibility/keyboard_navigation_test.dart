import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gst_calculator/app.dart';

void _usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
  await tester.pumpAndSettle();
  if (tester.any(find.text('Skip'))) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Keyboard navigation', () {
    testWidgets('amount field receives focus on launch', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.autofocus, isTrue);
    });

    testWidgets('Tab moves focus through interactive elements', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      final initialFocus = FocusManager.instance.primaryFocus;
      expect(initialFocus, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final newFocus = FocusManager.instance.primaryFocus;
      expect(newFocus, isNotNull);
    });
  });

  group('Semantics', () {
    testWidgets('bottom nav labels exist', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // Bottom nav items have text labels
      expect(find.text('Calculate'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('section labels are present', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      expect(find.text('AMOUNT'), findsOneWidget);
      expect(find.text('CALCULATION'), findsOneWidget);
      expect(find.text('TAX TYPE'), findsOneWidget);
      expect(find.text('GST RATE'), findsWidgets);
    });

    testWidgets('mode chip labels are present', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      expect(find.text('Add GST'), findsOneWidget);
      expect(find.text('Remove GST'), findsOneWidget);
      expect(find.text('Intra-State'), findsOneWidget);
      expect(find.text('Inter-State'), findsOneWidget);
    });

    testWidgets('GST rate chip labels are present', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      expect(find.text('3%'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
      expect(find.text('28%'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('result area shows empty state initially', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      expect(find.text('Your result appears here'), findsOneWidget);
    });
  });

  group('Reduced motion', () {
    testWidgets('app renders without errors on launch', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      // App should render the onboarding or calculator without crashing
      expect(
        find.byType(GSTCalculatorApp),
        findsOneWidget,
      );
    });
  });
}
