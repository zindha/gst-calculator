import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// A single onboarding slide definition.
class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

/// The onboarding slides shown on first launch.
const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    icon: LucideIcons.calculator,
    title: 'Instant GST Math',
    description:
        'Enter an amount, pick a rate, get the breakdown. Add or remove GST in one tap — the result updates as you type.',
    accentColor: Color(0xFF1565C0),
  ),
  _OnboardingSlide(
    icon: LucideIcons.arrowLeftRight,
    title: 'Reverse & Recall',
    description:
        'Got a gross total? Reverse-calculate the base price. Every calculation is saved — tap History to revisit any time.',
    accentColor: Color(0xFF2E7D32),
  ),
  _OnboardingSlide(
    icon: LucideIcons.palette,
    title: 'Your Way',
    description:
        'Set your default rate, tax type, and transaction. Switch between light and dark. The app adapts to how you work.',
    accentColor: Color(0xFF6A1B9A),
  ),
];

/// Full-screen onboarding shown only on the first app launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDone() {
    ref.read(settingsProvider.notifier).markOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final slideDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 300);
    final indicatorDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _onDone,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon inside a soft colored container —
                                  // gives each slide its own visual identity.
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: slide.accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      slide.icon,
                                      size: 32,
                                      color: slide.accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Page indicators + action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: indicatorDuration,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? primary
                                  : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          _currentPage < _slides.length - 1
                              ? () => _pageController.nextPage(
                                duration: slideDuration,
                                curve: Curves.easeOutCubic,
                              )
                              : _onDone,
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
