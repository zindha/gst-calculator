import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  group('Full calculator flow', () {
    testWidgets('enter amount → select rate → verify result → copy', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '2500');
      await tester.pumpAndSettle();

      // Default is 18% exclusive: ₹2,500 + 18% = ₹2,950
      expect(find.text('₹2,950.00'), findsOneWidget);
      expect(find.text('₹2,500.00'), findsOneWidget); // base
      expect(find.text('CGST @ 9%'), findsOneWidget);
      expect(find.text('SGST @ 9%'), findsOneWidget);

      // Switch to 5% rate
      await tester.tap(find.text('5%'));
      await tester.pumpAndSettle();
      expect(find.text('₹2,625.00'), findsOneWidget); // 2500 + 5%

      // Switch to inclusive mode
      await tester.tap(find.text('Remove GST'));
      await tester.pumpAndSettle();
      // 2625 inclusive at 5% → base = 2500
      expect(find.text('₹2,500.00'), findsOneWidget);

      // Switch to inter-state
      await tester.tap(find.text('Inter-State'));
      await tester.pumpAndSettle();
      expect(find.text('IGST @ 5%'), findsOneWidget);
    });

    testWidgets('quick-add buttons add to amount', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      await tester.tap(find.text('₹100'));
      await tester.pumpAndSettle();
      expect(find.text('₹100.00'), findsOneWidget);
      // 100 + 18% = 118
      expect(find.text('₹118.00'), findsOneWidget);

      await tester.tap(find.text('₹500'));
      await tester.pumpAndSettle();
      // 600 + 18% = 708
      expect(find.text('₹708.00'), findsOneWidget);
    });

    testWidgets('0.25% slab: rough-diamond math', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // 0.25% slab (rough diamonds): ₹1,000 + 0.25% = ₹1,002.50, and the
      // split labels show the exact half rate (0.125%), not a rounded 0.13%.
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('0.25%'));
      await tester.pumpAndSettle();
      expect(find.text('₹1,002.50'), findsOneWidget);
      expect(find.text('CGST @ 0.125%'), findsOneWidget);
      expect(find.text('SGST @ 0.125%'), findsOneWidget);
    });

    testWidgets('clear amount resets result', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();
      expect(find.text('₹1,180.00'), findsOneWidget);

      // Clear via the X button
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('Your result appears here'), findsOneWidget);
    });

    testWidgets('clear all resets everything', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();
      expect(find.text('₹1,180.00'), findsOneWidget);

      // Tap clear all in header
      await tester.tap(find.byIcon(LucideIcons.trash));
      await tester.pumpAndSettle();
      expect(find.text('Your result appears here'), findsOneWidget);
    });
  });

  group('History flow', () {
    testWidgets('calculation appears in history', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // Make a calculation
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700)); // debounce
      await tester.pumpAndSettle();

      // Switch to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should show the entry — amountText is "1000" as typed, so the
      // list item shows ₹1000 (no comma in the raw amount text).
      expect(find.textContaining('₹1000'), findsWidgets);
      expect(find.textContaining('@ 18%'), findsWidgets);
    });

    testWidgets('empty history shows empty state', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No calculations yet'), findsOneWidget);
    });
  });

  group('Settings flow', () {
    testWidgets('theme toggle switches between light and dark', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // Initially shows moon icon (light mode → switch to dark)
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);

      // Switch to dark
      await tester.tap(find.byIcon(LucideIcons.moon));
      await tester.pumpAndSettle();

      // Now shows sun icon (dark mode → switch to light)
      expect(find.byIcon(LucideIcons.sun), findsOneWidget);

      // Switch back to light
      await tester.tap(find.byIcon(LucideIcons.sun));
      await tester.pumpAndSettle();

      // Back to moon
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
    });

    testWidgets('settings screen shows all sections', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Section headers are uppercased by _SectionHeader
      expect(find.text('THEME'), findsOneWidget);
      expect(find.text('DEFAULTS'), findsOneWidget);
      expect(find.text('DATA'), findsOneWidget);
      // ListTile titles are not uppercased
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Default GST Rate'), findsOneWidget);
      expect(find.text('Default Tax Type'), findsOneWidget);
      expect(find.text('Default Transaction'), findsOneWidget);
      expect(find.text('Clear Calculation History'), findsOneWidget);
    });
  });

  group('Onboarding flow', () {
    testWidgets('walks through all slides', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      // First slide
      expect(find.text('Instant GST Math'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Second slide
      expect(find.text('Reverse & Recall'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Third slide
      expect(find.text('Your Way'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should be on calculator
      expect(find.text('GST Calculator'), findsWidgets);
    });

    testWidgets('skip button goes to calculator', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('GST Calculator'), findsWidgets);
    });
  });

  group('Navigation', () {
    testWidgets('all three tabs are accessible', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});
      await _skipOnboarding(tester);

      // Calculator tab (default)
      expect(find.text('GST Calculator'), findsWidgets);

      // History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.history), findsWidgets);

      // Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);

      // Back to Calculator
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      expect(find.text('GST Calculator'), findsWidgets);
    });
  });
}
