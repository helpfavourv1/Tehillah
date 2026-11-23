import 'package:flutter/widgets.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/providers/match_provider.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/nerve_meter_view.dart';
import 'package:tehillah/widgets/stat_pill.dart';

/// Every word the HUD shows or speaks, supplied by the screen from the
/// localizations, so this file holds no literal text.
@immutable
final class MatchHudLabels {
  const MatchHudLabels({
    required this.you,
    required this.opponent,
    required this.pause,
    required this.selah,
    required this.selahWithCharges,
    required this.nerve,
    required this.nerveCalm,
    required this.nerveTense,
    required this.nerveFull,
    required this.suddenDeath,
    required this.promptShot,
    required this.promptDive,
    required this.promptWatch,
    required this.kickScored,
    required this.kickMissed,
    required this.kickPending,
  });

  final String you;
  final String opponent;
  final String pause;
  final String selah;

  /// "Selah, 2 left".
  final String Function(int charges) selahWithCharges;

  final String nerve;
  final String nerveCalm;
  final String nerveTense;
  final String nerveFull;
  final String suddenDeath;
  final String promptShot;
  final String promptDive;
  final String promptWatch;

  /// Spoken for each kick dot.
  final String kickScored;
  final String kickMissed;
  final String kickPending;
}

/// The overlay on the match: score, a row of kick marks per side, the pressure
/// meter and the Selah pause. Scores and marks use icons and words as well as
/// colour. Empty areas let touches through to the pitch.
class MatchHud extends StatelessWidget {
  const MatchHud({
    required this.view,
    required this.labels,
    required this.onPause,
    required this.onSelah,
    super.key,
    this.enabled = true,
  });

  final MatchView view;
  final MatchHudLabels labels;
  final VoidCallback onPause;

  /// Called when Selah is pressed and allowed.
  final VoidCallback onSelah;

  /// False while a kick is playing: Selah is dimmed until the next kick.
  final bool enabled;

  String _stateLabel(double nerve) {
    if (nerve < NerveMeterView.calmBelow) {
      return labels.nerveCalm;
    }
    return nerve < NerveMeterView.tenseAt ? labels.nerveTense : labels.nerveFull;
  }

  String? _prompt() => switch (view.prompt) {
        KickPrompt.humanShot => labels.promptShot,
        KickPrompt.humanDive => labels.promptDive,
        KickPrompt.automatic => labels.promptWatch,
        KickPrompt.finished => null,
      };

  @override
  Widget build(BuildContext context) {
    // The HUD sits over live play, so it is held to a glanceable ceiling; the
    // same facts are spoken through semantics, and every other screen follows
    // the system text size in full.
    final MediaQueryData mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: _maxTextScale)),
      child: Builder(builder: _content),
    );
  }

  static const double _maxTextScale = 1.6;

  Widget _content(BuildContext context) {
    final MatchState? state = view.state;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final AppThemeData theme = AppTheme.of(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final bool canSelah = enabled && view.canUseSelah;
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final Widget nerve = NerveMeterView(
      value: state.nerve,
      label: labels.nerve,
      stateLabel: _stateLabel(state.nerve),
    );
    final Widget selah = Opacity(
      opacity: canSelah ? 1 : Metrics.disabledOpacity,
      child: Semantics(
        label: labels.selahWithCharges(state.selahCharges),
        excludeSemantics: true,
        button: true,
        enabled: canSelah,
        child: AppChip(
          label: '${labels.selah} · ${state.selahCharges}',
          icon: AppIcons.lamp,
          tone: ChipTone.accent,
          onTap: canSelah ? onSelah : null,
        ),
      ),
    );
    final String? prompt = _prompt();
    return Padding(
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
                    StatPill(label: labels.you, value: '${state.playerScore}'),
                    StatPill(label: labels.opponent, value: '${state.opponentScore}'),
                  ],
                ),
              ),
              const SizedBox(width: Sp.sm),
              const SizedBox(width: Metrics.touchTarget),
            ],
          ),
          const SizedBox(height: Sp.sm),
          _KickMarks(
            side: MatchSide.player,
            name: labels.you,
            view: view,
            labels: labels,
          ),
          const SizedBox(height: Sp.xs),
          _KickMarks(
            side: MatchSide.opponent,
            name: labels.opponent,
            view: view,
            labels: labels,
          ),
          if (state.isSuddenDeath) ...<Widget>[
            const SizedBox(height: Sp.sm),
            Center(child: AppChip(label: labels.suddenDeath, icon: AppIcons.warning, tone: ChipTone.warning)),
          ],
          const Spacer(),
          if (prompt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  prompt,
                  textAlign: TextAlign.center,
                  style: theme.text.callout,
                ),
              ),
            ),
          if (stacked) ...<Widget>[
            nerve,
            const SizedBox(height: Sp.sm),
            Align(alignment: AlignmentDirectional.centerEnd, child: selah),
          ] else
            Row(
              children: <Widget>[
                Expanded(child: nerve),
                const SizedBox(width: Sp.md),
                selah,
              ],
            ),
        ],
      ),
    );
  }
}

/// One side's kicks: a mark for each kick taken and an empty ring for each
/// still to come. A goal is a ticked circle, a miss a crossed one.
class _KickMarks extends StatelessWidget {
  const _KickMarks({
    required this.side,
    required this.name,
    required this.view,
    required this.labels,
  });

  final MatchSide side;
  final String name;
  final MatchView view;
  final MatchHudLabels labels;

  static const double dot = Sp.lg;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final MatchState state = view.state!;
    final List<KickRecord> taken = <KickRecord>[
      for (final KickRecord k in view.history)
        if (k.side == side) k,
    ];
    final int slots = taken.length > state.kicksPerSide ? taken.length : state.kicksPerSide;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: Sp.sm),
            child: Text(name, style: theme.text.caption, overflow: TextOverflow.ellipsis),
          ),
        ),
        Wrap(
          spacing: Sp.xs,
          children: <Widget>[
            for (int i = 0; i < slots; i++)
              _Dot(
                result: i < taken.length ? taken[i].isGoal : null,
                labels: labels,
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.result, required this.labels});

  /// True for a goal, false for a miss, null for a kick not yet taken.
  final bool? result;
  final MatchHudLabels labels;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    final bool? r = result;
    final Color border = r == null ? p.borderSubtle : (r ? p.success : p.error);
    return Semantics(
      label: r == null ? labels.kickPending : (r ? labels.kickScored : labels.kickMissed),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: _KickMarks.dot,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: r == null ? const Color(0x00000000) : border.withValues(alpha: 0.18),
              border: Border.all(color: border, width: 1.5),
            ),
            child: r == null
                ? null
                : Center(
                    child: AppIcon(
                      r ? AppIcons.check : AppIcons.close,
                      size: IconSizes.rowTrailing - Sp.xs,
                      color: border,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
