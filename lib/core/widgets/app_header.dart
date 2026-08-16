import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The application's standard screen header.
///
/// Replaces the default [AppBar] so every tab screen shares one intentional
/// composition: an optional brand mark, a strong title, and a compact action
/// row — all vertically aligned on one baseline.
class AppHeader extends StatelessWidget {
  /// Screen title.
  final String title;

  /// Optional leading widget (e.g. the calculator's brand mark).
  final Widget? leading;

  /// Trailing action widgets (icon buttons).
  final List<Widget> actions;

  /// When true the title is rendered larger as the app-level display title
  /// (clean sans-serif — hierarchy comes from weight, not a serif face).
  final bool display;

  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.display = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.md, 6),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    display
                        ? const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        )
                        : theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// The calculator's brand mark — a rounded ₹ tile that anchors the header.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        Icons.currency_rupee_rounded,
        size: 22,
        color: colorScheme.onPrimary,
      ),
    );
  }
}
