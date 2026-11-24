import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';

/// Every string the home screen shows, supplied by the caller from the
/// localizations class so this file holds no literal text.
final class HomeLabels {
  const HomeLabels({
    required this.appName,
    required this.play,
    required this.playContinue,
    required this.journey,
    required this.journeySummary,
    required this.modes,
    required this.modesSubtitle,
    required this.daily,
    required this.dailyOpen,
    required this.dailyDone,
    required this.dailyStreak,
    required this.verses,
    required this.versesSubtitle,
    required this.achievements,
    required this.achievementsSummary,
    required this.settings,
  });

  final String appName;

  /// The main button when there is no stage to continue.
  final String play;

  /// The main button when a stage is next, given that stage's name.
  final String Function(String stageName) playContinue;
  final String journey;

  /// "3 of 12 lamps · 20 stars".
  final String Function(int lamps, int totalStages, int stars) journeySummary;
  final String modes;
  final String modesSubtitle;
  final String daily;
  final String dailyOpen;
  final String dailyDone;

  /// "4 day streak"; only asked for when the streak is above zero.
  final String Function(int days) dailyStreak;
  final String verses;
  final String versesSubtitle;
  final String achievements;

  /// "2 of 9".
  final String Function(int unlocked, int total) achievementsSummary;
  final String settings;
}

/// The front door: football first. One filled Play button, then cards to the
/// rest of the game. Settings sits in the nav bar. The ad slot, if any, comes
/// in through [bottom] so the screen never knows about ads.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.labels,
    required this.lamps,
    required this.totalStages,
    required this.totalStars,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.dailyDone,
    required this.dailyStreak,
    required this.onPlay,
    required this.onJourney,
    required this.onModes,
    required this.onDaily,
    required this.onVerses,
    required this.onAchievements,
    required this.onSettings,
    super.key,
    this.nextStageName,
    this.bottom,
  });

  final HomeLabels labels;

  /// The name of the stage to continue, or null when every stage is cleared.
  final String? nextStageName;
  final int lamps;
  final int totalStages;
  final int totalStars;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final bool dailyDone;
  final int dailyStreak;
  final VoidCallback onPlay;
  final VoidCallback onJourney;
  final VoidCallback onModes;
  final VoidCallback onDaily;
  final VoidCallback onVerses;
  final VoidCallback onAchievements;
  final VoidCallback onSettings;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final String? next = nextStageName;
    return ScreenFrame(
      navBar: NavBar.brand(
        name: labels.appName,
        actions: <Widget>[
          IconChip(icon: AppIcons.settings, semanticLabel: labels.settings, onTap: onSettings),
        ],
      ),
      bottom: bottom,
      child: ScrollBody(
        children: <Widget>[
          PrimaryButton(
            label: next == null ? labels.play : labels.playContinue(next),
            icon: AppIcons.play,
            onPressed: onPlay,
          ),
          const SizedBox(height: Sp.lg),
          AppCard(
            label: labels.journey,
            subtitle: labels.journeySummary(lamps, totalStages, totalStars),
            leading: AppIcons.journey,
            chevron: true,
            onTap: onJourney,
          ),
          const SizedBox(height: Sp.sm),
          AppCard(
            label: labels.modes,
            subtitle: labels.modesSubtitle,
            leading: AppIcons.ball,
            chevron: true,
            onTap: onModes,
          ),
          const SizedBox(height: Sp.sm),
          AppCard(
            label: labels.daily,
            subtitle: dailyDone ? labels.dailyDone : labels.dailyOpen,
            value: dailyStreak > 0 ? labels.dailyStreak(dailyStreak) : null,
            leading: AppIcons.daily,
            chevron: true,
            onTap: onDaily,
          ),
          const SizedBox(height: Sp.lg),
          AppCard(
            label: labels.verses,
            subtitle: labels.versesSubtitle,
            leading: AppIcons.verse,
            chevron: true,
            onTap: onVerses,
          ),
          const SizedBox(height: Sp.sm),
          AppCard(
            label: labels.achievements,
            value: labels.achievementsSummary(achievementsUnlocked, achievementsTotal),
            leading: AppIcons.achievements,
            chevron: true,
            onTap: onAchievements,
          ),
        ],
      ),
    );
  }
}
