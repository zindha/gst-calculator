import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// Calculation mode controls: the primary "Add GST / Remove GST" selector and
/// the quieter "Intra-State / Inter-State" transaction selector.
class CalculationModeToggle extends ConsumerWidget {
  const CalculationModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gstCalculatorProvider);

    final isExclusive = state.calculationType == GstCalculationType.exclusive;
    final isIntraState = state.transactionType == GstTransactionType.intraState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('CALCULATION'),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Calculation mode. Current: ${state.calculationType.label}',
          child: SegmentedControl(
            options: const [
              SegmentOption(
                label: 'Add GST',
                icon: LucideIcons.plusCircle,
              ),
              SegmentOption(
                label: 'Remove GST',
                icon: LucideIcons.minusCircle,
              ),
            ],
            selectedIndex: isExclusive ? 0 : 1,
            onSelected: (index) {
              if (index == 0 && !isExclusive || index == 1 && isExclusive) {
                HapticFeedback.selectionClick();
                ref
                    .read(gstCalculatorProvider.notifier)
                    .toggleCalculationType();
              }
            },
            emphasized: true,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: 'Transaction type. Current: ${state.transactionType.label}',
          child: SegmentedControl(
            options: const [
              SegmentOption(
                label: 'Intra-State',
                icon: LucideIcons.building,
              ),
              SegmentOption(label: 'Inter-State', icon: LucideIcons.globe),
            ],
            selectedIndex: isIntraState ? 0 : 1,
            onSelected: (index) {
              if (index == 0 && !isIntraState || index == 1 && isIntraState) {
                HapticFeedback.selectionClick();
                ref
                    .read(gstCalculatorProvider.notifier)
                    .toggleTransactionType();
              }
            },
            emphasized: false,
          ),
        ),
      ],
    );
  }
}

class SegmentOption {
  final String label;
  final IconData icon;

  const SegmentOption({required this.label, required this.icon});
}

/// A two-option segmented selector with a sliding background pill.
///
/// Selection is communicated through a filled container behind the active
/// segment plus bold typography — unmistakable, not just a colour shift.
/// [emphasized] picks the size: a taller, bolder primary control versus a
/// compact secondary one. Each segment is a full-height, full-width touch
/// target, not just its label.
class SegmentedControl extends StatefulWidget {
  final List<SegmentOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool emphasized;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.emphasized,
  });

  @override
  State<SegmentedControl> createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pillController;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Start at the selected position (no animation on first build).
    _pillController.value = widget.selectedIndex == 0 ? 0.0 : 1.0;
  }

  @override
  void didUpdateWidget(SegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      final target = widget.selectedIndex == 0 ? 0.0 : 1.0;
      // Spring the pill to the new position.
      final sim = AppSpring.medium.toSimulation(
        from: _pillController.value,
        to: target,
        velocity: _pillController.velocity,
      );
      _pillController.animateWith(sim);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Minimum 44px touch target for both variants.
    final height = widget.emphasized ? 46.0 : 44.0;
    final labelSize = widget.emphasized ? 14.0 : 13.0;
    final iconSize = widget.emphasized ? 17.0 : 16.0;

    // Track: subtle container that holds the sliding pill.
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    // Pill: the selected segment's filled background.
    final pillColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / widget.options.length;
        final pillRadius = AppRadius.sm;

        return SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _pillController,
            builder: (context, _) {
              // Interpolate pill position: 0.0 = left segment, 1.0 = right.
              final pillX = _pillController.value * segmentWidth;

              return Container(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(pillRadius + 2),
                ),
                padding: const EdgeInsets.all(2),
                child: Stack(
                  children: [
                    // Sliding pill — spring-driven background behind the
                    // selected segment.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      left: pillX,
                      top: 0,
                      width: segmentWidth,
                      height: height - 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(pillRadius),
                          // In light mode, a subtle border lifts the white pill
                          // off the light surface; in dark mode the shadow alone
                          // provides enough separation.
                          border: isDark
                              ? null
                              : Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.08),
                              blurRadius: isDark ? 6 : 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Segments.
                    Positioned.fill(
                      child: Row(
                        children: List.generate(widget.options.length, (i) {
                          final selected = i == widget.selectedIndex;
                          final contentColor = selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant;
                          return Expanded(
                            child: Semantics(
                              label: widget.options[i].label,
                              selected: selected,
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onSelected(i),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.options[i].icon,
                                        size: iconSize,
                                        color: contentColor,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            widget.options[i].label,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: labelSize,
                                              height: 1.2,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: contentColor,
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
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
