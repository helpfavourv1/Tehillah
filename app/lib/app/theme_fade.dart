import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// Provides the theme and cross-fades every token when the mode changes
/// (200 ms, linear). With Reduce Motion on, the change is instant.
class ThemeFade extends StatefulWidget {
  const ThemeFade({required this.mode, required this.locale, required this.child, super.key});

  final PaletteMode mode;
  final Locale locale;
  final Widget child;

  @override
  State<ThemeFade> createState() => _ThemeFadeState();
}

class _ThemeFadeState extends State<ThemeFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Motion.themeChange, value: 1);
  late AppPalette _from = AppPalette.forMode(widget.mode);
  late AppPalette _to = _from;

  @override
  void didUpdateWidget(ThemeFade old) {
    super.didUpdateWidget(old);
    if (old.mode == widget.mode) {
      return;
    }
    final AppPalette target = AppPalette.forMode(widget.mode);
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = target;
      _to = target;
      _controller.value = 1;
      return;
    }
    _from = AppPalette.lerp(_from, _to, _controller.value);
    _to = target;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final AppPalette palette = AppPalette.lerp(_from, _to, _controller.value);
        return AppTheme(
          data: AppThemeData.forPalette(palette, locale: widget.locale),
          child: child!,
        );
      },
    );
  }
}
