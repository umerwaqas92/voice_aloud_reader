import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_aloud_settings.dart';
import 'dependencies.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, VoiceAloudSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<VoiceAloudSettings> {
  @override
  Future<VoiceAloudSettings> build() async {
    await ref.watch(appInitProvider.future);
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load();
  }

  Future<void> _update(VoiceAloudSettings Function(VoiceAloudSettings) next) async {
    final current = state.valueOrNull ?? VoiceAloudSettings.defaults;
    final updated = next(current);
    state = AsyncData(updated);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(updated);
  }

  Future<void> setSpeechRate(double rate) async {
    await _update((s) => s.copyWith(speechRate: rate.clamp(0.5, 3.0)));
  }

  Future<void> setPitch(double pitch) async {
    await _update((s) => s.copyWith(pitch: pitch.clamp(0.0, 1.0)));
  }

  Future<void> setVolume(double volume) async {
    await _update((s) => s.copyWith(volume: volume.clamp(0.0, 1.0)));
  }

  Future<void> setFontSize(double fontSize) async {
    await _update((s) => s.copyWith(fontSize: fontSize.clamp(14.0, 30.0)));
  }

  Future<void> setThemeMode(ReaderThemeMode mode) async {
    await _update((s) => s.copyWith(themeMode: mode));
  }

  Future<void> toggleHighlight(bool enabled) async {
    await _update((s) => s.copyWith(highlightSpokenText: enabled));
  }

  Future<void> toggleAutoScroll(bool enabled) async {
    await _update((s) => s.copyWith(autoScroll: enabled));
  }

  Future<void> toggleKeepScreenOn(bool enabled) async {
    await _update((s) => s.copyWith(keepScreenOn: enabled));
  }

  Future<void> setLanguage(String language) async {
    await _update((s) => s.copyWith(language: language));
  }

  Future<void> setVoiceName(String voiceName, {String voiceLocale = ''}) async {
    await _update(
      (s) => s.copyWith(
        voiceName: voiceName,
        voiceLocale: voiceName.trim().isEmpty ? '' : voiceLocale,
      ),
    );
  }

  Future<void> save(VoiceAloudSettings settings) async {
    state = AsyncData(settings);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(settings);
  }

  Future<void> completeOnboarding() async {
    await _update((s) => s.copyWith(onboardingCompleted: true));
  }
}
