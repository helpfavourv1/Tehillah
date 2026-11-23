import 'dart:math' as math;
import 'dart:ui';

import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The ground, the stand behind the goal, the mowing stripes and the markings.
/// It is the bottom layer and paints the whole canvas.
class Pitch extends SceneLayer {
  Pitch() : super(priority: 0);

  static const double _nearZ = Tuning.cameraZ - Tuning.nearPlane - 0.01;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, p.width, p.height),
      Paint()..color = c.bgPrimary,
    );
    _stand(canvas, p, c);
    _grass(canvas, p, c);
    _markings(canvas, p, c);
  }

  void _stand(Canvas canvas, PitchProjection p, AppPalette c) {
    final ScreenPoint top = p.projectClamped(0, Tuning.standHeight, -Tuning.groundBehindGoal);
    final ScreenPoint bottom = p.projectClamped(0, 0, -Tuning.groundBehindGoal);
    canvas.drawRect(
      Rect.fromLTRB(0, top.y, p.width, bottom.y),
      Paint()..color = c.bgTertiary,
    );
  }

  void _grass(Canvas canvas, PitchProjection p, AppPalette c) {
    final List<double> edges = <double>[
      -Tuning.groundBehindGoal,
      0,
      Tuning.stripeDepth,
      2 * Tuning.stripeDepth,
      _nearZ,
    ];
    for (int i = 0; i < edges.length - 1; i++) {
      final double far = edges[i];
      final double near = edges[i + 1];
      final ScreenPoint a = p.projectClamped(-Tuning.groundHalfWidth, 0, far);
      final ScreenPoint b = p.projectClamped(Tuning.groundHalfWidth, 0, far);
      final ScreenPoint d = p.projectClamped(Tuning.groundHalfWidth, 0, near);
      final ScreenPoint e = p.projectClamped(-Tuning.groundHalfWidth, 0, near);
      final Path path = Path()
        ..moveTo(a.x, a.y)
        ..lineTo(b.x, b.y)
        ..lineTo(d.x, d.y)
        ..lineTo(e.x, e.y)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = i.isEven ? c.pitchGrass : c.pitchGrassAlt,
      );
    }
  }

  void _markings(Canvas canvas, PitchProjection p, AppPalette c) {
    final Paint line = Paint()
      ..color = c.pitchLine
      ..style = PaintingStyle.stroke;

    void seg(double ax, double az, double bx, double bz) {
      if (az > _nearZ && bz > _nearZ) {
        return;
      }
      final ScreenPoint a = p.projectClamped(ax, 0, math.min(az, _nearZ));
      final ScreenPoint b = p.projectClamped(bx, 0, math.min(bz, _nearZ));
      line.strokeWidth = math.max(1, 0.12 * (a.scale + b.scale) / 2);
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), line);
    }

    const double wide = Tuning.penaltyAreaHalfWidth;
    const double six = Tuning.sixYardHalfWidth;
    seg(-wide, 0, wide, 0);
    seg(-wide, 0, -wide, Tuning.penaltyAreaDepth);
    seg(wide, 0, wide, Tuning.penaltyAreaDepth);
    seg(-wide, Tuning.penaltyAreaDepth, wide, Tuning.penaltyAreaDepth);
    seg(-six, 0, -six, Tuning.sixYardDepth);
    seg(six, 0, six, Tuning.sixYardDepth);
    seg(-six, Tuning.sixYardDepth, six, Tuning.sixYardDepth);

    final ScreenPoint? spot = p.project(0, 0, Tuning.spotDistance);
    if (spot != null) {
      final double r = Tuning.spotRadius * spot.scale;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(spot.x, spot.y), width: r * 2, height: r * 0.7),
        Paint()..color = c.pitchLine,
      );
    }
  }
}
