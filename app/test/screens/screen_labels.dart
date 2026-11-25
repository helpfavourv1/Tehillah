import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/screens/achievements_screen.dart';
import 'package:tehillah/screens/home_screen.dart';
import 'package:tehillah/screens/journey_map_screen.dart';
import 'package:tehillah/screens/loadout_screen.dart';
import 'package:tehillah/screens/modes_screen.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';

String _stage(String n) => 'Continue: $n';
String _journey(int l, int t, int s) => '$l of $t lamps, $s stars';
String _streak(int d) => '$d day streak';
String _ach(int u, int t) => '$u of $t';

const HomeLabels homeLabels = HomeLabels(
  appName: 'Tehillah Soccer',
  play: 'Play',
  playContinue: _stage,
  journey: 'Journey',
  journeySummary: _journey,
  modes: 'Modes',
  modesSubtitle: 'Friendly, Watchman and more',
  daily: 'Daily Bread',
  dailyOpen: 'Today\'s challenge is ready',
  dailyDone: 'Done for today',
  dailyStreak: _streak,
  verses: 'Verse library',
  versesSubtitle: 'Read what you have unlocked',
  achievements: 'Achievements',
  achievementsSummary: _ach,
  settings: 'Settings',
);

const StageIntroLabels introLabels = StageIntroLabels(
  back: 'Back',
  start: 'Start match',
  opponent: 'Opponent',
  rulesHeader: 'How it plays',
  loadout: 'Your loadout',
  changeLoadout: 'Change loadout',
  noGear: 'No gear',
  readChapter: 'Read chapter',
  share: 'Share',
);

String _ballName(BallDef b) => 'Ball ${b.id}';
String _ballBenefit(BallDef b) => 'gain ${b.id}';
String _ballTradeoff(BallDef b) => 'cost ${b.id}';
String _gearName(GearDef g) => 'Gear ${g.id}';
String _gearBenefit(GearDef g) => 'gain ${g.id}';
String _gearTradeoff(GearDef g) => 'cost ${g.id}';
String _benefit(String s) => 'Benefit: $s';
String _tradeoff(String s) => 'Trade-off: $s';
String _locked(int n) => 'Earn $n lamps to unlock';

const LoadoutLabels loadoutLabels = LoadoutLabels(
  title: 'Loadout',
  back: 'Back',
  balls: 'Balls',
  gear: 'Keeper gear',
  noGear: 'No gear',
  noGearDetail: 'Play without gear',
  selected: 'Selected',
  ballName: _ballName,
  ballBenefit: _ballBenefit,
  ballTradeoff: _ballTradeoff,
  gearName: _gearName,
  gearBenefit: _gearBenefit,
  gearTradeoff: _gearTradeoff,
  benefitLine: _benefit,
  tradeoffLine: _tradeoff,
  lockedHint: _locked,
);

String _journeySummary(int l, int t, int s) => '$l of $t lamps, $s stars';
String _roundsProgress(int d, int t) => '$d of $t rounds';
String _stageStars(int s, int m) => '$s of $m stars';

const JourneyLabels journeyLabels = JourneyLabels(
  title: 'Journey',
  back: 'Back',
  summary: _journeySummary,
  roundsProgress: _roundsProgress,
  cleared: 'Cleared',
  locked: 'Clear the stage before it to open',
  boss: 'Boss stage',
  starsValue: _stageStars,
);

const ModesLabels modesLabels = ModesLabels(title: 'Modes', back: 'Back');

String _achSummary(int u, int t) => '$u of $t unlocked';
String _achProgress(int v, int t) => '$v of $t';

const AchievementsLabels achievementsLabels = AchievementsLabels(
  title: 'Achievements',
  back: 'Back',
  summary: _achSummary,
  unlocked: 'Unlocked',
  progress: _achProgress,
);
