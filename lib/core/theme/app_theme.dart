import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_presets.dart';
import 'theme_extensions.dart';

/// Builds the application's light theme ("The Ledger" identity).
///
/// Icon-derived navy brand on cool surfaces, with a single Manrope type
/// family for a clean, modern financial-instrument feel. The brand identity
/// is fixed: the icon-derived navy is always the primary action colour.
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.lightSeed,
    brightness: Brightness.light,
    primary: BrandColors.primary,
    onPrimary: Colors.white,
    secondary: BrandColors.highlight,
    onSecondary: BrandColors.onHighlight,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: BrandColors.surfaceLight,
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: BrandColors.surfaceLight,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        size: 18,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x1A5B4636),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.inputLight,
      labelStyle: _manrope(color: colorScheme.onSurfaceVariant, size: 14),
      hintStyle: _manrope(color: colorScheme.onSurfaceVariant, size: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: colorScheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _manrope(weight: FontWeight.w600, size: 14),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        elevation: 0,
        backgroundColor: BrandColors.inputLight,
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
        foregroundColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w600, size: 13),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: BrandColors.inputLight,
      labelStyle: _manrope(
        color: colorScheme.onSurfaceVariant,
        weight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: _manrope(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        size: 19,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      contentTextStyle: _manrope(color: colorScheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      dragHandleColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.primary,
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        weight: FontWeight.w600,
        size: 15,
      ),
      subtitleTextStyle: _manrope(
        color: colorScheme.onSurfaceVariant,
        size: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll(
        _manrope(
          color: colorScheme.onSurface,
          size: 12,
          weight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    extensions: const <ThemeExtension<dynamic>>[GSTColorScheme.light],
  );
}

/// Builds the application's dark theme ("The Ledger" identity).
ThemeData buildDarkTheme() {
  // The icon-derived royal blue is the dark-mode primary (white text, AA).
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.darkSeed,
    brightness: Brightness.dark,
    primary: BrandColors.primaryLight,
    onPrimary: Colors.white,
    secondary: BrandColors.highlight,
    onSecondary: BrandColors.onHighlight,
    surface: BrandColors.surfaceDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BrandColors.surfaceDark,
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: BrandColors.surfaceDark,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        size: 18,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: BrandColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.inputDark,
      labelStyle: _manrope(color: colorScheme.onSurfaceVariant, size: 14),
      hintStyle: _manrope(color: colorScheme.onSurfaceVariant, size: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: colorScheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w700, size: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _manrope(weight: FontWeight.w600, size: 14),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        elevation: 0,
        backgroundColor: BrandColors.inputDark,
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
        foregroundColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _manrope(weight: FontWeight.w600, size: 13),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: BrandColors.inputDark,
      labelStyle: _manrope(
        color: colorScheme.onSurfaceVariant,
        weight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: _manrope(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BrandColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        size: 19,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      contentTextStyle: _manrope(color: colorScheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: BrandColors.cardDark,
      showDragHandle: true,
      dragHandleColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.primary,
      titleTextStyle: _manrope(
        color: colorScheme.onSurface,
        weight: FontWeight.w600,
        size: 15,
      ),
      subtitleTextStyle: _manrope(
        color: colorScheme.onSurfaceVariant,
        size: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: BrandColors.cardDark,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        _manrope(
          color: colorScheme.onSurface,
          size: 12,
          weight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    extensions: const <ThemeExtension<dynamic>>[GSTColorScheme.dark],
  );
}

/// Builds the app typography: one clean sans family (Manrope) for every
/// level, with hierarchy expressed through size and weight rather than a
/// decorative serif display face.
TextTheme _buildTextTheme(Brightness brightness) {
  final base =
      brightness == Brightness.dark
          ? Typography.material2021(platform: TargetPlatform.android).white
          : Typography.material2021(platform: TargetPlatform.android).black;
  return base.copyWith(
    displayLarge: _manrope(size: 56, weight: FontWeight.w600, height: 1.05, letterSpacing: -0.5),
    displayMedium: _manrope(size: 44, weight: FontWeight.w600, height: 1.1, letterSpacing: -0.5),
    displaySmall: _manrope(size: 36, weight: FontWeight.w600, height: 1.15, letterSpacing: -0.5),
    headlineLarge: _manrope(size: 32, weight: FontWeight.w600, height: 1.2, letterSpacing: -0.3),
    headlineMedium: _manrope(size: 27, weight: FontWeight.w600, height: 1.25, letterSpacing: -0.3),
    headlineSmall: _manrope(size: 23, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.3),
    titleLarge: _manrope(size: 21, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.3),
    titleMedium: _manrope(size: 16, weight: FontWeight.w700, height: 1.35),
    titleSmall: _manrope(size: 14, weight: FontWeight.w700, height: 1.35),
    bodyLarge: _manrope(size: 16, weight: FontWeight.w400, height: 1.45),
    bodyMedium: _manrope(size: 14, weight: FontWeight.w400, height: 1.45),
    bodySmall: _manrope(size: 12, weight: FontWeight.w400, height: 1.4),
    labelLarge: _manrope(size: 14, weight: FontWeight.w700, height: 1.3),
    labelMedium: _manrope(size: 12, weight: FontWeight.w600, height: 1.3),
    labelSmall: _manrope(size: 11, weight: FontWeight.w600, height: 1.3),
  );
}

/// Manrope text style with an explicit variable weight axis.
TextStyle _manrope({
  Color? color,
  double size = 14,
  FontWeight weight = FontWeight.w400,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    fontVariations: [FontVariation("wght", weight.value.toDouble())],
  );
}
