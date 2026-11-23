import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

/// One choice in a [SegmentedControl].
@immutable
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Two to four exclusive choices in one pill (input scheme, reader theme).
/// The chosen segment is raised on the secondary surface and its label is
/// bold; every segment is at least 48 high.
class SegmentedControl<T> extends StatelessWidget {
  SegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  }) : assert(options.length >= 2 && options.length <= 4, 'use two to four segments');

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.bgTertiary,
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.xxs),
          child: Row(
            children: <Widget>[
              for (final SegmentOption<T> option in options)
                Expanded(
                  child: _Segment<T>(
                    option: option,
                    isSelected: option.value == selected,
                    onTap: () => onChanged(option.value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({required this.option, required this.isSelected, required this.onTap});

  final SegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return Semantics(
      selected: isSelected,
      child: Pressable(
        onTap: onTap,
        focusRadius: Radii.chip,
        builder: (BuildContext context, bool pressed) => AnimatedOpacity(
          opacity: pressed ? Metrics.pressedOpacity : 1,
          duration: Motion.scaled(context, Motion.press),
          curve: Motion.out,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected ? p.bgSecondary : const Color(0x00000000),
              borderRadius: BorderRadius.circular(Radii.chip - Sp.xxs),
              border: isSelected
                  ? Border.all(color: p.borderSubtle, width: Metrics.hairline)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (option.icon != null) ...<Widget>[
                      AppIcon(
                        option.icon!,
                        size: IconSizes.rowTrailing,
                        color: isSelected ? p.accent : p.textSecondary,
                      ),
                      const SizedBox(width: Sp.xs),
                    ],
                    Flexible(
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: theme.text.footnote.copyWith(
                          color: isSelected ? p.textPrimary : p.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
