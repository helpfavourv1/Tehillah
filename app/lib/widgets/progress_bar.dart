import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// A determinate bar with its percent shown as text. [valueLabel] is the
/// caller's formatted percent (for example "42%"), so number formatting stays
/// locale-aware.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.fraction,
    required this.valueLabel,
    super.key,
    this.label,
  }) : assert(fraction >= 0 && fraction <= 1, 'fraction is from 0 to 1');

  final double fraction;
  final String valueLabel;

  /// What is progressing, for example "Downloading".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    const double height = Sp.sm;
    return Semantics(
      label: label,
      value: valueLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (label != null) Expanded(child: Text(label!, style: theme.text.footnote)),
                if (label == null) const Spacer(),
                Text(
                  valueLabel,
                  style: theme.text.footnote.copyWith(
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.xs),
            SizedBox(
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.bgTertiary,
                  borderRadius: BorderRadius.circular(Radii.pill(height)),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedFractionallySizedBox(
                    duration: Motion.scaled(context, Motion.press),
                    curve: Motion.out,
                    widthFactor: fraction,
                    heightFactor: 1,
                    alignment: AlignmentDirectional.centerStart,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(Radii.pill(height)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
