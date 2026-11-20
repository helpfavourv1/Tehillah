import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/language_codes.dart';

Map<String, Object?> _read(String name) =>
    jsonDecode(File('assets/verses/$name').readAsStringSync()) as Map<String, Object?>;

void main() {
  final Map<String, Object?> curatedFile = _read('curated.json');
  final List<CuratedVerse> curated = <CuratedVerse>[
    for (final Object? e in curatedFile['verses']! as List<Object?>)
      CuratedVerse.fromJson(e! as Map<String, Object?>),
  ];

  test('curated list has unique ids and every moment is covered', () {
    expect(curated.length, greaterThan(100));
    expect(curated.map((CuratedVerse v) => v.id).toSet().length, curated.length);
    for (final VerseMoment m in VerseMoment.values) {
      expect(curated.where((CuratedVerse v) => v.suits(m)).length, greaterThanOrEqualTo(25), reason: m.name);
    }
  });

  for (final String lang in LanguageCodes.all) {
    test('$lang has a non-empty text for every curated verse and nothing extra', () {
      final Map<String, Object?> file = _read('$lang.json');
      expect(file['language'], lang);
      final Map<String, Object?> texts = file['texts']! as Map<String, Object?>;
      expect(texts.keys.toSet(), curated.map((CuratedVerse v) => v.id).toSet());
      for (final MapEntry<String, Object?> e in texts.entries) {
        expect((e.value! as String).trim(), isNotEmpty, reason: e.key);
      }
    });
  }
}
