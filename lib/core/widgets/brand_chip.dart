import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_animations.dart';

/// A pressable brand chip for discrete choices such as the GST rate slabs.
///
/// One consistent recipe for icon/label alignment, radii, spacing and
/// selected state:
/// - subtle radius (never a giant capsule)
/// - transparent fill + thin border when unselected, so only the active
///   choice carries a surface (the page background shows through)
/// - solid brand-primary fill + high-contrast content when selected
/// - a small 0.97 press scale (120ms) as the only press feedback
class BrandChip extends StatefulWidget {
  /// Chip label, e.g. `18%`.
  final String label;

  /// Optional leading icon (check mark when selected).
  final IconData? icon;

  /// Selected chips use the solid brand-primary treatment.
  final bool selected;

  /// Overrides the default `Semantics` label.
  final String? semanticsLabel;

  final VoidCallback? onTap;

  const BrandChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.semanticsLabel,
    this.onTap,
  });

  @override
  State<BrandChip> createState() => _BrandChipState();
}

class _BrandChipState extends State<BrandChip>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    // Spring into the pressed state: low velocity gives a soft bounce.
    final simulation = AppSpring.gentle.toSimulation(from: 1.0, to: 0.97);
    _pressController.animateWith(simulation);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    // Spring back: reversed spring with the release velocity.
    final simulation = AppSpring.gentle.toSimulation(
      from: _pressController.value,
      to: 1.0,
      velocity: _pressController.velocity,
    );
    _pressController.animateWith(simulation);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    final simulation = AppSpring.gentle.toSimulation(
      from: _pressController.value,
      to: 1.0,
      velocity: _pressController.velocity,
    );
    _pressController.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final duration = appMotion(context, milliseconds: 120);

    // Unselected chips are transparent: the page shows through and the thin
    // outline alone marks the option, so unselected states stay quiet and
    // only the active choice earns a solid surface.
    final fill = selected ? theme.colorScheme.primary : Colors.transparent;
    final content = selected
        ? theme.colorScheme.onPrimary
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
        onTapDown: _onTapDown,
        onTapCancel: _onTapCancel,
        onTapUp: _onTapUp,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pressAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pressAnimation.value,
              child: child,
            );
          },
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
              // min size keeps pills content-hugging inside a Wrap so every
              // rate slab hugs its content; [center] keeps the icon + label
              // centered as one unit.
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
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
                // Scale the label down (never up) when a stretched pill is
                // narrower than its text at large font scales — the same
                // guard the segmented controls use, so no pill ever clips.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
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
