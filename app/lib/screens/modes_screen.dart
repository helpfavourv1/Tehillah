import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';

/// One mode as the list shows it.
final class ModeEntry {
  const ModeEntry({
    required this.mode,
    required this.name,
    required this.subtitle,
    required this.unlocked,
    this.value,
    this.lockedHint,
  });

  final MatchMode mode;
  final String name;

  /// What the mode is, in one line.
  final String subtitle;

  /// Progress or best result, such as "Round 3 of 7"; shown only when open.
  final String? value;
  final bool unlocked;

  /// How to open it ("Clear Sinai to unlock"); shown instead of [subtitle]
  /// when locked.
  final String? lockedHint;
}

final class ModesLabels {
  const ModesLabels({required this.title, required this.back});

  final String title;
  final String back;
}

/// Every way to play, in one list. A locked mode shows a padlock and how to
/// open it, and does nothing when tapped.
class ModesScreen extends StatelessWidget {
  const ModesScreen({
    required this.labels,
    required this.entries,
    required this.onSelect,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final ModesLabels labels;
  final List<ModeEntry> entries;
  final void Function(MatchMode mode) onSelect;
  final VoidCallback onBack;
  final Widget? bottom;

  static IconData iconFor(MatchMode mode) {
    switch (mode) {
      case MatchMode.journey:
        return AppIcons.journey;
      case MatchMode.friendly:
        return AppIcons.ball;
      case MatchMode.watchman:
        return AppIcons.armor;
      case MatchMode.slingAndStone:
        return AppIcons.target;
      case MatchMode.jericho:
        return AppIcons.flag;
      case MatchMode.sevenDays:
        return AppIcons.timer;
      case MatchMode.dailyBread:
        return AppIcons.daily;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: ScrollBody(
        children: <Widget>[
          for (final ModeEntry e in entries) ...<Widget>[
            AppCard(
              label: e.name,
              subtitle: e.unlocked ? e.subtitle : (e.lockedHint ?? e.subtitle),
              value: e.unlocked ? e.value : null,
              leading: e.unlocked ? iconFor(e.mode) : AppIcons.locked,
              chevron: e.unlocked,
              onTap: e.unlocked ? () => onSelect(e.mode) : null,
            ),
            const SizedBox(height: Sp.sm),
          ],
        ],
      ),
    );
  }
}
