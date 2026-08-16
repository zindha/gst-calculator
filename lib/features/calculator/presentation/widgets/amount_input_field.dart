import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/color_presets.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/accessibility_helper.dart';
import '../../../../core/widgets/brand_chip.dart';
import '../../../../core/widgets/section_label.dart';
import '../providers/gst_calculator_notifier.dart';

/// Quick action amount chips to add to the current amount.
const List<double> _quickAmounts = [100, 500, 1000, 5000];

/// The hero amount input — the single most important control on the screen.
///
/// The value carries the visual weight; the label is a quiet eyebrow. The
/// surface reacts to focus with a short, restrained border transition so the
/// field reads unmistakably as "this is where I type the amount" without a
/// heavy glowing outline.
class AmountInputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  ConsumerState<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends ConsumerState<AmountInputField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _focused != widget.focusNode.hasFocus) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(gstCalculatorProvider);
    final gstColors = theme.gstColors;
    final duration = appMotion(context);
    final primary = theme.colorScheme.primary;
    // The entered value is primary content: dark charcoal in light mode,
    // near-white in dark — never the brand navy, which stays an accent.
    final textPrimary =
        theme.brightness == Brightness.dark
            ? BrandColors.textPrimaryDark
            : BrandColors.textPrimaryLight;

    final amountStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: textPrimary,
      fontVariations: const [FontVariation('wght', 700)],
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow label — deliberately small so the amount stays the hero.
        const SectionLabel('AMOUNT'),
        const SizedBox(height: AppSpacing.sm),

        // Main input surface.
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: gstColors.inputBackground,
            border: Border.all(
              color: _focused
                  ? primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
            style: amountStyle,
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: amountStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              // Fixed-width rupee slot, independent of the editable area: the
              // symbol is muted and centered so it reads as a label for the
              // number, never part of it, and it cannot shift as the value
              // changes. The 46px slot plus the small left inset keep the
              // cursor and digits clear of the symbol.
              prefixIcon: SizedBox(
                width: 46,
                child: Center(
                  child: Text(
                    '₹',
                    style: amountStyle.copyWith(
                      fontSize: 32,
                      height: 1.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              suffixIcon:
                  state.amountText.isNotEmpty
                      ? IconButton(
                        onPressed: () {
                          A11y.tap();
                          widget.controller.clear();
                          ref
                              .read(gstCalculatorProvider.notifier)
                              .updateAmount('');
                          widget.focusNode.requestFocus();
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Clear amount',
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                      : null,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              // Left inset stays small because the rupee slot already provides
              // the visual separation; right keeps comfortable breathing room
              // before the clear button.
              contentPadding: const EdgeInsets.fromLTRB(4, 20, 16, 20),
            ),
            onChanged: (value) {
              ref.read(gstCalculatorProvider.notifier).updateAmount(value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quick action chips — a deliberate 2×2 grid: every pill shares one
        // geometry, both rows are balanced edge to edge, and the layout reads
        // as intentional instead of an accidental wrap.
        Column(
          children: [
            for (var row = 0; row < _quickAmounts.length; row += 2) ...[
              if (row > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = row; i < row + 2; i++) ...[
                    if (i > row) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildQuickChip(_quickAmounts[i])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(double amount) {
    return BrandChip(
      label: _quickLabel(amount),
      icon: Icons.add_rounded,
      tinted: true,
      semanticsLabel: 'Add ${_quickLabel(amount)} to amount',
      onTap: () {
        A11y.tap();
        ref.read(gstCalculatorProvider.notifier).quickAddAmount(amount);
        widget.controller.text = ref.read(gstCalculatorProvider).amountText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      },
    );
  }

  static String _quickLabel(double amount) {
    // 100 → '+₹100', 500 → '+₹500', 1000 → '+₹1000', 5000 → '+₹5000'.
    return '+₹${amount ~/ 100 >= 1 ? '${amount ~/ 100}00' : amount.toString()}';
  }
}
