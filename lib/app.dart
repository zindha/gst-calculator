import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/accessibility_helper.dart';
import 'core/utils/deep_link_handler.dart';
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

class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  DeepLinkParams? _deepLink;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDeepLink();
  }

  Future<void> _loadDeepLink() async {
    final params = await DeepLinkHandler.parseInitial();
    if (mounted) {
      setState(() {
        _deepLink = params;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!settings.onboardingDone) return const OnboardingScreen();
    if (!_loaded) return const SizedBox.shrink();

    return _MainShell(
      initialAmount: _deepLink?.amount,
      initialRate: _deepLink?.rate,
    );
  }
}

/// Bottom-navigation shell with 3 tabs.
class _MainShell extends ConsumerStatefulWidget {
  final double? initialAmount;
  final double? initialRate;

  const _MainShell({
    this.initialAmount,
    this.initialRate,
  });

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _selectedIndex = 0;

  static const _tabs = <_NavTab>[
    _NavTab(
      label: 'Calculate',
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate_rounded,
    ),
    _NavTab(
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _NavTab(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  // Screens are built in build() to pass deep link params.
  Widget _buildCalculatorScreen() => GstCalculatorScreen(
    initialAmount: widget.initialAmount,
    initialRate: widget.initialRate,
  );

  Widget _buildHistoryScreen() => const HistoryScreen();

  Widget _buildSettingsScreen() => const SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildCalculatorScreen(),
          _buildHistoryScreen(),
          _buildSettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
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

class _NavTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// A flat bottom navigation bar.
///
/// Deliberately quiet: no floating dock, no shadow, no pill indicator. A
/// single hairline divider separates it from the page, and the selected
/// destination is marked by a filled icon, the brand colour and a bolder
/// label — never a container. Every destination keeps a stable icon + label
/// column so nothing shifts on selection.
class _BottomNavBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BottomNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        // The bar is the page itself, not a floating surface: same background
        // as the screens, with only a hairline to mark the boundary.
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
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
                        Icon(
                          selected ? tab.selectedIcon : tab.icon,
                          size: 20,
                          color:
                              selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 2),
                        // Scale the label down (never up, never clipped) when
                        // large system fonts would overflow the fixed-height
                        // bar. Single-word labels cannot wrap, so this is the
                        // smallest guard that keeps them fully visible at every
                        // text scale.
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
                              fontSize: 10.5,
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
