import 'package:flutter/foundation.dart';
import 'package:tehillah/core/models/bookmark.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';

@immutable
final class MarksState {
  const MarksState({this.bookmarks = const <Bookmark>[], this.highlights = const <Highlight>[]});

  /// Newest first.
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;

  bool isBookmarked(VerseRef ref, String language) =>
      bookmarks.any((Bookmark b) => b.ref == ref && b.language == language);

  HighlightColor? highlightOf(VerseRef ref, String language) {
    for (final Highlight h in highlights) {
      if (h.ref == ref && h.language == language) {
        return h.color;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is MarksState &&
      listEquals(other.bookmarks, bookmarks) &&
      listEquals(other.highlights, highlights);

  @override
  int get hashCode => Object.hash(Object.hashAll(bookmarks), Object.hashAll(highlights));
}

/// Reader bookmarks and highlights. They live in the career file, so this
/// reads from [ProgressProvider] and writes through its `update`.
final class BookmarkProvider extends SafeNotifier<MarksState> {
  BookmarkProvider(this._progress, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(_derive(_progress.progress)) {
    _progress.addListener(_sync);
  }

  final ProgressProvider _progress;
  final DateTime Function() _clock;

  static MarksState _derive(Progress p) {
    final List<Bookmark> marks = List<Bookmark>.of(p.bookmarks)
      ..sort((Bookmark a, Bookmark b) => b.createdAt.compareTo(a.createdAt));
    return MarksState(bookmarks: marks, highlights: p.highlights);
  }

  void _sync() => value = _derive(_progress.progress);

  /// Adds the bookmark, or removes it if it is already there. Returns whether
  /// the verse is bookmarked afterwards.
  bool toggleBookmark(VerseRef ref, String language) {
    final bool had = value.isBookmarked(ref, language);
    _progress.update((Progress p) {
      final List<Bookmark> rest = <Bookmark>[
        for (final Bookmark b in p.bookmarks)
          if (!(b.ref == ref && b.language == language)) b,
      ];
      return p.copyWith(
        bookmarks: had
            ? rest
            : <Bookmark>[...rest, Bookmark(ref: ref, language: language, createdAt: _clock())],
      );
    });
    return !had;
  }

  /// Sets a verse's highlight colour; null removes it. Choosing the colour a
  /// verse already has removes it too, so one tap undoes a highlight.
  void setHighlight(VerseRef ref, String language, HighlightColor? color) {
    final HighlightColor? current = value.highlightOf(ref, language);
    final HighlightColor? target = color == current ? null : color;
    _progress.update((Progress p) {
      final List<Highlight> rest = <Highlight>[
        for (final Highlight h in p.highlights)
          if (!(h.ref == ref && h.language == language)) h,
      ];
      return p.copyWith(
        highlights: target == null
            ? rest
            : <Highlight>[
                ...rest,
                Highlight(ref: ref, language: language, color: target, createdAt: _clock()),
              ],
      );
    });
  }

  @override
  void dispose() {
    _progress.removeListener(_sync);
    super.dispose();
  }
}
