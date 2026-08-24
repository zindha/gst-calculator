import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/theme/theme_extensions.dart';

void main() {
  group('GSTColorScheme', () {
    group('light', () {
      test('has all required colors', () {
        const scheme = GSTColorScheme.light;
        expect(scheme.cgstColor, isNotNull);
        expect(scheme.sgstColor, isNotNull);
        expect(scheme.igstColor, isNotNull);
        expect(scheme.totalColor, isNotNull);
        expect(scheme.inputBackground, isNotNull);
        expect(scheme.cardBackground, isNotNull);
        expect(scheme.labelColor, isNotNull);
      });

      test('cardBackground is white', () {
        expect(GSTColorScheme.light.cardBackground, Colors.white);
      });
    });

    group('dark', () {
      test('has all required colors', () {
        const scheme = GSTColorScheme.dark;
        expect(scheme.cgstColor, isNotNull);
        expect(scheme.sgstColor, isNotNull);
        expect(scheme.igstColor, isNotNull);
        expect(scheme.totalColor, isNotNull);
        expect(scheme.inputBackground, isNotNull);
        expect(scheme.cardBackground, isNotNull);
        expect(scheme.labelColor, isNotNull);
      });

      test('cardBackground is not white', () {
        expect(GSTColorScheme.dark.cardBackground, isNot(Colors.white));
      });
    });

    group('rateColor', () {
      test('returns correct color for each standard rate', () {
        const scheme = GSTColorScheme.light;
        expect(scheme.rateColor(0), scheme.rate0Color);
        expect(scheme.rateColor(5), scheme.rate5Color);
        expect(scheme.rateColor(12), scheme.rate12Color);
        expect(scheme.rateColor(18), scheme.rate18Color);
      });

      test('returns rate28Color for any non-standard rate', () {
        const scheme = GSTColorScheme.light;
        expect(scheme.rateColor(28), scheme.rate28Color);
        expect(scheme.rateColor(15), scheme.rate28Color);
        expect(scheme.rateColor(7), scheme.rate28Color);
      });
    });

    group('copyWith', () {
      test('returns a new instance with replaced fields', () {
        const original = GSTColorScheme.light;
        final modified = original.copyWith(cgstColor: Colors.red);
        expect(modified.cgstColor, Colors.red);
        expect(modified.sgstColor, original.sgstColor);
      });

      test('returns identical instance when no fields replaced', () {
        const original = GSTColorScheme.light;
        final copy = original.copyWith();
        expect(copy.cgstColor, original.cgstColor);
        expect(copy.sgstColor, original.sgstColor);
        expect(copy.igstColor, original.igstColor);
      });
    });

    group('lerp', () {
      test('at t=0 returns start value', () {
        const a = GSTColorScheme.light;
        const b = GSTColorScheme.dark;
        final result = a.lerp(b, 0.0);
        expect(result.cgstColor, a.cgstColor);
      });

      test('at t=1 returns end value', () {
        const a = GSTColorScheme.light;
        const b = GSTColorScheme.dark;
        final result = a.lerp(b, 1.0);
        expect(result.cgstColor, b.cgstColor);
      });

      test('returns this when other is not GSTColorScheme', () {
        const scheme = GSTColorScheme.light;
        final result = scheme.lerp(null, 0.5);
        expect(result, same(scheme));
      });
    });
  });

  group('GSTTheme extension', () {
    test('gstColors returns the extension from ThemeData', () {
      final theme = ThemeData(
        extensions: const [GSTColorScheme.light],
      );
      expect(theme.gstColors, isA<GSTColorScheme>());
      expect(theme.gstColors.cardBackground, Colors.white);
    });
  });
}
