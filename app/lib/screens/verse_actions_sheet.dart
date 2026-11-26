import 'package:flutter/widgets.dart';
import 'package:tehillah/screens/reader_screen.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_row.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/section_header.dart';

final class VerseActionsLabels {
  const VerseActionsLabels({
    required this.bookmark,
    required this.removeBookmark,
    required this.highlight,
    required this.removeHighlight,
    required this.share,
    required this.tone,
    required this.chosen,
  });

  final String bookmark;
  final String removeBookmark;
  final String highlight;
  final String removeHighlight;
  final String share;

  /// The name of a highlight colour ("Gold", "Green", "Blue", "Rose").
  final String Function(MarkTone tone) tone;

  /// Said after the colour that is on the verse now.
  final String chosen;
}

/// The content of the verse actions sheet: bookmark on or off, four highlight
/// colours (the one in use is ringed and carries a check) with a remove row,
/// and share. The text of the verse is the sheet title, set by the caller.
class VerseActionsSheet extends StatelessWidget {
  const VerseActionsSheet({
    required this.labels,
    required this.bookmarked,
    required this.highlight,
    required this.onToggleBookmark,
    required this.onHighlight,
    required this.onShare,
    super.key,
  });

  final VerseActionsLabels labels;
  final bool bookmarked;
  final MarkTone? highlight;
  final VoidCallback onToggleBookmark;

  /// Null removes the highlight.
  final void Function(MarkTone? tone) onHighlight;
  final VoidCallback onShare;

  Color _fill(AppPalette p, MarkTone t) => switch (t) {
        MarkTone.sun => p.highlightSun,
        MarkTone.leaf => p.highlightLeaf,
        MarkTone.sky => p.highlightSky,
        MarkTone.rose => p.highlightRose,
      };

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppTheme.of(context).palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              AppRow(
                label: bookmarked ? labels.removeBookmark : labels.bookmark,
                leading: AppIcons.bookmark,
                chevron: false,
                onTap: onToggleBookmark,
              ),
              AppRow(
                label: labels.share,
                leading: AppIcons.share,
                chevron: false,
                onTap: onShare,
              ),
            ],
          ),
        ),
        SectionHeader(labels.highlight, padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.lg, 0, Sp.sm)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final MarkTone t in MarkTone.values)
              Semantics(
                label: highlight == t ? '${labels.tone(t)}. ${labels.chosen}' : labels.tone(t),
                button: true,
                selected: highlight == t,
                excludeSemantics: true,
                child: Pressable(
                  onTap: () => onHighlight(t),
                  builder: (BuildContext context, bool pressed) => AnimatedOpacity(
                    opacity: pressed ? Metrics.pressedOpacity : 1,
                    duration: Motion.scaled(context, Motion.press),
                    child: SizedBox.square(
                      dimension: Metrics.touchTarget,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _fill(p, t),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: highlight == t ? p.borderFocus : p.borderSubtle,
                            width: highlight == t ? 2 : 0.5,
                          ),
                        ),
                        child: highlight == t
                            ? Center(
                                child: AppIcon(
                                  AppIcons.check,
                                  size: IconSizes.rowLeading,
                                  color: p.textPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (highlight != null) ...<Widget>[
          const SizedBox(height: Sp.sm),
          CardSurface(
            padding: EdgeInsets.zero,
            child: AppRow(
              label: labels.removeHighlight,
              leading: AppIcons.close,
              chevron: false,
              onTap: () => onHighlight(null),
            ),
          ),
        ],
      ],
    );
  }
}
