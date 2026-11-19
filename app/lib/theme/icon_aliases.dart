import 'package:flutter/widgets.dart';

/// The icon font bundled in assets/icons (declared in pubspec.yaml).
abstract final class AppIconFont {
  static const String family = 'PhosphorBold';
}

/// The only file that names icon glyphs. Screens use these aliases. The font
/// is Phosphor Icons in its bold weight (MIT license), reduced to the icons
/// listed in tools/icons/icon_set.json, whose codepoints these values match.
abstract final class AppIcons {
  /// caretLeft
  static const IconData back = IconData(
    0xe138,
    fontFamily: AppIconFont.family,
    matchTextDirection: true,
  );
  /// caretRight
  static const IconData forward = IconData(
    0xe13a,
    fontFamily: AppIconFont.family,
    matchTextDirection: true,
  );
  /// caretDown
  static const IconData chevronDown = IconData(
    0xe136,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// x
  static const IconData close = IconData(
    0xe4f6,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// check
  static const IconData check = IconData(
    0xe182,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// house
  static const IconData home = IconData(
    0xe2c2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// path
  static const IconData journey = IconData(
    0xe39c,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// soccerBall
  static const IconData ball = IconData(
    0xe716,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// target
  static const IconData target = IconData(
    0xe47c,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// calendarCheck
  static const IconData daily = IconData(
    0xe712,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// flame
  static const IconData streak = IconData(
    0xe624,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// trophy
  static const IconData achievements = IconData(
    0xe67e,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// medal
  static const IconData medal = IconData(
    0xe320,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// star
  static const IconData star = IconData(
    0xe46a,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// lamp
  static const IconData lamp = IconData(
    0xe638,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// leaf
  static const IconData fruit = IconData(
    0xe2da,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// shieldStar
  static const IconData armor = IconData(
    0xec34,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// heartStraight
  static const IconData nerve = IconData(
    0xe2aa,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// pause
  static const IconData pause = IconData(
    0xe39e,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// play
  static const IconData play = IconData(
    0xe3d0,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// hourglass
  static const IconData timer = IconData(
    0xe2b2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// flag
  static const IconData flag = IconData(
    0xe244,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// bookOpenText
  static const IconData reader = IconData(
    0xe8f2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// bookOpen
  static const IconData verse = IconData(
    0xe0e6,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// magnifyingGlass
  static const IconData search = IconData(
    0xe30c,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// bookmarkSimple
  static const IconData bookmark = IconData(
    0xe0ea,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// textAa
  static const IconData textSize = IconData(
    0xe6ee,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// palette
  static const IconData theme = IconData(
    0xe6c8,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// translate
  static const IconData language = IconData(
    0xe4a2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// shareNetwork
  static const IconData share = IconData(
    0xe408,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// listBullets
  static const IconData list = IconData(
    0xe2f2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// gear
  static const IconData settings = IconData(
    0xe270,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// bell
  static const IconData reminder = IconData(
    0xe0ce,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// speakerHigh
  static const IconData sound = IconData(
    0xe44a,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// speakerSlash
  static const IconData soundOff = IconData(
    0xe45a,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// vibrate
  static const IconData haptics = IconData(
    0xe4d8,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// shieldCheck
  static const IconData privacy = IconData(
    0xe40c,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// scroll
  static const IconData license = IconData(
    0xeb7a,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// envelope
  static const IconData email = IconData(
    0xe214,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// prohibit
  static const IconData removeAds = IconData(
    0xe3de,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// arrowsClockwise
  static const IconData restore = IconData(
    0xe094,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// lockKey
  static const IconData locked = IconData(
    0xe2fe,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// downloadSimple
  static const IconData download = IconData(
    0xe20c,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// trash
  static const IconData delete = IconData(
    0xe4a6,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// arrowCounterClockwise
  static const IconData retry = IconData(
    0xe038,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// warning
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// info
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// wifiSlash
  static const IconData offline = IconData(
    0xe4f2,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
  /// wifiHigh
  static const IconData wifi = IconData(
    0xe4ea,
    fontFamily: AppIconFont.family,
    matchTextDirection: false,
  );
}
