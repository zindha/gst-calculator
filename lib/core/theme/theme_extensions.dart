import 'package:flutter/material.dart';

import 'color_presets.dart';

/// Extension on [ThemeData] to access custom GST color schemes.
extension GSTTheme on ThemeData {
  /// Returns the [GSTColorScheme] for this theme.
  GSTColorScheme get gstColors => extension<GSTColorScheme>()!;
}

/// Custom color scheme for the GST Calculator app.
///
/// Provides semantically named colors for GST-related UI elements
/// like CGST, SGST, and IGST labels.
class GSTColorScheme extends ThemeExtension<GSTColorScheme> {
  /// Color used for CGST indicators (blue-tinted).
  final Color cgstColor;

  /// Color used for SGST indicators (green-tinted).
  final Color sgstColor;

  /// Color used for IGST indicators (purple-tinted).
  final Color igstColor;

  /// Color for the total/gross amount display.
  final Color totalColor;

  /// Color for positive/gain indicators.
  final Color positiveColor;

  /// Color for success states.
  final Color successColor;

  /// Color for warning states.
  final Color warningColor;

  /// Color for the 0% GST rate badge.
  final Color rate0Color;

  /// Color for the 5% GST rate badge.
  final Color rate5Color;

  /// Color for the 12% GST rate badge.
  final Color rate12Color;

  /// Color for the 18% GST rate badge.
  final Color rate18Color;

  /// Color for the 28% GST rate badge.
  final Color rate28Color;

  /// Color for input fields background.
  final Color inputBackground;

  /// Color for card backgrounds.
  final Color cardBackground;

  /// Color for section labels.
  final Color labelColor;

  const GSTColorScheme({
    required this.cgstColor,
    required this.sgstColor,
    required this.igstColor,
    required this.totalColor,
    required this.positiveColor,
    required this.successColor,
    required this.warningColor,
    required this.rate0Color,
    required this.rate5Color,
    required this.rate12Color,
    required this.rate18Color,
    required this.rate28Color,
    required this.inputBackground,
    required this.cardBackground,
    required this.labelColor,
  });

  /// Returns the semantic color for a GST slab [rate].
  Color rateColor(double rate) => switch (rate) {
    0 => rate0Color,
    5 => rate5Color,
    12 => rate12Color,
    18 => rate18Color,
    _ => rate28Color,
  };

  /// Light theme GST color scheme.
  ///
  /// Text colors are chosen to meet WCAG AA (>= 4.5:1) on white surfaces.
  static const light = GSTColorScheme(
    cgstColor: Color(0xFF1565C0), // Blue 800
    sgstColor: Color(0xFF2E7D32), // Green 800
    igstColor: Color(0xFF6A1B9A), // Purple 800
    totalColor: Color(0xFFB45309), // Amber 800 (saffron)
    positiveColor: Color(0xFF1B5E20), // Green 900
    successColor: Color(0xFF2E7D32), // Green 800
    warningColor: Color(0xFFB45309), // Amber 800 (saffron)
    rate0Color: Color(0xFF616161), // Grey 700
    rate5Color: Color(0xFF2E7D32), // Green 800
    rate12Color: Color(0xFFB45309), // Amber 800 (saffron)
    rate18Color: Color(0xFF1565C0), // Blue 800
    rate28Color: Color(0xFFC62828), // Red 900
    inputBackground: BrandColors.inputLight, // Cool brand surface
    cardBackground: Colors.white,
    labelColor: BrandColors.onSurfaceVariantLight, // Cool grey
  );

  /// Dark theme GST color scheme.
  ///
  /// Text colors are chosen to meet WCAG AA (>= 4.5:1) on dark card surfaces.
  static const dark = GSTColorScheme(
    cgstColor: Color(0xFF64B5F6), // Blue 300
    sgstColor: Color(0xFF81C784), // Green 300
    igstColor: Color(0xFFCE93D8), // Purple 300
    totalColor: Color(0xFFFFB85C), // Saffron 300
    positiveColor: Color(0xFFA5D6A7), // Green 200
    successColor: Color(0xFF81C784), // Green 300
    warningColor: Color(0xFFFFB85C), // Saffron 300
    rate0Color: Color(0xFFBDBDBD), // Grey 400
    rate5Color: Color(0xFF81C784), // Green 300
    rate12Color: Color(0xFFFFB85C), // Saffron 300
    rate18Color: Color(0xFF64B5F6), // Blue 300
    rate28Color: Color(0xFFEF9A9A), // Red 200
    inputBackground: BrandColors.inputDark, // Cool brand surface
    cardBackground: BrandColors.cardDark, // Cool brand card
    labelColor: BrandColors.onSurfaceVariantDark, // Cool grey
  );

  @override
  GSTColorScheme copyWith({
    Color? cgstColor,
    Color? sgstColor,
    Color? igstColor,
    Color? totalColor,
    Color? positiveColor,
    Color? successColor,
    Color? warningColor,
    Color? rate0Color,
    Color? rate5Color,
    Color? rate12Color,
    Color? rate18Color,
    Color? rate28Color,
    Color? inputBackground,
    Color? cardBackground,
    Color? labelColor,
  }) {
    return GSTColorScheme(
      cgstColor: cgstColor ?? this.cgstColor,
      sgstColor: sgstColor ?? this.sgstColor,
      igstColor: igstColor ?? this.igstColor,
      totalColor: totalColor ?? this.totalColor,
      positiveColor: positiveColor ?? this.positiveColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      rate0Color: rate0Color ?? this.rate0Color,
      rate5Color: rate5Color ?? this.rate5Color,
      rate12Color: rate12Color ?? this.rate12Color,
      rate18Color: rate18Color ?? this.rate18Color,
      rate28Color: rate28Color ?? this.rate28Color,
      inputBackground: inputBackground ?? this.inputBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      labelColor: labelColor ?? this.labelColor,
    );
  }

  @override
  GSTColorScheme lerp(ThemeExtension<GSTColorScheme>? other, double t) {
    if (other is! GSTColorScheme) return this;
    return GSTColorScheme(
      cgstColor: Color.lerp(cgstColor, other.cgstColor, t)!,
      sgstColor: Color.lerp(sgstColor, other.sgstColor, t)!,
      igstColor: Color.lerp(igstColor, other.igstColor, t)!,
      totalColor: Color.lerp(totalColor, other.totalColor, t)!,
      positiveColor: Color.lerp(positiveColor, other.positiveColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      rate0Color: Color.lerp(rate0Color, other.rate0Color, t)!,
      rate5Color: Color.lerp(rate5Color, other.rate5Color, t)!,
      rate12Color: Color.lerp(rate12Color, other.rate12Color, t)!,
      rate18Color: Color.lerp(rate18Color, other.rate18Color, t)!,
      rate28Color: Color.lerp(rate28Color, other.rate28Color, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      labelColor: Color.lerp(labelColor, other.labelColor, t)!,
    );
  }
}
