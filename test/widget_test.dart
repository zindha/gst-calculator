import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App shows onboarding on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GSTCalculatorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // On first launch, the onboarding screen should be shown
    expect(find.text('Quick GST Calculations'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    // First slide shows "Next" not "Get Started"
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Navigating onboarding shows calculator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GSTCalculatorApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Next" through all three slides, then "Get Started"
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // After completing onboarding, the calculator tab should be visible.
    // The ledger dock shows the label on the selected tab and icons on the
    // remaining tabs. The dock has exactly three destinations — the Invoice
    // tab was removed from the primary app experience.
    expect(find.text('GST Calculator'), findsWidgets);
    expect(find.text('Calculate'), findsWidgets);
    expect(find.byIcon(Icons.history_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
    expect(find.text('Invoices'), findsNothing);
  });
}
