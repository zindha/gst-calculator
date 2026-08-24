import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring-based animation presets for natural, physics-driven motion.
///
/// Springs replace easeOutCubic throughout the app so interactive elements
/// feel alive — they overshoot slightly and settle, mimicking real-world
/// momentum instead of mathematical curves. Every animation driven by these
/// springs uses a real [SpringSimulation] on every frame, not a baked curve.
abstract final class AppSpring {
  AppSpring._();

  /// Gentle spring for press feedback (chip scale, button press).
  /// Low stiffness, moderate damping — a soft "bouncette".
  static const SpringDescription gentle = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 18,
  );

  /// Medium spring for content transitions (result card fade+slide).
  /// Snappier than gentle, minimal overshoot.
  static const SpringDescription medium = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 22,
  );

  /// Fast spring for micro-interactions (underline slide, icon swap).
  /// Nearly critical damping — moves quickly, settles instantly.
  static const SpringDescription fast = SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 26,
  );

  /// Stiff spring for error shake feedback.
  /// High stiffness, low damping — sharp rebound that decays quickly.
  static const SpringDescription shake = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 12,
  );
}

/// Extension on [SpringDescription] to create simulations with defaults.
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

/// A widget that animates its child with a true spring simulation on build.
///
/// Wraps the child in a fade + slight upward slide that springs into place,
/// giving staggered entrance animations a natural feel. The spring is driven
/// by a real [SpringSimulation] on every frame — not a baked curve.
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Duration is a safety cap; the spring simulation settles on its own.
      duration: const Duration(milliseconds: 800),
    );

    if (widget.reduceMotion) {
      _controller.value = 1.0;
    } else {
      // Stagger: each child waits `index * delay` before springing in.
      Future.delayed(widget.delay * widget.index, () {
        if (mounted) {
          // Drive with a real spring: starts at 0, springs to 1 with
          // zero initial velocity. The spring overshoots slightly and
          // settles — no baked curve, just physics.
          final simulation = AppSpring.medium.toSimulation(
            from: 0,
            to: 1,
            velocity: 0,
          );
          _controller.animateWith(simulation);
        }
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
    // The controller value is driven by the spring simulation (0→1 with
    // overshoot). We map it directly to opacity and slide offset.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A spring-driven scale animation for interactive elements.
///
/// Wraps a child and applies a spring-physics scale on press/release.
/// The spring overshoots slightly on press and settles with momentum
/// on release — no baked curves, just real [SpringSimulation] on every frame.
class SpringScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool pressed;
  final VoidCallback? onTap;

  const SpringScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    required this.pressed,
    this.onTap,
  });

  @override
  State<SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<SpringScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(SpringScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pressed != oldWidget.pressed) {
      final newTarget = widget.pressed ? widget.pressedScale : 1.0;
      final sim = AppSpring.gentle.toSimulation(
        from: _controller.value,
        to: newTarget,
        velocity: _controller.velocity,
      );
      _controller.animateWith(sim);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
