import 'package:flutter/material.dart';

/// Centers [child] and constrains it to a readable maximum width so
/// full-width screens don't stretch edge-to-edge on tablets and desktop.
class MaxWidthWrapper extends StatelessWidget {
  /// The content to constrain.
  final Widget child;

  /// Maximum content width in logical pixels.
  final double maxWidth;

  const MaxWidthWrapper({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
