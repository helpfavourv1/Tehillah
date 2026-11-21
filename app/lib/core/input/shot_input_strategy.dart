import 'package:tehillah/core/models/shot_params.dart';

/// How the player's gesture becomes a kick. Both schemes (flick, timing bar)
/// emit the same [ShotParams], so the match logic never knows which was used.
abstract interface class ShotInputStrategy {
  /// Every completed shot, in order.
  Stream<ShotParams> get shots;

  /// Releases the stream. The strategy cannot be used afterwards.
  void dispose();
}
