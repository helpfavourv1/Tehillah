import 'package:flutter/services.dart';
import 'package:tehillah/core/ports/haptics_port.dart';

final class HapticsService implements HapticsPort {
  bool _enabled = true;

  @override
  void setEnabled({required bool enabled}) => _enabled = enabled;

  @override
  Future<void> play(HapticKind kind) async {
    if (!_enabled) {
      return;
    }
    try {
      switch (kind) {
        case HapticKind.light:
          await HapticFeedback.lightImpact();
        case HapticKind.medium:
          await HapticFeedback.mediumImpact();
        case HapticKind.success:
          await HapticFeedback.successNotification();
        case HapticKind.error:
          await HapticFeedback.errorNotification();
      }
    } on Object {
      // A device without a vibrator is not an error.
    }
  }
}
