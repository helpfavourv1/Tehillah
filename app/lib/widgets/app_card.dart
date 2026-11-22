import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// The card surface: secondary fill, a hairline border, 16 radius, no
/// elevation, no shadow. Everything that looks like a card is this or
/// [AppCard].
class CardSurface extends StatelessWidget {
  const CardSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(Sp.md),
    this.radius = Radii.card,
    this.fill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// A different fill token, for example the verse card surface.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.of(context).palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? palette.bgSecondary,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.borderSubtle, width: Metrics.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The one tappable card: optional leading icon, a label (with an optional
/// second line), an optional value, and an optional chevron. Press feedback is
/// opacity only. With no [onTap] it is a plain surface and does not react.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.label,
    super.key,
    this.subtitle,
    this.value,
    this.leading,
    this.onTap,
    this.chevron = false,
    this.semanticLabel,
  });

  final String label;

  /// The secondary line under the label.
  final String? subtitle;

  /// A short value at the trailing edge, for example "3 stars".
  final String? value;
  final IconData? leading;
  final VoidCallback? onTap;
  final bool chevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Metrics.rowMinHeight),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            AppIcon(leading!, size: IconSizes.rowLeading, color: theme.palette.accent),
            const SizedBox(width: Sp.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: theme.text.title2),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: Sp.xxs),
                  Text(subtitle!, style: theme.text.footnote),
                ],
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: Sp.sm),
            Flexible(child: Text(value!, style: theme.text.footnote, textAlign: TextAlign.end)),
          ],
          if (chevron) ...<Widget>[
            const SizedBox(width: Sp.sm),
            AppIcon(AppIcons.forward, size: IconSizes.rowTrailing, color: theme.palette.textTertiary),
          ],
        ],
      ),
    );
    final Widget card = CardSurface(child: row);
    if (onTap == null) {
      return card;
    }
    return Pressable.opacity(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: card,
    );
  }
}
