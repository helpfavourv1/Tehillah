import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/scroll_body.dart';
import 'package:tehillah/widgets/section_header.dart';
import 'package:tehillah/widgets/verse_card.dart';

final class StageIntroLabels {
  const StageIntroLabels({
    required this.back,
    required this.start,
    required this.opponent,
    required this.loadout,
    required this.changeLoadout,
    required this.noGear,
    required this.readChapter,
    required this.share,
  });

  final String back;
  final String start;
  final String opponent;
  final String loadout;

  /// The accessibility label of the loadout card, which opens the picker.
  final String changeLoadout;

  /// Shown where the gear would be when none is chosen.
  final String noGear;
  final String readChapter;
  final String share;
}

/// One fact about the match, shown as a chip (boss stage, wind, difficulty).
final class IntroFact {
  const IntroFact({required this.label, required this.icon, this.tone = ChipTone.neutral});

  final String label;
  final IconData icon;
  final ChipTone tone;
}

/// A verse for the intro, already in the app language.
final class IntroVerse {
  const IntroVerse({
    required this.text,
    required this.reference,
    required this.language,
    this.translationLabel,
    this.onReadChapter,
    this.onShare,
  });

  final String text;
  final String reference;
  final String language;
  final String? translationLabel;
  final VoidCallback? onReadChapter;
  final VoidCallback? onShare;
}

/// Before the whistle: who you face, what is special about it, a verse, and
/// the ball and gear you take in. Start is fixed at the bottom; only the
/// content above it scrolls.
class StageIntroScreen extends StatelessWidget {
  const StageIntroScreen({
    required this.labels,
    required this.title,
    required this.opponentName,
    required this.opponentTeam,
    required this.ballName,
    required this.onStart,
    required this.onChangeLoadout,
    required this.onBack,
    super.key,
    this.roundLabel,
    this.facts = const <IntroFact>[],
    this.verse,
    this.gearName,
  });

  final StageIntroLabels labels;

  /// The stage or mode name.
  final String title;

  /// "Round 2 of 4", when the mode has rounds.
  final String? roundLabel;
  final String opponentName;
  final String opponentTeam;
  final List<IntroFact> facts;
  final IntroVerse? verse;
  final String ballName;
  final String? gearName;
  final VoidCallback onStart;
  final VoidCallback onChangeLoadout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final IntroVerse? v = verse;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ScrollBody(
              children: <Widget>[
                if (roundLabel != null) ...<Widget>[
                  Text(roundLabel!, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
                  const SizedBox(height: Sp.sm),
                ],
                SectionHeader(labels.opponent, padding: EdgeInsets.zero),
                const SizedBox(height: Sp.sm),
                AppCard(label: opponentName, subtitle: opponentTeam, leading: AppIcons.flag),
                if (facts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Sp.sm),
                  Wrap(
                    spacing: Sp.sm,
                    runSpacing: Sp.xs,
                    children: <Widget>[
                      for (final IntroFact f in facts) AppChip(label: f.label, icon: f.icon, tone: f.tone),
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
                const SizedBox(height: Sp.lg),
                SectionHeader(labels.loadout, padding: EdgeInsets.zero),
                const SizedBox(height: Sp.sm),
                AppCard(
                  label: ballName,
                  subtitle: gearName ?? labels.noGear,
                  leading: AppIcons.ball,
                  chevron: true,
                  onTap: onChangeLoadout,
                  semanticLabel: '${labels.changeLoadout}: $ballName, ${gearName ?? labels.noGear}',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.md),
            child: PrimaryButton(label: labels.start, icon: AppIcons.play, onPressed: onStart),
          ),
        ],
      ),
    );
  }
}
