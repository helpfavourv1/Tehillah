import 'package:flutter/widgets.dart';

/// The icon font bundled in assets/icons (declared in pubspec.yaml).
abstract final class AppIconFont {
  static const String family = 'PhosphorBold';
}

/// An icon by meaning. [mirrorsInRtl] is true only for icons that imply
/// direction (back, forward); every other icon keeps its orientation in
/// right-to-left layouts.
@immutable
class AppSymbol {
  const AppSymbol.glyph(int codePoint, {this.mirrorsInRtl = false})
      : data = IconData(
          codePoint,
          fontFamily: AppIconFont.family,
          matchTextDirection: mirrorsInRtl,
        );

  /// A constant, so the build can strip unused glyphs from the icon font.
  final IconData data;
  final bool mirrorsInRtl;
}

/// The only file that names icon glyphs. Screens use these aliases. The font
/// is Phosphor Icons in its bold weight (MIT license), reduced to the icons
/// listed in tools/icons/icon_set.json, whose codepoints these values match.
abstract final class AppIcons {
  /// caretLeft
  static const AppSymbol back = AppSymbol.glyph(0xe138, mirrorsInRtl: true);
  /// caretRight
  static const AppSymbol forward = AppSymbol.glyph(0xe13a, mirrorsInRtl: true);
  /// caretDown
  static const AppSymbol chevronDown = AppSymbol.glyph(0xe136);
  /// x
  static const AppSymbol close = AppSymbol.glyph(0xe4f6);
  /// check
  static const AppSymbol check = AppSymbol.glyph(0xe182);
  /// house
  static const AppSymbol home = AppSymbol.glyph(0xe2c2);
  /// path
  static const AppSymbol journey = AppSymbol.glyph(0xe39c);
  /// soccerBall
  static const AppSymbol ball = AppSymbol.glyph(0xe716);
  /// target
  static const AppSymbol target = AppSymbol.glyph(0xe47c);
  /// calendarCheck
  static const AppSymbol daily = AppSymbol.glyph(0xe712);
  /// flame
  static const AppSymbol streak = AppSymbol.glyph(0xe624);
  /// trophy
  static const AppSymbol achievements = AppSymbol.glyph(0xe67e);
  /// medal
  static const AppSymbol medal = AppSymbol.glyph(0xe320);
  /// star
  static const AppSymbol star = AppSymbol.glyph(0xe46a);
  /// lamp
  static const AppSymbol lamp = AppSymbol.glyph(0xe638);
  /// leaf
  static const AppSymbol fruit = AppSymbol.glyph(0xe2da);
  /// shieldStar
  static const AppSymbol armor = AppSymbol.glyph(0xec34);
  /// heartStraight
  static const AppSymbol nerve = AppSymbol.glyph(0xe2aa);
  /// pause
  static const AppSymbol pause = AppSymbol.glyph(0xe39e);
  /// play
  static const AppSymbol play = AppSymbol.glyph(0xe3d0);
  /// hourglass
  static const AppSymbol timer = AppSymbol.glyph(0xe2b2);
  /// flag
  static const AppSymbol flag = AppSymbol.glyph(0xe244);
  /// bookOpenText
  static const AppSymbol reader = AppSymbol.glyph(0xe8f2);
  /// bookOpen
  static const AppSymbol verse = AppSymbol.glyph(0xe0e6);
  /// magnifyingGlass
  static const AppSymbol search = AppSymbol.glyph(0xe30c);
  /// bookmarkSimple
  static const AppSymbol bookmark = AppSymbol.glyph(0xe0ea);
  /// textAa
  static const AppSymbol textSize = AppSymbol.glyph(0xe6ee);
  /// palette
  static const AppSymbol theme = AppSymbol.glyph(0xe6c8);
  /// translate
  static const AppSymbol language = AppSymbol.glyph(0xe4a2);
  /// shareNetwork
  static const AppSymbol share = AppSymbol.glyph(0xe408);
  /// listBullets
  static const AppSymbol list = AppSymbol.glyph(0xe2f2);
  /// gear
  static const AppSymbol settings = AppSymbol.glyph(0xe270);
  /// bell
  static const AppSymbol reminder = AppSymbol.glyph(0xe0ce);
  /// speakerHigh
  static const AppSymbol sound = AppSymbol.glyph(0xe44a);
  /// speakerSlash
  static const AppSymbol soundOff = AppSymbol.glyph(0xe45a);
  /// vibrate
  static const AppSymbol haptics = AppSymbol.glyph(0xe4d8);
  /// shieldCheck
  static const AppSymbol privacy = AppSymbol.glyph(0xe40c);
  /// scroll
  static const AppSymbol license = AppSymbol.glyph(0xeb7a);
  /// envelope
  static const AppSymbol email = AppSymbol.glyph(0xe214);
  /// prohibit
  static const AppSymbol removeAds = AppSymbol.glyph(0xe3de);
  /// arrowsClockwise
  static const AppSymbol restore = AppSymbol.glyph(0xe094);
  /// lockKey
  static const AppSymbol locked = AppSymbol.glyph(0xe2fe);
  /// downloadSimple
  static const AppSymbol download = AppSymbol.glyph(0xe20c);
  /// trash
  static const AppSymbol delete = AppSymbol.glyph(0xe4a6);
  /// arrowCounterClockwise
  static const AppSymbol retry = AppSymbol.glyph(0xe038);
  /// warning
  static const AppSymbol warning = AppSymbol.glyph(0xe4e0);
  /// info
  static const AppSymbol info = AppSymbol.glyph(0xe2ce);
  /// wifiSlash
  static const AppSymbol offline = AppSymbol.glyph(0xe4f2);
  /// wifiHigh
  static const AppSymbol wifi = AppSymbol.glyph(0xe4ea);
}
