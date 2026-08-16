import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/color_presets.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    // Primary content is dark charcoal in light mode / near-white in dark —
    // the brand navy stays an accent, never the title colour.
    final titleColor = isDark
        ? BrandColors.textPrimaryDark
        : BrandColors.textPrimaryLight;

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
                        // Display titles are extra bold (variable-font wght
                        // 800) with tight tracking so the wordmark carries
                        // the same strong, confident weight as the icon.
                        ? TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: titleColor,
                          fontVariations: const [FontVariation('wght', 800)],
                        )
                        : theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: titleColor,
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

/// The calculator's brand mark — the actual app launcher icon rendered as a
/// small rounded tile that anchors the header (instead of a generic glyph).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Navy base matches the icon artwork's own background, so the PNG's
        // transparent corners blend into one clean rounded tile.
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Image.asset(
        'app-icon.png',
        fit: BoxFit.cover,
        semanticLabel: 'GST Calculator app icon',
      ),
    );
  }
}
