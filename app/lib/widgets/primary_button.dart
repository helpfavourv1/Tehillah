import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

enum _ButtonKind { primary, secondary, destructive }

class _ButtonBase extends StatelessWidget {
  const _ButtonBase({
    required this.kind,
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.expanded,
    super.key,
  });

  final _ButtonKind kind;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final bool enabled = onPressed != null;
    return Pressable(
      onTap: onPressed,
      focusRadius: Radii.button,
      builder: (BuildContext context, bool pressed) {
        final Color fill;
        final Color ink;
        switch (kind) {
          case _ButtonKind.primary:
            fill = pressed ? p.accentDim : p.accent;
            ink = p.onAccent;
          case _ButtonKind.secondary:
            fill = pressed ? p.borderSubtle : p.bgTertiary;
            ink = p.textPrimary;
          case _ButtonKind.destructive:
            fill = p.error;
            ink = p.onAccent;
        }
        final Widget face = AnimatedOpacity(
          opacity: enabled ? 1 : Metrics.disabledOpacity,
          duration: Motion.scaled(context, Motion.press),
          child: AnimatedScale(
            scale: pressed ? Metrics.pressedScale : 1,
            duration: Motion.scaled(context, Motion.press),
            curve: Motion.out,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Metrics.buttonHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
                  child: Row(
                    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        AppIcon(icon!, size: IconSizes.rowLeading, color: ink),
                        const SizedBox(width: Sp.sm),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.text.callout.copyWith(color: ink, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        return expanded ? face : Center(widthFactor: 1, heightFactor: 1, child: face);
      },
    );
  }
}

/// The one primary action: a filled accent button, 48 high, 12 radius. A null
/// [onPressed] disables it (40% opacity).
class PrimaryButton extends _ButtonBase {
  const PrimaryButton({
    required super.label,
    required super.onPressed,
    super.key,
    super.icon,
    super.expanded = true,
  }) : super(kind: _ButtonKind.primary);
}

/// A quieter filled button for the second choice (Cancel, Not now). It is
/// filled, not outlined: outlined is never used for a button.
class SecondaryButton extends _ButtonBase {
  const SecondaryButton({
    required super.label,
    required super.onPressed,
    super.key,
    super.icon,
    super.expanded = true,
  }) : super(kind: _ButtonKind.secondary);
}

/// A filled button in the error colour for destructive confirmations.
class DestructiveButton extends _ButtonBase {
  const DestructiveButton({
    required super.label,
    required super.onPressed,
    super.key,
    super.icon,
    super.expanded = true,
  }) : super(kind: _ButtonKind.destructive);
}
