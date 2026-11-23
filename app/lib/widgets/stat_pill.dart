import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// A label over a value, for the scoreboard and statistics. The value uses the
/// tabular score style so digits do not jitter as they change.
class StatPill extends StatelessWidget {
  const StatPill({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Semantics(
      label: '$label $value',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.palette.bgSecondary,
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(color: theme.palette.borderSubtle, width: Metrics.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: theme.text.caption, textAlign: TextAlign.center),
                Text(value, style: theme.text.score.copyWith(fontSize: 22), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
