import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';

class FlutterTtsService implements TtsService {
  FlutterTtsService() : _tts = FlutterTts() {
    _tts.setCompletionHandler(() => _onComplete?.call());
    _tts.setErrorHandler((message) => _onError?.call(message));
    _tts.setProgressHandler((text, start, end, word) {
      _onProgress?.call(text, start, end, word);
    });
  }

  final FlutterTts _tts;

  TtsProgressCallback? _onProgress;
  void Function()? _onComplete;
  void Function(String message)? _onError;

  @override
  Future<List<String>> getLanguages() async {
    final langs = await _tts.getLanguages;
    if (langs is List) {
      return langs.map((e) => e.toString()).toList()..sort();
    }
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getVoices() async {
    final voices = await _tts.getVoices;
    if (voices is List) {
      return voices
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    return const [];
  }

  @override
  Future<void> setLanguage(String language) async {
    if (language.trim().isEmpty) return;
    await _tts.setLanguage(language);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    final normalized = (rate / 3.0).clamp(0.0, 1.0);
    await _tts.setSpeechRate(normalized);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
  }

  @override
  Future<void> setVoiceByName(String voiceName) async {
    if (voiceName.trim().isEmpty) return;
    final voices = await getVoices();
    final match = voices.firstWhere(
      (v) => (v['name'] ?? v['Name'] ?? '').toString() == voiceName,
      orElse: () => const {},
    );
    if (match.isEmpty) return;

    final name = (match['name'] ?? match['Name'] ?? '').toString();
    final locale = (match['locale'] ?? match['Locale'] ?? '').toString();
    if (name.isEmpty) return;
    final payload =
        locale.isNotEmpty ? <String, String>{'name': name, 'locale': locale} : <String, String>{'name': name};
    await _tts.setVoice(payload);
  }

  @override
  void setCompletionHandler(void Function()? handler) {
    _onComplete = handler;
  }

  @override
  void setErrorHandler(void Function(String message)? handler) {
    _onError = handler;
  }

  @override
  void setProgressHandler(TtsProgressCallback? handler) {
    _onProgress = handler;
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
