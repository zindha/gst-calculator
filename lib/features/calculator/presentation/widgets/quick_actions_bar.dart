import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/accessibility_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/gst_math.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/gst_calculator_state.dart';
import '../../domain/entities/gst_transaction_type.dart';
import '../providers/gst_calculator_notifier.dart';

/// Quick actions for a completed calculation: copy and share.
class QuickActionsBar extends ConsumerWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(gstCalculatorProvider);
    final result = state.result;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Copy calculation breakdown to clipboard',
                child: OutlinedButton.icon(
                  onPressed: () => _copyBreakdown(context, state, result),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size(0, AppDimens.touch),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                label: 'Share calculation breakdown',
                child: FilledButton.icon(
                  onPressed: () => _shareBreakdown(context, state, result),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size(0, AppDimens.touch),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyBreakdown(
    BuildContext context,
    GstCalculatorState state,
    GstResult result,
  ) {
    A11y.tap();
    final summary = _buildSummaryText(state, result);
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareBreakdown(
    BuildContext context,
    GstCalculatorState state,
    GstResult result,
  ) {
    A11y.tap();
    final summary = _buildSummaryText(state, result);
    SharePlus.instance.share(ShareParams(text: summary));
  }

  String _buildSummaryText(GstCalculatorState state, GstResult result) {
    final isIntraState = state.transactionType == GstTransactionType.intraState;
    // Same reconciliation policy as the result card, so the copied/shared
    // breakdown sums exactly like the numbers shown on screen.
    final breakdown = Money.reconcileResult(
      result,
      isIntraState: isIntraState,
    );
    final buffer = StringBuffer();
    buffer.writeln('GST Calculation Summary');
    buffer.writeln('-' * 24);
    if (result.isInclusive) {
      buffer.writeln(
        'Total (incl. GST): ${CurrencyFormatter.format(breakdown.total)}',
      );
    } else {
      buffer.writeln(
        'Base Amount: ${CurrencyFormatter.format(breakdown.base)}',
      );
    }
    buffer.writeln('Rate: ${result.rate}%');
    if (isIntraState) {
      buffer.writeln(
        'CGST (${result.rate / 2}%): '
        '${CurrencyFormatter.format(breakdown.cgst)}',
      );
      buffer.writeln(
        'SGST (${result.rate / 2}%): '
        '${CurrencyFormatter.format(breakdown.sgst)}',
      );
    } else {
      buffer.writeln(
        'IGST (${result.rate}%): ${CurrencyFormatter.format(breakdown.igst)}',
      );
    }
    buffer.writeln('-' * 24);
    buffer.writeln('TOTAL: ${CurrencyFormatter.format(breakdown.total)}');
    buffer.writeln('-' * 24);
    buffer.writeln('Transaction: ${state.transactionType.shortLabel}');
    buffer.writeln(
      'Type: ${result.isInclusive ? "Inclusive (-GST)" : "Exclusive (+GST)"}',
    );
    buffer.writeln('');
    buffer.writeln('Shared via GST Calculator');
    return buffer.toString();
  }
}
