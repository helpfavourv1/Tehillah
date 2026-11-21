enum SoundEffect { kick, goal, save, post, miss, whistle, selah, tap }

abstract interface class AudioPort {
  Future<void> preload();

  Future<void> play(SoundEffect effect);

  Future<void> startMenuLoop();

  Future<void> stopMenuLoop();

  void setSoundEnabled({required bool enabled});

  void setMusicEnabled({required bool enabled});

  Future<void> dispose();
}
