import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// The one press behaviour. It gives every control a hit area of at least
/// 48 by 48, reports its pressed state to [builder] (each component chooses
/// its own feedback: opacity, tint or scale; never a ripple), exposes button
/// semantics, and shows a focus ring when driven from a keyboard.
///
/// A null [onTap] disables the control: no press, no focus, and the semantics
/// say so. Components dim themselves when disabled; this widget does not.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.builder,
    super.key,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.focusRadius = Radii.chip,
    this.minSize = Metrics.touchTarget,
  });

  /// Press feedback by opacity only, the card and chip behaviour.
  factory Pressable.opacity({
    required Widget child,
    Key? key,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? semanticLabel,
    double focusRadius = Radii.card,
  }) {
    return Pressable(
      key: key,
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      focusRadius: focusRadius,
      builder: (BuildContext context, bool pressed) => AnimatedOpacity(
        opacity: pressed ? Metrics.pressedOpacity : 1,
        duration: Motion.scaled(context, Motion.press),
        curve: Motion.out,
        child: child,
      ),
    );
  }

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Read by screen readers instead of the text inside, when given.
  final String? semanticLabel;

  /// The corner radius of the focus ring.
  final double focusRadius;

  final double minSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _showFocus = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _showFocus)) {
      _pressed = false;
      _showFocus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.of(context).palette;
    Widget content = widget.builder(context, _pressed && _enabled);
    if (_showFocus && _enabled) {
      content = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.focusRadius),
          border: Border.all(color: palette.borderFocus, width: Metrics.focusRing),
        ),
        child: content,
      );
    }
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: _enabled,
        onShowFocusHighlight: (bool value) {
          if (_showFocus != value) {
            setState(() => _showFocus = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (TapDownDetails _) => _setPressed(true) : null,
          onTapUp: _enabled ? (TapUpDetails _) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onTap,
          onLongPress: _enabled ? widget.onLongPress : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize),
            child: content,
          ),
        ),
      ),
    );
  }
}
