enum ReaderThemeMode { light, sepia, dark }

class VoiceAloudSettings {
  const VoiceAloudSettings({
    required this.speechRate,
    required this.pitch,
    required this.volume,
    required this.fontSize,
    required this.themeMode,
    required this.highlightSpokenText,
    required this.autoScroll,
    required this.keepScreenOn,
    required this.language,
    required this.voiceName,
  });

  final double speechRate;
  final double pitch;
  final double volume;
  final double fontSize;
  final ReaderThemeMode themeMode;
  final bool highlightSpokenText;
  final bool autoScroll;
  final bool keepScreenOn;
  final String language;
  final String voiceName;

  static const defaults = VoiceAloudSettings(
    speechRate: 1.5,
    pitch: 0.5,
    volume: 0.6,
    fontSize: 18,
    themeMode: ReaderThemeMode.light,
    highlightSpokenText: true,
    autoScroll: true,
    keepScreenOn: true,
    language: '',
    voiceName: '',
  );

  VoiceAloudSettings copyWith({
    double? speechRate,
    double? pitch,
    double? volume,
    double? fontSize,
    ReaderThemeMode? themeMode,
    bool? highlightSpokenText,
    bool? autoScroll,
    bool? keepScreenOn,
    String? language,
    String? voiceName,
  }) {
    return VoiceAloudSettings(
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      highlightSpokenText: highlightSpokenText ?? this.highlightSpokenText,
      autoScroll: autoScroll ?? this.autoScroll,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      language: language ?? this.language,
      voiceName: voiceName ?? this.voiceName,
    );
  }

  Map<String, dynamic> toJson() => {
    'speechRate': speechRate,
    'pitch': pitch,
    'volume': volume,
    'fontSize': fontSize,
    'themeMode': themeMode.name,
    'highlightSpokenText': highlightSpokenText,
    'autoScroll': autoScroll,
    'keepScreenOn': keepScreenOn,
    'language': language,
    'voiceName': voiceName,
  };

  static VoiceAloudSettings fromJson(Map<dynamic, dynamic> json) {
    double readDouble(String key, double fallback) {
      final v = json[key];
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '').toString()) ?? fallback;
    }

    bool readBool(String key, bool fallback) {
      final v = json[key];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    ReaderThemeMode parseTheme(String name) {
      return ReaderThemeMode.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ReaderThemeMode.light,
      );
    }

    return VoiceAloudSettings(
      speechRate: readDouble('speechRate', defaults.speechRate).clamp(0.5, 3.0),
      pitch: readDouble('pitch', defaults.pitch).clamp(0.0, 1.0),
      volume: readDouble('volume', defaults.volume).clamp(0.0, 1.0),
      fontSize: readDouble('fontSize', defaults.fontSize).clamp(14.0, 30.0),
      themeMode: parseTheme((json['themeMode'] ?? '').toString()),
      highlightSpokenText: readBool(
        'highlightSpokenText',
        defaults.highlightSpokenText,
      ),
      autoScroll: readBool('autoScroll', defaults.autoScroll),
      keepScreenOn: readBool('keepScreenOn', defaults.keepScreenOn),
      language: (json['language'] ?? '').toString(),
      voiceName: (json['voiceName'] ?? '').toString(),
    );
  }
}
