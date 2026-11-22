/// The eleven interface and reader languages. Codes match the ARB file names
/// (`app_pt_BR.arb`, `app_zh_Hans.arb`).
abstract final class LanguageCodes {
  static const List<String> all = <String>[
    'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
  ];

  static const Set<String> rightToLeft = <String>{'ar', 'he'};

  static bool isSupported(String code) => all.contains(code);

  /// The supported code for a device language, or null if there is none.
  /// Portuguese maps to Brazilian Portuguese, every Chinese variant maps to
  /// Simplified Chinese (the only Chinese text shipped), and the old Android
  /// code `iw` maps to Hebrew.
  static String? match(String languageCode) {
    final String lang = languageCode.toLowerCase();
    switch (lang) {
      case 'pt':
        return 'pt_BR';
      case 'zh':
        return 'zh_Hans';
      case 'iw':
        return 'he';
      default:
        return isSupported(lang) ? lang : null;
    }
  }

  /// The interface language for a device whose preferred languages are
  /// [deviceLanguages] (most preferred first): the first one supported, else
  /// English.
  static String resolve(Iterable<String> deviceLanguages) {
    for (final String lang in deviceLanguages) {
      final String? code = match(lang);
      if (code != null) {
        return code;
      }
    }
    return 'en';
  }
}
