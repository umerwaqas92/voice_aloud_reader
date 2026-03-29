import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_aloud_settings.dart';
import '../state/providers.dart';
import '../va_tokens.dart';

Future<void> showVoicePickerSheet(BuildContext context, WidgetRef ref) async {
  final settings =
      ref.read(settingsControllerProvider).valueOrNull ??
      VoiceAloudSettings.defaults;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: VAColors.panel,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => VoicePickerSheet(language: settings.language),
  );
}

class VoicePickerSheet extends ConsumerWidget {
  const VoicePickerSheet({super.key, required this.language});

  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voicesAsync = ref.watch(availableVoicesProvider);
    final settings =
        ref.watch(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;
    final applying = ref.watch(applyingVoiceNameProvider);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: voicesAsync.when(
          data: (voices) {
            final filtered =
                language.trim().isEmpty
                    ? voices
                    : voices.where((v) {
                      final locale =
                          (v['locale'] ?? v['Locale'] ?? '').toString();
                      return locale.startsWith(language);
                    }).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text('No voices found'));
            }

            String nameOf(Map<String, dynamic> v) =>
                (v['name'] ?? v['Name'] ?? '').toString().trim();

            final names =
                filtered
                    .map(nameOf)
                    .where((n) => n.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            return ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) {
                final name = names[index];
                final selected = name == settings.voiceName;
                final isApplying = applying == name;
                return ListTile(
                  title: Text(name, style: TextStyle(color: VAColors.cream)),
                  trailing:
                      isApplying
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(VAColors.gold),
                            ),
                            const SizedBox(width: 8),
                            LucideSvgIcon(
                              'waves',
                              size: 18,
                              color: VAColors.gold,
                            ),
                          )
                        : selected
                            ? Icon(Icons.check, color: VAColors.gold)
                            : null,
                  onTap: () async {
                    if (ref.read(applyingVoiceNameProvider.notifier).state !=
                        null) {
                      return;
                    }
                    ref.read(applyingVoiceNameProvider.notifier).state = name;
                    try {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setVoiceName(name);
                      await ref
                          .read(playbackControllerProvider.notifier)
                          .applyVoiceAndResume();
                      if (context.mounted) Navigator.of(context).pop();
                    } finally {
                      ref.read(applyingVoiceNameProvider.notifier).state = null;
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
