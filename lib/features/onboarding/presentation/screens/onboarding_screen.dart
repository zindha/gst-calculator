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

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// The onboarding slides shown on first launch.
const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    icon: LucideIcons.calculator,
    title: 'Quick GST Calculations',
    description:
        'Calculate GST instantly with live updates. Switch between Exclusive (+GST) and Inclusive (-GST) modes.',
  ),
  _OnboardingSlide(
    icon: LucideIcons.arrowLeftRight,
    title: 'Reverse GST & History',
    description:
        'Reverse-calculate the base price from a gross total. Every calculation is saved to your history automatically.',
  ),
  _OnboardingSlide(
    icon: LucideIcons.palette,
    title: 'Settings & Themes',
    description:
        'Pick a theme and set your default rate, tax type, and transaction type.',
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
                    // Content stays centered when there is room, but scrolls
                    // instead of overflowing on short screens or at large
                    // system font scales.
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
                                  // A quiet icon accent — no tinted circle, no
                                  // illustration. The text carries the slide.
                                  Icon(slide.icon, size: 32, color: primary),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      height: 1.4,
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
