import 'package:tehillah/core/models/bible_book.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// One search result. [ref] uses the pack's own numbering.
final class SearchHit {
  const SearchHit(this.ref, this.text);

  final VerseRef ref;
  final String text;
}

/// Turns text into comparable search terms: lower case, Latin accents and
/// Hebrew and Arabic vowel marks removed, then split into words. Runs of
/// Chinese, Japanese and Korean characters have no spaces, so they are cut into
/// overlapping pairs of characters.
abstract final class SearchText {
  static const String _from = 'àáâãäåāăąçćčèéêëēęěìíîïīñńòóôõöøōùúûüūýÿšž';
  static const String _to = 'aaaaaaaaaccceeeeeeeiiiiinnoooooooouuuuuyysz';
  static final RegExp _wordChar = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);

  static bool isCjk(int c) =>
      (c >= 0x3040 && c <= 0x30FF) ||
      (c >= 0x3400 && c <= 0x4DBF) ||
      (c >= 0x4E00 && c <= 0x9FFF) ||
      (c >= 0xAC00 && c <= 0xD7AF);

  static String fold(String input) {
    final StringBuffer out = StringBuffer();
    for (final int rune in input.toLowerCase().runes) {
      if ((rune >= 0x0591 && rune <= 0x05BD) ||
          rune == 0x05BF ||
          rune == 0x05C1 ||
          rune == 0x05C2 ||
          rune == 0x05C4 ||
          rune == 0x05C5 ||
          rune == 0x05C7 ||
          (rune >= 0x064B && rune <= 0x065F) ||
          rune == 0x0670 ||
          rune == 0x0640) {
        continue;
      }
      if (rune == 0x05BE) {
        out.write(' ');
        continue;
      }
      if (rune == 0x0623 || rune == 0x0625 || rune == 0x0622) {
        out.write('ا');
        continue;
      }
      final String ch = String.fromCharCode(rune);
      final int at = _from.indexOf(ch);
      if (at >= 0) {
        out.write(_to[at]);
      } else if (ch == 'ß') {
        out.write('ss');
      } else if (ch == 'œ') {
        out.write('oe');
      } else if (ch == 'æ') {
        out.write('ae');
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  /// Search terms of folded text. Chinese, Japanese and Korean runs give pairs
  /// (a run of one character gives that character).
  static List<String> terms(String folded) {
    final List<String> out = <String>[];
    final StringBuffer word = StringBuffer();
    final List<int> cjk = <int>[];

    void flushWord() {
      if (word.isNotEmpty) {
        out.add(word.toString());
        word.clear();
      }
    }

    void flushCjk() {
      if (cjk.length == 1) {
        out.add(String.fromCharCode(cjk.first));
      } else {
        for (int i = 0; i + 1 < cjk.length; i++) {
          out.add(String.fromCharCodes(<int>[cjk[i], cjk[i + 1]]));
        }
      }
      cjk.clear();
    }

    for (final int rune in folded.runes) {
      if (isCjk(rune)) {
        flushWord();
        cjk.add(rune);
      } else if (_wordChar.hasMatch(String.fromCharCode(rune))) {
        flushCjk();
        word.writeCharCode(rune);
      } else {
        flushWord();
        flushCjk();
      }
    }
    flushWord();
    flushCjk();
    return out;
  }
}

/// A full-text index over one installed Bible pack, built once when the pack
/// loads. A search reads only the posting lists of the query's terms, so it
/// stays fast on all 31,000 verses.
final class ReaderIndex {
  ReaderIndex._(this._refs, this._texts, this._postings, this._vocabulary);

  /// Builds the index. Empty verses (gaps in a source) are skipped.
  factory ReaderIndex.build(BiblePack pack) {
    final List<VerseRef> refs = <VerseRef>[];
    final List<String> texts = <String>[];
    final Map<String, List<int>> postings = <String, List<int>>{};
    for (final BibleBook book in pack.books) {
      for (int c = 1; c <= book.chapterVerseCounts.length; c++) {
        final List<String> verses = pack.chapter(book.osisId, c)!;
        for (int v = 1; v <= verses.length; v++) {
          final String text = verses[v - 1];
          if (text.trim().isEmpty) {
            continue;
          }
          final int id = refs.length;
          refs.add(VerseRef(book.osisId, c, v));
          texts.add(text);
          for (final String term in SearchText.terms(SearchText.fold(text))) {
            final List<int> list = postings.putIfAbsent(term, () => <int>[]);
            if (list.isEmpty || list.last != id) {
              list.add(id);
            }
          }
        }
      }
    }
    final List<String> vocabulary = postings.keys.toList()..sort();
    return ReaderIndex._(refs, texts, postings, vocabulary);
  }

  /// Terms shorter than this match whole words only; longer ones also match as
  /// word starts ("lov" finds "love").
  static const int prefixFrom = 3;
  static const int _maxExpansions = 64;

  final List<VerseRef> _refs;
  final List<String> _texts;
  final Map<String, List<int>> _postings;
  final List<String> _vocabulary;

  int get verseCount => _refs.length;

  int _lowerBound(String prefix) {
    int lo = 0;
    int hi = _vocabulary.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_vocabulary[mid].compareTo(prefix) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Set<int> _matches(String term) {
    final bool cjk = SearchText.isCjk(term.runes.first);
    if (cjk || term.runes.length < prefixFrom) {
      return (_postings[term] ?? const <int>[]).toSet();
    }
    final Set<int> union = <int>{};
    int taken = 0;
    for (int i = _lowerBound(term);
        i < _vocabulary.length && _vocabulary[i].startsWith(term) && taken < _maxExpansions;
        i++, taken++) {
      union.addAll(_postings[_vocabulary[i]]!);
    }
    return union;
  }

  /// Verses containing every word of [query], in canonical order, at most
  /// [limit]. A one-character Chinese, Japanese or Korean query scans the text
  /// directly, because the index holds pairs.
  List<SearchHit> search(String query, {int limit = 200}) {
    final String folded = SearchText.fold(query);
    final List<String> terms = SearchText.terms(folded);
    if (terms.isEmpty || limit < 1) {
      return const <SearchHit>[];
    }
    final List<int> found;
    if (terms.length == 1 && terms.first.runes.length == 1 && SearchText.isCjk(terms.first.runes.first)) {
      found = <int>[
        for (int i = 0; i < _texts.length && i < 1 << 30; i++)
          if (_texts[i].contains(terms.first)) i,
      ];
    } else {
      final List<Set<int>> sets = <Set<int>>[for (final String t in terms) _matches(t)]
        ..sort((Set<int> a, Set<int> b) => a.length.compareTo(b.length));
      Set<int> result = sets.first;
      for (int i = 1; i < sets.length && result.isNotEmpty; i++) {
        final Set<int> other = sets[i];
        result = <int>{
          for (final int id in result)
            if (other.contains(id)) id,
        };
      }
      found = result.toList()..sort();
    }
    final List<SearchHit> hits = <SearchHit>[];
    final List<String> cjkRuns = <String>[
      for (final String run in folded.split(RegExp(r'[^\p{L}\p{N}\p{M}]', unicode: true)))
        if (run.isNotEmpty && SearchText.isCjk(run.runes.first)) run,
    ];
    for (final int id in found) {
      if (cjkRuns.isNotEmpty) {
        final String text = SearchText.fold(_texts[id]);
        if (!cjkRuns.every(text.contains)) {
          continue;
        }
      }
      hits.add(SearchHit(_refs[id], _texts[id]));
      if (hits.length >= limit) {
        break;
      }
    }
    return hits;
  }
}
