import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/storage/progress_codec.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/loadout_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';

import '../fakes/fake_storage.dart';
import '../support/match_helpers.dart';

MatchSummary _win(int round, {int stage = 1}) {
  final MatchConfig config = ModeRules.journey(
    stage: StageCatalog.stages[stage - 1],
    round: round,
    loadout: Loadout.starter,
    seed: round,
  );
  return MatchSummary(
    config: config,
    finalState: stateOf(playerScore: 5, opponentScore: 0, playerKicks: 5, opponentKicks: 5),
    history: <KickRecord>[
      for (int i = 0; i < 5; i++) kickRecord(MatchSide.player, i + 1, goal: true),
      for (int i = 0; i < 5; i++) kickRecord(MatchSide.opponent, i + 1, goal: false),
    ],
  );
}

void main() {
  late FakeStorage storage;
  late FakeLog log;
  late ProgressProvider progress;

  ProgressProvider make() => ProgressProvider(ProgressStore(storage, log), log);

  setUp(() async {
    storage = FakeStorage();
    log = FakeLog();
    progress = make();
    await progress.load();
  });

  tearDown(() => progress.dispose());

  group('ProgressProvider loading', () {
    test('a new player starts fresh with no notice', () {
      expect(progress.value.loaded, isTrue);
      expect(progress.value.loadStatus, ProgressLoadStatus.fresh);
      expect(progress.value.needsNotice, isFalse);
      expect(progress.value.savingBroken, isFalse);
    });

    test('a damaged file and no backup starts clean with a notice that can be dismissed', () async {
      storage.files['progress.json'] = 'garbage';
      final ProgressProvider p = make();
      await p.load();
      expect(p.value.loadStatus, ProgressLoadStatus.startedClean);
      expect(p.value.needsNotice, isTrue);
      p.dismissNotice();
      expect(p.value.needsNotice, isFalse);
      p.dispose();
    });

    test('a damaged file with a good backup recovers from the backup', () async {
      progress.applyMatch(_win(1));
      await progress.flush();
      progress.update((Progress p) => p.copyWith(sessions: 5));
      await progress.flush();
      storage.files['progress.json'] = 'garbage';
      final ProgressProvider p = make();
      await p.load();
      expect(p.value.loadStatus, ProgressLoadStatus.recoveredFromBackup);
      expect(p.value.needsNotice, isTrue);
      p.dispose();
    });

    test('a file from a newer app is read-only and shows the warning', () async {
      final Progress future = Progress(schemaVersion: Progress.currentSchemaVersion + 1);
      storage.files['progress.json'] = ProgressCodec().encode(future);
      final ProgressProvider p = make();
      await p.load();
      expect(p.value.loadStatus, ProgressLoadStatus.newerVersionReadOnly);
      expect(p.value.readOnly, isTrue);
      expect(p.value.savingBroken, isTrue);
      final String before = storage.files['progress.json']!;
      p.update((Progress x) => x.copyWith(sessions: 9));
      await p.flush();
      expect(storage.files['progress.json'], before);
      p.dispose();
    });

    test('an unreadable store blocks writes', () async {
      storage.failReads = true;
      final ProgressProvider p = make();
      await p.load();
      expect(p.value.loadStatus, ProgressLoadStatus.storageUnavailable);
      expect(p.value.readOnly, isTrue);
      storage.failReads = false;
      p.update((Progress x) => x.copyWith(sessions: 1));
      await p.flush();
      expect(storage.files, isEmpty);
      p.dispose();
    });

    test('an update before load is ignored', () {
      final ProgressProvider p = make();
      expect(p.update((Progress x) => x.copyWith(sessions: 1)), isFalse);
      expect(p.progress.sessions, 0);
      p.dispose();
    });
  });

  group('ProgressProvider saving', () {
    test('changes are written and read back by a new provider', () async {
      progress.update((Progress p) => p.copyWith(sessions: 3));
      await progress.flush();
      final ProgressProvider again = make();
      await again.load();
      expect(again.progress.sessions, 3);
      again.dispose();
    });

    test('a failed write keeps the change, shows the warning, and the next write clears it', () async {
      storage.failWrites = true;
      progress.update((Progress p) => p.copyWith(sessions: 2));
      await progress.flush();
      expect(progress.progress.sessions, 2);
      expect(progress.value.saveFailed, isTrue);
      expect(progress.value.savingBroken, isTrue);
      storage.failWrites = false;
      await progress.retrySave();
      expect(progress.value.saveFailed, isFalse);
      final ProgressProvider again = make();
      await again.load();
      expect(again.progress.sessions, 2);
      again.dispose();
    });

    test('quick changes end with the newest one saved', () async {
      progress.update((Progress p) => p.copyWith(sessions: 1));
      progress.update((Progress p) => p.copyWith(sessions: 2));
      progress.update((Progress p) => p.copyWith(sessions: 3));
      await progress.flush();
      final ProgressProvider again = make();
      await again.load();
      expect(again.progress.sessions, 3);
      again.dispose();
    });

    test('beginSession counts one launch once', () async {
      progress.beginSession();
      progress.beginSession();
      expect(progress.progress.sessions, 1);
      await progress.flush();
    });

    test('the rating prompt is remembered', () async {
      progress.markRatingPromptShown();
      expect(progress.progress.ratingPromptShown, isTrue);
      await progress.flush();
    });
  });

  group('ProgressProvider results', () {
    test('a Journey win records stars and the match statistics', () async {
      final MatchRecorded r = progress.applyMatch(_win(1));
      expect(r.stars, 3);
      expect(progress.progress.stats.matchesWon, 1);
      expect(progress.progress.starsFor(StageCatalog.stages[0].opponents[0].id), 3);
      expect(r.newLamps, isEmpty);
      await progress.flush();
    });

    test('winning all four rounds earns the lamp and opens unlocks', () async {
      late MatchRecorded last;
      for (int round = 1; round <= 4; round++) {
        last = progress.applyMatch(_win(round));
      }
      expect(last.newLamps, <int>{1});
      expect(last.newUnlocks, contains('ball:joy'));
      expect(progress.newUnlocks, contains('ball:joy'));
      expect(progress.newUnlocks, isNot(contains('ball:love')));
      progress.markUnlocksAnnounced();
      expect(progress.newUnlocks, isEmpty);
      await progress.flush();
    });

    test('a new achievement is reported once and saved', () async {
      MatchRecorded? reached;
      for (int i = 0; i < 12 && reached == null; i++) {
        final MatchRecorded r = progress.applyMatch(_win(1));
        if (r.newAchievements.isNotEmpty) {
          reached = r;
        }
      }
      expect(reached, isNotNull);
      expect(progress.progress.achievements, containsAll(reached!.newAchievements));
      final MatchRecorded next = progress.applyMatch(_win(1));
      expect(next.newAchievements.toSet().intersection(reached.newAchievements.toSet()), isEmpty);
      await progress.flush();
    });

    test('Daily Bread counts only the first result of a day', () async {
      final DailyChallenge challenge = DailyChallenge(
        dateKey: '2026-11-22',
        seed: 7,
        opponent: StageCatalog.stages[0].opponents[0],
        difficulty: 0.3,
        wind: 0,
      );
      progress.applyDaily(challenge, won: true, goals: 4);
      progress.applyDaily(challenge, won: false, goals: 0);
      expect(progress.progress.dailyHistory.length, 1);
      expect(progress.progress.dailyHistory['2026-11-22']!.won, isTrue);
      await progress.flush();
    });

    test('Seven Days starts the week on the first result', () async {
      progress.applySevenDays(todayKey: '2026-11-22', won: true);
      expect(progress.progress.sevenDaysStart, '2026-11-22');
      expect(progress.progress.sevenDaysDone, <int>{1});
      await progress.flush();
    });
  });

  group('LoadoutProvider', () {
    test('a new player has only the starter ball and no gear', () {
      final LoadoutProvider loadout = LoadoutProvider(progress);
      expect(loadout.value.selected, Loadout.starter);
      expect(loadout.value.unlockedBalls, <String>{'love'});
      expect(loadout.value.unlockedGear, isEmpty);
      loadout.dispose();
    });

    test('a locked ball cannot be chosen', () {
      final LoadoutProvider loadout = LoadoutProvider(progress);
      expect(loadout.selectBall('joy'), isFalse);
      expect(loadout.selectGear('beltOfTruth'), isFalse);
      expect(loadout.value.selected, Loadout.starter);
      loadout.dispose();
    });

    test('earning a lamp unlocks a ball that can then be chosen and is saved', () async {
      final LoadoutProvider loadout = LoadoutProvider(progress);
      for (int round = 1; round <= 4; round++) {
        progress.applyMatch(_win(round));
      }
      expect(loadout.value.ballUnlocked('joy'), isTrue);
      expect(loadout.selectBall('joy'), isTrue);
      expect(loadout.value.selected.ballId, 'joy');
      await progress.flush();
      final ProgressProvider again = make();
      await again.load();
      expect(again.progress.loadout.ballId, 'joy');
      again.dispose();
      loadout.dispose();
    });

    test('a saved choice that is not unlocked is replaced by the starter', () {
      progress.update((Progress p) => p.copyWith(loadout: const Loadout(ballId: 'joy', gearId: 'nope')));
      final LoadoutProvider loadout = LoadoutProvider(progress);
      expect(loadout.value.selected, Loadout.starter);
      loadout.dispose();
    });

    test('clearing gear with null is allowed', () {
      final LoadoutProvider loadout = LoadoutProvider(progress);
      expect(loadout.selectGear(null), isTrue);
      expect(loadout.value.selected.gearId, isNull);
      loadout.dispose();
    });
  });
}
