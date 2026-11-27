import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/app/locale_codes.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/language_names.dart';

void main() {
  test('every app language has a native name and a locale', () {
    for (final String code in LanguageCodes.all) {
      expect(LanguageNames.of(code), isNot(code), reason: code);
      expect(localeForCode(code).languageCode, isNotEmpty);
    }
    expect(LanguageNames.all.length, LanguageCodes.all.length);
  });

  test('regional and script codes map to full locales', () {
    expect(localeForCode('pt_BR'), const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'));
    expect(
      localeForCode('zh_Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(localeForCode('he'), const Locale('he'));
  });

  test('unknown names fall back to the code', () {
    expect(LanguageNames.of('xx'), 'xx');
  });
}
