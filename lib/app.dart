import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/color_presets.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/accessibility_helper.dart';
import 'features/calculator/presentation/screens/gst_calculator_screen.dart';
import 'features/history/presentation/screens/history_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

/// The root widget of the GST Calculator application.
class GSTCalculatorApp extends ConsumerWidget {
  const GSTCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'GST Calculator',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (!settings.onboardingDone) return const OnboardingScreen();
    return const _MainShell();
  }
}

/// Bottom-navigation shell with 3 tabs, styled as a floating ledger dock.
class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _selectedIndex = 0;

  static const _tabs = <_DockTab>[
    _DockTab(
      label: 'Calculate',
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate_rounded,
    ),
    _DockTab(
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _DockTab(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  static const _screens = <Widget>[
    GstCalculatorScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _LedgerDock(
        tabs: _tabs,
        selectedIndex: _selectedIndex,
        onSelected: (i) {
          A11y.tap();
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

class _DockTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _DockTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// A floating bottom navigation dock.
///
/// Every destination keeps a stable icon + label column (no layout jumps on
/// selection); the selected destination is marked with a tonal pill behind
/// the icon, a filled icon and a bold label — never color alone.
class _LedgerDock extends StatelessWidget {
  final List<_DockTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _LedgerDock({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? BrandColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  label: tab.label,
                  selected: selected,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with tonal pill behind it when selected.
                        AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          width: 42,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? colorScheme.primary.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    )
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            selected ? tab.selectedIcon : tab.icon,
                            size: 22,
                            color:
                                selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Scale the label down (never up, never clipped) when
                        // large system fonts would overflow the fixed-height
                        // dock. Single-word labels cannot wrap, so this is the
                        // smallest guard that keeps them fully visible at every
                        // text scale while leaving the 58px dock unchanged.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight:
                                  selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              fontSize: 11,
                              color:
                                  selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
