import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:tehillah/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  test('intl names map app locales', () {
    expect(Formatters.intlName(const Locale('pt')), 'pt_BR');
    expect(Formatters.intlName(const Locale('pt', 'BR')), 'pt_BR');
    expect(Formatters.intlName(const Locale('en')), 'en');
    expect(Formatters.intlName(const Locale('ar')), 'ar');
    expect(
      Formatters.intlName(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      'zh',
    );
  });

  test('integers group by locale', () {
    expect(Formatters(const Locale('en')).integer(1234567), '1,234,567');
    expect(Formatters(const Locale('de')).integer(1234567), '1.234.567');
  });

  test('percent formats a fraction', () {
    expect(Formatters(const Locale('en')).percent(0.5), '50%');
    expect(Formatters(const Locale('en')).percent(1), '100%');
  });

  test('dates use the locale pattern', () {
    final DateTime d = DateTime(2026, 11, 18);
    expect(Formatters(const Locale('en')).date(d), 'Nov 18, 2026');
    expect(Formatters(const Locale('de')).date(d), contains('2026'));
    expect(Formatters(const Locale('ja')).date(d), contains('2026'));
    expect(Formatters(const Locale('en')).weekdayShort(d), 'Wed');
  });

  test('score joins two numbers with an en dash', () {
    expect(Formatters(const Locale('en')).score(3, 2), '3 – 2');
    expect(Formatters(const Locale('en')).score(0, 0), '0 – 0');
  });
}
