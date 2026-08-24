import 'package:flutter/material.dart';

/// Icon-derived brand palette for the GST Calculator.
///
/// Every colour here is sourced from the actual launcher-icon artwork
/// (`app-icon.png`, 1195×1195 — the single image `flutter_launcher_icons`
/// uses to generate the Android/iOS/web launcher icons), or derived from it:
///
/// | Token            | Value     | Source                                                            |
/// |------------------|-----------|-------------------------------------------------------------------|
/// | `primary`        | `#01226A` | Deep navy — the icon's dominant background colour (exact opaque   |
/// |                  |           | pixels `#012269`/`#01226A`/`#002168`; the adaptive-icon           |
/// |                  |           | background is its near-twin `#002162`).                           |
/// | `primaryLight`   | `#0043B0` | Royal blue — the brightest brand blue in the artwork (exact       |
/// |                  |           | pixels `#0043B0`/`#0140AA`/`#003FA7`); also the dark-theme        |
/// |                  |           | primary (white text ≈ 8.3:1 WCAG AA).                             |
/// | `highlight`      | `#FD8B01` | Orange accent — exact pixels `#FD8A01`/`#FD8C02` (theme           |
/// |                  |           | `secondary`; `onHighlight` pairing is 5.8:1 AA).                  |
/// | `green`          | `#1F8A10` | Green accent — exact pixels `#1A8311`/`#249311`/`#1A8A0A`         |
/// |                  |           | (reserved for non-GST brand moments).                             |
/// | `white`          | `#FEFEFE` | The icon's white badge (exact pixels `#FEFEFE`/`#FDFDFD`).        |
///
/// Surfaces are derived from the navy/white pair — subtle cool tints that
/// replace the previous warm paper — so the UI reads as the same product as
/// the launcher icon without colour flooding. All light/dark pairings meet
/// WCAG AA (>= 4.5:1); the exact icon colours are kept as the brand
/// reference and only ever adjusted for contrast where documented.
class BrandColors {
  BrandColors._();

  /// Brand primary — deep navy (light-theme primary action colour).
  static const Color primary = Color(0xFF01226A);

  /// Brand primary light-variant — royal blue (dark-theme primary).
  static const Color primaryLight = Color(0xFF0043B0);

  /// Brand highlight — the icon's orange (theme `secondary`).
  static const Color highlight = Color(0xFFFD8B01);

  /// Brand supporting green (reserved for non-GST brand moments).
  static const Color green = Color(0xFF1F8A10);

  /// Brand white — the icon's badge colour (card/surface base).
  static const Color white = Color(0xFFFEFEFE);

  // ── Primary content text (title / hero numerals) ────────────────────────

  /// Light-theme primary content — deep navy charcoal. Softer than pure
  /// black, it matches the brand navy family while staying the strongest
  /// text on screen. Content is navy-charcoal, brand navy is the accent,
  /// neutrals are gray — never the reverse.
  static const Color textPrimaryLight = Color(0xFF172033);

  /// Dark-theme primary content — near-white on the deep navy surfaces.
  static const Color textPrimaryDark = Color(0xFFF1F3F9);

  // ── Surfaces (derived from the brand navy/white pair) ─────────────────

  /// Light app background — cool off-white (white + a hint of navy).
  static const Color surfaceLight = Color(0xFFF4F5F8);

  /// Light input fill — cool, one step deeper than the background.
  static const Color inputLight = Color(0xFFE9ECF2);

  /// Dark app background — deep cool navy-charcoal.
  static const Color surfaceDark = Color(0xFF0E1320);

  /// Dark card surface — one step above the background.
  static const Color cardDark = Color(0xFF182136);

  /// Dark input fill — one step above the card (the interactive/elevated
  /// level, so the three dark surfaces stay clearly distinct).
  static const Color inputDark = Color(0xFF212B42);

  /// Light secondary-text grey (WCAG AA on scaffold, ≈ 4.6:1).
  static const Color onSurfaceVariantLight = Color(0xFF4A5568);

  /// Dark secondary-text grey (WCAG AA on cardDark, ≈ 4.6:1).
  static const Color onSurfaceVariantDark = Color(0xFFCBD5E1);

  /// Foreground for [highlight] (WCAG AA ≈ 5.8:1).
  static const Color onHighlight = Color(0xFF3E2A00);

  /// Seed for the light theme (drives the derived M3 tones).
  static const Color lightSeed = primary;

  /// Seed for the dark theme.
  static const Color darkSeed = primaryLight;
}
