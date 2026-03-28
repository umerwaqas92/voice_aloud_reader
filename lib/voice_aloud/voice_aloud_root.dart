import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'views/splash_view.dart';
import 'views/onboarding_view.dart';
import 'voice_aloud_mockup_page.dart';
import 'widgets/animated_page_entrance.dart';

class VoiceAloudRoot extends ConsumerWidget {
  const VoiceAloudRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);

    final child = init.when(
      data: (_) {
        final settings = ref.watch(settingsControllerProvider).valueOrNull;
        if (settings == null) {
          return const SplashView(key: ValueKey('splash'));
        }
        if (!settings.onboardingCompleted) {
          return const OnboardingView(key: ValueKey('onboarding'));
        }
        return const VoiceAloudAppPage(key: ValueKey('app'));
      },
      loading: () => const SplashView(key: ValueKey('loading')),
      error:
          (e, _) => _InitErrorView(
            key: const ValueKey('error'),
            message: e.toString(),
            onRetry: () => ref.invalidate(appInitProvider),
          ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder:
          (child, animation) => FadeTransition(opacity: animation, child: child),
      child: AnimatedPageEntrance(
        key: ValueKey(child.key),
        offsetY: 16,
        child: child,
      ),
    );
  }
}

class _InitErrorView extends StatelessWidget {
  const _InitErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to start',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
