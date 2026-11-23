import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// A grid laid over the goal mouth, [columns] across and [rows] up (row 0 is
/// the bottom row), drawn where the goal is on screen because it asks the same
/// [PitchProjection] the scene uses. Each zone is a button. A zone drawn
/// shorter than 48 grows its touch area away from the middle of the goal (up
/// for the upper row, down for the lower) so every target is at least 48 high
/// and no two overlap.
class ZoneGrid extends StatelessWidget {
  const ZoneGrid({
    required this.projection,
    required this.zoneLabel,
    required this.onSelect,
    super.key,
    this.columns = 3,
    this.rows = 2,
    this.selected,
  });

  final PitchProjection projection;

  /// The localized name of a zone, for screen readers ("Left, low").
  final String Function(int column, int row) zoneLabel;

  /// Null makes the zones display-only.
  final void Function(int column, int row)? onSelect;

  final int columns;
  final int rows;

  /// The zone to highlight, if any.
  final ({int column, int row})? selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    final List<Widget> zones = <Widget>[];
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final ScreenRect v = projection.zoneRect(column, row, columns: columns, rows: rows);
        final double visualHeight = v.bottom - v.top;
        final double grow = math.max(Metrics.touchTarget - visualHeight, 0);
        final bool upper = row >= rows / 2;
        final double hitTop = upper ? v.top - grow : v.top;
        final double hitBottom = upper ? v.bottom : v.bottom + grow;
        final bool isSelected = selected?.column == column && selected?.row == row;
        final void Function(int, int)? select = onSelect;
        zones.add(
          Positioned.fromRect(
            rect: Rect.fromLTRB(v.left, hitTop, v.right, hitBottom),
            child: Pressable(
              minSize: 0,
              focusRadius: Radii.chip,
              semanticLabel: zoneLabel(column, row),
              onTap: select == null ? null : () => select(column, row),
              builder: (BuildContext context, bool pressed) => Padding(
                padding: EdgeInsets.fromLTRB(
                  Sp.xxs,
                  v.top - hitTop + Sp.xxs,
                  Sp.xxs,
                  hitBottom - v.bottom + Sp.xxs,
                ),
                child: AnimatedOpacity(
                  opacity: pressed ? Metrics.pressedOpacity : 1,
                  duration: Motion.scaled(context, Motion.press),
                  curve: Motion.out,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: (isSelected ? p.accent : p.pitchLine)
                          .withValues(alpha: isSelected ? 0.4 : 0.12),
                      borderRadius: BorderRadius.circular(Radii.chip),
                      border: Border.all(
                        color: isSelected ? p.accent : p.pitchLine.withValues(alpha: 0.7),
                        width: isSelected ? 2 : Metrics.hairline * 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return Stack(children: zones);
  }
}
