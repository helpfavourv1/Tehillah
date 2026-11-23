import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';

/// A scripture moment: the verse, its reference, and optional Read chapter and
/// Share actions. The verse keeps the direction of its own language, so a
/// Hebrew verse reads right to left under an English interface.
class VerseCard extends StatelessWidget {
  const VerseCard({
    required this.text,
    required this.reference,
    required this.language,
    super.key,
    this.translationLabel,
    this.onReadChapter,
    this.readChapterLabel,
    this.onShare,
    this.shareLabel,
  }) : assert(
          (onReadChapter == null) == (readChapterLabel == null) &&
              (onShare == null) == (shareLabel == null),
          'each action needs both its callback and its label',
        );

  final String text;

  /// The localized reference, for example "John 3:16".
  final String reference;

  /// The verse's language code, which sets its reading direction.
  final String language;

  /// The translation name shown with the reference, for example "BSB".
  final String? translationLabel;

  final VoidCallback? onReadChapter;
  final String? readChapterLabel;
  final VoidCallback? onShare;
  final String? shareLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final TextDirection direction = directionForLanguage(language);
    final bool hasActions = onReadChapter != null || onShare != null;
    final String credit =
        translationLabel == null ? reference : '$reference · $translationLabel';
    return CardSurface(
      fill: theme.palette.verseCardSurface,
      radius: Radii.hero,
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Directionality(
            textDirection: direction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(text, style: theme.text.body),
                const SizedBox(height: Sp.md),
                Text(credit, style: theme.text.footnote),
              ],
            ),
          ),
          if (hasActions) ...<Widget>[
            const SizedBox(height: Sp.md),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.xs,
              children: <Widget>[
                if (onReadChapter != null)
                  AppChip(
                    label: readChapterLabel!,
                    icon: AppIcons.reader,
                    tone: ChipTone.accent,
                    onTap: onReadChapter,
                  ),
                if (onShare != null)
                  AppChip(
                    label: shareLabel!,
                    icon: AppIcons.share,
                    tone: ChipTone.accent,
                    onTap: onShare,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
