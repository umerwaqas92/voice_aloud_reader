import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'views/splash_view.dart';
import 'voice_aloud_mockup_page.dart';

class VoiceAloudRoot extends ConsumerWidget {
  const VoiceAloudRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);
    return init.when(
      data: (_) => const VoiceAloudAppPage(),
      loading: () => const SplashView(),
      error:
          (e, _) => _InitErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(appInitProvider),
          ),
    );
  }
}

class _InitErrorView extends StatelessWidget {
  const _InitErrorView({required this.message, required this.onRetry});

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

