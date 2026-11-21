import 'package:tehillah/core/logic/keeper_ai.dart';
import 'package:tehillah/core/logic/match_rules.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/logic/shooter_ai.dart';
import 'package:tehillah/core/logic/shot_resolver.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// What the engine needs next.
enum KickPrompt {
  /// The player aims and strikes ([MatchEngine.kick] needs a shot).
  humanShot,

  /// The player, as the goalkeeper, chooses a dive ([MatchEngine.kick] needs a
  /// dive).
  humanDive,

  /// The computer plays both parts of the kick; call [MatchEngine.kick] with no
  /// arguments.
  automatic,

  /// The match is decided.
  finished,
}

/// Plays one match from a [MatchConfig]. It holds the running state, the kick
/// history, the unused Shield of Faith and the seeded generators, and is the
/// object the match provider wraps. Given the same config and the same inputs
/// it always produces the same match.
final class MatchEngine {
  MatchEngine(this.config, {bool? isBoss})
      : mods = Modifiers.fromLoadout(config.loadout),
        isBoss = isBoss ?? false,
        _shotRng = SeededRng(config.seed).fork('shot'),
        _keeperRng = SeededRng(config.seed).fork('keeper'),
        _shooterRng = SeededRng(config.seed).fork('shooter') {
    _state = MatchRules.start(config, mods);
  }

  /// The keeper the player controls in Watchman. It stands for the player's
  /// reflexes; the dive itself is the player's choice.
  static final KeeperProfile watchmanKeeper = KeeperProfile(
    reaction: 0.7,
    reach: 0.7,
    habitReading: 0,
    tendency: <KeeperDive, double>{
      KeeperDive.leftLow: 1,
      KeeperDive.leftHigh: 1,
      KeeperDive.centerLow: 1,
      KeeperDive.centerHigh: 1,
      KeeperDive.rightLow: 1,
      KeeperDive.rightHigh: 1,
    },
  );

  /// Difficulty of the computer shooter that takes the player's kicks in
  /// Watchman.
  static const double watchmanShooterDifficulty = 0.5;

  final MatchConfig config;
  final Modifiers mods;
  final bool isBoss;

  final SeededRng _shotRng;
  final SeededRng _keeperRng;
  final SeededRng _shooterRng;
  late MatchState _state;
  final List<KickRecord> _history = <KickRecord>[];
  bool _shieldUsed = false;

  MatchState get state => _state;
  List<KickRecord> get history => List<KickRecord>.unmodifiable(_history);
  bool get isFinished => MatchRules.isFinished(_state);
  MatchSide? get winner => MatchRules.winner(_state);

  /// Whether the Shield of Faith can still turn a post into a goal.
  bool get shieldAvailable =>
      mods.special == GearSpecial.postToGoalOnce && !_shieldUsed;

  bool get _isWatchman => config.mode == MatchMode.watchman;

  KickPrompt get prompt {
    if (isFinished) {
      return KickPrompt.finished;
    }
    final bool playerTurn = _state.turn == MatchSide.player;
    if (_isWatchman) {
      return playerTurn ? KickPrompt.automatic : KickPrompt.humanDive;
    }
    return playerTurn ? KickPrompt.humanShot : KickPrompt.automatic;
  }

  /// True when the player may pause with Selah before this kick.
  bool get canUseSelah =>
      prompt == KickPrompt.humanShot && _state.selahCharges > 0;

  /// With the Belt of Truth, the dive the keeper favours, once the player has
  /// taken two kicks. Null otherwise.
  KeeperDive? get revealedTendency {
    if (mods.special != GearSpecial.revealTendency ||
        prompt != KickPrompt.humanShot ||
        _state.playerKicks < 2) {
      return null;
    }
    return KeeperAi.mostLikely(config.opponent.keeper);
  }

  /// Uses a Selah pause before the next kick.
  void useSelah() {
    if (!canUseSelah) {
      throw StateError('Selah cannot be used now');
    }
    _state = MatchRules.useSelah(_state, mods);
  }

  List<ShotParams> get _playerShots => <ShotParams>[
        for (final KickRecord k in _history)
          if (k.side == MatchSide.player) k.params,
      ];

  /// Plays the next kick. Pass [shot] when [prompt] is
  /// [KickPrompt.humanShot] and [dive] when it is [KickPrompt.humanDive].
  KickRecord kick({ShotParams? shot, KeeperDive? dive}) {
    final KickPrompt now = prompt;
    final MatchSide side = _state.turn;
    final ShotParams params;
    final KeeperDive keeperDive;
    final KeeperProfile keeper;
    final double nerve;
    final Modifiers shotMods;
    final bool humanShooter = now == KickPrompt.humanShot;

    switch (now) {
      case KickPrompt.finished:
        throw StateError('the match is already finished');
      case KickPrompt.humanShot:
        if (shot == null) {
          throw ArgumentError.notNull('shot');
        }
        params = shot;
        keeper = config.opponent.keeper;
        keeperDive = KeeperAi.decide(
          profile: keeper,
          playerShots: _playerShots,
          rng: _keeperRng,
        );
        nerve = _state.nerve;
        shotMods = mods;
      case KickPrompt.humanDive:
        if (dive == null) {
          throw ArgumentError.notNull('dive');
        }
        params = ShooterAi.choose(
          difficulty: config.difficulty,
          rng: _shooterRng,
        );
        keeper = watchmanKeeper;
        keeperDive = dive;
        nerve = 0;
        shotMods = Modifiers.none;
      case KickPrompt.automatic:
        if (side == MatchSide.opponent) {
          params = ShooterAi.choose(
            difficulty: config.difficulty,
            rng: _shooterRng,
          );
          keeper = ShooterAi.defender(config.difficulty);
          keeperDive = KeeperAi.decide(
            profile: keeper,
            playerShots: const <ShotParams>[],
            rng: _keeperRng,
          );
        } else {
          params = ShooterAi.choose(
            difficulty: watchmanShooterDifficulty,
            rng: _shooterRng,
          );
          keeper = config.opponent.keeper;
          keeperDive = KeeperAi.decide(
            profile: keeper,
            playerShots: _playerShots,
            rng: _keeperRng,
          );
        }
        nerve = 0;
        shotMods = Modifiers.none;
    }

    final ShotResolution resolution = ShotResolver.resolve(
      params: params,
      dive: keeperDive,
      mods: shotMods,
      nerve: nerve,
      wind: config.wind,
      keeper: keeper,
      rng: _shotRng,
      postToGoalAvailable: humanShooter && shieldAvailable,
    );
    if (resolution.shieldUsed) {
      _shieldUsed = true;
    }
    final KickRecord record = KickRecord(
      side: side,
      round: _state.kicksOf(side) + 1,
      params: params,
      outcome: resolution.outcome,
    );
    _state = MatchRules.apply(
      state: _state,
      kick: record,
      mods: mods,
      isBoss: isBoss,
    );
    _history.add(record);
    return record;
  }
}
