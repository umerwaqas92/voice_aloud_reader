import '../models/voice_aloud_settings.dart';

abstract class SettingsRepository {
  Future<VoiceAloudSettings> load();
  Future<void> save(VoiceAloudSettings settings);
}

class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository({VoiceAloudSettings? seed})
      : _settings = seed ?? VoiceAloudSettings.defaults;

  VoiceAloudSettings _settings;

  @override
  Future<VoiceAloudSettings> load() async => _settings;

  @override
  Future<void> save(VoiceAloudSettings settings) async {
    _settings = settings;
  }
}

