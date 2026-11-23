import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';

/// The pressure meter. Colour is never the only signal: an icon, the caller's
/// word for the state ("Calm", "Tense"), the bar's length, and a percent value
/// for screen readers all say the same thing.
class NerveMeterView extends StatelessWidget {
  const NerveMeterView({
    required this.value,
    required this.label,
    required this.stateLabel,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction from 0 to 1');

  /// 0 is calm, 1 is full pressure.
  final double value;

  /// The meter's name, for example "Nerve".
  final String label;

  /// The state in words, for example "Calm".
  final String stateLabel;

  /// Below this the meter reads calm, above [tenseAt] it reads full.
  static const double calmBelow = 0.5;
  static const double tenseAt = 0.8;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final Color fill = value < calmBelow
        ? p.accent
        : (value < tenseAt ? p.warning : p.error);
    return Semantics(
      label: '$label, $stateLabel',
      value: '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            AppIcon(AppIcons.nerve, size: IconSizes.rowTrailing, color: fill),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('$label · $stateLabel', style: theme.text.caption),
                  const SizedBox(height: Sp.xs),
                  _Track(value: value, fill: fill, track: p.bgTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.value, required this.fill, required this.track});

  final double value;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    const double height = Sp.sm;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(Radii.pill(height)),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedFractionallySizedBox(
            duration: Motion.scaled(context, Motion.press),
            curve: Motion.out,
            widthFactor: value,
            heightFactor: 1,
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(Radii.pill(height)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
