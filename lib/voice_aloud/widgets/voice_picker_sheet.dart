import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_aloud_settings.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/lucide_svg_icon.dart';

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

String _nameOf(Map<String, dynamic> v) =>
    (v['name'] ?? v['Name'] ?? '').toString().trim();

String _localeOf(Map<String, dynamic> v) =>
    (v['locale'] ?? v['Locale'] ?? '').toString();
String _normLocale(String v) => v.trim().replaceAll('_', '-').toLowerCase();
String _langCode(String v) {
  final n = _normLocale(v);
  if (n.isEmpty) return '';
  final i = n.indexOf('-');
  return i == -1 ? n : n.substring(0, i);
}

String _voiceKey(Map<String, dynamic> v) => '${_nameOf(v)}|${_localeOf(v)}';

String _genderOf(Map<String, dynamic> v) =>
    (v['gender'] ?? v['Gender'] ?? '').toString().toLowerCase();

IconData _genderIcon(Map<String, dynamic> v) {
  final g = _genderOf(v);
  if (g.contains('female') || g == 'f' || g == 'woman') {
    return Icons.female;
  }
  if (g.contains('male') || g == 'm' || g == 'man') {
    return Icons.male;
  }
  return Icons.person_outline;
}

bool _rowSelected(
  Map<String, dynamic> v,
  List<Map<String, dynamic>> filtered,
  VoiceAloudSettings settings,
) {
  final n = _nameOf(v);
  final loc = _localeOf(v);
  if (n != settings.voiceName) return false;
  if (settings.voiceLocale.isNotEmpty) {
    return _normLocale(loc) == _normLocale(settings.voiceLocale);
  }
  final sameNameCount = filtered.where((x) => _nameOf(x) == n).length;
  return sameNameCount == 1;
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
    final applying = ref.watch(applyingVoiceKeyProvider);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: voicesAsync.when(
          data: (voices) {
            final filtered =
                language.trim().isEmpty
                    ? List<Map<String, dynamic>>.from(voices)
                    : voices.where((v) {
                      final locale = _localeOf(v);
                      final target = _normLocale(language);
                      final localeNorm = _normLocale(locale);
                      return localeNorm.startsWith(target) ||
                          _langCode(localeNorm) == _langCode(target);
                    }).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text('No voices found'));
            }

            filtered.sort((a, b) {
              final byName = _nameOf(a).compareTo(_nameOf(b));
              if (byName != 0) return byName;
              return _localeOf(a).compareTo(_localeOf(b));
            });

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final v = filtered[index];
                final name = _nameOf(v);
                final locale = _localeOf(v);
                final key = _voiceKey(v);
                if (name.isEmpty) return const SizedBox.shrink();

                final selected = _rowSelected(v, filtered, settings);
                final isApplying = applying == key;

                return ListTile(
                  leading: Icon(_genderIcon(v), color: VAColors.muted),
                  title: Text(name, style: TextStyle(color: VAColors.cream)),
                  subtitle:
                      locale.isNotEmpty
                          ? Text(
                            locale,
                            style: TextStyle(
                              color: VAColors.muted,
                              fontSize: 12,
                            ),
                          )
                          : null,
                  trailing:
                      isApplying
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    VAColors.gold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              LucideSvgIcon(
                                'volume-2',
                                size: 18,
                                color: VAColors.gold,
                              ),
                            ],
                          )
                          : selected
                          ? Icon(Icons.check, color: VAColors.gold)
                          : null,
                  onTap: () async {
                    if (ref.read(applyingSettingsProvider)) {
                      return;
                    }
                    ref.read(applyingVoiceKeyProvider.notifier).state = key;
                    ref.read(applyingSettingsProvider.notifier).state = true;
                    try {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setVoiceName(name, voiceLocale: locale);
                      await ref
                          .read(playbackControllerProvider.notifier)
                          .applySettingsAndResume();
                      if (context.mounted) Navigator.of(context).pop();
                    } finally {
                      ref.read(applyingVoiceKeyProvider.notifier).state = null;
                      ref.read(applyingSettingsProvider.notifier).state = false;
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
