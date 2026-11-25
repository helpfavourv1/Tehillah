/// Fixed values the owner supplied. Nothing here is secret.
abstract final class AppConfig {
  static const String applicationId = 'com.zdmgold.tehillah';
  static const String siteOrigin = 'https://tehillah.helpfavourv1.workers.dev';
  static const String manifestUrl = '$siteOrigin/scripture/manifest.json';
  static const String flagsUrl = '$siteOrigin/flags.json';
  static const String privacyUrl = '$siteOrigin/privacy';
  static const String supportUrl = '$siteOrigin/support';
  static const String supportEmail = 'stmakarios@gmail.com';

  /// The build number of this version: the number after the plus sign in
  /// `version:` in pubspec.yaml. A test keeps the two equal.
  static const int buildNumber = 1;

  /// Where an update to the Android app is offered.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$applicationId';

  /// The one purchase: removes the banner and interstitials.
  static const String removeAdsProductId = 'com.zdmgold.tehillah.removeads';
}
