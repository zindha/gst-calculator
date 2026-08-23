import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                icon: Icons.add_circle_outline_rounded,
              ),
              SegmentOption(
                label: 'Remove GST',
                icon: Icons.remove_circle_outline_rounded,
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
                icon: Icons.location_city_rounded,
              ),
              SegmentOption(label: 'Inter-State', icon: Icons.public_rounded),
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

/// A two-option selector with a sliding underline.
///
/// Deliberately container-free: the options sit directly on the page and the
/// only selection affordance is a 2px brand underline that slides beneath the
/// active segment — colour, weight and underline, never a pill or a track.
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
  late final AnimationController _underlineController;
  double _underlineTarget = -1;

  @override
  void initState() {
    super.initState();
    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _underlineTarget = widget.selectedIndex == 0 ? -1.0 : 1.0;
    _underlineController.value = _underlineTarget;
  }

  @override
  void didUpdateWidget(SegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      final newTarget = widget.selectedIndex == 0 ? -1.0 : 1.0;
      // Spring the underline to the new position.
      final sim = AppSpring.fast.toSimulation(
        from: _underlineController.value,
        to: newTarget,
        velocity: _underlineController.velocity,
      );
      _underlineController.animateWith(sim);
      _underlineTarget = newTarget;
    }
  }

  @override
  void dispose() {
    _underlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final height = widget.emphasized ? 46.0 : 38.0;
    final labelSize = widget.emphasized ? 14.0 : 13.0;
    final iconSize = widget.emphasized ? 17.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / widget.options.length;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Sliding underline — spring-driven, not curve-driven.
              AnimatedBuilder(
                animation: _underlineController,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment(_underlineController.value, 1),
                    child: Container(
                      width: segmentWidth,
                      height: 2,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                },
              ),
              // Segments. Positioned.fill makes the row span the full control
              // height; each segment then centers its content so the icon and
              // label stay vertically centered as one unit in both states.
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
    );
  }
}
