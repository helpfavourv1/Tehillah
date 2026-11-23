import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_row.dart';

/// The switch face: a pill track and a round thumb. It is only drawn; the row
/// around it takes the tap. State is carried by the thumb's position as well
/// as the colour.
class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, super.key, this.enabled = true});

  final bool value;
  final bool enabled;

  static const double trackWidth = 52;
  static const double trackHeight = 32;
  static const double thumb = 28;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    return Opacity(
      opacity: enabled ? 1 : Metrics.disabledOpacity,
      child: AnimatedContainer(
        duration: Motion.scaled(context, Motion.press),
        curve: Motion.out,
        width: trackWidth,
        height: trackHeight,
        padding: const EdgeInsets.all(Sp.xxs),
        decoration: BoxDecoration(
          color: value ? p.accent : p.borderSubtle,
          borderRadius: BorderRadius.circular(Radii.pill(trackHeight)),
        ),
        alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: const SizedBox.square(
          dimension: thumb,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFFFFFFF), shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// A settings row with a switch. Tapping anywhere on the row toggles it. A null
/// [onChanged] disables it.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final IconData? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? change = onChanged;
    return Semantics(
      toggled: value,
      child: AppRow(
        label: label,
        subtitle: subtitle,
        leading: leading,
        trailing: AppSwitch(value: value, enabled: change != null),
        chevron: false,
        onTap: change == null ? null : () => change(!value),
      ),
    );
  }
}
