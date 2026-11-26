import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/verse_card.dart';

/// One verse in the library, already in the app language.
final class LibraryVerse {
  const LibraryVerse({
    required this.id,
    required this.text,
    required this.reference,
    required this.language,
    this.translationLabel,
  });

  final String id;
  final String text;
  final String reference;
  final String language;
  final String? translationLabel;
}

/// One filter chip: a game moment, or "All" (id null).
final class LibraryFilter {
  const LibraryFilter({required this.id, required this.label});

  final String? id;
  final String label;
}

final class VerseLibraryLabels {
  const VerseLibraryLabels({
    required this.title,
    required this.back,
    required this.filterLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.readChapter,
    required this.share,
  });

  final String title;
  final String back;

  /// What a screen reader says about the filter chips as a group.
  final String filterLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final String readChapter;
  final String share;
}

/// The curated verses that ship in the app, by game moment. Always works
/// offline. The filter row is fixed; only the verses scroll, and they are
/// built as they come into view. Read chapter hands over to the reader, which
/// asks for the download if the Bible is not installed.
class VerseLibraryScreen extends StatelessWidget {
  const VerseLibraryScreen({
    required this.labels,
    required this.filters,
    required this.selectedFilter,
    required this.verses,
    required this.onFilter,
    required this.onReadChapter,
    required this.onShare,
    required this.onBack,
    super.key,
    this.bottom,
  });

  final VerseLibraryLabels labels;
  final List<LibraryFilter> filters;

  /// The id of the chosen filter; null is "All".
  final String? selectedFilter;
  final List<LibraryVerse> verses;
  final void Function(String? id) onFilter;
  final void Function(LibraryVerse verse) onReadChapter;
  final void Function(LibraryVerse verse) onShare;
  final VoidCallback onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: labels.filterLabel,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.sm),
              child: Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.xs,
                children: <Widget>[
                  for (final LibraryFilter f in filters)
                    AppChip(
                      label: f.label,
                      selected: f.id == selectedFilter,
                      onTap: () => onFilter(f.id),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: verses.isEmpty
                ? EmptyState(
                    icon: AppIcons.verse,
                    title: labels.emptyTitle,
                    subtitle: labels.emptySubtitle,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.lg),
                    itemCount: verses.length,
                    separatorBuilder: (BuildContext c, int i) => const SizedBox(height: Sp.md),
                    itemBuilder: (BuildContext c, int i) {
                      final LibraryVerse v = verses[i];
                      return VerseCard(
                        key: ValueKey<String>(v.id),
                        text: v.text,
                        reference: v.reference,
                        language: v.language,
                        translationLabel: v.translationLabel,
                        readChapterLabel: labels.readChapter,
                        onReadChapter: () => onReadChapter(v),
                        shareLabel: labels.share,
                        onShare: () => onShare(v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
