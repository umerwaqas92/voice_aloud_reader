import 'tts_service.dart';

class FakeTtsService implements TtsService {
  TtsProgressCallback? _progress;
  void Function()? _complete;

  @override
  Future<List<String>> getLanguages() async => const ['en-US'];

  @override
  Future<List<Map<String, dynamic>>> getVoices() async =>
      const [
        {'name': 'Samantha', 'locale': 'en-US'},
      ];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVoiceByName(String voiceName, {String voiceLocale = ''}) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  void setCompletionHandler(void Function()? handler) {
    _complete = handler;
  }

  @override
  void setErrorHandler(void Function(String message)? handler) {
  }

  @override
  void setProgressHandler(TtsProgressCallback? handler) {
    _progress = handler;
  }

  @override
  Future<void> speak(String text) async {
    _progress?.call(text, 0, text.length, '');
    _complete?.call();
  }

  @override
  Future<void> stop() async {}
}
