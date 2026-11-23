import 'package:flutter/widgets.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/input/zone_grid.dart';

/// The keeper's dive for a zone of the 3 by 2 grid: the column is the side as
/// the shooter sees it, the top row is high.
KeeperDive diveForZone(int column, int row) {
  assert(column >= 0 && column < 3 && row >= 0 && row < 2);
  final bool high = row == 1;
  return switch (column) {
    0 => high ? KeeperDive.leftHigh : KeeperDive.leftLow,
    1 => high ? KeeperDive.centerHigh : KeeperDive.centerLow,
    _ => high ? KeeperDive.rightHigh : KeeperDive.rightLow,
  };
}

/// Watchman mode: the player is the goalkeeper and taps where to dive.
class DiveLayer extends StatelessWidget {
  const DiveLayer({
    required this.projection,
    required this.zoneLabel,
    required this.onDive,
    super.key,
    this.enabled = true,
  });

  final PitchProjection projection;
  final String Function(int column, int row) zoneLabel;
  final void Function(KeeperDive dive) onDive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }
    return ZoneGrid(
      projection: projection,
      zoneLabel: zoneLabel,
      onSelect: (int column, int row) => onDive(diveForZone(column, row)),
    );
  }
}
