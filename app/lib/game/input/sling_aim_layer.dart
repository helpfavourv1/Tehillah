import 'package:flutter/widgets.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// Aim and release for Sling and Stone. Press anywhere, drag to move the
/// crosshair over the goal, lift the finger to throw. The crosshair sits above
/// the finger so the finger never hides it. The point is turned into the
/// rules' units (-1 to 1 across, 0 to 1 up) by the same [PitchProjection] the
/// scene uses, so what is under the crosshair is what is aimed at. Only the
/// first finger counts; a cancelled touch throws nothing.
class SlingAimLayer extends StatefulWidget {
  const SlingAimLayer({
    required this.projection,
    required this.onRelease,
    required this.semanticLabel,
    super.key,
    this.enabled = true,
    this.lift = defaultLift,
  });

  /// How far above the finger the crosshair sits, in logical pixels.
  static const double defaultLift = 56;

  final PitchProjection projection;

  /// Called with the aim when the finger lifts.
  final void Function(double direction, double elevation) onRelease;

  /// What a screen reader says about this area.
  final String semanticLabel;

  final bool enabled;
  final double lift;

  @override
  State<SlingAimLayer> createState() => _SlingAimLayerState();
}

class _SlingAimLayerState extends State<SlingAimLayer> {
  final ValueNotifier<Offset?> _aim = ValueNotifier<Offset?>(null);
  int? _pointer;

  @override
  void didUpdateWidget(SlingAimLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pointer != null) {
      _abandon();
    }
  }

  void _abandon() {
    _pointer = null;
    _aim.value = null;
  }

  Offset _crosshair(Offset finger) => finger - Offset(0, widget.lift);

  void _down(PointerDownEvent e) {
    if (!widget.enabled || _pointer != null) {
      return;
    }
    _pointer = e.pointer;
    _aim.value = _crosshair(e.localPosition);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer == _pointer) {
      _aim.value = _crosshair(e.localPosition);
    }
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) {
      return;
    }
    final Offset at = _crosshair(e.localPosition);
    _abandon();
    final ({double x, double y}) g = widget.projection.goalPlaneAt(at.dx, at.dy);
    widget.onRelease(
      (g.x / Tuning.halfGoal).clamp(-1.0, 1.0).toDouble(),
      (g.y / Tuning.goalHeight).clamp(0.0, 1.0).toDouble(),
    );
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) {
      _abandon();
    }
  }

  @override
  void dispose() {
    _aim.dispose();
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
          child: CustomPaint(painter: _CrosshairPainter(_aim, ink)),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.aim, this.color) : super(repaint: aim);

  final ValueNotifier<Offset?> aim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset? at = aim.value;
    if (at == null) {
      return;
    }
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round;
    const double radius = 18;
    const double tick = 9;
    canvas.drawCircle(at, radius, line);
    canvas.drawLine(at + const Offset(-radius - tick, 0), at + const Offset(-radius + 4, 0), line);
    canvas.drawLine(at + const Offset(radius - 4, 0), at + const Offset(radius + tick, 0), line);
    canvas.drawLine(at + const Offset(0, -radius - tick), at + const Offset(0, -radius + 4), line);
    canvas.drawLine(at + const Offset(0, radius - 4), at + const Offset(0, radius + tick), line);
    canvas.drawCircle(at, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color || old.aim != aim;
}
