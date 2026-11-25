import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';

/// One fruit achievement as the list shows it.
final class AchievementEntry {
  const AchievementEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.threshold,
    required this.unlocked,
  }) : assert(threshold >= 1);

  final String id;
  final String name;

  /// What it asks for ("Score 50 goals").
  final String description;

  /// Where the player is now (may exceed [threshold]).
  final int value;
  final int threshold;
  final bool unlocked;
}

final class AchievementsLabels {
  const AchievementsLabels({
    required this.title,
    required this.back,
    required this.summary,
    required this.unlocked,
    required this.progress,
  });

  final String title;
  final String back;

  /// "2 of 9 unlocked".
  final String Function(int unlocked, int total) summary;

  /// The value of an earned achievement.
  final String unlocked;

  /// "3 of 10".
  final String Function(int value, int threshold) progress;
}

/// The nine fruit of the Spirit as local milestones. An earned one has a check
/// and says so; one in progress shows how far along it is. Nothing here is for
/// sale and nothing is shared; it is stored on the device only.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({
    required this.labels,
    required this.entries,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final AchievementsLabels labels;
  final List<AchievementEntry> entries;
  final VoidCallback onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final int done = entries.where((AchievementEntry e) => e.unlocked).length;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: ScrollBody(
        children: <Widget>[
          Text(
            labels.summary(done, entries.length),
            style: theme.text.callout.copyWith(color: theme.palette.textSecondary),
          ),
          const SizedBox(height: Sp.md),
          for (final AchievementEntry e in entries) ...<Widget>[
            AppCard(
              label: e.name,
              subtitle: e.description,
              value: e.unlocked
                  ? labels.unlocked
                  : labels.progress(e.value < e.threshold ? e.value : e.threshold, e.threshold),
              leading: e.unlocked ? AppIcons.check : AppIcons.fruit,
            ),
            const SizedBox(height: Sp.sm),
          ],
        ],
      ),
    );
  }
}
