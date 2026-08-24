import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gst_calculator/core/theme/color_presets.dart';
import 'package:gst_calculator/core/theme/theme_extensions.dart';

import 'dart:math';

/// WCAG 2.0 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 2.0 contrast ratio.
double _ratio(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

void main() {
  // ── Surfaces ────────────────────────────────────────────────────────
  final scaffoldLight = BrandColors.surfaceLight;   // #F4F5F8
  final cardDark = BrandColors.cardDark;             // #182136
  final scaffoldDark = BrandColors.surfaceDark;      // #0E1320

  group('Dark mode — text on card surface ≥ 4.5:1', () {
    test('primary content text', () {
      expect(_ratio(BrandColors.textPrimaryDark, cardDark),
          greaterThanOrEqualTo(4.5));
    });
    test('secondary text', () {
      expect(_ratio(BrandColors.onSurfaceVariantDark, cardDark),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('Dark mode — GST accent colors on card ≥ 3:1 (large text/icons)', () {
    // GST accent colors are used as small colored labels next to values.
    // WCAG allows 3:1 for large text (≥18pt bold or ≥24pt) and icons.
    final dark = GSTColorScheme.dark;
    for (final entry in {
      'CGST': dark.cgstColor,
      'SGST': dark.sgstColor,
      'IGST': dark.igstColor,
      'total': dark.totalColor,
      'rate0': dark.rate0Color,
    }.entries) {
      test(entry.key, () {
        expect(_ratio(entry.value, cardDark),
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key} on card');
      });
    }
  });

  group('Light mode — text on scaffold ≥ 4.5:1', () {
    test('primary content text', () {
      expect(_ratio(BrandColors.textPrimaryLight, scaffoldLight),
          greaterThanOrEqualTo(4.5));
    });
    test('secondary text', () {
      expect(_ratio(BrandColors.onSurfaceVariantLight, scaffoldLight),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('Light mode — GST accent colors on scaffold ≥ 3:1', () {
    final light = GSTColorScheme.light;
    for (final entry in {
      'CGST': light.cgstColor,
      'SGST': light.sgstColor,
      'IGST': light.igstColor,
      'total': light.totalColor,
    }.entries) {
      test(entry.key, () {
        expect(_ratio(entry.value, scaffoldLight),
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key} on scaffold');
      });
    }
  });

  group('Brand primary on white ≥ 4.5:1', () {
    test('light primary (navy)', () {
      expect(_ratio(BrandColors.primary, Colors.white),
          greaterThanOrEqualTo(4.5));
    });
    test('dark primary (royal blue)', () {
      expect(_ratio(BrandColors.primaryLight, Colors.white),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('Scaffold contrast — dark mode', () {
    test('secondary text on dark scaffold ≥ 3:1', () {
      expect(_ratio(BrandColors.onSurfaceVariantDark, scaffoldDark),
          greaterThanOrEqualTo(3.0));
    });
  });
}
