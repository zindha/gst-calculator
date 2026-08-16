import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper mixin/utility for consistent accessibility labels and haptics.
class A11y {
  A11y._();

  // ── Haptics ──────────────────────────────────────────

  /// Light tap feedback (buttons, chips).
  static void tap() => HapticFeedback.lightImpact();

  /// Medium impact (destructive actions, clear all).
  static void impact() => HapticFeedback.mediumImpact();

  /// Selection feedback (toggles, switches).
  static void select() => HapticFeedback.selectionClick();

  /// Heavy impact (important completions).
  static void confirm() => HapticFeedback.heavyImpact();

  // ── Semantics wrappers ───────────────────────────────

  /// Wraps a widget with a semantic label for screen readers.
  static Widget label(Widget child, String label) =>
      Semantics(label: label, child: child);

  /// Creates an icon button with haptic feedback and a tooltip.
  ///
  /// When [onPressed] is null the button renders disabled (grayed out) — use
  /// this for state-aware actions that are unavailable in the current state
  /// rather than hiding the button entirely.
  static Widget iconButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    double? iconSize,
  }) {
    return Semantics(
      label: label,
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        tooltip: label,
        onPressed:
            onPressed == null
                ? null
                : () {
                  tap();
                  onPressed();
                },
        onLongPress:
            onLongPress != null
                ? () {
                  tap();
                  onLongPress();
                }
                : null,
      ),
    );
  }

  /// Wraps a value display (e.g., a calculated amount) with a semantic label.
  static Widget valueDisplay(Widget child, String label, String value) =>
      Semantics(label: '$label: $value', child: child);
}
