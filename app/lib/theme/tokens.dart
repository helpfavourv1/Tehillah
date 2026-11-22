import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The three palettes the app can show. Sepia is used by the reader only.
enum PaletteMode { light, dark, sepia }

/// Every color the app uses, named by meaning. Widgets read these and never
/// contain a raw color value.
@immutable
class AppPalette {
  const AppPalette({
    required this.mode,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderSubtle,
    required this.borderFocus,
    required this.error,
    required this.success,
    required this.warning,
    required this.starFill,
    required this.lampFill,
    required this.pitchLine,
    required this.postWood,
    required this.verseCardSurface,
    required this.scrim,
  });

  final PaletteMode mode;

  /// Screen background.
  final Color bgPrimary;

  /// Cards, sheets and dialogs.
  final Color bgSecondary;

  /// Inputs, empty and disabled fills, pressed row tint.
  final Color bgTertiary;

  /// Primary actions and active state.
  final Color accent;

  /// Pressed fill of a primary action.
  final Color accentDim;

  /// Label color on top of [accent] and [accentDim].
  final Color onAccent;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Card borders and dividers.
  final Color borderSubtle;

  /// Border of a focused input.
  final Color borderFocus;

  final Color error;
  final Color success;
  final Color warning;

  /// Filled star in a match result.
  final Color starFill;

  /// Lit lamp on the Journey map.
  final Color lampFill;

  /// Pitch markings.
  final Color pitchLine;

  /// Goal posts and crossbar.
  final Color postWood;

  /// Surface of the scripture moment card.
  final Color verseCardSurface;

  /// Barrier behind sheets and dialogs.
  final Color scrim;

  static const AppPalette light = AppPalette(
    mode: PaletteMode.light,
    bgPrimary: Color(0xFFF2F2F7),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFE9E9EE),
    accent: Color(0xFF17703F),
    accentDim: Color(0xFF14633A),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF5A5A63),
    textTertiary: Color(0xFF62626C),
    borderSubtle: Color(0xFFD8D8DE),
    borderFocus: Color(0xFF17703F),
    error: Color(0xFFC4262B),
    success: Color(0xFF1A6B3D),
    warning: Color(0xFF8A5A00),
    starFill: Color(0xFFB26A00),
    lampFill: Color(0xFF9A6700),
    pitchLine: Color(0xFFFFFFFF),
    postWood: Color(0xFF8B5E3C),
    verseCardSurface: Color(0xFFEAF4EE),
    scrim: Color(0x66000000),
  );

  static const AppPalette dark = AppPalette(
    mode: PaletteMode.dark,
    bgPrimary: Color(0xFF0B0B0E),
    bgSecondary: Color(0xFF1C1C20),
    bgTertiary: Color(0xFF2A2A30),
    accent: Color(0xFF3DBF7F),
    accentDim: Color(0xFF2E9962),
    onAccent: Color(0xFF06140C),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFB0B0B8),
    textTertiary: Color(0xFF9A9AA4),
    borderSubtle: Color(0xFF38383F),
    borderFocus: Color(0xFF3DBF7F),
    error: Color(0xFFFF6B6B),
    success: Color(0xFF4CD08A),
    warning: Color(0xFFF5B94A),
    starFill: Color(0xFFF5B94A),
    lampFill: Color(0xFFF0B040),
    pitchLine: Color(0xFFFFFFFF),
    postWood: Color(0xFFC99A6B),
    verseCardSurface: Color(0xFF16251D),
    scrim: Color(0x99000000),
  );

  /// Warm paper, for the reader.
  static const AppPalette sepia = AppPalette(
    mode: PaletteMode.sepia,
    bgPrimary: Color(0xFFF4ECD8),
    bgSecondary: Color(0xFFFBF6E8),
    bgTertiary: Color(0xFFE8DDC2),
    accent: Color(0xFF17703F),
    accentDim: Color(0xFF14633A),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF3B2F1E),
    textSecondary: Color(0xFF6B5B45),
    textTertiary: Color(0xFF6F5F49),
    borderSubtle: Color(0xFFD9CCAA),
    borderFocus: Color(0xFF17703F),
    error: Color(0xFFB3261E),
    success: Color(0xFF1A6B3D),
    warning: Color(0xFF7A4F00),
    starFill: Color(0xFF9A5B00),
    lampFill: Color(0xFF8A5A00),
    pitchLine: Color(0xFFFFFFFF),
    postWood: Color(0xFF7A4F2A),
    verseCardSurface: Color(0xFFEAE0C4),
    scrim: Color(0x66000000),
  );

  static AppPalette forMode(PaletteMode mode) {
    switch (mode) {
      case PaletteMode.light:
        return light;
      case PaletteMode.dark:
        return dark;
      case PaletteMode.sepia:
        return sepia;
    }
  }

  /// Blends two palettes for the 200 ms theme cross-fade. The mode of the
  /// target palette is kept so that behavior switches at once.
  static AppPalette lerp(AppPalette a, AppPalette b, double t) {
    Color mix(Color x, Color y) => Color.lerp(x, y, t)!;
    return AppPalette(
      mode: t < 0.5 ? a.mode : b.mode,
      bgPrimary: mix(a.bgPrimary, b.bgPrimary),
      bgSecondary: mix(a.bgSecondary, b.bgSecondary),
      bgTertiary: mix(a.bgTertiary, b.bgTertiary),
      accent: mix(a.accent, b.accent),
      accentDim: mix(a.accentDim, b.accentDim),
      onAccent: mix(a.onAccent, b.onAccent),
      textPrimary: mix(a.textPrimary, b.textPrimary),
      textSecondary: mix(a.textSecondary, b.textSecondary),
      textTertiary: mix(a.textTertiary, b.textTertiary),
      borderSubtle: mix(a.borderSubtle, b.borderSubtle),
      borderFocus: mix(a.borderFocus, b.borderFocus),
      error: mix(a.error, b.error),
      success: mix(a.success, b.success),
      warning: mix(a.warning, b.warning),
      starFill: mix(a.starFill, b.starFill),
      lampFill: mix(a.lampFill, b.lampFill),
      pitchLine: mix(a.pitchLine, b.pitchLine),
      postWood: mix(a.postWood, b.postWood),
      verseCardSurface: mix(a.verseCardSurface, b.verseCardSurface),
      scrim: mix(a.scrim, b.scrim),
    );
  }

  List<Object> get _fields => <Object>[
        mode,
        bgPrimary,
        bgSecondary,
        bgTertiary,
        accent,
        accentDim,
        onAccent,
        textPrimary,
        textSecondary,
        textTertiary,
        borderSubtle,
        borderFocus,
        error,
        success,
        warning,
        starFill,
        lampFill,
        pitchLine,
        postWood,
        verseCardSurface,
        scrim,
      ];

  @override
  bool operator ==(Object other) =>
      other is AppPalette && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Spacing scale on a 4 px grid.
abstract final class Sp {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Corner radii.
abstract final class Radii {
  static const double card = 16;
  static const double hero = 24;
  static const double chip = 12;
  static const double button = 12;
  static const double input = 12;
  static const double sheetTop = 20;
  static const double dialog = 16;

  /// Pill radius: half of the height.
  static double pill(double height) => height / 2;
}

/// Fixed icon sizes.
abstract final class IconSizes {
  static const double navBar = 22;
  static const double rowLeading = 22;
  static const double rowTrailing = 16;
  static const double hero = 32;
}

/// Sizes and opacities shared by controls.
abstract final class Metrics {
  /// Minimum touch target, no exceptions.
  static const double touchTarget = 48;

  /// Container around a toolbar icon.
  static const double iconChip = 40;

  /// Height of a primary button.
  static const double buttonHeight = 48;

  /// Width of card and divider borders.
  static const double hairline = 0.5;

  /// Opacity of a card while pressed.
  static const double pressedOpacity = 0.7;

  /// Scale of a button while pressed.
  static const double pressedScale = 0.97;

  /// Opacity of a disabled control.
  static const double disabledOpacity = 0.4;

  /// The widest a screen's content grows, so tablets and landscape phones do
  /// not stretch lines across the whole display.
  static const double contentMaxWidth = 640;

  /// The keyboard-focus ring around a control.
  static const double focusRing = 2;

  /// The minimum height of a card or row: two lines of text plus padding.
  static const double rowMinHeight = 56;

  /// The height of the navigation bar.
  static const double navBarHeight = 56;

  /// The height of the small pill chip.
  static const double chipHeight = 32;
}

/// Durations and curves of interface motion. No spring or bounce anywhere.
/// When Reduce Motion is on, every duration becomes [Duration.zero].
abstract final class Motion {
  static const Duration push = Duration(milliseconds: 350);
  static const Duration pop = Duration(milliseconds: 280);
  static const Duration sheet = Duration(milliseconds: 400);
  static const Duration press = Duration(milliseconds: 150);
  static const Duration success = Duration(milliseconds: 300);
  static const Duration themeChange = Duration(milliseconds: 200);

  /// Distance a pushed screen slides while it fades in.
  static const double pushSlide = 20;

  static const Curve inOut = Curves.easeInOut;
  static const Curve out = Curves.easeOut;
  static const Curve linear = Curves.linear;

  /// Returns [d], or zero when the user asked to reduce motion.
  static Duration scaled(BuildContext context, Duration d) {
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduce ? Duration.zero : d;
  }
}
