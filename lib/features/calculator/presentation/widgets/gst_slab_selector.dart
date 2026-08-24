import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/gst_rates.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/rate_formatter.dart';
import '../../../../core/widgets/brand_chip.dart';
import '../../../../core/widgets/section_label.dart';
import '../providers/gst_calculator_notifier.dart';

/// GST slab rate selector: standard slabs as chips plus a custom rate option.
class GstSlabSelector extends ConsumerStatefulWidget {
  const GstSlabSelector({super.key});

  @override
  ConsumerState<GstSlabSelector> createState() => _GstSlabSelectorState();
}

class _GstSlabSelectorState extends ConsumerState<GstSlabSelector> {
  final TextEditingController _customRateController = TextEditingController();

  @override
  void dispose() {
    _customRateController.dispose();
    super.dispose();
  }

  void _openCustomRateDialog() {
    _customRateController.text = '';
    showDialog(
      context: context,
      builder: (ctx) => _CustomRateDialog(
        controller: _customRateController,
        onApply: (rate) {
          HapticFeedback.selectionClick();
          ref.read(gstCalculatorProvider.notifier).setCustomSlab(rate);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gstCalculatorProvider);

    return Semantics(
      label:
          'GST rate selection. Selected: ${formatRate(state.effectiveRate)} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('GST RATE'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...GstRates.standardSlabs.map(
                (slab) {
                  final selected =
                      !state.isCustomSlab && state.selectedSlab == slab;
                  return BrandChip(
                    // formatRate renders fractional slabs correctly:
                    // 0.25 → '0.25%', whole slabs like 18 → '18%'.
                    label: '${formatRate(slab)}%',
                    icon: selected ? LucideIcons.check : null,
                    selected: selected,
                    semanticsLabel:
                        '${formatRate(slab)}% GST rate'
                        '${selected ? ', selected' : ''}',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(gstCalculatorProvider.notifier).selectSlab(slab);
                    },
                  );
                },
              ),
              BrandChip(
                label: state.isCustomSlab
                    ? '${formatRate(state.customSlabValue)}%'
                    : 'Custom',
                icon: state.isCustomSlab ? LucideIcons.check : LucideIcons.pencil,
                selected: state.isCustomSlab,
                semanticsLabel:
                    'Custom GST rate'
                    '${state.isCustomSlab ? ', selected' : ''}',
                onTap: _openCustomRateDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A dialog for entering a custom GST rate with inline validation.
///
/// Shows real-time error text below the field instead of a SnackBar,
/// following the Forms & Feedback UX guideline: "Error near field, not at top."
class _CustomRateDialog extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<double> onApply;

  const _CustomRateDialog({
    required this.controller,
    required this.onApply,
  });

  @override
  State<_CustomRateDialog> createState() => _CustomRateDialogState();
}

class _CustomRateDialogState extends State<_CustomRateDialog>
    with SingleTickerProviderStateMixin {
  String? _errorText;
  late final AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    // Spring-driven shake: the spring overshoots and decays, creating
    // a natural left-right vibration that settles.
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _validate() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = null);
      return;
    }
    final rate = double.tryParse(text);
    if (rate == null) {
      setState(() => _errorText = 'Enter a valid number');
    } else if (rate < 0 || rate > 100) {
      setState(() => _errorText = 'Rate must be between 0 and 100');
    } else {
      setState(() => _errorText = null);
    }
  }

  void _apply() {
    final text = widget.controller.text.trim();
    final rate = double.tryParse(text);
    if (rate == null || rate < 0 || rate > 100) {
      _validate();
      _triggerShake();
      return;
    }
    widget.onApply(rate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom GST Rate'),
      content: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          // Map the spring value to a horizontal offset: the spring
          // overshoots past 1.0, creating a natural decaying shake.
          final shakeOffset =
              _shakeAnimation.value == 0
                  ? 0.0
                  : (1 - _shakeAnimation.value) *
                      6 *
                      ((_shakeController.value * 6) % 2 < 1 ? 1 : -1);
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _validate(),
              decoration: InputDecoration(
                labelText: 'Rate (%)',
                hintText: 'e.g., 0.25, 1.5, 40',
                suffixText: '%',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a rate between 0% and 100%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
