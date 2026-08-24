import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// Calculation mode controls: the primary "Add GST / Remove GST" selector and
/// the quieter "Intra-State / Inter-State" transaction selector.
///
/// Both controls use the same selection language as the GST rate chips:
/// selected = blue fill + white text + checkmark, unselected = transparent
/// + muted text + subtle border. One glance tells you what's active.
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
          child: Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Add GST',
                  icon: LucideIcons.plusCircle,
                  selected: isExclusive,
                  onTap: () {
                    if (!isExclusive) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(gstCalculatorProvider.notifier)
                          .toggleCalculationType();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ModeChip(
                  label: 'Remove GST',
                  icon: LucideIcons.minusCircle,
                  selected: !isExclusive,
                  onTap: () {
                    if (isExclusive) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(gstCalculatorProvider.notifier)
                          .toggleCalculationType();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionLabel('TAX TYPE'),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Transaction type. Current: ${state.transactionType.label}',
          child: Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Intra-State',
                  icon: LucideIcons.building,
                  selected: isIntraState,
                  onTap: () {
                    if (!isIntraState) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(gstCalculatorProvider.notifier)
                          .toggleTransactionType();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ModeChip(
                  label: 'Inter-State',
                  icon: LucideIcons.globe,
                  selected: !isIntraState,
                  onTap: () {
                    if (isIntraState) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(gstCalculatorProvider.notifier)
                          .toggleTransactionType();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single selection chip that matches the GST rate chip visual language.
///
/// Selected: blue fill + white text + checkmark.
/// Unselected: transparent + muted text + subtle border.
/// One glance tells you what's active — no decoding required.
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Selection language: identical to the GST rate chips.
    final fill = selected ? theme.colorScheme.primary : Colors.transparent;
    final content = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final borderOpacity = isDark ? 0.8 : 0.6;
    final border = selected
        ? fill
        : theme.colorScheme.outlineVariant.withValues(alpha: borderOpacity);

    return Semantics(
      label: '$label${selected ? ', selected' : ''}',
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark when selected, original icon when not.
              SizedBox(
                width: 16,
                height: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    selected ? LucideIcons.check : icon,
                    key: ValueKey(selected),
                    size: 16,
                    color: content,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
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
    );
  }
}
