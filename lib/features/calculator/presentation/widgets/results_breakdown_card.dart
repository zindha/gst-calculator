import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/color_presets.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/gst_math.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_calculator_state.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// The result surface — the visual payoff of the calculator.
///
/// Hierarchy: TOTAL amount (hero) > GST total (saffron accent) > breakdown
/// rows (restrained, color-coded values). A quiet mode line confirms the
/// calculation type without competing with the total. All monetary values
/// use tabular figures so the digits align in a column, and the amount is
/// wrapped in [FittedBox] so it never clips at large font scales or long
/// Indian-formatted numbers. The empty state is deliberately light — it is
/// part of the screen flow, not a second hero panel — and the empty/result
/// swap animates with a fast fade + rise so state changes never snap.
class ResultsBreakdownCard extends ConsumerWidget {
  const ResultsBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(gstCalculatorProvider);
    final result = state.result;

    final hasResult = result != null && state.amountText.isNotEmpty;
    final transition = appMotion(context, milliseconds: 220);

    return AnimatedSwitcher(
      duration: transition,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: hasResult
          ? _buildResultCard(context, state, result)
          : _buildEmptyState(theme),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    GstCalculatorState state,
    GstResult result,
  ) {
    final theme = Theme.of(context);
    final gstColors = theme.gstColors;

    final isIntraState = state.transactionType == GstTransactionType.intraState;
    final isExclusive = state.calculationType == GstCalculationType.exclusive;
    // Displayed values reconcile: base + gst == total, cgst + sgst == gst.
    final breakdown = Money.reconcileResult(result, isIntraState: isIntraState);

    return Container(
      key: const ValueKey('result-card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: gstColors.cardBackground,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + a quiet mode confirmation. The title flexes so
            // the mode line never pushes the row past the surface on narrow
            // screens; the mode text is muted (no pill chrome) so it confirms
            // the calculation without competing with the total.
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Result',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    isExclusive
                        ? (isIntraState ? '+GST · CGST + SGST' : '+GST · IGST')
                        : (isIntraState ? '-GST · CGST + SGST' : '-GST · IGST'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Primary result — the hero number.
            Text(
              'Total Amount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: AnimatedSwitcher(
                duration: appMotion(context, milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child: FittedBox(
                  key: ValueKey(breakdown.total),
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(breakdown.total),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color:
                          theme.brightness == Brightness.dark
                              ? BrandColors.textPrimaryDark
                              : BrandColors.textPrimaryLight,
                      fontVariations: const [FontVariation('wght', 700)],
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // GST total — the secondary number. Wrapped in Flexible + FittedBox
            // so long formatted amounts never overflow the row at large text
            // scales or on narrow screens.
            Row(
              children: [
                Text(
                  'GST',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: appMotion(context),
                    child: FittedBox(
                      key: ValueKey(breakdown.gst),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.format(breakdown.gst),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: gstColors.totalColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            const _DashedDivider(),
            const SizedBox(height: AppSpacing.lg),

            // Breakdown rows. Values use tabular figures so the column of
            // money reads as one aligned statement; the tax color lives on
            // the value text (semantic) rather than a decorative dot.
            _BreakdownRow(
              label: 'Base Amount',
              value: CurrencyFormatter.format(breakdown.base),
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isIntraState) ...[
              _BreakdownRow(
                label: 'CGST @ ${_formatRate(result.rate / 2)}%',
                value: CurrencyFormatter.format(breakdown.cgst),
                color: gstColors.cgstColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              _BreakdownRow(
                label: 'SGST @ ${_formatRate(result.rate / 2)}%',
                value: CurrencyFormatter.format(breakdown.sgst),
                color: gstColors.sgstColor,
              ),
            ] else
              _BreakdownRow(
                label: 'IGST @ ${_formatRate(result.rate)}%',
                value: CurrencyFormatter.format(breakdown.igst),
                color: gstColors.igstColor,
              ),
          ],
        ),
      ),
    );
  }

  static String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) {
      return rate.toStringAsFixed(0);
    }
    var text = rate.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  Widget _buildEmptyState(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Container(
      key: const ValueKey('result-empty'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        // Same radius as the filled result card so the empty/result swap
        // never changes the surface geometry.
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: theme.gstColors.cardBackground.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.5 : 0.65,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: primary.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your result appears here',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enter an amount and pick a rate to see the GST breakdown',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Manrope',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// A thin dashed horizontal line, like the separator on a printed receipt.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
