import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/gst_rates.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/rate_formatter.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/max_width_wrapper.dart';
import '../../../calculator/domain/entities/gst_calculation_type.dart';
import '../../../calculator/domain/entities/gst_transaction_type.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../presentation/providers/settings_provider.dart';

/// Application settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final historyCount = ref.watch(historyProvider).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'Settings'),
            Expanded(
              child: MaxWidthWrapper(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    _SectionHeader(title: 'Theme', icon: Icons.palette_rounded),
                    _SettingsCard(
                      children: [
                        ListTile(
                          title: const Text('Appearance'),
                          subtitle: Text(_themeLabel(settings.themeMode)),
                          leading: const Icon(Icons.brightness_6_rounded),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showThemePicker(context, ref, settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _SectionHeader(title: 'Defaults', icon: Icons.tune_rounded),
                    _SettingsCard(
                      children: [
                        ListTile(
                          title: const Text('Default GST Rate'),
                          subtitle: Text('${formatRate(settings.defaultSlab)}%'),
                          leading: const Icon(Icons.percent_rounded),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showSlabPicker(context, ref, settings),
                        ),
                        const Divider(height: 1, indent: 72),
                        ListTile(
                          title: const Text('Default Tax Type'),
                          subtitle: Text(settings.defaultCalculationType.label),
                          leading: const Icon(Icons.calculate_rounded),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap:
                              () => _showCalcTypePicker(context, ref, settings),
                        ),
                        const Divider(height: 1, indent: 72),
                        ListTile(
                          title: const Text('Default Transaction'),
                          subtitle: Text(settings.defaultTransactionType.label),
                          leading: const Icon(Icons.location_city_rounded),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap:
                              () =>
                                  _showTransTypePicker(context, ref, settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _SectionHeader(title: 'Data', icon: Icons.storage_rounded),
                    _SettingsCard(
                      children: [
                        ListTile(
                          title: const Text('Clear Calculation History'),
                          subtitle: Text('$historyCount entries stored'),
                          leading: const Icon(Icons.delete_outline_rounded),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap:
                              historyCount > 0
                                  ? () => _confirmClearHistory(context, ref)
                                  : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    Center(
                      child: Text(
                        'GST Calculator v1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System Default',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  void _showThemePicker(BuildContext context, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                ...ThemeMode.values.map(
                  (mode) => ListTile(
                    leading: Icon(
                      mode == ThemeMode.system
                          ? Icons.brightness_auto_rounded
                          : mode == ThemeMode.light
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                    title: Text(_themeLabel(mode)),
                    trailing:
                        mode == settings.themeMode
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setThemeMode(mode);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _showSlabPicker(BuildContext context, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'Default GST Rate',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                ...GstRates.standardSlabs.map(
                  (slab) => ListTile(
                    title: Text('${formatRate(slab)}%'),
                    trailing:
                        slab == settings.defaultSlab
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setDefaultSlab(slab);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _showCalcTypePicker(BuildContext context, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'Default Tax Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                ...GstCalculationType.values.map(
                  (type) => ListTile(
                    title: Text(type.label),
                    trailing:
                        type == settings.defaultCalculationType
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setDefaultCalculationType(type);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _showTransTypePicker(BuildContext context, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'Default Transaction',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                ...GstTransactionType.values.map(
                  (type) => ListTile(
                    title: Text(type.label),
                    trailing:
                        type == settings.defaultTransactionType
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setDefaultTransactionType(type);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear History'),
            content: const Text(
              'Delete all saved calculations? This cannot be undone.',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A Material (not a decorated Container) so the ListTiles inside paint
    // their ink splashes on this surface instead of an invisible
    // intermediate DecoratedBox — same card look, correct ink behavior.
    return Material(
      color: theme.gstColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
