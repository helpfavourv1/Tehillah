import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An icon by meaning. [mirrorsInRtl] is true only for icons that imply
/// direction (back, forward, chevrons); everything else keeps its orientation
/// in right-to-left layouts.
@immutable
class AppSymbol {
  const AppSymbol(this.data, {this.mirrorsInRtl = false});

  final IconData data;
  final bool mirrorsInRtl;
}

/// The only file that names the underlying icon set. Screens use these
/// aliases and never import the icon package.
abstract final class AppIcons {
  static const AppSymbol back =
      AppSymbol(PhosphorIconsBold.caretLeft, mirrorsInRtl: true);
  static const AppSymbol forward =
      AppSymbol(PhosphorIconsBold.caretRight, mirrorsInRtl: true);
  static const AppSymbol chevronDown = AppSymbol(PhosphorIconsBold.caretDown);
  static const AppSymbol close = AppSymbol(PhosphorIconsBold.x);
  static const AppSymbol check = AppSymbol(PhosphorIconsBold.check);

  static const AppSymbol home = AppSymbol(PhosphorIconsBold.house);
  static const AppSymbol journey = AppSymbol(PhosphorIconsBold.path);
  static const AppSymbol ball = AppSymbol(PhosphorIconsBold.soccerBall);
  static const AppSymbol target = AppSymbol(PhosphorIconsBold.target);
  static const AppSymbol daily = AppSymbol(PhosphorIconsBold.calendarCheck);
  static const AppSymbol streak = AppSymbol(PhosphorIconsBold.flame);
  static const AppSymbol achievements = AppSymbol(PhosphorIconsBold.trophy);
  static const AppSymbol medal = AppSymbol(PhosphorIconsBold.medal);
  static const AppSymbol star = AppSymbol(PhosphorIconsBold.star);
  static const AppSymbol lamp = AppSymbol(PhosphorIconsBold.lamp);
  static const AppSymbol fruit = AppSymbol(PhosphorIconsBold.leaf);
  static const AppSymbol armor = AppSymbol(PhosphorIconsBold.shieldStar);
  static const AppSymbol nerve = AppSymbol(PhosphorIconsBold.heartStraight);
  static const AppSymbol pause = AppSymbol(PhosphorIconsBold.pause);
  static const AppSymbol play = AppSymbol(PhosphorIconsBold.play);
  static const AppSymbol timer = AppSymbol(PhosphorIconsBold.hourglass);
  static const AppSymbol flag = AppSymbol(PhosphorIconsBold.flag);

  static const AppSymbol reader = AppSymbol(PhosphorIconsBold.bookOpenText);
  static const AppSymbol verse = AppSymbol(PhosphorIconsBold.bookOpen);
  static const AppSymbol search = AppSymbol(PhosphorIconsBold.magnifyingGlass);
  static const AppSymbol bookmark = AppSymbol(PhosphorIconsBold.bookmarkSimple);
  static const AppSymbol textSize = AppSymbol(PhosphorIconsBold.textAa);
  static const AppSymbol theme = AppSymbol(PhosphorIconsBold.palette);
  static const AppSymbol language = AppSymbol(PhosphorIconsBold.translate);
  static const AppSymbol share = AppSymbol(PhosphorIconsBold.shareNetwork);
  static const AppSymbol list = AppSymbol(PhosphorIconsBold.listBullets);

  static const AppSymbol settings = AppSymbol(PhosphorIconsBold.gear);
  static const AppSymbol reminder = AppSymbol(PhosphorIconsBold.bell);
  static const AppSymbol sound = AppSymbol(PhosphorIconsBold.speakerHigh);
  static const AppSymbol soundOff = AppSymbol(PhosphorIconsBold.speakerSlash);
  static const AppSymbol haptics = AppSymbol(PhosphorIconsBold.vibrate);
  static const AppSymbol privacy = AppSymbol(PhosphorIconsBold.shieldCheck);
  static const AppSymbol license = AppSymbol(PhosphorIconsBold.scroll);
  static const AppSymbol email = AppSymbol(PhosphorIconsBold.envelope);
  static const AppSymbol removeAds = AppSymbol(PhosphorIconsBold.prohibit);
  static const AppSymbol restore = AppSymbol(PhosphorIconsBold.arrowsClockwise);
  static const AppSymbol locked = AppSymbol(PhosphorIconsBold.lockKey);

  static const AppSymbol download = AppSymbol(PhosphorIconsBold.downloadSimple);
  static const AppSymbol delete = AppSymbol(PhosphorIconsBold.trash);
  static const AppSymbol retry =
      AppSymbol(PhosphorIconsBold.arrowCounterClockwise);
  static const AppSymbol warning = AppSymbol(PhosphorIconsBold.warning);
  static const AppSymbol info = AppSymbol(PhosphorIconsBold.info);
  static const AppSymbol offline = AppSymbol(PhosphorIconsBold.wifiSlash);
  static const AppSymbol wifi = AppSymbol(PhosphorIconsBold.wifiHigh);
}
