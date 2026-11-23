import 'package:flutter/widgets.dart';
import 'package:tehillah/core/input/flick_strategy.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// Reads a swipe from the ball towards the goal and feeds it to a
/// [FlickStrategy], which turns it into a shot. Only the first finger counts.
/// A faint trail follows the finger. A swipe too short, too slow or pointing
/// the wrong way calls [onRejected] so the screen can say how to try again.
class FlickLayer extends StatefulWidget {
  const FlickLayer({
    required this.strategy,
    required this.semanticLabel,
    super.key,
    this.enabled = true,
    this.onRejected,
  });

  final FlickStrategy strategy;

  /// What a screen reader says about this area ("Swipe up toward the goal").
  final String semanticLabel;

  final bool enabled;
  final VoidCallback? onRejected;

  @override
  State<FlickLayer> createState() => _FlickLayerState();
}

class _FlickLayerState extends State<FlickLayer> {
  static const int _maxTrail = 48;

  final ValueNotifier<List<Offset>> _trail = ValueNotifier<List<Offset>>(const <Offset>[]);
  int? _pointer;

  @override
  void didUpdateWidget(FlickLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pointer != null) {
      _abandon();
    }
  }

  void _abandon() {
    widget.strategy.cancel();
    _pointer = null;
    _trail.value = const <Offset>[];
  }

  void _down(PointerDownEvent e) {
    if (!widget.enabled || _pointer != null) {
      return;
    }
    _pointer = e.pointer;
    widget.strategy.begin(e.localPosition.dx, e.localPosition.dy, e.timeStamp.inMilliseconds);
    _trail.value = <Offset>[e.localPosition];
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) {
      return;
    }
    widget.strategy.update(e.localPosition.dx, e.localPosition.dy, e.timeStamp.inMilliseconds);
    final List<Offset> next = <Offset>[..._trail.value, e.localPosition];
    _trail.value = next.length > _maxTrail ? next.sublist(next.length - _maxTrail) : next;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) {
      return;
    }
    _pointer = null;
    _trail.value = const <Offset>[];
    final Object? shot =
        widget.strategy.end(e.localPosition.dx, e.localPosition.dy, e.timeStamp.inMilliseconds);
    if (shot == null) {
      widget.onRejected?.call();
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) {
      _abandon();
    }
  }

  @override
  void dispose() {
    _trail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = AppTheme.of(context).palette.accent;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Listener(
        behavior: widget.enabled ? HitTestBehavior.opaque : HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: SizedBox.expand(
          child: CustomPaint(painter: _TrailPainter(_trail, ink)),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.trail, this.color) : super(repaint: trail);

  final ValueNotifier<List<Offset>> trail;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = trail.value;
    if (points.length < 2) {
      return;
    }
    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Sp.xs;
    for (int i = 1; i < points.length; i++) {
      paint.color = color.withValues(alpha: 0.15 + 0.7 * i / points.length);
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.color != color || old.trail != trail;
}
