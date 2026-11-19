import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.rtl}) {
  return Directionality(
    textDirection: direction,
    child: AppTheme(
      data: AppThemeData.forMode(PaletteMode.light),
      child: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('a non-directional icon does not match the text direction',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const AppIcon(AppIcons.settings)));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon!.matchTextDirection, isFalse);
    expect(icon.icon!.fontFamily, AppIconFont.family);
    expect(icon.size, IconSizes.rowLeading);
    expect(icon.color, AppPalette.light.textPrimary);
  });

  testWidgets('a directional icon matches the text direction',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const AppIcon(AppIcons.back)));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon!.matchTextDirection, isTrue);
  });

  testWidgets('size, color and semantic label are passed through',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(
      const AppIcon(
        AppIcons.search,
        size: IconSizes.hero,
        color: Color(0xFF123456),
        semanticLabel: 'Search',
      ),
    ));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, IconSizes.hero);
    expect(icon.color, const Color(0xFF123456));
    expect(icon.semanticLabel, 'Search');
  });

  test('only direction-implying aliases mirror', () {
    expect(AppIcons.back.matchTextDirection, isTrue);
    expect(AppIcons.forward.matchTextDirection, isTrue);
    expect(AppIcons.settings.matchTextDirection, isFalse);
    expect(AppIcons.ball.matchTextDirection, isFalse);
    expect(AppIcons.search.matchTextDirection, isFalse);
  });

  test('every alias codepoint is in the bundled icon set and vice versa', () {
    final Map<String, dynamic> set = jsonDecode(
      File('../tools/icons/icon_set.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final Set<int> inSet = set.values
        .map((dynamic v) => int.parse((v as String).substring(2), radix: 16))
        .toSet();
    final String source = File('lib/theme/icon_aliases.dart').readAsStringSync();
    final Set<int> used = RegExp(r'IconData\(\s*0x([0-9a-f]+)')
        .allMatches(source)
        .map((RegExpMatch m) => int.parse(m.group(1)!, radix: 16))
        .toSet();
    expect(used, inSet);
  });
}
