import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/color_presets.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/gst_math.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/gst_calculation_type.dart';
import '../../domain/entities/gst_calculator_state.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// The result — the visual payoff of the calculator.
///
/// Deliberately container-free: once a calculation exists, the total becomes
/// the star of the screen, sitting directly on the page with a receipt-style
/// dashed divider and restrained breakdown rows below. Hierarchy: TOTAL
/// amount (hero) > GST total (saffron accent) > breakdown rows (quiet,
/// color-coded values). A muted mode line confirms the calculation type
/// without competing with the total. All monetary values use tabular figures
/// so the digits align in a column, and the amount is wrapped in [FittedBox]
/// so it never clips at large font scales or long Indian-formatted numbers.
/// The empty state is a single quiet hint — part of the screen flow, not a
/// second hero panel — and the empty/result swap animates with a fast fade +
/// rise so state changes never snap.
class ResultsBreakdownCard extends ConsumerWidget {
  const ResultsBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(gstCalculatorProvider);
    final result = state.result;

    final hasResult = result != null && state.amountText.isNotEmpty;
    final transition = appMotion(context, milliseconds: 220);

    return _SpringSwitcher(
      duration: transition,
      child: hasResult
          ? _buildResultSection(context, state, result)
          : _buildEmptyState(theme),
    );
  }

  Widget _buildResultSection(
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

    return Column(
      key: const ValueKey('result-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row: a quiet "Total Amount" eyebrow with the muted mode
        // confirmation beside it — no heading, no chrome; the number below
        // is the content.
        Row(
          children: [
            Expanded(
              child: Text(
                'Total Amount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
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
        const SizedBox(height: AppSpacing.xs),

        // Primary result — the hero number.
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

        const SizedBox(height: AppSpacing.xxl),
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
    return Row(
      key: const ValueKey('result-empty'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.receipt,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
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

/// An animated switcher that uses spring physics for the transition.
///
/// When the child changes (empty → result), the new child springs into
/// place with a natural overshoot instead of a mathematical easeOutCubic.
class _SpringSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SpringSwitcher({
    required this.child,
    required this.duration,
  });

  @override
  State<_SpringSwitcher> createState() => _SpringSwitcherState();
}

class _SpringSwitcherState extends State<_SpringSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Widget? _oldChild;
  Widget? _newChild;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Safety cap; the spring settles on its own.
      duration: const Duration(milliseconds: 800),
    );
    _newChild = widget.child;
  }

  @override
  void didUpdateWidget(_SpringSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child && !_isAnimating) {
      _isAnimating = true;
      _oldChild = _newChild;
      _newChild = widget.child;
      // Drive the crossfade with a real spring simulation.
      final simulation = AppSpring.medium.toSimulation(
        from: 0,
        to: 1,
        velocity: 0,
      );
      _controller
          .animateWith(simulation)
          .then((_) {
        _isAnimating = false;
        _oldChild = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Clamp because the spring overshoots past 1.0.
        final t = _controller.value.clamp(0.0, 1.0);

        return Stack(
          children: [
            if (_oldChild != null && _isAnimating)
              IgnorePointer(
                child: Opacity(
                  opacity: 1 - t,
                  child: _oldChild,
                ),
              ),
            Opacity(
              opacity: _isAnimating ? t : 1,
              child: Transform.translate(
                offset: Offset(0, _isAnimating ? (1 - t) * 8 : 0),
                child: _newChild,
              ),
            ),
          ],
        );
      },
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
