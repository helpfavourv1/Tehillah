import 'package:audioplayers/audioplayers.dart';
import 'package:tehillah/core/ports/audio_port.dart';
import 'package:tehillah/core/ports/log_port.dart';

/// Sound effects and the menu loop. One low-latency player per effect, so a
/// kick never waits for a file to load. The sounds are generated in batch p7a;
/// until the files exist every call is a quiet no-op and is logged once.
final class AudioService implements AudioPort {
  AudioService({LogPort? log}) : _log = log;

  static const String menuLoopAsset = 'audio/menu_loop.wav';
  static const double _loopVolume = 0.35;

  /// The asset a sound effect plays, relative to the `assets/` folder.
  static String assetFor(SoundEffect effect) => 'audio/${effect.name}.wav';

  final LogPort? _log;
  final Map<SoundEffect, AudioPlayer> _players = <SoundEffect, AudioPlayer>{};
  AudioPlayer? _loop;
  bool _sound = true;
  bool _music = true;
  bool _loopWanted = false;
  final Set<String> _reported = <String>{};

  // Mix with other apps' audio instead of taking over: a player who listens to
  // music keeps it. Sound effects never request audio focus.
  final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  void _report(String what, Object error) {
    if (_reported.add(what)) {
      _log?.log(LogLevel.warning, 'audio', '$what unavailable: $error');
    }
  }

  @override
  Future<void> preload() async {
    for (final SoundEffect effect in SoundEffect.values) {
      try {
        final AudioPlayer player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setAudioContext(_context);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(assetFor(effect)));
        _players[effect] = player;
      } on Object catch (error) {
        _report(effect.name, error);
      }
    }
  }

  @override
  Future<void> play(SoundEffect effect) async {
    final AudioPlayer? player = _players[effect];
    if (!_sound || player == null) {
      return;
    }
    try {
      await player.stop();
      await player.resume();
    } on Object catch (error) {
      _report(effect.name, error);
    }
  }

  @override
  Future<void> startMenuLoop() async {
    _loopWanted = true;
    if (!_music) {
      return;
    }
    try {
      AudioPlayer? loop = _loop;
      if (loop == null) {
        loop = AudioPlayer();
        await loop.setAudioContext(_context);
        await loop.setReleaseMode(ReleaseMode.loop);
        await loop.setVolume(_loopVolume);
        _loop = loop;
      }
      await loop.play(AssetSource(menuLoopAsset));
    } on Object catch (error) {
      _report('menu loop', error);
    }
  }

  @override
  Future<void> stopMenuLoop() async {
    _loopWanted = false;
    try {
      await _loop?.stop();
    } on Object catch (error) {
      _report('menu loop', error);
    }
  }

  @override
  void setSoundEnabled({required bool enabled}) => _sound = enabled;

  @override
  void setMusicEnabled({required bool enabled}) {
    _music = enabled;
    if (!enabled) {
      _loop?.stop().ignore();
    } else if (_loopWanted) {
      startMenuLoop().ignore();
    }
  }

  @override
  Future<void> dispose() async {
    for (final AudioPlayer player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    await _loop?.dispose();
    _loop = null;
  }
}
