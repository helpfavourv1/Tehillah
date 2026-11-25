import 'dart:convert';

import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/models/bookmark.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/progress_stats.dart';

/// The saved career, kept in one versioned JSON file. Everything is local and
/// stays on the device. Equality compares the saved form, which is canonical
/// (sets and maps are written in sorted order).
final class Progress {
  Progress({
    this.schemaVersion = currentSchemaVersion,
    Map<String, int> matchStars = const <String, int>{},
    Set<int> lamps = const <int>{},
    Set<String> announcedUnlocks = const <String>{},
    Set<String> achievements = const <String>{},
    Map<String, DailyRecord> dailyHistory = const <String, DailyRecord>{},
    List<Bookmark> bookmarks = const <Bookmark>[],
    List<Highlight> highlights = const <Highlight>[],
    this.loadout = Loadout.starter,
    this.stats = const ProgressStats(),
    this.sessions = 0,
    this.ratingPromptShown = false,
    this.sevenDaysStart,
    Set<int> sevenDaysDone = const <int>{},
    Set<String> rescuedDays = const <String>{},
    this.jerichoCleared = 0,
    this.jerichoCompletions = 0,
    this.slingBest = 0,
    this.slingPlays = 0,
  })  : matchStars = Map<String, int>.unmodifiable(matchStars),
        lamps = Set<int>.unmodifiable(lamps),
        announcedUnlocks = Set<String>.unmodifiable(announcedUnlocks),
        achievements = Set<String>.unmodifiable(achievements),
        dailyHistory = Map<String, DailyRecord>.unmodifiable(dailyHistory),
        bookmarks = List<Bookmark>.unmodifiable(bookmarks),
        highlights = List<Highlight>.unmodifiable(highlights),
        sevenDaysDone = Set<int>.unmodifiable(sevenDaysDone),
        rescuedDays = Set<String>.unmodifiable(rescuedDays);

  /// The version this build writes. A file with a higher number is read-only.
  static const int currentSchemaVersion = 2;

  /// A brand-new career.
  factory Progress.empty() => Progress();

  factory Progress.fromJson(Map<String, Object?> json) {
    List<Object?> list(String key) =>
        json.containsKey(key) ? jsonList(json[key], key) : const <Object?>[];

    final Map<String, int> stars = <String, int>{};
    if (json.containsKey('matchStars')) {
      for (final MapEntry<String, Object?> e
          in jsonMap(json['matchStars'], 'matchStars').entries) {
        final Object? v = e.value;
        if (v is! int || v < 0 || v > 3) {
          throw FormatException('stars for "${e.key}" must be 0 to 3');
        }
        stars[e.key] = v;
      }
    }
    final Map<String, DailyRecord> daily = <String, DailyRecord>{};
    if (json.containsKey('dailyHistory')) {
      for (final MapEntry<String, Object?> e
          in jsonMap(json['dailyHistory'], 'dailyHistory').entries) {
        final DailyRecord r = DailyRecord.fromJson(jsonMap(e.value, 'daily record'));
        if (r.dateKey != e.key) {
          throw const FormatException('daily record key does not match its date');
        }
        daily[e.key] = r;
      }
    }
    final Object? start = json['sevenDaysStart'];
    if (start != null && start is! String) {
      throw const FormatException('"sevenDaysStart" must be text or null');
    }
    return Progress(
      schemaVersion: readInt(json, 'schemaVersion', min: 1),
      matchStars: stars,
      lamps: <int>{
        for (final Object? v in list('lamps'))
          if (v is int && v >= 1) v else throw const FormatException('bad lamp'),
      },
      announcedUnlocks: <String>{
        for (final Object? v in list('announcedUnlocks'))
          if (v is String && v.isNotEmpty) v else throw const FormatException('bad unlock'),
      },
      achievements: <String>{
        for (final Object? v in list('achievements'))
          if (v is String && v.isNotEmpty) v else throw const FormatException('bad achievement'),
      },
      dailyHistory: daily,
      bookmarks: <Bookmark>[
        for (final Object? v in list('bookmarks')) Bookmark.fromJson(jsonMap(v, 'bookmark')),
      ],
      highlights: <Highlight>[
        for (final Object? v in list('highlights')) Highlight.fromJson(jsonMap(v, 'highlight')),
      ],
      loadout: json.containsKey('loadout')
          ? Loadout.fromJson(jsonMap(json['loadout'], 'loadout'))
          : Loadout.starter,
      stats: json.containsKey('stats')
          ? ProgressStats.fromJson(jsonMap(json['stats'], 'stats'))
          : const ProgressStats(),
      sessions: json.containsKey('sessions') ? readInt(json, 'sessions', min: 0) : 0,
      ratingPromptShown:
          json.containsKey('ratingPromptShown') ? readBool(json, 'ratingPromptShown') : false,
      sevenDaysStart: start as String?,
      sevenDaysDone: <int>{
        for (final Object? v in list('sevenDaysDone'))
          if (v is int && v >= 1 && v <= 7) v else throw const FormatException('bad day'),
      },
      rescuedDays: <String>{
        for (final Object? v in list('rescuedDays'))
          if (v is String) DateKey.of(DateKey.parse(v)) else throw const FormatException('bad rescued day'),
      },
      jerichoCleared: json.containsKey('jerichoCleared')
          ? readInt(json, 'jerichoCleared', min: 0, max: 7)
          : 0,
      jerichoCompletions: json.containsKey('jerichoCompletions')
          ? readInt(json, 'jerichoCompletions', min: 0)
          : 0,
      slingBest: json.containsKey('slingBest') ? readInt(json, 'slingBest', min: 0, max: 3) : 0,
      slingPlays: json.containsKey('slingPlays') ? readInt(json, 'slingPlays', min: 0) : 0,
    );
  }

  final int schemaVersion;

  /// Best stars (0 to 3) per beaten opponent id, for example `s03r2`.
  final Map<String, int> matchStars;

  /// Stage ids that have earned their lamp.
  final Set<int> lamps;

  /// Unlocks (balls, gear, modes) the player has already been told about.
  final Set<String> announcedUnlocks;

  /// Ids of unlocked fruit achievements.
  final Set<String> achievements;

  /// Daily Bread results by `YYYY-MM-DD`.
  final Map<String, DailyRecord> dailyHistory;

  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;

  /// The ball and gear the player last chose.
  final Loadout loadout;
  final ProgressStats stats;

  /// How many times the app has been opened. Interstitials never show in the
  /// first session.
  final int sessions;

  /// The rating prompt is shown once, after a stage win.
  final bool ratingPromptShown;

  /// `YYYY-MM-DD` the current Seven Days run started, or null.
  final String? sevenDaysStart;

  /// Days (1 to 7) of the current Seven Days run that are done.
  final Set<int> sevenDaysDone;

  /// Days (`YYYY-MM-DD`) a rewarded ad restored to a Daily Bread streak. They
  /// count as played for the streak but are not results.
  final Set<String> rescuedDays;

  /// Rounds (0 to 7) of the current Jericho run already won.
  final int jerichoCleared;

  /// How many times the walls of Jericho have come down.
  final int jerichoCompletions;

  /// The best Sling and Stone stars (0 to 3).
  final int slingBest;

  /// How many Sling and Stone rounds have been played.
  final int slingPlays;

  int starsFor(String opponentId) => matchStars[opponentId] ?? 0;

  int get totalStars => matchStars.values.fold(0, (int a, int b) => a + b);

  Progress copyWith({
    int? schemaVersion,
    Map<String, int>? matchStars,
    Set<int>? lamps,
    Set<String>? announcedUnlocks,
    Set<String>? achievements,
    Map<String, DailyRecord>? dailyHistory,
    List<Bookmark>? bookmarks,
    List<Highlight>? highlights,
    Loadout? loadout,
    ProgressStats? stats,
    int? sessions,
    bool? ratingPromptShown,
    String? sevenDaysStart,
    bool clearSevenDays = false,
    Set<int>? sevenDaysDone,
    Set<String>? rescuedDays,
    int? jerichoCleared,
    int? jerichoCompletions,
    int? slingBest,
    int? slingPlays,
  }) {
    return Progress(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      matchStars: matchStars ?? this.matchStars,
      lamps: lamps ?? this.lamps,
      announcedUnlocks: announcedUnlocks ?? this.announcedUnlocks,
      achievements: achievements ?? this.achievements,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      loadout: loadout ?? this.loadout,
      stats: stats ?? this.stats,
      sessions: sessions ?? this.sessions,
      ratingPromptShown: ratingPromptShown ?? this.ratingPromptShown,
      sevenDaysStart: clearSevenDays ? null : (sevenDaysStart ?? this.sevenDaysStart),
      sevenDaysDone: clearSevenDays ? const <int>{} : (sevenDaysDone ?? this.sevenDaysDone),
      rescuedDays: rescuedDays ?? this.rescuedDays,
      jerichoCleared: jerichoCleared ?? this.jerichoCleared,
      jerichoCompletions: jerichoCompletions ?? this.jerichoCompletions,
      slingBest: slingBest ?? this.slingBest,
      slingPlays: slingPlays ?? this.slingPlays,
    );
  }

  Map<String, Object?> toJson() {
    final List<String> starKeys = matchStars.keys.toList()..sort();
    final List<String> dayKeys = dailyHistory.keys.toList()..sort();
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'matchStars': <String, Object?>{for (final String k in starKeys) k: matchStars[k]},
      'lamps': lamps.toList()..sort(),
      'announcedUnlocks': announcedUnlocks.toList()..sort(),
      'achievements': achievements.toList()..sort(),
      'dailyHistory': <String, Object?>{
        for (final String k in dayKeys) k: dailyHistory[k]!.toJson(),
      },
      'bookmarks': <Object?>[for (final Bookmark b in bookmarks) b.toJson()],
      'highlights': <Object?>[for (final Highlight h in highlights) h.toJson()],
      'loadout': loadout.toJson(),
      'stats': stats.toJson(),
      'sessions': sessions,
      'ratingPromptShown': ratingPromptShown,
      'sevenDaysStart': sevenDaysStart,
      'sevenDaysDone': sevenDaysDone.toList()..sort(),
      'rescuedDays': rescuedDays.toList()..sort(),
      'jerichoCleared': jerichoCleared,
      'jerichoCompletions': jerichoCompletions,
      'slingBest': slingBest,
      'slingPlays': slingPlays,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Progress && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}
