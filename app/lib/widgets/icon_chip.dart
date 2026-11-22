import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// A toolbar action: an icon in a 40 by 40 container inside a 48 hit area. A
/// bare icon is never placed in a toolbar. [semanticLabel] is required because
/// an icon alone says nothing to a screen reader.
class IconChip extends StatelessWidget {
  const IconChip({
    required this.icon,
    required this.semanticLabel,
    super.key,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// Filled with the accent, for a toggled-on action.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, bool pressed) => Center(
        widthFactor: 1,
        heightFactor: 1,
        child: AnimatedOpacity(
          opacity: onTap == null ? Metrics.disabledOpacity : (pressed ? Metrics.pressedOpacity : 1),
          duration: Motion.scaled(context, Motion.press),
          curve: Motion.out,
          child: SizedBox.square(
            dimension: Metrics.iconChip,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active ? p.accent : p.bgTertiary,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Center(
                child: AppIcon(
                  icon,
                  size: IconSizes.navBar,
                  color: active ? p.onAccent : p.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
