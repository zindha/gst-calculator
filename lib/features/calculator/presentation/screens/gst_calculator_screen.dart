import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/accessibility_helper.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/max_width_wrapper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/gst_calculator_notifier.dart';
import '../widgets/amount_input_field.dart';
import '../widgets/calculation_mode_toggle.dart';
import '../widgets/gst_slab_selector.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/results_breakdown_card.dart';

/// The main GST Calculator screen.
///
/// Composition order: amount (hero) → calculation mode → GST rate → result →
/// quick actions. The body clamps text scaling at the platform maximum
/// (2.0×) purely to cap runaway scaling — accessibility scaling up to 2.0×
/// is supported. The `FittedBox`/`Flexible` layout guards below keep
/// display numerals and controls from overflowing at large font sizes.
class GstCalculatorScreen extends ConsumerStatefulWidget {
  const GstCalculatorScreen({super.key});

  @override
  ConsumerState<GstCalculatorScreen> createState() =>
      _GstCalculatorScreenState();
}

class _GstCalculatorScreenState extends ConsumerState<GstCalculatorScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAll() {
    A11y.impact();
    _amountController.clear();
    ref.read(gstCalculatorProvider.notifier).clearAll();
    _amountFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'GST Calculator',
              display: true,
              leading: const BrandMark(),
              actions: [
                // Theme switch — part of the app chrome, not an afterthought.
                // Both header icons share one size (22) so the moon and the
                // clear glyph read as the same icon family as the brand tile.
                Consumer(
                  builder: (context, ref, _) {
                    final themeMode = ref.watch(themeModeProvider);
                    return A11y.iconButton(
                      icon:
                          themeMode == ThemeMode.dark
                              ? LucideIcons.sun
                              : LucideIcons.moon,
                      label:
                          themeMode == ThemeMode.dark
                              ? 'Switch to light theme'
                              : 'Switch to dark theme',
                      iconSize: 22,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final newMode =
                            themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                        ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(newMode);
                      },
                    );
                  },
                ),
                // Clear all — resets amount, rate and mode to defaults.
                A11y.iconButton(
                  icon: LucideIcons.trash,
                  label: 'Clear all',
                  iconSize: 22,
                  onPressed: _clearAll,
                ),
              ],
            ),
            Expanded(
              child: MaxWidthWrapper(
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 2.0,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      2, // Minimal top gap — content starts close to header
                      AppSpacing.xl,
                      AppSpacing.xxxl,
                    ),
                    child: Semantics(
                      label: 'GST calculator input and results',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpringEntrance(
                            index: 0,
                            child: AmountInputField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          SpringEntrance(
                            index: 1,
                            child: const CalculationModeToggle(),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SpringEntrance(
                            index: 2,
                            child: const GstSlabSelector(),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          SpringEntrance(
                            index: 3,
                            child: const ResultsBreakdownCard(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SpringEntrance(
                            index: 4,
                            child: const QuickActionsBar(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
