import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:gst_calculator/core/theme/app_theme.dart';
import 'package:gst_calculator/core/widgets/app_header.dart';
import 'package:gst_calculator/core/widgets/brand_chip.dart';
import 'package:gst_calculator/core/widgets/empty_state.dart';
import 'package:gst_calculator/core/widgets/section_label.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? buildLightTheme() : buildDarkTheme(),
    home: Scaffold(body: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    )),
  );
}

void main() {
  group('Golden — Light Theme', () {
    testWidgets('SectionLabel', (tester) async {
      await tester.pumpWidget(_app(const SectionLabel('GST RATE')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SectionLabel),
        matchesGoldenFile('goldens/section_label_light.png'),
      );
    });

    testWidgets('BrandChip unselected', (tester) async {
      await tester.pumpWidget(_app(
        BrandChip(label: '18%', onTap: () {}),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrandChip),
        matchesGoldenFile('goldens/brand_chip_unselected_light.png'),
      );
    });

    testWidgets('BrandChip selected', (tester) async {
      await tester.pumpWidget(_app(
        BrandChip(label: '18%', selected: true, onTap: () {}),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrandChip),
        matchesGoldenFile('goldens/brand_chip_selected_light.png'),
      );
    });

    testWidgets('EmptyState', (tester) async {
      await tester.pumpWidget(_app(const EmptyState(
        icon: LucideIcons.history,
        title: 'No calculations yet',
        subtitle: 'Your saved calculations will appear here',
      )));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_light.png'),
      );
    });

    testWidgets('AppHeader standard', (tester) async {
      await tester.pumpWidget(_app(const AppHeader(title: 'Settings')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppHeader),
        matchesGoldenFile('goldens/app_header_standard_light.png'),
      );
    });

    testWidgets('AppHeader display', (tester) async {
      await tester.pumpWidget(_app(
        const AppHeader(title: 'GST Calculator', display: true),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppHeader),
        matchesGoldenFile('goldens/app_header_display_light.png'),
      );
    });

    testWidgets('Rate chips row', (tester) async {
      await tester.pumpWidget(_app(
        Wrap(
          spacing: 8,
          children: [
            BrandChip(label: '3%', onTap: () {}),
            BrandChip(label: '5%', onTap: () {}),
            BrandChip(label: '12%', onTap: () {}),
            BrandChip(label: '18%', selected: true, onTap: () {}),
            BrandChip(label: '28%', onTap: () {}),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Wrap),
        matchesGoldenFile('goldens/rate_chips_row_light.png'),
      );
    });
  });

  group('Golden — Dark Theme', () {
    testWidgets('SectionLabel', (tester) async {
      await tester.pumpWidget(_app(
        const SectionLabel('GST RATE'),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SectionLabel),
        matchesGoldenFile('goldens/section_label_dark.png'),
      );
    });

    testWidgets('BrandChip unselected', (tester) async {
      await tester.pumpWidget(_app(
        BrandChip(label: '18%', onTap: () {}),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrandChip),
        matchesGoldenFile('goldens/brand_chip_unselected_dark.png'),
      );
    });

    testWidgets('BrandChip selected', (tester) async {
      await tester.pumpWidget(_app(
        BrandChip(label: '18%', selected: true, onTap: () {}),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrandChip),
        matchesGoldenFile('goldens/brand_chip_selected_dark.png'),
      );
    });

    testWidgets('EmptyState', (tester) async {
      await tester.pumpWidget(_app(
        const EmptyState(
          icon: LucideIcons.history,
          title: 'No calculations yet',
          subtitle: 'Your saved calculations will appear here',
        ),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_dark.png'),
      );
    });

    testWidgets('AppHeader display', (tester) async {
      await tester.pumpWidget(_app(
        const AppHeader(title: 'GST Calculator', display: true),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppHeader),
        matchesGoldenFile('goldens/app_header_display_dark.png'),
      );
    });

    testWidgets('Rate chips row', (tester) async {
      await tester.pumpWidget(_app(
        Wrap(
          spacing: 8,
          children: [
            BrandChip(label: '3%', onTap: () {}),
            BrandChip(label: '5%', onTap: () {}),
            BrandChip(label: '12%', onTap: () {}),
            BrandChip(label: '18%', selected: true, onTap: () {}),
            BrandChip(label: '28%', onTap: () {}),
          ],
        ),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Wrap),
        matchesGoldenFile('goldens/rate_chips_row_dark.png'),
      );
    });
  });
}
