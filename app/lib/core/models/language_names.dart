import 'package:tehillah/core/models/language_codes.dart';

/// Each language named in itself. These are never translated: a person who
/// cannot read the current language must still find their own.
abstract final class LanguageNames {
  static const Map<String, String> native = <String, String>{
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt_BR': 'Português (Brasil)',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'ja': '日本語',
    'ko': '한국어',
    'zh_Hans': '简体中文',
    'he': 'עברית',
  };

  /// The native name for [code], or the code itself when it is unknown.
  static String of(String code) => native[code] ?? code;

  /// Codes and native names in the app's fixed language order.
  static List<({String code, String name})> get all => <({String code, String name})>[
        for (final String code in LanguageCodes.all) (code: code, name: of(code)),
      ];
}
