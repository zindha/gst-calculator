import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// A pressable brand chip with one consistent recipe for icon/label
/// alignment, radii, spacing and selected state.
///
/// Used by the GST rate slabs and the quick amount actions so every pill on
/// the calculator screen reads as part of one intentional system:
/// - subtle radius (never a giant capsule)
/// - quiet input surface + thin border when unselected
/// - solid brand-primary fill + high-contrast content when selected
/// - a small 0.97 press scale (120ms) as the only press feedback
class BrandChip extends StatefulWidget {
  /// Chip label, e.g. `18%` or `+₹100`.
  final String label;

  /// Optional leading icon (check mark when selected, `+` for quick amounts).
  final IconData? icon;

  /// Selected chips use the solid brand-primary treatment.
  final bool selected;

  /// Secondary chips (quick amounts) tint their content with the brand
  /// primary instead of plain on-surface text.
  final bool tinted;

  /// Overrides the default `Semantics` label.
  final String? semanticsLabel;

  final VoidCallback? onTap;

  const BrandChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.tinted = false,
    this.semanticsLabel,
    this.onTap,
  });

  @override
  State<BrandChip> createState() => _BrandChipState();
}

class _BrandChipState extends State<BrandChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final duration = appMotion(context, milliseconds: 120);

    final fill = selected
        ? theme.colorScheme.primary
        : theme.gstColors.inputBackground;
    final content = selected
        ? theme.colorScheme.onPrimary
        : widget.tinted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final border = selected
        ? fill
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return Semantics(
      label:
          widget.semanticsLabel ??
          '${widget.label}${selected ? ', selected' : ''}',
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  AnimatedSwitcher(
                    duration: duration,
                    child: Icon(
                      widget.icon,
                      key: ValueKey(widget.icon),
                      size: 16,
                      color: content,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    height: 1.2,
                    color: content,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
