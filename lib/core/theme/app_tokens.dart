import 'package:flutter/material.dart';

/// Centralized spacing rhythm for the app.
///
/// The rhythm follows a 4 → 32 logical pixel ladder so every gap in the UI
/// reads as part of one system: 4, 8, 12, 16, 20, 24, 32.
abstract final class AppSpacing {
  AppSpacing._();

  /// 4 — micro gaps (icon-to-text inside a control).
  static const double xs = 4;

  /// 8 — tight gaps (icon row, badge to text).
  static const double sm = 8;

  /// 12 — default gap between related elements.
  static const double md = 12;

  /// 16 — comfortable gap between groups.
  static const double lg = 16;

  /// 20 — screen horizontal padding.
  static const double xl = 20;

  /// 24 — section separation.
  static const double xxl = 24;

  /// 32 — major section separation / generous padding.
  static const double xxxl = 32;
}

/// Centralized corner radii.
abstract final class AppRadius {
  AppRadius._();

  /// 12 — small controls, chips, buttons.
  static const double sm = 12;

  /// 16 — list items, small surfaces.
  static const double md = 16;

  /// 20 — cards and input surfaces.
  static const double lg = 20;

  /// 24 — hero surfaces (result card, dialog).
  static const double xl = 24;

  /// Fully rounded — pills, segmented track ends.
  static const double pill = 999;
}

/// Centralized dimensions (touch targets, icon sizes, control heights).
abstract final class AppDimens {
  AppDimens._();

  /// Minimum comfortable touch target (Material 48dp guidance).
  static const double touch = 48;

  /// Standard action icon size.
  static const double icon = 24;

  /// Height of primary segmented controls (Add/Remove GST).
  static const double control = 54;

  /// Height of compact secondary controls (transaction type).
  static const double controlCompact = 44;

  /// Maximum content width on large screens (tablet/desktop).
  static const double maxContentWidth = 640;
}

/// Convenience: the standard 150–250ms motion duration used across the app.
Duration appMotion(BuildContext context, {int milliseconds = 200}) {
  if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
  return Duration(milliseconds: milliseconds);
}
