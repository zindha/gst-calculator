import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// Calculation mode controls: the primary "Add GST / Remove GST" selector and
/// the compact "Intra-State / Inter-State" transaction selector.
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
          child: _SegmentedControl(
            options: const [
              _SegmentOption(
                label: 'Add GST',
                icon: Icons.add_circle_outline_rounded,
              ),
              _SegmentOption(
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
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          label: 'Transaction type. Current: ${state.transactionType.label}',
          child: _SegmentedControl(
            options: const [
              _SegmentOption(
                label: 'Intra-State',
                icon: Icons.location_city_rounded,
              ),
              _SegmentOption(label: 'Inter-State', icon: Icons.public_rounded),
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

class _SegmentOption {
  final String label;
  final IconData icon;

  const _SegmentOption({required this.label, required this.icon});
}

/// A two-option segmented control with a sliding thumb.
///
/// [emphasized] selects the thumb treatment: a solid brand-primary thumb for
/// the primary control versus a quiet tonal thumb for the secondary control.
/// The selected indicator animates smoothly between segments (~200ms).
class _SegmentedControl extends StatelessWidget {
  final List<_SegmentOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool emphasized;

  const _SegmentedControl({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gstColors = theme.gstColors;
    final isDark = theme.brightness == Brightness.dark;
    final duration = appMotion(context, milliseconds: 200);

    final thumbColor = emphasized
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = (constraints.maxWidth / options.length) - 6;
        return Container(
          height: emphasized ? AppDimens.control : AppDimens.controlCompact,
          decoration: BoxDecoration(
            color: gstColors.inputBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              // Sliding thumb.
              AnimatedAlign(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment(selectedIndex == 0 ? -1 : 1, 0),
                child: Container(
                  width: thumbWidth,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(AppRadius.md - 3),
                  ),
                ),
              ),
              // Segments.
              Row(
                children: List.generate(options.length, (i) {
                  final selected = i == selectedIndex;
                  final contentColor = selected
                      ? (emphasized
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary)
                      : theme.colorScheme.onSurfaceVariant;
                  return Expanded(
                    child: Semantics(
                      label: options[i].label,
                      selected: selected,
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelected(i),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              options[i].icon,
                              size: 17,
                              color: contentColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  options[i].label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: emphasized ? 14 : 13,
                                    height: 1.2,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: contentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
