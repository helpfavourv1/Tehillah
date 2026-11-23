import 'package:flutter/widgets.dart';

/// Languages written right to left among those the app can show.
const Set<String> _rtlLanguages = <String>{'ar', 'he', 'fa', 'ur'};

/// The reading direction of a language code such as `ar` or `pt_BR`. Verse
/// text keeps its own direction even when the interface language differs (a
/// Hebrew Bible read from an English interface).
TextDirection directionForLanguage(String languageCode) {
  final String base = languageCode.split(RegExp('[-_]')).first.toLowerCase();
  return _rtlLanguages.contains(base) ? TextDirection.rtl : TextDirection.ltr;
}
