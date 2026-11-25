import 'package:tehillah/core/models/progress.dart';

/// When the store's rating prompt may be asked for: once in the life of the
/// install, right after the player clears a stage, and never after a loss.
abstract final class RatingRules {
  static bool shouldPrompt(Progress progress, {required bool won, required bool stageCleared}) =>
      won && stageCleared && !progress.ratingPromptShown;
}
