import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tehillah/core/ads/consent_tracker.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/core/verses/verse_repository.dart';
import 'package:tehillah/platform/ad_service.dart';
import 'package:tehillah/platform/audio_service.dart';
import 'package:tehillah/platform/billing_service.dart';
import 'package:tehillah/platform/connectivity_service.dart';
import 'package:tehillah/platform/consent_service.dart';
import 'package:tehillah/platform/flags_service.dart';
import 'package:tehillah/platform/haptics_service.dart';
import 'package:tehillah/platform/log_service.dart';
import 'package:tehillah/platform/notification_service.dart';
import 'package:tehillah/platform/pack_service.dart';
import 'package:tehillah/platform/rating_service.dart';
import 'package:tehillah/platform/share_service.dart';
import 'package:tehillah/platform/storage_service.dart';
import 'package:tehillah/platform/url_service.dart';
import 'package:tehillah/providers/achievements_provider.dart';
import 'package:tehillah/providers/ad_provider.dart';
import 'package:tehillah/providers/app_scope.dart';
import 'package:tehillah/providers/bookmark_provider.dart';
import 'package:tehillah/providers/consent_provider.dart';
import 'package:tehillah/providers/daily_provider.dart';
import 'package:tehillah/providers/entitlement_provider.dart';
import 'package:tehillah/providers/feedback_provider.dart';
import 'package:tehillah/providers/flags_provider.dart';
import 'package:tehillah/providers/loadout_provider.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/match_provider.dart';
import 'package:tehillah/providers/pack_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/reader_provider.dart';
import 'package:tehillah/providers/settings_provider.dart';
import 'package:tehillah/providers/theme_provider.dart';
import 'package:tehillah/providers/verse_provider.dart';
import 'package:tehillah/utils/global_error_handler.dart';

/// The services plus the things only `main` needs to hold on to.
final class Boot {
  const Boot({required this.services, required this.errors});

  final AppServices services;
  final GlobalErrorHandler errors;
}

/// The device's preferred language codes, most preferred first.
List<String> deviceLanguages() => <String>[
      for (final ui.Locale l in ui.PlatformDispatcher.instance.locales) l.languageCode,
    ];

/// Builds every service and provider in dependency order and loads what has
/// to be ready before the first frame (settings and progress). Nothing here
/// can stop the app opening: a failed read leaves defaults and a log line.
Future<Boot> boot() async {
  final Directory support = await getApplicationSupportDirectory();
  final LogService log = LogService(Directory('${support.path}/tehillah/logs'));

  final GlobalErrorHandler errors = GlobalErrorHandler(
    sink: (AppError error, StackTrace? stack) {
      log.log(LogLevel.error, 'app', '${error.code}: ${error.message}${stack == null ? '' : '\n$stack'}');
    },
  );

  final StorageService storage = await StorageService.open(log: log);

  final SettingsProvider settings = SettingsProvider(storage, log);
  await settings.load();
  final ThemeProvider theme = ThemeProvider(settings);
  final LocaleProvider locale = LocaleProvider(settings);

  final ProgressProvider progress = ProgressProvider(ProgressStore(storage, log), log);
  await progress.load();
  progress.beginSession();

  final HapticsService haptics = HapticsService();
  final AudioService audio = AudioService(log: log);
  final ConnectivityService connectivity = ConnectivityService();
  final NotificationService notifications = NotificationService(log: log);
  final ShareService share = ShareService(log: log);
  final UrlService url = UrlService(log: log);
  final RatingService rating = RatingService(log: log);

  final FlagsProvider flags = FlagsProvider(FlagsService(storage, log: log), log);
  final EntitlementProvider entitlement = EntitlementProvider(BillingService(storage, log: log), log);

  final ConsentProvider consent = ConsentProvider(
    ConsentTracker(ConsentService(log: log), storage, log),
  );
  final AdService adService = AdService(
    mayRequest: () => consent.value.canRequestAds,
    log: log,
  );
  final AdProvider ads = AdProvider(
    ads: adService,
    consent: consent,
    entitlement: entitlement,
    flags: flags,
    progress: progress,
    log: log,
  );

  final PackService packService = PackService(Directory('${storage.root.path}/packs'), log: log);
  final PackProvider packs = PackProvider(
    packs: packService,
    connectivity: connectivity,
    flags: flags,
    log: log,
  );
  final ReaderProvider reader = ReaderProvider(
    packs: packService,
    locale: locale,
    settings: settings,
    packState: packs,
    storage: storage,
    log: log,
  );

  final VerseRepository verseRepository = await _loadVerses(log);
  final VerseProvider verses = VerseProvider(verseRepository, locale, deviceLanguages);

  final DailyProvider daily = DailyProvider(
    progress: progress,
    settings: settings,
    notifications: notifications,
    log: log,
  );

  final AppServices services = AppServices(
    log: log,
    storage: storage,
    share: share,
    url: url,
    haptics: haptics,
    audio: audio,
    connectivity: connectivity,
    notifications: notifications,
    verseRepository: verseRepository,
    settings: settings,
    theme: theme,
    locale: locale,
    progress: progress,
    loadout: LoadoutProvider(progress),
    entitlement: entitlement,
    flags: flags,
    consent: consent,
    ads: ads,
    daily: daily,
    verses: verses,
    achievements: AchievementsProvider(progress),
    match: MatchProvider(log),
    packs: packs,
    reader: reader,
    bookmarks: BookmarkProvider(progress),
    feedback: FeedbackProvider(),
    rating: rating,
    bannerBuilder: (BuildContext context, int widthDp) =>
        adService.buildBanner() ?? const SizedBox.shrink(),
  );

  _applySettings(services);
  return Boot(services: services, errors: errors);
}

Future<VerseRepository> _loadVerses(LogService log) async {
  final String curated = await rootBundle.loadString('assets/verses/curated.json');
  final Map<String, String> text = <String, String>{
    for (final String code in LanguageCodes.all)
      code: await rootBundle.loadString('assets/verses/$code.json'),
  };
  try {
    return VerseRepository.parse(curatedJson: curated, textJsonByLanguage: text);
  } on Object catch (error) {
    log.log(LogLevel.error, 'boot', 'verse data failed to parse: $error');
    rethrow;
  }
}

/// Keeps the haptics and audio adapters in step with the settings, now and
/// whenever they change.
void _applySettings(AppServices s) {
  void apply() {
    final SettingsModel m = s.settings.value;
    s.haptics.setEnabled(enabled: m.hapticsOn);
    s.audio.setSoundEnabled(enabled: m.soundOn);
    s.audio.setMusicEnabled(enabled: m.musicOn);
  }

  apply();
  s.settings.addListener(apply);
}

/// Work that must not hold up the first frame: remote flags, the store's
/// purchase list, consent for people who already finished onboarding, and the
/// reminder schedule. Every call is safe to run unawaited.
void startBackgroundWork(AppServices s) {
  unawaited(s.flags.refresh());
  unawaited(s.entitlement.start());
  unawaited(s.audio.preload());
  if (s.settings.value.onboardingDone) {
    unawaited(s.consent.refreshOnLaunch());
  }
}
