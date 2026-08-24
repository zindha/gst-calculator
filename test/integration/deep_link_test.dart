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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep link handling', () {
    const channel = MethodChannel('com.zindha.gst_calculator/deep_links');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null; // No deep link params
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('app launches without deep link params', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      // Should show onboarding or calculator (no crash)
      expect(
        find.byType(GSTCalculatorApp),
        findsOneWidget,
      );
    });

    testWidgets('app handles missing deep link params on web', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      // On Linux (test environment), Platform.isAndroid/iOS are false,
      // so the handler falls through to _parseWeb() which reads Uri.base.
      // We verify the app still renders without crashing.
      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      if (tester.any(find.text('Skip'))) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // App should render the calculator screen
      expect(find.text('GST Calculator'), findsWidgets);
    });

    testWidgets('app handles missing deep link gracefully', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getInitialLink') {
          return null; // No params
        }
        return null;
      });

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(GSTCalculatorApp), findsOneWidget);
    });

    testWidgets('app handles deep link channel failure', (tester) async {
      _usePhoneView(tester);
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR', message: 'Channel failed');
      });

      await tester.pumpWidget(const ProviderScope(child: GSTCalculatorApp()));
      await tester.pumpAndSettle();

      // Should still render — deep link failure is non-fatal
      expect(find.byType(GSTCalculatorApp), findsOneWidget);
    });
  });
}
