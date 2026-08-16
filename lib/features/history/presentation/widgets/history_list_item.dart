import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/rate_formatter.dart';
import '../../data/models/history_entry.dart';
import '../providers/history_provider.dart';

/// A single history entry shown in the list.
class HistoryListItem extends ConsumerWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;

  const HistoryListItem({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gstColors = theme.gstColors;

    final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final timeStr = DateFormatter.dateTime(date);
    // Displayed values reconcile: base + gst == total, matching the policy
    // used by the calculator result card, so the GST line always equals the
    // visible CGST + SGST + IGST sum.
    final breakdown = Money.reconcile(
      base: entry.baseAmount,
      cgst: entry.cgst,
      sgst: entry.sgst,
      igst: entry.igst,
      total: entry.totalAmount,
      isIntraState: entry.isIntraState,
    );
    final accent =
        entry.isInclusive ? gstColors.totalColor : theme.colorScheme.primary;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Remove this calculation from history?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (_) {
        ref.read(historyProvider.notifier).deleteEntry(entry.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.gstColors.cardBackground,
          // Same radius as the result card and settings cards so every
          // surface in the app shares one card language.
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Mode icon.
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      entry.isInclusive
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                      color: accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Content.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${entry.amountText} @ ${formatRate(entry.rate)}%',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total ${CurrencyFormatter.format(breakdown.total)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'GST ${CurrencyFormatter.format(breakdown.gst)} • $timeStr • '
                          '${entry.isIntraState ? "Intra-State" : "Inter-State"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
