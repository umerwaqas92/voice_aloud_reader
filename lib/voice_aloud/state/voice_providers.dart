import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependencies.dart';

/// Caches the available TTS voices for the session so the picker opens instantly
/// after the first load.
final availableVoicesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final tts = ref.watch(ttsServiceProvider);
  return tts.getVoices();
});

/// Tracks `"name|locale"` while applying a voice (inline spinner, no double-tap).
final applyingVoiceKeyProvider = StateProvider<String?>((ref) => null);

/// Tracks when voice/language settings are being applied (loading state for UI).
final applyingSettingsProvider = StateProvider<bool>((ref) => false);
