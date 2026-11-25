import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/core/input/flick_strategy.dart';
import 'package:tehillah/core/input/shot_input_strategy.dart';
import 'package:tehillah/core/input/timing_bar_strategy.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/hud/match_hud.dart';
import 'package:tehillah/game/input/dive_layer.dart';
import 'package:tehillah/game/input/flick_layer.dart';
import 'package:tehillah/game/input/timing_bar_layer.dart';
import 'package:tehillah/game/match_controller.dart';
import 'package:tehillah/game/tehillah_game.dart';
import 'package:tehillah/providers/match_provider.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/widgets/pause_sheet.dart';

final class MatchScreenLabels {
  const MatchScreenLabels({
    required this.hud,
    required this.zoneLabel,
    required this.flickHint,
    required this.stopLabel,
    required this.pauseTitle,
    required this.resume,
    required this.leave,
  });

  final MatchHudLabels hud;

  /// The localized name of a goal zone, for screen readers ("Left, low").
  final String Function(int column, int row) zoneLabel;

  /// What a screen reader says about the swipe area.
  final String flickHint;

  /// What a screen reader says about the stop button of the timing bar.
  final String stopLabel;
  final String pauseTitle;
  final String resume;
  final String leave;
}

/// The match: the Flame pitch full-bleed, the input layer for what is being
/// asked (swipe, timing bar or dive), and the HUD over everything. Pausing
/// (the HUD button or the system back gesture) opens a sheet with Resume and
/// Leave; nothing moves and no kick is taken while it is open.
///
/// The caller starts the match on [match] before showing this screen, owns
/// [game] and [controller], and learns the result through [onFinished] (after
/// the last kick has played) or [onQuit].
class MatchScreen extends StatefulWidget {
  const MatchScreen({
    required this.labels,
    required this.match,
    required this.controller,
    required this.game,
    required this.scheme,
    required this.onFinished,
    required this.onQuit,
    super.key,
    this.onFlickRejected,
  });

  final MatchScreenLabels labels;
  final MatchProvider match;
  final MatchController controller;
  final TehillahGame game;
  final InputScheme scheme;
  final VoidCallback onFinished;
  final VoidCallback onQuit;

  /// A swipe that was too short or the wrong way; the caller may say so.
  final VoidCallback? onFlickRejected;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  ShotInputStrategy? _strategy;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _strategy = _buildStrategy();
    widget.controller.onMatchFinished = widget.onFinished;
    widget.controller.attach(input: _strategy);
  }

  @override
  void didUpdateWidget(MatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheme != widget.scheme) {
      final ShotInputStrategy? old = _strategy;
      _strategy = _buildStrategy();
      widget.controller.setInput(_strategy);
      old?.dispose();
    }
    widget.controller.onMatchFinished = widget.onFinished;
  }

  @override
  void dispose() {
    widget.controller.detach();
    _strategy?.dispose();
    super.dispose();
  }

  ShotInputStrategy? _buildStrategy() {
    final MatchConfig? config = widget.match.value.config;
    if (config != null && config.mode == MatchMode.watchman) {
      return null;
    }
    switch (widget.scheme) {
      case InputScheme.flick:
        return FlickStrategy();
      case InputScheme.timingBar:
        final double speed = config == null
            ? 1.0
            : (1 + Modifiers.fromLoadout(config.loadout).timingBarSpeed).clamp(0.5, 1.5);
        return TimingBarStrategy(speedFactor: speed);
    }
  }

  Future<void> _pause() async {
    if (_sheetOpen || !mounted) {
      return;
    }
    _sheetOpen = true;
    widget.controller.pause();
    final MatchScreenLabels labels = widget.labels;
    final bool leave = await showPauseSheet(
      context: context,
      title: labels.pauseTitle,
      resumeLabel: labels.resume,
      leaveLabel: labels.leave,
    );
    _sheetOpen = false;
    if (!mounted) {
      return;
    }
    if (leave) {
      widget.onQuit();
    } else {
      widget.controller.resume();
    }
  }

  Widget _input(PitchProjection projection, bool enabled) {
    final MatchView view = widget.match.value;
    if (!view.active || !enabled) {
      return const SizedBox.shrink();
    }
    final MatchScreenLabels labels = widget.labels;
    final ShotInputStrategy? strategy = _strategy;
    switch (view.prompt) {
      case KickPrompt.humanShot:
        if (strategy is FlickStrategy) {
          return FlickLayer(
            strategy: strategy,
            semanticLabel: labels.flickHint,
            onRejected: widget.onFlickRejected,
          );
        }
        if (strategy is TimingBarStrategy) {
          return TimingBarLayer(
            strategy: strategy,
            projection: projection,
            zoneLabel: labels.zoneLabel,
            stopLabel: labels.stopLabel,
          );
        }
        return const SizedBox.shrink();
      case KickPrompt.humanDive:
        return DiveLayer(
          projection: projection,
          zoneLabel: labels.zoneLabel,
          onDive: widget.controller.submitDive,
        );
      case KickPrompt.automatic:
      case KickPrompt.finished:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    widget.game.palette = theme.palette;
    widget.game.reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_pause());
        }
      },
      child: ColoredBox(
        color: theme.palette.bgPrimary,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final PitchProjection projection =
                PitchProjection.fit(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GameWidget<TehillahGame>(game: widget.game),
                ListenableBuilder(
                  listenable: Listenable.merge(<Listenable>[widget.match, widget.controller.inputEnabled]),
                  builder: (BuildContext context, Widget? _) => _input(
                    projection,
                    widget.controller.inputEnabled.value,
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge(<Listenable>[widget.match, widget.controller.inputEnabled]),
                  builder: (BuildContext context, Widget? _) => MatchHud(
                    view: widget.match.value,
                    labels: widget.labels.hud,
                    onPause: () => unawaited(_pause()),
                    onSelah: widget.controller.useSelah,
                    enabled: widget.controller.inputEnabled.value,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
