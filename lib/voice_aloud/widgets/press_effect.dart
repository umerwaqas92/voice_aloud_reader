import 'package:flutter/material.dart';

class PressEffect extends StatefulWidget {
  const PressEffect({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
