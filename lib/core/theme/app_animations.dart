import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring-based animation presets for natural, physics-driven motion.
///
/// Springs replace easeOutCubic throughout the app so interactive elements
/// feel alive — they overshoot slightly and settle, mimicking real-world
/// momentum instead of mathematical curves.
abstract final class AppSpring {
  AppSpring._();

  /// Gentle spring for press feedback (chip scale, button press).
  /// Low stiffness, moderate damping — a soft "bouncette".
  static final SpringDescription gentle = const SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 18,
  );

  /// Medium spring for content transitions (result card fade+slide).
  /// Snappier than gentle, minimal overshoot.
  static final SpringDescription medium = const SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 22,
  );

  /// Fast spring for micro-interactions (underline slide, icon swap).
  /// Nearly critical damping — moves quickly, settles instantly.
  static final SpringDescription fast = const SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 26,
  );
}

/// Creates a spring-driven [AnimationController] simulation.
///
/// Usage:
/// ```dart
/// final sim = AppSpring.gentle
///     .toSimulation(velocity: _gestureVelocity);
/// _controller.animateWith(sim);
/// ```
extension SpringExtension on SpringDescription {
  /// Converts this spring to a [Simulation] with the given endpoint and
  /// initial velocity. [from] defaults to 0, [to] defaults to 1.
  Simulation toSimulation({
    double from = 0,
    double to = 1,
    double velocity = 0,
  }) {
    return SpringSimulation(this, from, to, velocity);
  }
}

/// A widget that animates its child with a spring curve on build.
///
/// Wraps the child in a fade + slight upward slide that springs into place,
/// giving staggered entrance animations a natural feel.
class SpringEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final bool reduceMotion;

  const SpringEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 60),
    this.reduceMotion = false,
  });

  @override
  State<SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<SpringEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    if (widget.reduceMotion) {
      _controller.value = 1.0;
    } else {
      // Stagger: each child waits `index * delay` before springing in.
      Future.delayed(widget.index * widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
