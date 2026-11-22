import 'package:flutter/widgets.dart';
import 'package:tehillah/core/ports/audio_port.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';
import 'package:tehillah/core/ports/haptics_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/notification_port.dart';
import 'package:tehillah/core/ports/share_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';
import 'package:tehillah/core/ports/url_port.dart';
import 'package:tehillah/core/verses/verse_repository.dart';
import 'package:tehillah/providers/achievements_provider.dart';
import 'package:tehillah/providers/ad_provider.dart';
import 'package:tehillah/providers/bookmark_provider.dart';
import 'package:tehillah/providers/consent_provider.dart';
import 'package:tehillah/providers/daily_provider.dart';
import 'package:tehillah/providers/entitlement_provider.dart';
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

/// Every provider and service the screens use, built once in `main`.
final class AppServices {
  const AppServices({
    required this.log,
    required this.storage,
    required this.share,
    required this.url,
    required this.haptics,
    required this.audio,
    required this.connectivity,
    required this.notifications,
    required this.verseRepository,
    required this.settings,
    required this.theme,
    required this.locale,
    required this.progress,
    required this.loadout,
    required this.entitlement,
    required this.flags,
    required this.consent,
    required this.ads,
    required this.daily,
    required this.verses,
    required this.achievements,
    required this.match,
    required this.packs,
    required this.reader,
    required this.bookmarks,
  });

  final LogPort log;
  final StoragePort storage;
  final SharePort share;
  final UrlPort url;
  final HapticsPort haptics;
  final AudioPort audio;
  final ConnectivityPort connectivity;
  final NotificationPort notifications;
  final VerseRepository verseRepository;

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final ProgressProvider progress;
  final LoadoutProvider loadout;
  final EntitlementProvider entitlement;
  final FlagsProvider flags;
  final ConsentProvider consent;
  final AdProvider ads;
  final DailyProvider daily;
  final VerseProvider verses;
  final AchievementsProvider achievements;
  final MatchProvider match;
  final PackProvider packs;
  final ReaderProvider reader;
  final BookmarkProvider bookmarks;
}

/// Hands [AppServices] down the widget tree, so there are no global
/// singletons and tests can supply fakes.
final class AppScope extends InheritedWidget {
  const AppScope({required this.services, required super.child, super.key});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.services;
  }

  static AppServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => !identical(oldWidget.services, services);
}
