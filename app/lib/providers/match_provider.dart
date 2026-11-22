import 'package:flutter/foundation.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/core/models/stage_def.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// A snapshot of the running match for the world and the HUD. [version] grows
/// with every change, so widgets rebuild exactly when something happened.
@immutable
final class MatchView {
  const MatchView({
    this.config,
    this.state,
    this.history = const <KickRecord>[],
    this.prompt = KickPrompt.finished,
    this.canUseSelah = false,
    this.shieldAvailable = false,
    this.revealedTendency,
    this.lastKick,
    this.version = 0,
  });

  final MatchConfig? config;
  final MatchState? state;
  final List<KickRecord> history;
  final KickPrompt prompt;
  final bool canUseSelah;
  final bool shieldAvailable;

  /// The keeper's favourite dive, when the Belt of Truth reveals it.
  final KeeperDive? revealedTendency;

  /// The kick that was just taken, for the world to animate.
  final KickRecord? lastKick;
  final int version;

  bool get active => config != null;
  bool get finished => active && prompt == KickPrompt.finished;

  @override
  bool operator ==(Object other) =>
      other is MatchView && other.version == version && identical(other.config, config);

  @override
  int get hashCode => Object.hash(version, identityHashCode(config));
}

/// Runs one match at a time on top of [MatchEngine]. It never lets a wrong
/// call reach the engine (which throws): a kick that does not fit the current
/// prompt is ignored and logged.
final class MatchProvider extends SafeNotifier<MatchView> {
  MatchProvider(this._log) : super(const MatchView());

  final LogPort _log;
  MatchEngine? _engine;
  int _version = 0;

  /// Starts a match, replacing any match in progress. Stages 6 and 12 are
  /// boss stages in Journey.
  void start(MatchConfig config) {
    final int? stageId = config.stageId;
    bool boss = false;
    if (config.mode == MatchMode.journey && stageId != null) {
      for (final StageDef stage in StageCatalog.stages) {
        if (stage.id == stageId) {
          boss = stage.isBoss;
        }
      }
    }
    _engine = MatchEngine(config, isBoss: boss);
    _publish(null);
  }

  /// Takes the next kick. Give [shot] when the prompt is a human shot and
  /// [dive] when it is a human dive; automatic kicks need neither. Returns the
  /// kick, or null if it could not be taken.
  KickRecord? kick({ShotParams? shot, KeeperDive? dive}) {
    final MatchEngine? engine = _engine;
    if (engine == null) {
      _log.log(LogLevel.warning, 'match', 'kick with no match');
      return null;
    }
    switch (engine.prompt) {
      case KickPrompt.finished:
        _log.log(LogLevel.warning, 'match', 'kick after the match finished');
        return null;
      case KickPrompt.humanShot:
        if (shot == null) {
          _log.log(LogLevel.warning, 'match', 'a shot is needed');
          return null;
        }
      case KickPrompt.humanDive:
        if (dive == null) {
          _log.log(LogLevel.warning, 'match', 'a dive is needed');
          return null;
        }
      case KickPrompt.automatic:
        break;
    }
    final KickRecord record = engine.kick(shot: shot, dive: dive);
    _publish(record);
    return record;
  }

  /// Uses one Selah. Returns false if none can be used now.
  bool useSelah() {
    final MatchEngine? engine = _engine;
    if (engine == null || !engine.canUseSelah) {
      return false;
    }
    engine.useSelah();
    _publish(value.lastKick);
    return true;
  }

  /// The facts the career needs, once the match has finished.
  MatchSummary? get summary {
    final MatchEngine? engine = _engine;
    if (engine == null || !engine.isFinished) {
      return null;
    }
    return MatchSummary(
      config: engine.config,
      finalState: engine.state,
      history: engine.history,
    );
  }

  /// The side that won, once finished.
  MatchSide? get winner => _engine?.winner;

  /// Throws the match away (leaving mid-match counts for nothing).
  void abandon() {
    _engine = null;
    _version += 1;
    value = MatchView(version: _version);
  }

  void _publish(KickRecord? last) {
    final MatchEngine engine = _engine!;
    _version += 1;
    value = MatchView(
      config: engine.config,
      state: engine.state,
      history: engine.history,
      prompt: engine.prompt,
      canUseSelah: engine.canUseSelah,
      shieldAvailable: engine.shieldAvailable,
      revealedTendency: engine.revealedTendency,
      lastKick: last,
      version: _version,
    );
  }
}
