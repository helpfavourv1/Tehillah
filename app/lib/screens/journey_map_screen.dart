import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';

/// Where a Journey stage stands.
enum StageStatus { locked, open, cleared }

/// One stage as the map shows it, already named in the app language.
final class JourneyStageItem {
  const JourneyStageItem({
    required this.id,
    required this.name,
    required this.status,
    required this.stars,
    required this.maxStars,
    required this.roundsCleared,
    required this.rounds,
    this.isBoss = false,
  });

  final int id;
  final String name;
  final StageStatus status;
  final int stars;
  final int maxStars;
  final int roundsCleared;
  final int rounds;
  final bool isBoss;
}

final class JourneyLabels {
  const JourneyLabels({
    required this.title,
    required this.back,
    required this.summary,
    required this.roundsProgress,
    required this.cleared,
    required this.locked,
    required this.boss,
    required this.starsValue,
  });

  final String title;
  final String back;

  /// "3 of 12 lamps, 20 stars".
  final String Function(int lamps, int totalStages, int stars) summary;

  /// "2 of 4 rounds".
  final String Function(int done, int total) roundsProgress;

  /// The line under a stage with its lamp.
  final String cleared;

  /// The line under a stage that is not open yet.
  final String locked;

  /// Marks the boss stages.
  final String boss;

  /// "7 of 12 stars" (the stage's stars).
  final String Function(int stars, int max) starsValue;
}

/// The career map: twelve stages in order, each a card. A cleared stage shows
/// a lamp, a locked one a padlock and the reason, an open one its round
/// progress. Locked stages do nothing when tapped. Status is told by the icon
/// and the text, never by colour.
class JourneyMapScreen extends StatelessWidget {
  const JourneyMapScreen({
    required this.labels,
    required this.stages,
    required this.onStage,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final JourneyLabels labels;
  final List<JourneyStageItem> stages;

  /// Called with the stage id when an open or cleared stage is tapped.
  final void Function(int stageId) onStage;
  final VoidCallback onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final int lamps = stages.where((JourneyStageItem s) => s.status == StageStatus.cleared).length;
    final int stars = stages.fold(0, (int sum, JourneyStageItem s) => sum + s.stars);
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: ScrollBody(
        children: <Widget>[
          Text(
            labels.summary(lamps, stages.length, stars),
            style: theme.text.callout.copyWith(color: theme.palette.textSecondary),
          ),
          const SizedBox(height: Sp.md),
          for (final JourneyStageItem s in stages) ...<Widget>[
            _card(s),
            const SizedBox(height: Sp.sm),
          ],
        ],
      ),
    );
  }

  Widget _card(JourneyStageItem s) {
    final String line = switch (s.status) {
      StageStatus.locked => labels.locked,
      StageStatus.cleared => labels.cleared,
      StageStatus.open => labels.roundsProgress(s.roundsCleared, s.rounds),
    };
    return AppCard(
      label: s.name,
      subtitle: s.isBoss ? '$line\n${labels.boss}' : line,
      value: s.status == StageStatus.locked ? null : labels.starsValue(s.stars, s.maxStars),
      leading: switch (s.status) {
        StageStatus.locked => AppIcons.locked,
        StageStatus.cleared => AppIcons.lamp,
        StageStatus.open => s.isBoss ? AppIcons.medal : AppIcons.journey,
      },
      chevron: s.status != StageStatus.locked,
      onTap: s.status == StageStatus.locked ? null : () => onStage(s.id),
    );
  }
}
