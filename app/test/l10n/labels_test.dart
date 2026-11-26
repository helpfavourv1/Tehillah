import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tehillah/core/catalog/achievement_catalog.dart';
import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/stage_def.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/l10n/gen/app_localizations.dart';
import 'package:tehillah/l10n/labels.dart';
import 'package:tehillah/screens/reader_screen.dart';

void main() {
  const Locale en = Locale('en');
  late Labels t;

  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => t = Labels(lookupAppLocalizations(en), en));

  test('English is the only supported locale until the translations land', () {
    expect(AppLocalizations.supportedLocales, contains(en));
  });

  test('every Journey stage has a name', () {
    for (final StageDef s in StageCatalog.stages) {
      final String name = t.stageName(s.nameKey);
      expect(name, isNot(s.nameKey), reason: s.nameKey);
      expect(name, isNotEmpty);
    }
    expect(t.stageName('stageSinai'), 'Sinai');
    expect(t.stageName('stageNewJerusalem'), 'New Jerusalem');
  });

  test('every ball has a name, a benefit and a trade-off', () {
    for (final ball in BallCatalog.all) {
      expect(t.ballName(ball), isNot(ball.id), reason: ball.id);
      expect(t.ballBenefit(ball), isNotEmpty, reason: ball.id);
      expect(t.ballTradeoff(ball), isNotEmpty, reason: ball.id);
    }
  });

  test('every piece of gear has a name, a benefit and a trade-off', () {
    for (final gear in GearCatalog.all) {
      expect(t.gearName(gear), isNot(gear.id), reason: gear.id);
      expect(t.gearBenefit(gear), isNotEmpty, reason: gear.id);
      expect(t.gearTradeoff(gear), isNotEmpty, reason: gear.id);
    }
  });

  test('every achievement has a name and a description', () {
    for (final a in AchievementCatalog.all) {
      expect(t.achievementName(a), isNot(a.id), reason: a.id);
      expect(t.achievementDescription(a), isNotEmpty, reason: a.id);
    }
  });

  test('every mode has a name, a subtitle and rules', () {
    for (final MatchMode m in MatchMode.values) {
      expect(t.modeName(m), isNotEmpty);
      expect(t.modeSubtitle(m), isNotEmpty);
      expect(t.modeRules(m).single, isNotEmpty);
    }
  });

  test('all 66 books have distinct names', () {
    final Set<String> names = <String>{for (final String id in osisBookIds) t.bookName(id)};
    expect(names.length, 66);
    expect(t.bookName('Ps'), 'Psalms');
    expect(t.verseReference(const VerseRef('Ps', 23, 1)), 'Psalms 23:1');
  });

  test('every verse moment, colour and day state has a word', () {
    for (final VerseMoment m in VerseMoment.values) {
      expect(t.momentName(m), isNotEmpty);
    }
    for (final MarkTone tone in MarkTone.values) {
      expect(t.toneName(tone), isNotEmpty);
    }
  });

  test('plurals resolve', () {
    expect(t.home().dailyStreak(1), '1 day streak');
    expect(t.home().dailyStreak(4), '4 day streak');
    expect(t.daily().goalsValue(1), '1 goal');
    expect(t.daily().goalsValue(3), '3 goals');
    expect(t.readerSearch().resultCount(0), 'No verses');
    expect(t.readerSearch().resultCount(1), '1 verse');
    expect(t.readerSearch().resultCount(12), '12 verses');
    expect(t.loadout().lockedHint(1), 'Light 1 lamp to unlock');
    expect(t.loadout().lockedHint(3), 'Light 3 lamps to unlock');
  });

  test('numbers use grouping', () {
    expect(t.readerSearch().resultCount(1234), '1,234 verses');
  });

  test('function labels fill their placeholders', () {
    expect(t.home().playContinue('Sinai'), 'Continue: Sinai');
    expect(t.home().journeySummary(3, 12, 20), '3 of 12 lamps · 20 stars');
    expect(t.result().scoreLine(3, 2), '3 to 2');
    expect(t.result().starsLabel(2, 3), '2 of 3 stars');
    expect(t.sling().summary(4, 5), 'You hit 4 of 5 targets.');
    expect(t.upgrade().buyWithPrice(r'$2.99'), r'Remove ads, $2.99');
    expect(t.settings(version: '1.0.0', build: '1').version, 'Version 1.0.0 (1)');
    expect(t.readerPicker().chapterLabel('Genesis', 3), 'Genesis, chapter 3');
    expect(t.reader().verseLabel(3, 'Text'), 'Verse 3. Text');
    expect(t.downloadPrompt('English').title, 'Download the English Bible');
  });

  test('zone labels name column and row', () {
    expect(t.zoneLabel(0, 0), 'Left, low');
    expect(t.zoneLabel(1, 1), 'Centre, high');
    expect(t.zoneLabel(2, 0), 'Right, low');
  });

  test('time and percent follow the locale format', () {
    expect(t.readerSettings().sizeValue(1.2), '120%');
    expect(t.reminderTime().timeOf(18, 0).replaceAll(RegExp(r'\s'), ' '), '6:00 PM');
  });

  test('pack error codes map to words, unknown ones to the generic line', () {
    expect(t.packError('pack.offline'), contains('offline'));
    expect(t.packError('pack.needs_wifi'), contains('Wi-Fi'));
    expect(t.packError('something.else'), t.l.dlErrorUnexpected);
  });

  test('every screen label factory builds', () {
    // Building each one proves no constructor argument is missing.
    t
      ..home()
      ..journey()
      ..modes()
      ..achievements()
      ..stageIntro()
      ..loadout()
      ..hud()
      ..match()
      ..result()
      ..sling()
      ..daily()
      ..verseLibrary()
      ..reader()
      ..readerPicker()
      ..readerSearch()
      ..readerSettings()
      ..readerTheme()
      ..readerLanguage()
      ..verseActions()
      ..bookmarks()
      ..downloadPrompt('English')
      ..onboarding()
      ..appLanguage('English')
      ..reminderTime()
      ..settings(version: '1', build: '1')
      ..upgrade()
      ..licenses();
  });
}
