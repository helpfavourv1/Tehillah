import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/theme/typography.dart';

void main() {
  final TextRoles roles = TextRoles.forPalette(AppPalette.light);

  test('ramp matches the design spec', () {
    expect(roles.display.fontSize, 34);
    expect(roles.display.fontWeight, FontWeight.w700);
    expect(roles.display.height, closeTo(1.1, 0.0001));
    expect(roles.headline.fontSize, 28);
    expect(roles.headline.fontWeight, FontWeight.w600);
    expect(roles.title1.fontSize, 22);
    expect(roles.title2.fontSize, 17);
    expect(roles.title2.fontWeight, FontWeight.w600);
    expect(roles.body.fontSize, 17);
    expect(roles.body.fontWeight, FontWeight.w400);
    expect(roles.body.height, closeTo(1.5, 0.0001));
    expect(roles.callout.fontSize, 16);
    expect(roles.callout.fontWeight, FontWeight.w500);
    expect(roles.footnote.fontSize, 13);
    expect(roles.caption.fontSize, 12);
    expect(roles.sectionHeader.fontSize, 12);
    expect(roles.sectionHeader.letterSpacing, greaterThan(0));
  });

  test('chrome roles use the chrome face and reading uses the reading face',
      () {
    for (final TextStyle s in <TextStyle>[
      roles.display,
      roles.score,
      roles.headline,
      roles.title1,
      roles.title2,
      roles.callout,
      roles.footnote,
      roles.caption,
      roles.sectionHeader,
    ]) {
      expect(s.fontFamily, AppFonts.chrome);
    }
    expect(roles.body.fontFamily, AppFonts.reading);
  });

  test('score uses tabular figures', () {
    expect(roles.score.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(roles.display.fontFeatures, isNull);
  });

  test('colors come from the palette', () {
    expect(roles.display.color, AppPalette.light.textPrimary);
    expect(roles.footnote.color, AppPalette.light.textSecondary);
    expect(roles.caption.color, AppPalette.light.textTertiary);
    final TextRoles dark = TextRoles.forPalette(AppPalette.dark);
    expect(dark.display.color, AppPalette.dark.textPrimary);
  });

  test('line height grows for scripts that need it', () {
    expect(TextRoles.heightScaleFor(null), 1.0);
    expect(TextRoles.heightScaleFor(const Locale('en')), 1.0);
    expect(TextRoles.heightScaleFor(const Locale('hi')), 1.15);
    expect(TextRoles.heightScaleFor(const Locale('ar')), 1.1);
    expect(TextRoles.heightScaleFor(const Locale('ja')), 1.08);
    expect(TextRoles.heightScaleFor(const Locale('he')), 1.05);
    final TextRoles hindi =
        TextRoles.forPalette(AppPalette.light, locale: const Locale('hi'));
    expect(hindi.body.height, closeTo(1.5 * 1.15, 0.0001));
  });

  test('readerBody scales the reading size only', () {
    final TextStyle big = roles.readerBody(1.5);
    expect(big.fontSize, closeTo(25.5, 0.0001));
    expect(big.fontFamily, AppFonts.reading);
    expect(roles.readerBody(1).fontSize, 17);
  });
}
