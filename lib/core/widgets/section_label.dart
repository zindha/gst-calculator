import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// A quiet uppercase eyebrow used above each calculator section
/// (AMOUNT, CALCULATION, GST RATE).
///
/// One shared primitive keeps every section label on the same size, weight,
/// tracking and colour — hierarchy comes from spacing, not decoration.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.gstColors.labelColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }
}
