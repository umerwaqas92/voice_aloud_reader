import 'package:flutter/material.dart';

class AnimatedPageEntrance extends StatelessWidget {
  const AnimatedPageEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 20,
  });

  final Widget child;
  final Duration duration;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, builtChild) {
        final opacity = value.clamp(0.0, 1.0);
        final dy = (1 - value) * offsetY;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, dy), child: builtChild),
        );
      },
    );
  }
}
