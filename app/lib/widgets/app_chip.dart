import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// What a chip means. The label always says it too; colour is never alone.
enum ChipTone { neutral, accent, success, warning, error }

/// The one chip: a small labelled pill for metadata, or, with [onTap], a
/// choice. The pill is 32 high inside a 48 hit area.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.icon,
    this.tone = ChipTone.neutral,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;

  /// A selected chip is filled with the accent.
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final Color toneColor;
    switch (tone) {
      case ChipTone.neutral:
        toneColor = p.textSecondary;
      case ChipTone.accent:
        toneColor = p.accent;
      case ChipTone.success:
        toneColor = p.success;
      case ChipTone.warning:
        toneColor = p.warning;
      case ChipTone.error:
        toneColor = p.error;
    }
    final Color fill = selected ? p.accent : p.bgTertiary;
    final Color ink = selected ? p.onAccent : toneColor;
    final Widget pill = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Metrics.chipHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.pill(Metrics.chipHeight)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(icon!, size: IconSizes.rowTrailing, color: ink),
                const SizedBox(width: Sp.xs),
              ],
              Flexible(
                child: Text(label, style: theme.text.footnote.copyWith(color: ink, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return pill;
    }
    return Pressable(
      onTap: onTap,
      focusRadius: Radii.pill(Metrics.chipHeight),
      builder: (BuildContext context, bool pressed) => Center(
        widthFactor: 1,
        heightFactor: 1,
        child: AnimatedOpacity(
          opacity: pressed ? Metrics.pressedOpacity : 1,
          duration: Motion.scaled(context, Motion.press),
          curve: Motion.out,
          child: pill,
        ),
      ),
    );
  }
}
