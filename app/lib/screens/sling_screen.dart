import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/core/logic/sling_rules.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/input/sling_aim_layer.dart';
import 'package:tehillah/game/sling_controller.dart';
import 'package:tehillah/game/sling_game.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/pause_sheet.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/star_row.dart';
import 'package:tehillah/widgets/stat_pill.dart';

final class SlingLabels {
  const SlingLabels({
    required this.pause,
    required this.pauseTitle,
    required this.resume,
    required this.leave,
    required this.stones,
    required this.targets,
    required this.targetsValue,
    required this.aimHint,
    required this.aimArea,
    required this.roundDone,
    required this.roundPerfect,
    required this.starsLabel,
    required this.playAgain,
    required this.extraStones,
    required this.summary,
  });

  final String pause;
  final String pauseTitle;
  final String resume;
  final String leave;

  /// The stones-left pill.
  final String stones;

  /// The targets pill, and its value ("2 of 5").
  final String targets;
  final String Function(int hit, int total) targetsValue;

  /// Shown while aiming.
  final String aimHint;

  /// What a screen reader says about the aiming area.
  final String aimArea;

  /// The headline when the round ends with targets left, and when every
  /// target was hit.
  final String roundDone;
  final String roundPerfect;

  /// "2 of 3 stars".
  final String Function(int stars, int total) starsLabel;
  final String playAgain;
  final String extraStones;

  /// "You hit 4 of 5 targets."
  final String Function(int hit, int total) summary;
}

/// Sling and Stone: the scene full-bleed, the aiming layer over it, the pills
/// at the top and, when the round ends, a panel with the stars and the way on.
///
/// The caller owns [game] and [controller] and starts the round
/// (`controller.start(seed)`). A round is recorded only when the player moves
/// on from the end panel, through [onPlayAgain] or [onLeave], each with the
/// stars earned; leaving from the pause sheet reports [onQuit] and records
/// nothing. [onWatchForStones] is null when no rewarded ad is available; it
/// returns whether the reward was earned.
class SlingScreen extends StatefulWidget {
  const SlingScreen({
    required this.labels,
    required this.controller,
    required this.game,
    required this.onPlayAgain,
    required this.onLeave,
    required this.onQuit,
    super.key,
    this.onWatchForStones,
  });

  final SlingLabels labels;
  final SlingController controller;
  final SlingGame game;
  final void Function(int stars) onPlayAgain;
  final void Function(int stars) onLeave;
  final VoidCallback onQuit;
  final Future<bool> Function()? onWatchForStones;

  @override
  State<SlingScreen> createState() => _SlingScreenState();
}

class _SlingScreenState extends State<SlingScreen> {
  bool _sheetOpen = false;
  bool _busy = false;

  Future<void> _pause() async {
    final SlingState? s = widget.controller.state.value;
    if (_sheetOpen || !mounted || s == null || s.finished) {
      return;
    }
    _sheetOpen = true;
    widget.controller.pause();
    final SlingLabels labels = widget.labels;
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

  Future<void> _extraStones() async {
    final Future<bool> Function()? watch = widget.onWatchForStones;
    if (watch == null || _busy || !widget.controller.canOfferExtraStones) {
      return;
    }
    setState(() => _busy = true);
    bool earned = false;
    try {
      earned = await watch();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    if (earned && mounted) {
      widget.controller.addExtraStones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    widget.game.palette = theme.palette;
    final SlingController c = widget.controller;
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
                GameWidget<SlingGame>(game: widget.game),
                ValueListenableBuilder<bool>(
                  valueListenable: c.inputEnabled,
                  builder: (BuildContext context, bool enabled, Widget? _) => enabled
                      ? SlingAimLayer(
                          projection: projection,
                          semanticLabel: widget.labels.aimArea,
                          onRelease: (double d, double e) =>
                              c.release(direction: d, elevation: e),
                        )
                      : const SizedBox.shrink(),
                ),
                ValueListenableBuilder<SlingState?>(
                  valueListenable: c.state,
                  builder: (BuildContext context, SlingState? s, Widget? _) =>
                      _Hud(state: s, labels: widget.labels, onPause: () => unawaited(_pause())),
                ),
                ValueListenableBuilder<SlingState?>(
                  valueListenable: c.state,
                  builder: (BuildContext context, SlingState? s, Widget? _) {
                    if (s == null || !s.finished) {
                      return const SizedBox.shrink();
                    }
                    return _EndPanel(
                      state: s,
                      labels: widget.labels,
                      canExtra: widget.onWatchForStones != null && s.canOfferExtraStones,
                      busy: _busy,
                      onExtra: () => unawaited(_extraStones()),
                      onPlayAgain: () => widget.onPlayAgain(s.stars),
                      onLeave: () => widget.onLeave(s.stars),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state, required this.labels, required this.onPause});

  final SlingState? state;
  final SlingLabels labels;
  final VoidCallback onPause;

  static const double _maxTextScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final SlingState? s = state;
    if (s == null) {
      return const SizedBox.shrink();
    }
    final MediaQueryData mq = MediaQuery.of(context);
    final EdgeInsets safe = mq.padding;
    final AppThemeData theme = AppTheme.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: _maxTextScale)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.md + safe.left,
          Sp.sm + safe.top,
          Sp.md + safe.right,
          Sp.md + safe.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconChip(icon: AppIcons.pause, semanticLabel: labels.pause, onTap: onPause),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Sp.sm,
                    runSpacing: Sp.xs,
                    children: <Widget>[
                      StatPill(label: labels.stones, value: '${s.stonesLeft}'),
                      StatPill(
                        label: labels.targets,
                        value: labels.targetsValue(s.hits, s.targets.length),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.sm),
                const SizedBox(width: Metrics.touchTarget),
              ],
            ),
            const Spacer(),
            if (!s.finished)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text(labels.aimHint, textAlign: TextAlign.center, style: theme.text.callout),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EndPanel extends StatelessWidget {
  const _EndPanel({
    required this.state,
    required this.labels,
    required this.canExtra,
    required this.busy,
    required this.onExtra,
    required this.onPlayAgain,
    required this.onLeave,
  });

  final SlingState state;
  final SlingLabels labels;
  final bool canExtra;
  final bool busy;
  final VoidCallback onExtra;
  final VoidCallback onPlayAgain;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.md + safe.left,
          Sp.md,
          Sp.md + safe.right,
          Sp.md + safe.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: CardSurface(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      state.allHit ? labels.roundPerfect : labels.roundDone,
                      textAlign: TextAlign.center,
                      style: theme.text.title1,
                    ),
                  ),
                  const SizedBox(height: Sp.sm),
                  Center(
                    child: StarRow(
                      stars: state.stars,
                      semanticLabel: labels.starsLabel(state.stars, 3),
                    ),
                  ),
                  const SizedBox(height: Sp.sm),
                  Text(
                    labels.summary(state.hits, state.targets.length),
                    textAlign: TextAlign.center,
                    style: theme.text.callout.copyWith(color: theme.palette.textSecondary),
                  ),
                  const SizedBox(height: Sp.md),
                  if (canExtra) ...<Widget>[
                    SecondaryButton(
                      label: labels.extraStones,
                      icon: AppIcons.play,
                      onPressed: busy ? null : onExtra,
                    ),
                    const SizedBox(height: Sp.sm),
                  ],
                  PrimaryButton(label: labels.playAgain, icon: AppIcons.retry, onPressed: onPlayAgain),
                  const SizedBox(height: Sp.sm),
                  SecondaryButton(label: labels.leave, icon: AppIcons.close, onPressed: onLeave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
