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
            // Content-driven height (≈ AppDimens.chip at the standard text
            // scale): the pill hugs its content so the icon + label are always
            // perfectly vertically centered, and every pill in a group shares
            // identical geometry because the content metrics are identical.
            // The pill grows uniformly when text scaling increases instead of
            // clipping inside a fixed height.
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              // Uniform border width in both states: Container adds the
              // decoration's border to its layout size, so a wider selected
              // border made the selected pill 1px taller (baseline jump).
              // The selected state is conveyed by the fill, check and bold
              // label instead — the border is the same color as the fill and
              // was never visible.
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed-size icon slot, always reserved: a selected check (or
                // the + / edit glyph) appears inside the same 16×16 space, so
                // the label never shifts horizontally and selected/unselected
                // pills keep identical dimensions.
                SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      widget.icon == null
                          ? null
                          : AnimatedSwitcher(
                            duration: duration,
                            child: Icon(
                              widget.icon,
                              key: ValueKey(widget.icon),
                              size: 16,
                              color: content,
                            ),
                          ),
                ),
                const SizedBox(width: 6),
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
