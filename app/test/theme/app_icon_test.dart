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
  testWidgets('a non-directional icon never mirrors', (WidgetTester tester) async {
    await tester.pumpWidget(host(const AppIcon(AppIcons.settings)));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.textDirection, TextDirection.ltr);
    expect(icon.size, IconSizes.rowLeading);
    expect(icon.color, AppPalette.light.textPrimary);
  });

  testWidgets('a directional icon follows the ambient direction',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const AppIcon(AppIcons.back)));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.textDirection, isNull);
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
    expect(AppIcons.back.mirrorsInRtl, isTrue);
    expect(AppIcons.forward.mirrorsInRtl, isTrue);
    expect(AppIcons.settings.mirrorsInRtl, isFalse);
    expect(AppIcons.ball.mirrorsInRtl, isFalse);
    expect(AppIcons.search.mirrorsInRtl, isFalse);
  });
}
