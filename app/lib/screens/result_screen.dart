import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';
import 'package:tehillah/widgets/star_row.dart';
import 'package:tehillah/widgets/stat_pill.dart';
import 'package:tehillah/widgets/verse_card.dart';

final class ResultLabels {
  const ResultLabels({
    required this.win,
    required this.loss,
    required this.you,
    required this.opponent,
    required this.scoreLine,
    required this.starsLabel,
    required this.readChapter,
    required this.share,
  });

  /// The headline after a win and after a loss. A loss is met with
  /// encouragement, never mockery.
  final String win;
  final String loss;
  final String you;
  final String opponent;

  /// "3 to 2", for screen readers.
  final String Function(int you, int opponent) scoreLine;

  /// "2 of 3 stars".
  final String Function(int stars, int total) starsLabel;
  final String readChapter;
  final String share;
}

/// After the whistle: the score, the stars, what was earned, a verse, and the
/// way on. The leaving buttons run [beforeLeave] first (the interstitial's
/// natural break), once, and ignore a second tap while it runs.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.labels,
    required this.won,
    required this.playerScore,
    required this.opponentScore,
    required this.stars,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
    this.earned = const <IntroFact>[],
    this.verse,
    this.secondaryLabel,
    this.onSecondary,
    this.rewardedRetryLabel,
    this.onRewardedRetry,
    this.beforeLeave,
  })  : assert((secondaryLabel == null) == (onSecondary == null)),
        assert((rewardedRetryLabel == null) == (onRewardedRetry == null));

  final ResultLabels labels;
  final bool won;
  final int playerScore;
  final int opponentScore;

  /// Zero to three.
  final int stars;

  /// New lamps, unlocks and achievements, already in words.
  final List<IntroFact> earned;
  final IntroVerse? verse;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// An optional, opt-in ad offer to replay a lost Journey match.
  final String? rewardedRetryLabel;
  final VoidCallback? onRewardedRetry;

  /// Runs before leaving through the primary or secondary button.
  final Future<void> Function()? beforeLeave;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _leaving = false;

  Future<void> _leave(VoidCallback action) async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    await widget.beforeLeave?.call();
    if (!mounted) {
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final ResultLabels labels = widget.labels;
    final IntroVerse? v = widget.verse;
    // At very large text the buttons would crowd out the content, so they
    // scroll with it instead of staying fixed.
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final Widget buttonBar = Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (widget.rewardedRetryLabel != null) ...<Widget>[
                  SecondaryButton(
                    label: widget.rewardedRetryLabel!,
                    icon: AppIcons.retry,
                    onPressed: widget.onRewardedRetry,
                  ),
                  const SizedBox(height: Sp.sm),
                ],
                PrimaryButton(
                  label: widget.primaryLabel,
                  icon: AppIcons.forward,
                  onPressed: () => unawaited(_leave(widget.onPrimary)),
                ),
                if (widget.secondaryLabel != null) ...<Widget>[
                  const SizedBox(height: Sp.sm),
                  SecondaryButton(
                    label: widget.secondaryLabel!,
                    onPressed: () => unawaited(_leave(widget.onSecondary!)),
                  ),
                ],
              ],
            ),
          );
    return ScreenFrame(
      navBar: NavBar(title: widget.won ? labels.win : labels.loss),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ScrollBody(
              children: <Widget>[
                Semantics(
                  label: labels.scoreLine(widget.playerScore, widget.opponentScore),
                  excludeSemantics: true,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Sp.sm,
                    runSpacing: Sp.xs,
                    children: <Widget>[
                      StatPill(label: labels.you, value: '${widget.playerScore}'),
                      StatPill(label: labels.opponent, value: '${widget.opponentScore}'),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.lg),
                Center(
                  child: StarRow(
                    stars: widget.stars,
                    semanticLabel: labels.starsLabel(widget.stars, 3),
                  ),
                ),
                const SizedBox(height: Sp.xs),
                Center(
                  child: Text(
                    labels.starsLabel(widget.stars, 3),
                    style: theme.text.footnote,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.earned.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Sp.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Sp.sm,
                    runSpacing: Sp.xs,
                    children: <Widget>[
                      for (final IntroFact f in widget.earned)
                        AppChip(label: f.label, icon: f.icon, tone: f.tone),
                    ],
                  ),
                ],
                if (v != null) ...<Widget>[
                  const SizedBox(height: Sp.lg),
                  VerseCard(
                    text: v.text,
                    reference: v.reference,
                    language: v.language,
                    translationLabel: v.translationLabel,
                    onReadChapter: v.onReadChapter,
                    readChapterLabel: v.onReadChapter == null ? null : labels.readChapter,
                    onShare: v.onShare,
                    shareLabel: v.onShare == null ? null : labels.share,
                  ),
                ],
                if (stacked) buttonBar,
              ],
            ),
          ),
          if (!stacked) buttonBar,
        ],
      ),
    );
  }
}
