import 'package:flutter/widgets.dart';

/// Turns an app language code (`es`, `pt_BR`, `zh_Hans`) into a [Locale].
Locale localeForCode(String code) {
  switch (code) {
    case 'pt_BR':
      return const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR');
    case 'zh_Hans':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    default:
      return Locale(code);
  }
}
