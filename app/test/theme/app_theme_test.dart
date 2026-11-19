import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

void main() {
  testWidgets('AppTheme.of returns the nearest data and rebuilds on change',
      (WidgetTester tester) async {
    final List<PaletteMode> seen = <PaletteMode>[];
    Widget build(PaletteMode mode) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: AppTheme(
          data: AppThemeData.forMode(mode),
          child: Builder(builder: (BuildContext context) {
            seen.add(AppTheme.of(context).palette.mode);
            return const SizedBox();
          }),
        ),
      );
    }

    await tester.pumpWidget(build(PaletteMode.light));
    await tester.pumpWidget(build(PaletteMode.dark));
    expect(seen, <PaletteMode>[PaletteMode.light, PaletteMode.dark]);
  });

  test('AppThemeData equality follows the palette', () {
    expect(
      AppThemeData.forMode(PaletteMode.light),
      AppThemeData.forMode(PaletteMode.light, locale: const Locale('de')),
    );
    expect(
      AppThemeData.forMode(PaletteMode.light) ==
          AppThemeData.forMode(PaletteMode.dark),
      isFalse,
    );
  });

  test('forPalette keeps a blended palette', () {
    final AppPalette mid =
        AppPalette.lerp(AppPalette.light, AppPalette.dark, 0.5);
    expect(AppThemeData.forPalette(mid).palette, mid);
  });
}
