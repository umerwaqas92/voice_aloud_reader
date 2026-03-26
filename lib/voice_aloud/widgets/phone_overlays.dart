import 'package:flutter/material.dart';

import '../va_tokens.dart';

class FakeIosStatusBar extends StatelessWidget {
  const FakeIosStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 28,
        child: Padding(
          padding: const EdgeInsets.only(left: 28, right: 28, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:41',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),
              const _BatteryStub(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatteryStub extends StatelessWidget {
  const _BatteryStub();

  @override
  Widget build(BuildContext context) {
    final batteryColor = Colors.black.withValues(alpha: 0.8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 10,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: batteryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                right: -3,
                top: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: batteryColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2),
                    ),
                  ),
                  child: const SizedBox(width: 2, height: 6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FakeDynamicIsland extends StatelessWidget {
  const FakeDynamicIsland({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 128,
          height: 24,
          decoration: BoxDecoration(
            color: VAColors.gray900,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
