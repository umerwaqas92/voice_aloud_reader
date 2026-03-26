import 'dart:ui';

import 'package:flutter/material.dart';

class BlurPanel extends StatelessWidget {
  const BlurPanel({
    super.key,
    required this.borderRadius,
    required this.child,
    this.sigma = 18,
    this.color = const Color(0xE6FFFFFF),
    this.border,
    this.boxShadow,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final double sigma;
  final Color color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: border,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
