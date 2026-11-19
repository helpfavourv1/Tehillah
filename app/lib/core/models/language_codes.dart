/// The eleven interface and reader languages. Codes match the ARB file names
/// (`app_pt_BR.arb`, `app_zh_Hans.arb`).
abstract final class LanguageCodes {
  static const List<String> all = <String>[
    'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
  ];

  static const Set<String> rightToLeft = <String>{'ar', 'he'};

  static bool isSupported(String code) => all.contains(code);
}
