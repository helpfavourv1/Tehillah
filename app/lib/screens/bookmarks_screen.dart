import 'package:flutter/widgets.dart';
import 'package:tehillah/screens/reader_screen.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/screen_frame.dart';

/// One saved verse: a bookmark, a highlight, or both.
final class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.reference,
    required this.text,
    required this.language,
    this.bookmarked = false,
    this.highlight,
  });

  final String id;
  final String reference;
  final String text;
  final String language;
  final bool bookmarked;
  final MarkTone? highlight;
}

final class BookmarksLabels {
  const BookmarksLabels({
    required this.title,
    required this.back,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.bookmarked,
    required this.remove,
  });

  final String title;
  final String back;
  final String emptyTitle;
  final String emptySubtitle;
  final String bookmarked;

  /// Announced on each row's remove button.
  final String remove;
}

/// Saved verses, newest first (the caller orders them). Tapping a row opens it
/// in the reader; the small button on the row removes its bookmark and
/// highlight. Only the list scrolls and it is built lazily.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({
    required this.labels,
    required this.items,
    required this.onOpen,
    required this.onRemove,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final BookmarksLabels labels;
  final List<SavedVerse> items;
  final void Function(SavedVerse item) onOpen;
  final void Function(SavedVerse item) onRemove;
  final VoidCallback onBack;
  final Widget? bottom;

  Color _fill(AppPalette p, MarkTone t) => switch (t) {
        MarkTone.sun => p.highlightSun,
        MarkTone.leaf => p.highlightLeaf,
        MarkTone.sky => p.highlightSky,
        MarkTone.rose => p.highlightRose,
      };

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: items.isEmpty
          ? EmptyState(
              icon: AppIcons.bookmark,
              title: labels.emptyTitle,
              subtitle: labels.emptySubtitle,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.lg),
              itemCount: items.length,
              separatorBuilder: (BuildContext c, int i) => const SizedBox(height: Sp.sm),
              itemBuilder: (BuildContext c, int i) {
                final SavedVerse v = items[i];
                final MarkTone? tone = v.highlight;
                return Row(
                  key: ValueKey<String>(v.id),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        label: '${v.reference}. ${v.text}${v.bookmarked ? '. ${labels.bookmarked}' : ''}',
                        button: true,
                        excludeSemantics: true,
                        child: Pressable.opacity(
                          onTap: () => onOpen(v),
                          child: CardSurface(
                            fill: tone == null ? null : _fill(p, tone),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        v.reference,
                                        style: theme.text.callout.copyWith(color: p.accent),
                                      ),
                                    ),
                                    if (v.bookmarked)
                                      AppIcon(
                                        AppIcons.bookmark,
                                        size: IconSizes.rowTrailing,
                                        color: p.accent,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: Sp.xs),
                                Directionality(
                                  textDirection: directionForLanguage(v.language),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      v.text,
                                      style: theme.text
                                          .readerBody(1)
                                          .copyWith(color: p.textPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    Pressable.opacity(
                      onTap: () => onRemove(v),
                      semanticLabel: '${labels.remove}: ${v.reference}',
                      child: SizedBox.square(
                        dimension: Metrics.touchTarget,
                        child: Center(
                          child: AppIcon(
                            AppIcons.delete,
                            size: IconSizes.navBar,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
