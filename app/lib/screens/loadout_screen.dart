import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/providers/loadout_provider.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';
import 'package:tehillah/widgets/section_header.dart';

final class LoadoutLabels {
  const LoadoutLabels({
    required this.title,
    required this.back,
    required this.balls,
    required this.gear,
    required this.noGear,
    required this.noGearDetail,
    required this.selected,
    required this.ballName,
    required this.ballBenefit,
    required this.ballTradeoff,
    required this.gearName,
    required this.gearBenefit,
    required this.gearTradeoff,
    required this.benefitLine,
    required this.tradeoffLine,
    required this.lockedHint,
  });

  final String title;
  final String back;
  final String balls;
  final String gear;
  final String noGear;
  final String noGearDetail;

  /// The value shown on the chosen card (the check icon is never alone).
  final String selected;
  final String Function(BallDef ball) ballName;
  final String Function(BallDef ball) ballBenefit;
  final String Function(BallDef ball) ballTradeoff;
  final String Function(GearDef gear) gearName;
  final String Function(GearDef gear) gearBenefit;
  final String Function(GearDef gear) gearTradeoff;

  /// "Benefit: larger aim forgiveness".
  final String Function(String benefit) benefitLine;
  final String Function(String tradeoff) tradeoffLine;

  /// "Earn 3 lamps to unlock".
  final String Function(int lamps) lockedHint;
}

/// The strategy layer: one ball and one piece of keeper gear. Every card says
/// what it gives and what it costs; locked ones say how to earn them. Nothing
/// here is for sale.
class LoadoutScreen extends StatelessWidget {
  const LoadoutScreen({
    required this.labels,
    required this.state,
    required this.onSelectBall,
    required this.onSelectGear,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final LoadoutLabels labels;
  final ValueListenable<LoadoutState> state;
  final void Function(String ballId) onSelectBall;

  /// Null means no gear.
  final void Function(String? gearId) onSelectGear;
  final VoidCallback onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: ListenableBuilder(
        listenable: state,
        builder: (BuildContext context, Widget? _) {
          final LoadoutState s = state.value;
          return ScrollBody(
            children: <Widget>[
              SectionHeader(labels.balls, padding: EdgeInsets.zero),
              const SizedBox(height: Sp.sm),
              for (final BallDef ball in BallCatalog.all) ...<Widget>[
                _option(
                  name: labels.ballName(ball),
                  benefit: labels.ballBenefit(ball),
                  tradeoff: labels.ballTradeoff(ball),
                  unlocked: s.ballUnlocked(ball.id),
                  selected: s.selected.ballId == ball.id,
                  lamps: ball.unlockLamps,
                  icon: AppIcons.fruit,
                  onTap: () => onSelectBall(ball.id),
                ),
                const SizedBox(height: Sp.sm),
              ],
              const SizedBox(height: Sp.md),
              SectionHeader(labels.gear, padding: EdgeInsets.zero),
              const SizedBox(height: Sp.sm),
              AppCard(
                label: labels.noGear,
                subtitle: labels.noGearDetail,
                leading: s.selected.gearId == null ? AppIcons.check : AppIcons.armor,
                value: s.selected.gearId == null ? labels.selected : null,
                onTap: () => onSelectGear(null),
              ),
              const SizedBox(height: Sp.sm),
              for (final GearDef gear in GearCatalog.all) ...<Widget>[
                _option(
                  name: labels.gearName(gear),
                  benefit: labels.gearBenefit(gear),
                  tradeoff: labels.gearTradeoff(gear),
                  unlocked: s.gearUnlocked(gear.id),
                  selected: s.selected.gearId == gear.id,
                  lamps: gear.unlockLamps,
                  icon: AppIcons.armor,
                  onTap: () => onSelectGear(gear.id),
                ),
                const SizedBox(height: Sp.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _option({
    required String name,
    required String benefit,
    required String tradeoff,
    required bool unlocked,
    required bool selected,
    required int lamps,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final String detail = unlocked
        ? '${labels.benefitLine(benefit)}\n${labels.tradeoffLine(tradeoff)}'
        : '${labels.lockedHint(lamps)}\n${labels.benefitLine(benefit)}\n${labels.tradeoffLine(tradeoff)}';
    return AppCard(
      label: name,
      subtitle: detail,
      leading: !unlocked ? AppIcons.locked : (selected ? AppIcons.check : icon),
      value: selected ? labels.selected : null,
      onTap: unlocked ? onTap : null,
    );
  }
}
