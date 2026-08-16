import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/accessibility_helper.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/max_width_wrapper.dart';
import '../../../calculator/presentation/providers/gst_calculator_notifier.dart';
import '../../../csv_export/csv_export.dart';
import '../../data/models/history_entry.dart';
import '../providers/history_provider.dart';
import '../widgets/history_list_item.dart';

/// Screen showing all past GST calculations.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'History',
              actions: [
                // State-aware actions: always visible, disabled (grayed out)
                // when there is nothing to export or clear, so the controls
                // never disappear and never act on empty data.
                A11y.iconButton(
                  icon: Icons.file_download_outlined,
                  label: 'Export as CSV',
                  onPressed:
                      entries.isEmpty
                          ? null
                          : () {
                            HapticFeedback.lightImpact();
                            CsvExport.shareHistoryCsv(entries);
                          },
                ),
                A11y.iconButton(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear all history',
                  onPressed:
                      entries.isEmpty
                          ? null
                          : () {
                            HapticFeedback.mediumImpact();
                            _confirmClearAll(context, ref);
                          },
                ),
              ],
            ),
            Expanded(
              child: Semantics(
                label:
                    entries.isEmpty
                        ? 'No history entries'
                        : '${entries.length} history entries',
                child:
                    entries.isEmpty
                        ? const EmptyState(
                          icon: Icons.history_rounded,
                          title: 'No calculations yet',
                          subtitle: 'Your saved calculations will appear here',
                        )
                        : MaxWidthWrapper(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return HistoryListItem(
                                entry: entry,
                                onTap:
                                    () =>
                                        _reloadCalculation(context, ref, entry),
                              );
                            },
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadCalculation(
    BuildContext context,
    WidgetRef ref,
    HistoryEntry entry,
  ) {
    HapticFeedback.selectionClick();
    ref.read(gstCalculatorProvider.notifier).loadFromHistory(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: 'Loaded calculation from history',
          child: Text('Loaded: ${entry.summary}'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear All History'),
            content: const Text(
              'This will permanently delete all saved calculations. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(historyProvider.notifier).clearAll();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );
  }
}
