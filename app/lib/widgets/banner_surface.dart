import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/icon_chip.dart';

/// The one banner face shared by feedback and warning banners: an icon, a
/// message, an optional action chip and an optional dismiss button, on a
/// surface tinted with the [accent]. The icon and the words carry the meaning;
/// the tint only supports them. Actions sit below the message so large text
/// never pushes them off the edge.
class BannerSurface extends StatelessWidget {
  const BannerSurface({
    required this.icon,
    required this.message,
    required this.accent,
    super.key,
    this.actionLabel,
    this.onAction,
    this.dismissLabel,
    this.onDismiss,
    this.live = false,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'an action needs both its label and its callback',
        ),
        assert(
          (dismissLabel == null) == (onDismiss == null),
          'dismiss needs both its label and its callback',
        );

  final IconData icon;
  final String message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  /// Announce the message to screen readers when it appears.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return Semantics(
      container: true,
      liveRegion: live,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withValues(alpha: 0.12), p.bgSecondary),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: accent.withValues(alpha: 0.4),
            width: Metrics.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.xxs),
                    child: AppIcon(icon, size: IconSizes.rowLeading, color: accent),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: Sp.xxs),
                      child: Text(
                        message,
                        style: theme.text.footnote.copyWith(color: p.textPrimary),
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconChip(
                      icon: AppIcons.close,
                      semanticLabel: dismissLabel!,
                      onTap: onDismiss,
                    ),
                ],
              ),
              if (onAction != null) ...<Widget>[
                const SizedBox(height: Sp.xs),
                Wrap(
                  children: <Widget>[
                    AppChip(
                      label: actionLabel!,
                      tone: ChipTone.accent,
                      onTap: onAction,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
