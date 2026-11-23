import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/input/shot_input_strategy.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/providers/match_provider.dart';

/// The glue between the rules ([MatchProvider]), the picture ([MatchWorld]) and
/// the player's hands (a [ShotInputStrategy] or a dive choice).
///
/// The order of every kick: the player aims (or the computer does), the
/// provider decides the result at once, and the controller then plays that
/// result on the pitch. Input is closed while a kick is playing, the next
/// prompt opens when it ends, computer-only kicks follow after a short beat,
/// and when the last kick has played the match is reported finished once.
class MatchController {
  MatchController({
    required this.match,
    required this.world,
    this.autoKickDelay = const Duration(milliseconds: 700),
  });

  final MatchProvider match;
  final MatchWorld world;

  /// The pause before a computer-only kick starts.
  final Duration autoKickDelay;

  /// Called once, after the animation of the final kick.
  void Function()? onMatchFinished;

  /// True while a kick is being played on the pitch.
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  /// True when the player may aim, dive or use Selah right now.
  final ValueNotifier<bool> inputEnabled = ValueNotifier<bool>(false);

  ShotInputStrategy? _input;
  StreamSubscription<ShotParams>? _subscription;
  KickRecord? _lastPlayed;
  Timer? _timer;
  bool _attached = false;
  bool _paused = false;
  bool _finishedReported = false;
  bool _disposed = false;

  bool get isAttached => _attached;
  bool get isPaused => _paused;

  /// Starts listening. Call after the match has been started on the provider.
  void attach({ShotInputStrategy? input}) {
    if (_attached || _disposed) {
      return;
    }
    _attached = true;
    world.onKickFinished = _kickFinished;
    match.addListener(_onView);
    setInput(input);
    _onView();
  }

  /// Swaps the input scheme (Settings can change it between matches).
  void setInput(ShotInputStrategy? input) {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _input = input;
    _subscription = input?.shots.listen(submitShot);
  }

  ShotInputStrategy? get input => _input;

  void detach() {
    if (!_attached) {
      return;
    }
    _attached = false;
    match.removeListener(_onView);
    if (world.onKickFinished == _kickFinished) {
      world.onKickFinished = null;
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
    _cancelTimer();
    _setBusy(false);
    _refreshInput();
  }

  /// The player's shot. Ignored unless a shot is being asked for.
  void submitShot(ShotParams shot) {
    if (!_canAct || match.value.prompt != KickPrompt.humanShot) {
      return;
    }
    match.kick(shot: shot);
  }

  /// The player's dive in Watchman mode.
  void submitDive(KeeperDive dive) {
    if (!_canAct || match.value.prompt != KickPrompt.humanDive) {
      return;
    }
    match.kick(dive: dive);
  }

  /// Selah: steady the nerves before a shot. Returns whether it was used.
  bool useSelah() {
    if (!_canAct || !match.value.canUseSelah) {
      return false;
    }
    return match.useSelah();
  }

  void pause() {
    if (_paused) {
      return;
    }
    _paused = true;
    _cancelTimer();
    _refreshInput();
  }

  void resume() {
    if (!_paused) {
      return;
    }
    _paused = false;
    _evaluate();
  }

  bool get _canAct => _attached && !_paused && !busy.value && match.value.active;

  void _onView() {
    if (!_attached) {
      return;
    }
    final MatchView v = match.value;
    if (!v.active) {
      world.reset();
      _lastPlayed = null;
      _finishedReported = false;
      _cancelTimer();
      _setBusy(false);
      _refreshInput();
      return;
    }
    final KickRecord? last = v.lastKick;
    if (last != null && !identical(last, _lastPlayed)) {
      _lastPlayed = last;
      _cancelTimer();
      _setBusy(true);
      world.play(last);
      _refreshInput();
      return;
    }
    if (last == null) {
      _finishedReported = false;
    }
    _evaluate();
  }

  void _kickFinished() {
    _setBusy(false);
    final MatchView v = match.value;
    if (v.finished) {
      if (!_finishedReported) {
        _finishedReported = true;
        _refreshInput();
        onMatchFinished?.call();
      }
      return;
    }
    _evaluate();
  }

  /// Decides what happens next when nothing is playing.
  void _evaluate() {
    final MatchView v = match.value;
    if (v.active && v.state != null) {
      world.idleShooter = v.state!.turn;
    }
    _refreshInput();
    if (!_attached || _paused || busy.value || !v.active) {
      return;
    }
    if (v.prompt == KickPrompt.automatic && _timer == null) {
      _timer = Timer(autoKickDelay, () {
        _timer = null;
        if (_attached && !_paused && !busy.value && match.value.prompt == KickPrompt.automatic) {
          match.kick();
        }
      });
    }
  }

  void _refreshInput() {
    final MatchView v = match.value;
    final bool open = _attached &&
        !_paused &&
        !busy.value &&
        v.active &&
        (v.prompt == KickPrompt.humanShot || v.prompt == KickPrompt.humanDive);
    if (inputEnabled.value != open) {
      inputEnabled.value = open;
    }
  }

  void _setBusy(bool value) {
    if (busy.value != value) {
      busy.value = value;
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    detach();
    _disposed = true;
    busy.dispose();
    inputEnabled.dispose();
  }
}
