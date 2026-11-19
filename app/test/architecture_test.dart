import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/core must stay pure Dart: no Flutter, no dart:io or dart:ui, no plugins,
/// and no import of any other layer of the app.
void main() {
  const Set<String> allowedPackages = <String>{'crypto', 'collection', 'meta'};
  final RegExp importLine = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  test('core imports only pure Dart', () {
    final Directory core = Directory('lib/core');
    expect(core.existsSync(), isTrue, reason: 'lib/core must exist');

    final List<String> violations = <String>[];
    for (final FileSystemEntity entity in core.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String source = entity.readAsStringSync();
      for (final RegExpMatch m in importLine.allMatches(source)) {
        final String uri = m.group(1)!;
        if (uri.startsWith('dart:')) {
          if (uri == 'dart:io' ||
              uri == 'dart:ui' ||
              uri == 'dart:html' ||
              uri == 'dart:js_interop' ||
              uri == 'dart:isolate') {
            violations.add('${entity.path}: $uri');
          }
        } else if (uri.startsWith('package:')) {
          final String name = uri.substring(8).split('/').first;
          final bool ownCore = uri.startsWith('package:tehillah/core/');
          if (name == 'tehillah') {
            if (!ownCore) {
              violations.add('${entity.path}: $uri');
            }
          } else if (!allowedPackages.contains(name)) {
            violations.add('${entity.path}: $uri');
          }
        } else if (uri.startsWith('..') || uri.contains('/platform/')) {
          violations.add('${entity.path}: $uri (use package imports)');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('widget code does not import platform adapters directly', () {
    final List<String> violations = <String>[];
    for (final String folder in <String>['screens', 'widgets', 'game']) {
      final Directory dir = Directory('lib/$folder');
      if (!dir.existsSync()) {
        continue;
      }
      for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final String source = entity.readAsStringSync();
        for (final RegExpMatch m in importLine.allMatches(source)) {
          final String uri = m.group(1)!;
          if (uri.startsWith('package:tehillah/platform/')) {
            violations.add('${entity.path}: $uri');
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
