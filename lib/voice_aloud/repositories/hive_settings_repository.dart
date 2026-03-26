import 'package:hive/hive.dart';

import '../models/voice_aloud_settings.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository({this.boxName = 'prefs', this.settingsKey = 'settings'});

  final String boxName;
  final String settingsKey;

  Box<Map<dynamic, dynamic>> _box() => Hive.box<Map<dynamic, dynamic>>(boxName);

  @override
  Future<VoiceAloudSettings> load() async {
    final raw = _box().get(settingsKey);
    if (raw == null) return VoiceAloudSettings.defaults;
    return VoiceAloudSettings.fromJson(raw);
  }

  @override
  Future<void> save(VoiceAloudSettings settings) async {
    await _box().put(settingsKey, settings.toJson());
  }
}

