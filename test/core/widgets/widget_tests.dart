import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:gst_calculator/core/theme/app_theme.dart';
import 'package:gst_calculator/core/widgets/app_header.dart';
import 'package:gst_calculator/core/widgets/brand_chip.dart';
import 'package:gst_calculator/core/widgets/empty_state.dart';
import 'package:gst_calculator/core/widgets/section_label.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? buildLightTheme() : buildDarkTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SectionLabel', () {
    testWidgets('renders uppercase text', (tester) async {
      await tester.pumpWidget(_wrap(const SectionLabel('AMOUNT')));
      expect(find.text('AMOUNT'), findsOneWidget);
    });

    testWidgets('renders in both themes without error', (tester) async {
      await tester.pumpWidget(_wrap(const SectionLabel('GST RATE')));
      expect(find.text('GST RATE'), findsOneWidget);
      await tester.pumpWidget(
        _wrap(const SectionLabel('GST RATE'), brightness: Brightness.dark),
      );
      expect(find.text('GST RATE'), findsOneWidget);
    });

    testWidgets('has correct text style properties', (tester) async {
      await tester.pumpWidget(_wrap(const SectionLabel('TEST')));
      final text = tester.widget<Text>(find.text('TEST'));
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.fontSize, 12);
      expect(text.style?.letterSpacing, 1.2);
    });
  });

  group('BrandChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _wrap(BrandChip(label: '18%', onTap: () {})),
      );
      expect(find.text('18%'), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        _wrap(BrandChip(label: '18%', selected: true, onTap: () {})),
      );
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('hides check icon when not selected', (tester) async {
      await tester.pumpWidget(
        _wrap(BrandChip(label: '18%', selected: false, onTap: () {})),
      );
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('shows custom icon when provided and not selected', (tester) async {
      await tester.pumpWidget(
        _wrap(BrandChip(
          label: 'Custom',
          icon: LucideIcons.pencil,
          selected: false,
          onTap: () {},
        )),
      );
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(BrandChip(label: '18%', onTap: () => tapped = true)),
      );
      await tester.tap(find.text('18%'));
      expect(tapped, isTrue);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BrandChip(label: '18%', selected: true, onTap: () {}),
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('18%'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('has minimum touch target height', (tester) async {
      await tester.pumpWidget(
        _wrap(BrandChip(label:'X', onTap: () {})),
      );
      final size = tester.getSize(find.byType(BrandChip));
      expect(size.height, greaterThanOrEqualTo(40));
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(
          icon: LucideIcons.history,
          title: 'No data',
          subtitle: 'Nothing here yet',
        )),
      );
      expect(find.byIcon(LucideIcons.history), findsOneWidget);
      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(
          icon: LucideIcons.plus,
          title: 'Empty',
          actionLabel: 'Add Item',
          onAction: null,
        )),
      );
      // onAction is null so button should not appear
      expect(find.text('Add Item'), findsNothing);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyState(
            icon: LucideIcons.history,
            title: 'No data',
          ),
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('No data'), findsOneWidget);
    });
  });

  group('AppHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppHeader(title: 'GST Calculator')),
      );
      expect(find.text('GST Calculator'), findsOneWidget);
    });

    testWidgets('renders display title with larger text', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppHeader(title: 'GST Calculator', display: true)),
      );
      final text = tester.widget<Text>(find.text('GST Calculator'));
      expect(text.style?.fontSize, 26);
      expect(text.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(
        _wrap(AppHeader(
          title: 'Test',
          leading: const Icon(LucideIcons.calculator),
        )),
      );
      expect(find.byIcon(LucideIcons.calculator), findsOneWidget);
    });

    testWidgets('renders action widgets', (tester) async {
      await tester.pumpWidget(
        _wrap(AppHeader(
          title: 'Test',
          actions: const [Icon(LucideIcons.settings)],
        )),
      );
      expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppHeader(title: 'Settings'),
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
