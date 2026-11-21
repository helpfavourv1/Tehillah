enum HapticKind { light, medium, success, error }

abstract interface class HapticsPort {
  void setEnabled({required bool enabled});

  Future<void> play(HapticKind kind);
}
