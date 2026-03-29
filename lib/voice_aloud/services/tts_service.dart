typedef TtsProgressCallback =
    void Function(String text, int startOffset, int endOffset, String word);

abstract class TtsService {
  Future<void> setSpeechRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setVolume(double volume);
  Future<void> setLanguage(String language);
  Future<void> setVoiceByName(String voiceName, {String voiceLocale = ''});

  Future<List<String>> getLanguages();
  Future<List<Map<String, dynamic>>> getVoices();

  void setProgressHandler(TtsProgressCallback? handler);
  void setCompletionHandler(void Function()? handler);
  void setErrorHandler(void Function(String message)? handler);

  Future<void> speak(String text);
  Future<void> stop();
}

