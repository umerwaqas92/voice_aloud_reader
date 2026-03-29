// Maps TTS locale codes (from flutter_tts / OS) to readable labels.
// Stored settings still use the raw code — only UI text changes.

const Map<String, String> _languagePart = {
  'ar': 'Arabic',
  'bg': 'Bulgarian',
  'bn': 'Bengali',
  'ca': 'Catalan',
  'cs': 'Czech',
  'da': 'Danish',
  'de': 'German',
  'el': 'Greek',
  'en': 'English',
  'es': 'Spanish',
  'et': 'Estonian',
  'fi': 'Finnish',
  'fr': 'French',
  'gu': 'Gujarati',
  'he': 'Hebrew',
  'hi': 'Hindi',
  'hr': 'Croatian',
  'hu': 'Hungarian',
  'id': 'Indonesian',
  'it': 'Italian',
  'ja': 'Japanese',
  'kn': 'Kannada',
  'ko': 'Korean',
  'lt': 'Lithuanian',
  'lv': 'Latvian',
  'ml': 'Malayalam',
  'mr': 'Marathi',
  'ms': 'Malay',
  'nb': 'Norwegian Bokmål',
  'nl': 'Dutch',
  'no': 'Norwegian',
  'pl': 'Polish',
  'pt': 'Portuguese',
  'ro': 'Romanian',
  'ru': 'Russian',
  'sk': 'Slovak',
  'sl': 'Slovenian',
  'sv': 'Swedish',
  'ta': 'Tamil',
  'te': 'Telugu',
  'th': 'Thai',
  'tr': 'Turkish',
  'uk': 'Ukrainian',
  'ur': 'Urdu',
  'vi': 'Vietnamese',
  'zh': 'Chinese',
};

const Map<String, String> _regionPart = {
  'AE': 'United Arab Emirates',
  'AR': 'Argentina',
  'AT': 'Austria',
  'AU': 'Australia',
  'BE': 'Belgium',
  'BG': 'Bulgaria',
  'BH': 'Bahrain',
  'BR': 'Brazil',
  'BY': 'Belarus',
  'CA': 'Canada',
  'CH': 'Switzerland',
  'CL': 'Chile',
  'CN': 'China',
  'CO': 'Colombia',
  'CR': 'Costa Rica',
  'CZ': 'Czechia',
  'DE': 'Germany',
  'DK': 'Denmark',
  'DO': 'Dominican Republic',
  'EG': 'Egypt',
  'ES': 'Spain',
  'FI': 'Finland',
  'FR': 'France',
  'GB': 'United Kingdom',
  'GR': 'Greece',
  'GT': 'Guatemala',
  'HK': 'Hong Kong',
  'HN': 'Honduras',
  'HR': 'Croatia',
  'HU': 'Hungary',
  'ID': 'Indonesia',
  'IE': 'Ireland',
  'IL': 'Israel',
  'IN': 'India',
  'IQ': 'Iraq',
  'IR': 'Iran',
  'IT': 'Italy',
  'JO': 'Jordan',
  'JP': 'Japan',
  'KR': 'South Korea',
  'KW': 'Kuwait',
  'LB': 'Lebanon',
  'LT': 'Lithuania',
  'LU': 'Luxembourg',
  'LV': 'Latvia',
  'MA': 'Morocco',
  'MX': 'Mexico',
  'MY': 'Malaysia',
  'NI': 'Nicaragua',
  'NL': 'Netherlands',
  'NO': 'Norway',
  'NZ': 'New Zealand',
  'OM': 'Oman',
  'PA': 'Panama',
  'PE': 'Peru',
  'PH': 'Philippines',
  'PL': 'Poland',
  'PR': 'Puerto Rico',
  'PT': 'Portugal',
  'PY': 'Paraguay',
  'QA': 'Qatar',
  'RO': 'Romania',
  'RS': 'Serbia',
  'RU': 'Russia',
  'SA': 'Saudi Arabia',
  'SE': 'Sweden',
  'SG': 'Singapore',
  'SI': 'Slovenia',
  'SK': 'Slovakia',
  'SV': 'El Salvador',
  'SY': 'Syria',
  'TH': 'Thailand',
  'TN': 'Tunisia',
  'TR': 'Türkiye',
  'TW': 'Taiwan',
  'UA': 'Ukraine',
  'US': 'United States',
  'UY': 'Uruguay',
  'VE': 'Venezuela',
  'VN': 'Vietnam',
  'ZA': 'South Africa',
};

/// Normalizes Android-style `en_US` to `en-US` for comparisons.
String normalizeTtsLocaleCode(String code) =>
    code.trim().replaceAll('_', '-');

/// Human-readable name for a TTS language/locale code.
String ttsLanguageDisplayName(String code) {
  final normalized = normalizeTtsLocaleCode(code);
  if (normalized.isEmpty) return code;

  final parts = normalized.split(RegExp(r'[-_]')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return code;

  // Script/variant: zh-Hans-CN → language zh, region often last 2-letter uppercase
  String lang = parts.first.toLowerCase();
  if (lang == 'zh' && parts.length >= 2) {
    final scriptOrRegion = parts[1].toUpperCase();
    if (scriptOrRegion == 'HANS') {
      final region = parts.length >= 3 ? parts[2].toUpperCase() : 'CN';
      final regionName = _regionPart[region] ?? region;
      return 'Chinese Simplified ($regionName)';
    }
    if (scriptOrRegion == 'HANT') {
      final region = parts.length >= 3 ? parts[2].toUpperCase() : 'TW';
      final regionName = _regionPart[region] ?? region;
      return 'Chinese Traditional ($regionName)';
    }
  }

  final langName = _languagePart[lang] ?? lang.toUpperCase();
  if (parts.length == 1) return langName;

  // Region is typically the last 2-letter ISO code
  String? regionCode;
  for (var i = parts.length - 1; i >= 1; i--) {
    final p = parts[i].toUpperCase();
    if (p.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(p)) {
      regionCode = p;
      break;
    }
  }

  if (regionCode == null) {
    return '$langName (${parts.sublist(1).join('-')})';
  }

  final regionName = _regionPart[regionCode] ?? regionCode;
  return '$langName ($regionName)';
}
