import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/config/app_config.dart';

void main() {
  test('the build number in the app matches pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? m = RegExp(r'^version:\s*\S+\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(m, isNotNull);
    expect(AppConfig.buildNumber, int.parse(m!.group(1)!));
  });

  test('the update link points at this application', () {
    expect(AppConfig.playStoreUrl, contains('id=${AppConfig.applicationId}'));
  });
}
