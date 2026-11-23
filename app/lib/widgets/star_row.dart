import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';

/// Zero to three stars. Earned stars are filled with the star colour; unearned
/// ones are dimmed. The caller's [semanticLabel] ("2 of 3 stars") carries the
/// meaning for screen readers, and screens show the count as text as well.
class StarRow extends StatelessWidget {
  const StarRow({
    required this.stars,
    required this.semanticLabel,
    super.key,
    this.total = 3,
    this.size = IconSizes.hero,
  }) : assert(stars >= 0 && stars <= total, 'stars must be within 0 to total');

  final int stars;
  final int total;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < total; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Sp.xs),
              Opacity(
                opacity: i < stars ? 1 : 0.3,
                child: AppIcon(
                  AppIcons.star,
                  size: size,
                  color: i < stars ? p.starFill : p.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
