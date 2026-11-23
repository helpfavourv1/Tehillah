import 'dart:ui';

import 'package:tehillah/game/tuning.dart';

/// The colours of one figure.
final class FigureStyle {
  const FigureStyle({required this.kit, required this.limb, this.glove});

  final Color kit;
  final Color limb;

  /// Present for the keeper, who wears gloves.
  final Color? glove;
}

/// How the figure is posed.
final class FigurePose {
  const FigurePose({this.swing = 0, this.arms = 0, this.spread = 0, this.tilt = 0});

  /// Kicking leg lifted, 0 to 1.
  final double swing;

  /// Arms raised, 0 to 1.
  final double arms;

  /// Legs apart, 0 to 1.
  final double spread;

  /// Lean in radians, positive towards the right of the screen.
  final double tilt;
}

/// Draws the abstract player used for shooter and keeper: a rounded torso, a
/// round head, limbs as strokes. Nothing here depicts a face or a real person.
/// Geometry is in metres from the hip, y up; [scale] converts to pixels.
abstract final class FigurePainter {
  static void paint(
    Canvas canvas, {
    required Offset hip,
    required double scale,
    required FigureStyle style,
    FigurePose pose = const FigurePose(),
  }) {
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(pose.tilt);
    canvas.scale(scale, -scale);

    final Paint limb = Paint()
      ..color = style.limb
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double spread = FigureShape.legSpread + 0.25 * pose.spread;
    limb.strokeWidth = FigureShape.legWidth;
    canvas.drawLine(
      const Offset(-0.08, 0),
      Offset(-spread, -FigureShape.legLength),
      limb,
    );
    canvas.drawLine(
      const Offset(0.08, 0),
      Offset(spread + 0.1 * pose.swing, -FigureShape.legLength + 0.55 * pose.swing),
      limb,
    );

    final Paint kit = Paint()..color = style.kit;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(0, FigureShape.torsoCentreY),
          width: FigureShape.torsoWidth,
          height: FigureShape.torsoHeight,
        ),
        const Radius.circular(FigureShape.torsoRadius),
      ),
      kit,
    );

    limb.strokeWidth = FigureShape.armWidth;
    final double handX = FigureShape.shoulderX + 0.06 + 0.35 * pose.arms;
    final double handY = -0.05 + (FigureShape.shoulderY + 0.85) * pose.arms;
    for (final double side in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(side * FigureShape.shoulderX, FigureShape.shoulderY),
        Offset(side * handX, handY),
        limb,
      );
      final Color? glove = style.glove;
      if (glove != null) {
        canvas.drawCircle(
          Offset(side * handX, handY),
          FigureShape.gloveRadius,
          Paint()..color = glove,
        );
      }
    }

    canvas.drawCircle(
      const Offset(0, FigureShape.headY),
      FigureShape.headRadius,
      Paint()..color = style.limb,
    );
    canvas.restore();
  }

  /// A soft oval on the grass under a figure or the ball.
  static void shadow(Canvas canvas, {required Offset ground, required double width, required Color color}) {
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: width, height: width * 0.28),
      Paint()..color = color,
    );
  }
}
