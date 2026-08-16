import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      builder:
          (ctx) => AlertDialog(
            title: const Text('Custom GST Rate'),
            content: TextField(
              controller: _customRateController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rate (%)',
                hintText: 'e.g., 0.25, 1.5, 40',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _applyCustomRate(ctx),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _applyCustomRate(ctx),
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  void _applyCustomRate(BuildContext dialogContext) {
    final text = _customRateController.text.trim();
    final rate = double.tryParse(text);
    if (rate == null || rate < 0 || rate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid rate between 0 and 100'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    ref.read(gstCalculatorProvider.notifier).setCustomSlab(rate);
    Navigator.of(dialogContext).pop();
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
                    label: '${slab.toStringAsFixed(0)}%',
                    icon: selected ? Icons.check_rounded : null,
                    selected: selected,
                    semanticsLabel:
                        '${slab.toStringAsFixed(0)}% GST rate'
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
                icon: state.isCustomSlab ? Icons.check_rounded : Icons.edit_rounded,
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
