import 'package:flutter/widgets.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';
import 'package:tehillah/widgets/section_header.dart';
import 'package:tehillah/widgets/toggle_row.dart';

/// What happened on one of the last seven days.
enum DayState { won, played, rescued, missed, today }

/// One day in the week strip, already named in the app language ("Mon").
final class DailyDay {
  const DailyDay({required this.label, required this.state});

  final String label;
  final DayState state;
}

/// Today's result, once there is one.
final class DailyResult {
  const DailyResult({required this.won, required this.goals});

  final bool won;
  final int goals;
}

final class DailyBreadLabels {
  const DailyBreadLabels({
    required this.title,
    required this.back,
    required this.opponent,
    required this.recent,
    required this.start,
    required this.startAgain,
    required this.firstCounts,
    required this.resultWon,
    required this.resultLost,
    required this.goalsValue,
    required this.streak,
    required this.streakValue,
    required this.dayState,
    required this.reminder,
    required this.reminderDetail,
    required this.rescue,
    required this.rescueDetail,
  });

  final String title;
  final String back;
  final String opponent;

  /// The heading over the week strip.
  final String recent;
  final String start;

  /// The button once today has a result.
  final String startAgain;

  /// "Only your first result counts"; shown under the button text area once
  /// today is done.
  final String firstCounts;
  final String resultWon;
  final String resultLost;

  /// "3 goals".
  final String Function(int goals) goalsValue;
  final String streak;

  /// "4 days".
  final String Function(int days) streakValue;

  /// The word for a day state, spoken with the day's name.
  final String Function(DayState state) dayState;
  final String reminder;
  final String reminderDetail;
  final String rescue;
  final String rescueDetail;
}

/// Daily Bread: one seeded challenge a day, the same for everyone. Shows who
/// you face, today's result if there is one, the streak and the last seven
/// days, the opt-in reminder, and the streak-rescue offer when one is open.
/// The start button is fixed at the bottom; only the content above scrolls.
class DailyBreadScreen extends StatelessWidget {
  const DailyBreadScreen({
    required this.labels,
    required this.opponentName,
    required this.opponentTeam,
    required this.streak,
    required this.days,
    required this.remindersOn,
    required this.onReminders,
    required this.onStart,
    required this.onBack,
    super.key,
    this.facts = const <IntroFact>[],
    this.result,
    this.onRescue,
    this.bottom,
  });

  final DailyBreadLabels labels;
  final String opponentName;
  final String opponentTeam;
  final List<IntroFact> facts;

  /// Null until today has been played.
  final DailyResult? result;
  final int streak;
  final List<DailyDay> days;
  final bool remindersOn;
  final ValueChanged<bool> onReminders;

  /// Null when no day can be restored; otherwise opens the rewarded offer.
  final VoidCallback? onRescue;
  final VoidCallback onStart;
  final VoidCallback onBack;
  final Widget? bottom;

  static IconData _icon(DayState s) => switch (s) {
        DayState.won => AppIcons.check,
        DayState.played => AppIcons.ball,
        DayState.rescued => AppIcons.restore,
        DayState.missed => AppIcons.close,
        DayState.today => AppIcons.daily,
      };

  static ChipTone _tone(DayState s) => switch (s) {
        DayState.won => ChipTone.success,
        DayState.played => ChipTone.neutral,
        DayState.rescued => ChipTone.accent,
        DayState.missed => ChipTone.warning,
        DayState.today => ChipTone.accent,
      };

  @override
  Widget build(BuildContext context) {
    final DailyResult? r = result;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ScrollBody(
              children: <Widget>[
                SectionHeader(labels.opponent, padding: EdgeInsets.zero),
                const SizedBox(height: Sp.sm),
                AppCard(label: opponentName, subtitle: opponentTeam, leading: AppIcons.flag),
                if (facts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Sp.sm),
                  Wrap(
                    spacing: Sp.sm,
                    runSpacing: Sp.xs,
                    children: <Widget>[
                      for (final IntroFact f in facts)
                        AppChip(label: f.label, icon: f.icon, tone: f.tone),
                    ],
                  ),
                ],
                if (r != null) ...<Widget>[
                  const SizedBox(height: Sp.lg),
                  AppCard(
                    label: r.won ? labels.resultWon : labels.resultLost,
                    subtitle: labels.firstCounts,
                    value: labels.goalsValue(r.goals),
                    leading: r.won ? AppIcons.check : AppIcons.ball,
                  ),
                ],
                const SizedBox(height: Sp.lg),
                AppCard(
                  label: labels.streak,
                  value: labels.streakValue(streak),
                  leading: AppIcons.streak,
                ),
                const SizedBox(height: Sp.lg),
                SectionHeader(labels.recent, padding: EdgeInsets.zero),
                const SizedBox(height: Sp.sm),
                Wrap(
                  spacing: Sp.sm,
                  runSpacing: Sp.sm,
                  children: <Widget>[
                    for (final DailyDay d in days)
                      Semantics(
                        label: '${d.label}, ${labels.dayState(d.state)}',
                        child: ExcludeSemantics(
                          child: AppChip(label: d.label, icon: _icon(d.state), tone: _tone(d.state)),
                        ),
                      ),
                  ],
                ),
                if (onRescue != null) ...<Widget>[
                  const SizedBox(height: Sp.lg),
                  AppCard(
                    label: labels.rescue,
                    subtitle: labels.rescueDetail,
                    leading: AppIcons.restore,
                    chevron: true,
                    onTap: onRescue,
                  ),
                ],
                const SizedBox(height: Sp.lg),
                ToggleRow(
                  label: labels.reminder,
                  subtitle: labels.reminderDetail,
                  leading: AppIcons.reminder,
                  value: remindersOn,
                  onChanged: onReminders,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
            child: PrimaryButton(
              label: r == null ? labels.start : labels.startAgain,
              icon: AppIcons.play,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}
