import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/theme/tokens.dart';

double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final List<AppPalette> palettes = <AppPalette>[
    AppPalette.light,
    AppPalette.dark,
    AppPalette.sepia,
  ];

  for (final AppPalette p in palettes) {
    group('palette ${p.mode.name}', () {
      final Map<String, Color> surfaces = <String, Color>{
        'bgPrimary': p.bgPrimary,
        'bgSecondary': p.bgSecondary,
        'bgTertiary': p.bgTertiary,
      };
      final Map<String, Color> inks = <String, Color>{
        'textPrimary': p.textPrimary,
        'textSecondary': p.textSecondary,
        'textTertiary': p.textTertiary,
        'accent': p.accent,
        'error': p.error,
        'success': p.success,
        'warning': p.warning,
      };

      surfaces.forEach((String surfaceName, Color surface) {
        inks.forEach((String inkName, Color ink) {
          test('$inkName on $surfaceName is at least 4.5:1', () {
            expect(contrast(ink, surface), greaterThanOrEqualTo(4.5));
          });
        });
      });

      test('onAccent is readable on accent and accentDim', () {
        expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
        expect(contrast(p.onAccent, p.accentDim), greaterThanOrEqualTo(4.5));
      });

      test('text and accent are readable on the verse card surface', () {
        for (final Color ink in <Color>[
          p.textPrimary,
          p.textSecondary,
          p.textTertiary,
          p.accent,
        ]) {
          expect(contrast(ink, p.verseCardSurface), greaterThanOrEqualTo(4.5));
        }
      });

      test('graphic tokens are at least 3:1 against their surfaces', () {
        expect(contrast(p.starFill, p.bgSecondary), greaterThanOrEqualTo(3));
        expect(contrast(p.starFill, p.bgPrimary), greaterThanOrEqualTo(3));
        expect(contrast(p.lampFill, p.bgSecondary), greaterThanOrEqualTo(3));
        expect(contrast(p.lampFill, p.bgPrimary), greaterThanOrEqualTo(3));
        expect(contrast(p.postWood, p.bgPrimary), greaterThanOrEqualTo(3));
        expect(contrast(p.borderFocus, p.bgPrimary), greaterThanOrEqualTo(3));
      });
    });
  }

  test('forMode returns the matching palette', () {
    expect(AppPalette.forMode(PaletteMode.light), AppPalette.light);
    expect(AppPalette.forMode(PaletteMode.dark), AppPalette.dark);
    expect(AppPalette.forMode(PaletteMode.sepia), AppPalette.sepia);
  });

  test('lerp returns the endpoints at 0 and 1', () {
    expect(AppPalette.lerp(AppPalette.light, AppPalette.dark, 0),
        AppPalette.light);
    expect(AppPalette.lerp(AppPalette.light, AppPalette.dark, 1),
        AppPalette.dark);
  });

  test('palettes differ from each other', () {
    expect(AppPalette.light == AppPalette.dark, isFalse);
    expect(AppPalette.light.hashCode == AppPalette.sepia.hashCode, isFalse);
  });

  test('spacing follows the 4 px grid scale', () {
    expect(
      <double>[
        Sp.xxs,
        Sp.xs,
        Sp.sm,
        Sp.md,
        Sp.lg,
        Sp.xl,
        Sp.xxl,
        Sp.xxxl,
      ],
      <double>[2, 4, 8, 16, 24, 32, 48, 64],
    );
  });

  test('radii, icon sizes and metrics match the design spec', () {
    expect(Radii.card, 16);
    expect(Radii.hero, 24);
    expect(Radii.chip, 12);
    expect(Radii.button, 12);
    expect(Radii.sheetTop, 20);
    expect(Radii.dialog, 16);
    expect(Radii.pill(40), 20);
    expect(IconSizes.navBar, 22);
    expect(IconSizes.rowLeading, 22);
    expect(IconSizes.rowTrailing, 16);
    expect(IconSizes.hero, 32);
    expect(Metrics.touchTarget, 48);
    expect(Metrics.iconChip, 40);
    expect(Metrics.buttonHeight, 48);
    expect(Metrics.pressedOpacity, 0.7);
    expect(Metrics.disabledOpacity, 0.4);
  });

  test('motion durations match the design spec', () {
    expect(Motion.push, const Duration(milliseconds: 350));
    expect(Motion.pop, const Duration(milliseconds: 280));
    expect(Motion.sheet, const Duration(milliseconds: 400));
    expect(Motion.press, const Duration(milliseconds: 150));
    expect(Motion.success, const Duration(milliseconds: 300));
    expect(Motion.themeChange, const Duration(milliseconds: 200));
  });

  testWidgets('Motion.scaled is zero when animations are disabled',
      (WidgetTester tester) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(builder: (BuildContext context) {
          normal = Motion.scaled(context, Motion.push);
          return const SizedBox();
        }),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (BuildContext context) {
          reduced = Motion.scaled(context, Motion.push);
          return const SizedBox();
        }),
      ),
    );
    expect(normal, Motion.push);
    expect(reduced, Duration.zero);
  });
}
