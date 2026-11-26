import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/achievement_def.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/game/hud/match_hud.dart';
import 'package:tehillah/l10n/gen/app_localizations.dart';
import 'package:tehillah/screens/achievements_screen.dart';
import 'package:tehillah/screens/app_language_sheet.dart';
import 'package:tehillah/screens/bookmarks_screen.dart';
import 'package:tehillah/screens/daily_bread_screen.dart';
import 'package:tehillah/screens/download_prompt_sheet.dart';
import 'package:tehillah/screens/home_screen.dart';
import 'package:tehillah/screens/journey_map_screen.dart';
import 'package:tehillah/screens/licenses_screen.dart';
import 'package:tehillah/screens/loadout_screen.dart';
import 'package:tehillah/screens/match_screen.dart';
import 'package:tehillah/screens/modes_screen.dart';
import 'package:tehillah/screens/onboarding_screen.dart';
import 'package:tehillah/screens/reader_language_sheet.dart';
import 'package:tehillah/screens/reader_picker_sheet.dart';
import 'package:tehillah/screens/reader_screen.dart';
import 'package:tehillah/screens/reader_search_screen.dart';
import 'package:tehillah/screens/reader_settings_sheet.dart';
import 'package:tehillah/screens/reader_theme_sheet.dart';
import 'package:tehillah/screens/reminder_time_sheet.dart';
import 'package:tehillah/screens/result_screen.dart';
import 'package:tehillah/screens/settings_screen.dart';
import 'package:tehillah/screens/sling_screen.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/screens/upgrade_screen.dart';
import 'package:tehillah/screens/verse_actions_sheet.dart';
import 'package:tehillah/screens/verse_library_screen.dart';
import 'package:tehillah/utils/formatters.dart';

/// Turns the generated localizations class into the labels object each screen
/// takes. This is the only place screen text is assembled, so the screens hold
/// no literal text and the router stays short.
final class Labels {
  Labels(this.l, Locale locale) : fmt = Formatters(locale);

  final AppLocalizations l;
  final Formatters fmt;

  // ---- catalog lookups -----------------------------------------------------

  String stageName(String nameKey) => switch (nameKey) {
        'stageGarden' => l.stageGarden,
        'stageArarat' => l.stageArarat,
        'stageRedSeaShore' => l.stageRedSeaShore,
        'stageSinai' => l.stageSinai,
        'stageJerichoPlain' => l.stageJerichoPlain,
        'stageValleyOfElah' => l.stageValleyOfElah,
        'stageBabylonGates' => l.stageBabylonGates,
        'stageGalilee' => l.stageGalilee,
        'stageDamascusRoad' => l.stageDamascusRoad,
        'stageAntioch' => l.stageAntioch,
        'stagePatmosShore' => l.stagePatmosShore,
        'stageNewJerusalem' => l.stageNewJerusalem,
        _ => nameKey,
      };

  String ballName(BallDef b) => switch (b.fruitKey) {
        'fruitLove' => l.fruitLove,
        'fruitJoy' => l.fruitJoy,
        'fruitPeace' => l.fruitPeace,
        'fruitPatience' => l.fruitPatience,
        'fruitKindness' => l.fruitKindness,
        'fruitGoodness' => l.fruitGoodness,
        'fruitFaithfulness' => l.fruitFaithfulness,
        'fruitGentleness' => l.fruitGentleness,
        'fruitSelfControl' => l.fruitSelfControl,
        _ => b.id,
      };

  String ballBenefit(BallDef b) => switch (b.fruitKey) {
        'fruitLove' => l.fruitLoveBenefit,
        'fruitJoy' => l.fruitJoyBenefit,
        'fruitPeace' => l.fruitPeaceBenefit,
        'fruitPatience' => l.fruitPatienceBenefit,
        'fruitKindness' => l.fruitKindnessBenefit,
        'fruitGoodness' => l.fruitGoodnessBenefit,
        'fruitFaithfulness' => l.fruitFaithfulnessBenefit,
        'fruitGentleness' => l.fruitGentlenessBenefit,
        'fruitSelfControl' => l.fruitSelfControlBenefit,
        _ => '',
      };

  String ballTradeoff(BallDef b) => switch (b.fruitKey) {
        'fruitLove' => l.fruitLoveTradeoff,
        'fruitJoy' => l.fruitJoyTradeoff,
        'fruitPeace' => l.fruitPeaceTradeoff,
        'fruitPatience' => l.fruitPatienceTradeoff,
        'fruitKindness' => l.fruitKindnessTradeoff,
        'fruitGoodness' => l.fruitGoodnessTradeoff,
        'fruitFaithfulness' => l.fruitFaithfulnessTradeoff,
        'fruitGentleness' => l.fruitGentlenessTradeoff,
        'fruitSelfControl' => l.fruitSelfControlTradeoff,
        _ => '',
      };

  String gearName(GearDef g) => switch (g.armorKey) {
        'armorBeltOfTruth' => l.armorBeltOfTruth,
        'armorShoesOfReadiness' => l.armorShoesOfReadiness,
        'armorShieldOfFaith' => l.armorShieldOfFaith,
        'armorBreastplateOfRighteousness' => l.armorBreastplateOfRighteousness,
        'armorHelmetOfSalvation' => l.armorHelmetOfSalvation,
        'armorSwordOfTheSpirit' => l.armorSwordOfTheSpirit,
        _ => g.id,
      };

  String gearBenefit(GearDef g) => switch (g.armorKey) {
        'armorBeltOfTruth' => l.armorBeltOfTruthBenefit,
        'armorShoesOfReadiness' => l.armorShoesOfReadinessBenefit,
        'armorShieldOfFaith' => l.armorShieldOfFaithBenefit,
        'armorBreastplateOfRighteousness' => l.armorBreastplateOfRighteousnessBenefit,
        'armorHelmetOfSalvation' => l.armorHelmetOfSalvationBenefit,
        'armorSwordOfTheSpirit' => l.armorSwordOfTheSpiritBenefit,
        _ => '',
      };

  String gearTradeoff(GearDef g) => switch (g.armorKey) {
        'armorBeltOfTruth' => l.armorBeltOfTruthTradeoff,
        'armorShoesOfReadiness' => l.armorShoesOfReadinessTradeoff,
        'armorShieldOfFaith' => l.armorShieldOfFaithTradeoff,
        'armorBreastplateOfRighteousness' => l.armorBreastplateOfRighteousnessTradeoff,
        'armorHelmetOfSalvation' => l.armorHelmetOfSalvationTradeoff,
        'armorSwordOfTheSpirit' => l.armorSwordOfTheSpiritTradeoff,
        _ => '',
      };

  String achievementName(AchievementDef a) => switch (a.fruitKey) {
        'fruitLove' => l.achLove,
        'fruitJoy' => l.achJoy,
        'fruitPeace' => l.achPeace,
        'fruitPatience' => l.achPatience,
        'fruitKindness' => l.achKindness,
        'fruitGoodness' => l.achGoodness,
        'fruitFaithfulness' => l.achFaithfulness,
        'fruitGentleness' => l.achGentleness,
        'fruitSelfControl' => l.achSelfControl,
        _ => a.id,
      };

  String achievementDescription(AchievementDef a) => switch (a.fruitKey) {
        'fruitLove' => l.achLoveDescription,
        'fruitJoy' => l.achJoyDescription,
        'fruitPeace' => l.achPeaceDescription,
        'fruitPatience' => l.achPatienceDescription,
        'fruitKindness' => l.achKindnessDescription,
        'fruitGoodness' => l.achGoodnessDescription,
        'fruitFaithfulness' => l.achFaithfulnessDescription,
        'fruitGentleness' => l.achGentlenessDescription,
        'fruitSelfControl' => l.achSelfControlDescription,
        _ => '',
      };

  String modeName(MatchMode m) => switch (m) {
        MatchMode.journey => l.modeJourney,
        MatchMode.friendly => l.modeFriendly,
        MatchMode.watchman => l.modeWatchman,
        MatchMode.slingAndStone => l.modeSling,
        MatchMode.jericho => l.modeJericho,
        MatchMode.sevenDays => l.modeSevenDays,
        MatchMode.dailyBread => l.modeDaily,
      };

  String modeSubtitle(MatchMode m) => switch (m) {
        MatchMode.journey => l.modeJourneySubtitle,
        MatchMode.friendly => l.modeFriendlySubtitle,
        MatchMode.watchman => l.modeWatchmanSubtitle,
        MatchMode.slingAndStone => l.modeSlingSubtitle,
        MatchMode.jericho => l.modeJerichoSubtitle,
        MatchMode.sevenDays => l.modeSevenDaysSubtitle,
        MatchMode.dailyBread => l.modeDailySubtitle,
      };

  /// The rules shown on a mode's intro screen.
  List<String> modeRules(MatchMode m) => <String>[
        switch (m) {
          MatchMode.journey => l.introStageRules,
          MatchMode.friendly => l.introRulesFriendly,
          MatchMode.watchman => l.introRulesWatchman,
          MatchMode.slingAndStone => l.introRulesSling,
          MatchMode.jericho => l.introRulesJericho,
          MatchMode.sevenDays => l.introRulesSevenDays,
          MatchMode.dailyBread => l.introRulesDaily,
        },
      ];

  String momentName(VerseMoment m) => switch (m) {
        VerseMoment.miss => l.momentMiss,
        VerseMoment.goal => l.momentGoal,
        VerseMoment.selah => l.momentSelah,
        VerseMoment.win => l.momentWin,
        VerseMoment.daily => l.momentDaily,
      };

  String toneName(MarkTone t) => switch (t) {
        MarkTone.sun => l.toneSun,
        MarkTone.leaf => l.toneLeaf,
        MarkTone.sky => l.toneSky,
        MarkTone.rose => l.toneRose,
      };

  String dayState(DayState s) => switch (s) {
        DayState.won => l.dayWon,
        DayState.played => l.dayPlayed,
        DayState.rescued => l.dayRescued,
        DayState.missed => l.dayMissed,
        DayState.today => l.dayToday,
      };

  /// The Bible book's name in the app language, by OSIS id.
  String bookName(String osisId) => switch (osisId) {
        'Gen' => l.bookGen,
        'Exod' => l.bookExod,
        'Lev' => l.bookLev,
        'Num' => l.bookNum,
        'Deut' => l.bookDeut,
        'Josh' => l.bookJosh,
        'Judg' => l.bookJudg,
        'Ruth' => l.bookRuth,
        '1Sam' => l.book1Sam,
        '2Sam' => l.book2Sam,
        '1Kgs' => l.book1Kgs,
        '2Kgs' => l.book2Kgs,
        '1Chr' => l.book1Chr,
        '2Chr' => l.book2Chr,
        'Ezra' => l.bookEzra,
        'Neh' => l.bookNeh,
        'Esth' => l.bookEsth,
        'Job' => l.bookJob,
        'Ps' => l.bookPs,
        'Prov' => l.bookProv,
        'Eccl' => l.bookEccl,
        'Song' => l.bookSong,
        'Isa' => l.bookIsa,
        'Jer' => l.bookJer,
        'Lam' => l.bookLam,
        'Ezek' => l.bookEzek,
        'Dan' => l.bookDan,
        'Hos' => l.bookHos,
        'Joel' => l.bookJoel,
        'Amos' => l.bookAmos,
        'Obad' => l.bookObad,
        'Jonah' => l.bookJonah,
        'Mic' => l.bookMic,
        'Nah' => l.bookNah,
        'Hab' => l.bookHab,
        'Zeph' => l.bookZeph,
        'Hag' => l.bookHag,
        'Zech' => l.bookZech,
        'Mal' => l.bookMal,
        'Matt' => l.bookMatt,
        'Mark' => l.bookMark,
        'Luke' => l.bookLuke,
        'John' => l.bookJohn,
        'Acts' => l.bookActs,
        'Rom' => l.bookRom,
        '1Cor' => l.book1Cor,
        '2Cor' => l.book2Cor,
        'Gal' => l.bookGal,
        'Eph' => l.bookEph,
        'Phil' => l.bookPhil,
        'Col' => l.bookCol,
        '1Thess' => l.book1Thess,
        '2Thess' => l.book2Thess,
        '1Tim' => l.book1Tim,
        '2Tim' => l.book2Tim,
        'Titus' => l.bookTitus,
        'Phlm' => l.bookPhlm,
        'Heb' => l.bookHeb,
        'Jas' => l.bookJas,
        '1Pet' => l.book1Pet,
        '2Pet' => l.book2Pet,
        '1John' => l.book1John,
        '2John' => l.book2John,
        '3John' => l.book3John,
        'Jude' => l.bookJude,
        'Rev' => l.bookRev,
        _ => osisId,
      };

  /// "Psalms 23:1", with the locale's digits.
  String verseReference(VerseRef ref) =>
      '${bookName(ref.book)} ${fmt.integer(ref.chapter)}:${fmt.integer(ref.verse)}';

  /// The words for a pack error code (see `PackProvider`).
  String packError(String code) => switch (code) {
        'pack.offline' => l.dlErrorOffline,
        'pack.needs_wifi' => l.dlErrorNeedsWifi,
        'pack.disabled' => l.dlErrorDisabled,
        'pack.not_listed' => l.dlErrorNotListed,
        _ => l.dlErrorUnexpected,
      };

  // ---- screen labels -------------------------------------------------------

  String get appName => l.appName;

  HomeLabels home() => HomeLabels(
        appName: l.appName,
        play: l.homePlay,
        playContinue: (String stage) => l.homePlayContinue(stage),
        journey: l.homeJourney,
        journeySummary: (int lamps, int total, int stars) =>
            l.homeJourneySummary(lamps, total, stars),
        modes: l.homeModes,
        modesSubtitle: l.homeModesSubtitle,
        daily: l.homeDaily,
        dailyOpen: l.homeDailyOpen,
        dailyDone: l.homeDailyDone,
        dailyStreak: (int days) => l.homeDailyStreak(days),
        verses: l.homeVerses,
        versesSubtitle: l.homeVersesSubtitle,
        achievements: l.homeAchievements,
        achievementsSummary: (int unlocked, int total) =>
            l.homeAchievementsSummary(unlocked, total),
        settings: l.homeSettings,
      );

  JourneyLabels journey() => JourneyLabels(
        title: l.journeyTitle,
        back: l.commonBack,
        summary: (int lamps, int total, int stars) => l.journeySummary(lamps, total, stars),
        roundsProgress: (int done, int total) => l.journeyRoundsProgress(done, total),
        cleared: l.journeyCleared,
        locked: l.journeyLocked,
        boss: l.journeyBoss,
        starsValue: (int stars, int max) => l.journeyStarsValue(stars, max),
      );

  ModesLabels modes() => ModesLabels(title: l.modesTitle, back: l.commonBack);

  AchievementsLabels achievements() => AchievementsLabels(
        title: l.achTitle,
        back: l.commonBack,
        summary: (int unlocked, int total) => l.achSummary(unlocked, total),
        unlocked: l.achUnlocked,
        progress: (int value, int threshold) => l.achProgress(value, threshold),
      );

  StageIntroLabels stageIntro() => StageIntroLabels(
        back: l.commonBack,
        start: l.commonStart,
        opponent: l.commonOpponent,
        rulesHeader: l.introRulesHeader,
        loadout: l.introLoadout,
        changeLoadout: l.introChangeLoadout,
        noGear: l.introNoGear,
        readChapter: l.commonReadChapter,
        share: l.commonShare,
      );

  LoadoutLabels loadout() => LoadoutLabels(
        title: l.loadoutTitle,
        back: l.commonBack,
        balls: l.loadoutBalls,
        gear: l.loadoutGear,
        noGear: l.loadoutNoGear,
        noGearDetail: l.loadoutNoGearDetail,
        selected: l.commonSelected,
        ballName: ballName,
        ballBenefit: ballBenefit,
        ballTradeoff: ballTradeoff,
        gearName: gearName,
        gearBenefit: gearBenefit,
        gearTradeoff: gearTradeoff,
        benefitLine: (String text) => l.loadoutBenefitLine(text),
        tradeoffLine: (String text) => l.loadoutTradeoffLine(text),
        lockedHint: (int lamps) => l.loadoutLockedHint(lamps),
      );

  MatchHudLabels hud() => MatchHudLabels(
        you: l.commonYou,
        opponent: l.commonOpponent,
        pause: l.commonPause,
        selah: l.hudSelah,
        selahWithCharges: (int charges) => l.hudSelahWithCharges(charges),
        nerve: l.hudNerve,
        nerveCalm: l.hudNerveCalm,
        nerveTense: l.hudNerveTense,
        nerveFull: l.hudNerveFull,
        suddenDeath: l.hudSuddenDeath,
        promptShot: l.hudPromptShot,
        promptDive: l.hudPromptDive,
        promptWatch: l.hudPromptWatch,
        kickScored: l.hudKickScored,
        kickMissed: l.hudKickMissed,
        kickPending: l.hudKickPending,
      );

  String zoneLabel(int column, int row) {
    final String across = switch (column) {
      0 => l.matchZoneLeft,
      1 => l.matchZoneCentre,
      _ => l.matchZoneRight,
    };
    return l.matchZoneLabel(across, row == 0 ? l.matchZoneLow : l.matchZoneHigh);
  }

  MatchScreenLabels match() => MatchScreenLabels(
        hud: hud(),
        zoneLabel: zoneLabel,
        flickHint: l.matchFlickHint,
        stopLabel: l.matchStop,
        pauseTitle: l.matchPauseTitle,
        resume: l.commonResume,
        leave: l.commonLeave,
      );

  ResultLabels result() => ResultLabels(
        win: l.resultWin,
        loss: l.resultLoss,
        you: l.commonYou,
        opponent: l.commonOpponent,
        scoreLine: (int you, int opponent) => l.resultScoreLine(you, opponent),
        starsLabel: (int stars, int total) => l.resultStars(stars, total),
        readChapter: l.commonReadChapter,
        share: l.commonShare,
      );

  SlingLabels sling() => SlingLabels(
        pause: l.commonPause,
        pauseTitle: l.matchPauseTitle,
        resume: l.commonResume,
        leave: l.commonLeave,
        stones: l.slingStones,
        targets: l.slingTargets,
        targetsValue: (int hit, int total) => l.slingTargetsValue(hit, total),
        aimHint: l.slingAimHint,
        aimArea: l.slingAimArea,
        roundDone: l.slingRoundDone,
        roundPerfect: l.slingRoundPerfect,
        starsLabel: (int stars, int total) => l.resultStars(stars, total),
        playAgain: l.slingPlayAgain,
        extraStones: l.slingExtraStones,
        summary: (int hit, int total) => l.slingSummary(hit, total),
      );

  DailyBreadLabels daily() => DailyBreadLabels(
        title: l.dailyTitle,
        back: l.commonBack,
        opponent: l.commonOpponent,
        recent: l.dailyRecent,
        start: l.dailyStart,
        startAgain: l.dailyStartAgain,
        firstCounts: l.dailyFirstCounts,
        resultWon: l.dailyResultWon,
        resultLost: l.dailyResultLost,
        goalsValue: (int goals) => l.dailyGoalsValue(goals),
        streak: l.dailyStreak,
        streakValue: (int days) => l.dailyStreakValue(days),
        dayState: dayState,
        reminder: l.dailyReminder,
        reminderDetail: l.dailyReminderDetail,
        rescue: l.dailyRescue,
        rescueDetail: l.dailyRescueDetail,
      );

  VerseLibraryLabels verseLibrary() => VerseLibraryLabels(
        title: l.vlibTitle,
        back: l.commonBack,
        filterLabel: l.vlibFilter,
        emptyTitle: l.vlibEmptyTitle,
        emptySubtitle: l.vlibEmptySubtitle,
        readChapter: l.commonReadChapter,
        share: l.commonShare,
      );

  ReaderLabels reader() => ReaderLabels(
        back: l.commonBack,
        chooseChapter: l.readerChooseChapter,
        search: l.readerSearch,
        theme: l.readerTheme,
        language: l.readerLanguage,
        settings: l.readerSettings,
        previous: l.readerPrevious,
        next: l.readerNext,
        loading: l.readerLoading,
        missingTitle: l.readerMissingTitle,
        missingSubtitle: l.readerMissingSubtitle,
        download: l.commonDownload,
        failedTitle: l.readerFailedTitle,
        failedSubtitle: l.readerFailedSubtitle,
        retry: l.commonRetry,
        verseNumber: fmt.integer,
        bookmarked: l.readerBookmarked,
        verseLabel: (int verse, String text) => l.readerVerseLabel(verse, text),
      );

  ReaderPickerLabels readerPicker() => ReaderPickerLabels(
        oldTestament: l.rpickOldTestament,
        newTestament: l.rpickNewTestament,
        books: l.rpickBooks,
        chapterLabel: (String book, int chapter) => l.rpickChapterLabel(book, chapter),
        number: fmt.integer,
      );

  ReaderSearchLabels readerSearch() => ReaderSearchLabels(
        title: l.rsearchTitle,
        back: l.commonBack,
        hint: l.rsearchHint,
        clear: l.rsearchClear,
        idleTitle: l.rsearchIdleTitle,
        idleSubtitle: l.rsearchIdleSubtitle,
        noResultsTitle: l.rsearchNoResultsTitle,
        noResultsSubtitle: l.rsearchNoResultsSubtitle,
        resultCount: (int count) => l.rsearchResultCount(count),
        searching: l.rsearchSearching,
      );

  ReaderSettingsLabels readerSettings() => ReaderSettingsLabels(
        textSize: l.rsetTextSize,
        smaller: l.rsetSmaller,
        larger: l.rsetLarger,
        sizeValue: fmt.percent,
        preview: l.rsetPreview,
        bookmarks: l.rsetBookmarks,
      );

  ReaderThemeLabels readerTheme() => ReaderThemeLabels(
        light: l.rthemeLight,
        dark: l.rthemeDark,
        sepia: l.rthemeSepia,
        sepiaDetail: l.rthemeSepiaDetail,
        selected: l.commonSelected,
      );

  ReaderLanguageLabels readerLanguage() => ReaderLanguageLabels(
        reading: l.rlangReading,
        notDownloaded: l.rlangNotDownloaded,
        downloaded: l.rlangDownloaded,
        failed: l.rlangFailed,
        percent: fmt.percent,
        download: l.commonDownload,
      );

  VerseActionsLabels verseActions() => VerseActionsLabels(
        bookmark: l.vactBookmark,
        removeBookmark: l.vactRemoveBookmark,
        highlight: l.vactHighlight,
        removeHighlight: l.vactRemoveHighlight,
        share: l.commonShare,
        tone: toneName,
        chosen: l.vactChosen,
      );

  BookmarksLabels bookmarks() => BookmarksLabels(
        title: l.bmTitle,
        back: l.commonBack,
        emptyTitle: l.bmEmptyTitle,
        emptySubtitle: l.bmEmptySubtitle,
        bookmarked: l.readerBookmarked,
        remove: l.bmRemove,
      );

  /// The download prompt for one language, named in the app language.
  DownloadPromptLabels downloadPrompt(String languageName) => DownloadPromptLabels(
        title: l.dlTitle(languageName),
        explain: l.dlExplain,
        networkLabel: l.dlNetworkLabel,
        wifiOnly: l.dlWifiOnly,
        wifiAndData: l.dlWifiAndData,
        download: l.commonDownload,
        notNow: l.commonNotNow,
        downloading: l.dlDownloading,
        cancel: l.commonCancel,
        retry: l.commonRetry,
        percent: fmt.percent,
      );

  OnboardingLabels onboarding() => OnboardingLabels(
        appName: l.appName,
        promise: l.onbPromise,
        languageHeader: l.onbLanguageHeader,
        play: l.commonPlay,
        selected: l.commonSelected,
      );

  AppLanguageLabels appLanguage(String currentLanguageName) => AppLanguageLabels(
        followDevice: l.setSameAsDevice,
        followDeviceDetail: l.setCurrently(currentLanguageName),
        selected: l.commonSelected,
      );

  ReminderTimeLabels reminderTime() => ReminderTimeLabels(
        hour: l.timeHour,
        minute: l.timeMinute,
        earlier: l.timeEarlier,
        later: l.timeLater,
        timeOf: fmt.time,
        save: l.commonSave,
      );

  SettingsLabels settings({required String version, required String build}) => SettingsLabels(
        title: l.setTitle,
        back: l.commonBack,
        appearance: l.setAppearance,
        theme: l.setTheme,
        themeSystem: l.setThemeSystem,
        themeLight: l.setThemeLight,
        themeDark: l.setThemeDark,
        language: l.setLanguage,
        play: l.setPlay,
        inputScheme: l.setInputScheme,
        inputFlick: l.setInputFlick,
        inputTiming: l.setInputTiming,
        sound: l.setSound,
        music: l.setMusic,
        haptics: l.setHaptics,
        daily: l.setDaily,
        reminders: l.setReminders,
        remindersDetail: l.setRemindersDetail,
        reminderTime: l.setReminderTime,
        reading: l.setReading,
        bibleReader: l.setBibleReader,
        bibleReaderDetail: l.setBibleReaderDetail,
        purchases: l.setPurchases,
        removeAds: l.setRemoveAds,
        adsRemoved: l.setAdsRemoved,
        restore: l.setRestore,
        restoring: l.setRestoring,
        privacyChoices: l.setPrivacyChoices,
        data: l.setData,
        deleteBibles: l.setDeleteBibles,
        deleteBiblesNone: l.setDeleteBiblesNone,
        deleteBiblesCount: (int count) => l.setDeleteBiblesCount(count),
        emailLog: l.setEmailLog,
        emailLogDetail: l.setEmailLogDetail,
        about: l.setAbout,
        licenses: l.setLicenses,
        privacyPolicy: l.setPrivacyPolicy,
        support: l.setSupport,
        version: l.setVersion(version, build),
      );

  UpgradeLabels upgrade() => UpgradeLabels(
        title: l.upTitle,
        back: l.commonBack,
        headline: l.upHeadline,
        benefits: <String>[l.upBenefit1, l.upBenefit2, l.upBenefit3],
        notSold: l.upNotSold,
        buy: l.upBuy,
        buyWithPrice: (String price) => l.upBuyWithPrice(price),
        restore: l.setRestore,
        restoring: l.setRestoring,
        owned: l.upOwned,
        ownedDetail: l.upOwnedDetail,
        pending: l.upPending,
        unavailable: l.upUnavailable,
      );

  LicensesLabels licenses() => LicensesLabels(
        title: l.licTitle,
        back: l.commonBack,
        intro: l.licIntro,
        openLink: l.licOpenLink,
        emptyTitle: l.licEmptyTitle,
        emptySubtitle: l.licEmptySubtitle,
      );
}
