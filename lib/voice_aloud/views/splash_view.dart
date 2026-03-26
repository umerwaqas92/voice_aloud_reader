import 'package:flutter/material.dart';

import '../va_tokens.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VAColors.outerBackground,
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.8, end: 1.0),
          curve: Curves.easeOutCubic,
          builder:
              (context, value, child) =>
                  Transform.scale(scale: value, child: child),
          child: const Text(
            'Voxly',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

