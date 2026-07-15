import 'package:flutter/material.dart';

/// Common animation durations used across the app.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration entrance = Duration(milliseconds: 600);
  static const Duration stagger = Duration(milliseconds: 80);
}

/// Common animation curves.
class AppCurves {
  AppCurves._();
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve bounce = Curves.easeOutBack;
}

/// A widget that fades + slides in from bottom when first built.
/// Use [delay] to create staggered entrance effects.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 24.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Wraps a child with a scale-down-on-press micro-interaction.
class ScaleOnTap extends StatefulWidget {
  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Animated counter that tweens between old and new numeric values.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (_, v, __) => Text(
        v.toInt().toString(),
        style: style,
      ),
    );
  }
}

/// Subtle pulsing glow animation for icon backgrounds.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00D4AA),
    this.minRadius = 0.0,
    this.maxRadius = 8.0,
  });

  final Widget child;
  final Color glowColor;
  final double minRadius;
  final double maxRadius;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final radius = widget.minRadius + (t * (widget.maxRadius - widget.minRadius));
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.3 * t),
                blurRadius: radius,
                spreadRadius: radius * 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
