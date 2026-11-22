import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// The one list row: transparent, a leading icon, a label with an optional
/// second line, an optional value, and a trailing chevron. Press feedback is a
/// background tint. Use inside a [CardSurface] for grouped settings.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.label,
    super.key,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = true,
    this.semanticLabel,
  });

  final String label;
  final String? subtitle;
  final String? value;
  final IconData? leading;

  /// A control at the trailing edge, such as a switch. Replaces the chevron.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    Widget content(bool pressed) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: pressed ? theme.palette.bgTertiary : const Color(0x00000000),
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Metrics.rowMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
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
                      Text(label, style: theme.text.callout),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: Sp.xxs),
                        Text(subtitle!, style: theme.text.footnote),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...<Widget>[
                  const SizedBox(width: Sp.sm),
                  Flexible(
                    child: Text(value!, style: theme.text.footnote, textAlign: TextAlign.end),
                  ),
                ],
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: Sp.sm),
                  trailing!,
                ] else if (chevron && onTap != null) ...<Widget>[
                  const SizedBox(width: Sp.sm),
                  AppIcon(
                    AppIcons.forward,
                    size: IconSizes.rowTrailing,
                    color: theme.palette.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (onTap == null) {
      return content(false);
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, bool pressed) => content(pressed),
    );
  }
}
