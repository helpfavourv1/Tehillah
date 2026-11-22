import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/models/bible_book.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/pack_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';
import 'package:tehillah/core/verses/reader_index.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/pack_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';
import 'package:tehillah/providers/settings_provider.dart';

enum ReaderStatus { idle, loading, ready, missingPack, failed }

/// Everything the reader screens draw. [version] grows with every change.
@immutable
final class ReaderState {
  const ReaderState({
    this.status = ReaderStatus.idle,
    this.language = 'en',
    this.translationId,
    this.books = const <BibleBook>[],
    this.book,
    this.chapter = 1,
    this.verses = const <String>[],
    this.focusVerse,
    this.query = '',
    this.results = const <SearchHit>[],
    this.textScale = 1.0,
    this.hasPrevious = false,
    this.hasNext = false,
    this.version = 0,
  });

  final ReaderStatus status;

  /// The reader's language (independent of the interface language).
  final String language;
  final String? translationId;
  final List<BibleBook> books;

  /// The OSIS id of the open book, and the open chapter.
  final String? book;
  final int chapter;

  /// The chapter's verses; verse 1 is index 0.
  final List<String> verses;

  /// A verse to scroll to and mark, set when opening from a verse card.
  final int? focusVerse;

  final String query;
  final List<SearchHit> results;
  final double textScale;
  final bool hasPrevious;
  final bool hasNext;
  final int version;

  bool get ready => status == ReaderStatus.ready;

  @override
  bool operator ==(Object other) => other is ReaderState && other.version == version;

  @override
  int get hashCode => version;
}

/// The Bible reader: which Bible is open, where, and the search. It reads the
/// installed pack for the reader language and follows language, install and
/// text-size changes. It never downloads; that is [PackProvider]'s job.
final class ReaderProvider extends SafeNotifier<ReaderState> {
  ReaderProvider({
    required PackPort packs,
    required LocaleProvider locale,
    required SettingsProvider settings,
    required PackProvider packState,
    required StoragePort storage,
    required LogPort log,
  })  : _packs = packs,
        _locale = locale,
        _settings = settings,
        _packState = packState,
        _storage = storage,
        _log = log,
        super(ReaderState(
          language: locale.value.readerLanguage,
          textScale: settings.value.readerTextScale,
        )) {
    _locale.addListener(_onLocale);
    _packState.addListener(_onPacks);
    _settings.addListener(_onSettings);
  }

  static const String positionKey = 'reader.position.v1';

  final PackPort _packs;
  final LocaleProvider _locale;
  final SettingsProvider _settings;
  final PackProvider _packState;
  final StoragePort _storage;
  final LogPort _log;

  BiblePack? _pack;
  ReaderIndex? _index;
  Map<String, Object?> _positions = <String, Object?>{};
  bool _positionsRead = false;
  int _loadToken = 0;
  int _version = 0;
  bool _wasInstalled = false;

  void _emit(ReaderState Function(ReaderState current) change) {
    _version += 1;
    final ReaderState next = change(value);
    value = ReaderState(
      status: next.status,
      language: next.language,
      translationId: next.translationId,
      books: next.books,
      book: next.book,
      chapter: next.chapter,
      verses: next.verses,
      focusVerse: next.focusVerse,
      query: next.query,
      results: next.results,
      textScale: next.textScale,
      hasPrevious: next.hasPrevious,
      hasNext: next.hasNext,
      version: _version,
    );
  }

  void _onSettings() {
    final double scale = _settings.value.readerTextScale;
    if (scale != value.textScale) {
      _emit((ReaderState s) => _copy(s, textScale: scale));
    }
  }

  void _onLocale() {
    final String language = _locale.value.readerLanguage;
    if (language != value.language) {
      unawaited(load());
    }
  }

  void _onPacks() {
    final bool installed = _packState.value.isInstalled(value.language);
    if (installed != _wasInstalled) {
      _wasInstalled = installed;
      if (installed && !value.ready) {
        unawaited(load());
      }
      if (!installed && value.ready) {
        unawaited(load());
      }
    }
  }

  /// Opens the reader's Bible. Call when the reader screen opens. With no pack
  /// installed the status is [ReaderStatus.missingPack] and the screen offers
  /// the download.
  Future<void> load() async {
    final int token = ++_loadToken;
    final String language = _locale.value.readerLanguage;
    _pack = null;
    _index = null;
    _emit((ReaderState s) => ReaderState(
          status: ReaderStatus.loading,
          language: language,
          textScale: s.textScale,
        ));
    try {
      await _readPositions();
      final BiblePack? pack = await _packs.load(language);
      if (token != _loadToken || isDisposed) {
        return;
      }
      if (pack == null) {
        _wasInstalled = false;
        _emit((ReaderState s) => ReaderState(
              status: ReaderStatus.missingPack,
              language: language,
              textScale: s.textScale,
            ));
        return;
      }
      _wasInstalled = true;
      _pack = pack;
      final List<BibleBook> books = pack.books;
      final Object? saved = _positions[language];
      String? book;
      int chapter = 1;
      if (saved is Map<String, Object?>) {
        final Object? b = saved['book'];
        final Object? c = saved['chapter'];
        if (b is String && c is int && pack.chapter(b, c) != null) {
          book = b;
          chapter = c;
        }
      }
      book ??= books.first.osisId;
      _show(book, chapter, translationId: pack.translationId, books: books, status: ReaderStatus.ready);
    } on Object catch (error) {
      if (token != _loadToken || isDisposed) {
        return;
      }
      _log.log(LogLevel.error, 'reader', 'could not open the Bible: $error');
      _emit((ReaderState s) => ReaderState(
            status: ReaderStatus.failed,
            language: language,
            textScale: s.textScale,
          ));
    }
  }

  ReaderState _copy(
    ReaderState s, {
    double? textScale,
  }) {
    return ReaderState(
      status: s.status,
      language: s.language,
      translationId: s.translationId,
      books: s.books,
      book: s.book,
      chapter: s.chapter,
      verses: s.verses,
      focusVerse: s.focusVerse,
      query: s.query,
      results: s.results,
      textScale: textScale ?? s.textScale,
      hasPrevious: s.hasPrevious,
      hasNext: s.hasNext,
    );
  }

  void _show(
    String book,
    int chapter, {
    String? translationId,
    List<BibleBook>? books,
    ReaderStatus? status,
    int? focusVerse,
  }) {
    final BiblePack pack = _pack!;
    final List<BibleBook> list = books ?? value.books;
    final int bookIndex = list.indexWhere((BibleBook b) => b.osisId == book);
    final BibleBook current = list[bookIndex];
    _emit((ReaderState s) => ReaderState(
          status: status ?? s.status,
          language: s.language,
          translationId: translationId ?? s.translationId,
          books: list,
          book: book,
          chapter: chapter,
          verses: pack.chapter(book, chapter)!,
          focusVerse: focusVerse,
          query: s.query,
          results: s.results,
          textScale: s.textScale,
          hasPrevious: bookIndex > 0 || chapter > 1,
          hasNext: bookIndex < list.length - 1 || chapter < current.chapters,
        ));
    unawaited(_savePosition(book, chapter));
  }

  /// Opens a chapter. Returns false if there is no such chapter in this Bible.
  bool goTo(String book, int chapter) {
    final BiblePack? pack = _pack;
    if (pack == null || !value.ready || pack.chapter(book, chapter) == null) {
      return false;
    }
    _show(book, chapter);
    return true;
  }

  /// Opens the chapter of a verse and marks that verse, for "Read chapter" on
  /// a verse card. Returns false if the Bible is not open or lacks the verse.
  bool openRef(VerseRef ref) {
    final BiblePack? pack = _pack;
    if (pack == null || !value.ready || pack.verse(ref.book, ref.chapter, ref.verse) == null) {
      return false;
    }
    _show(ref.book, ref.chapter, focusVerse: ref.verse);
    return true;
  }

  bool next() {
    final String? book = value.book;
    if (book == null || !value.ready || !value.hasNext) {
      return false;
    }
    final List<BibleBook> books = value.books;
    final int i = books.indexWhere((BibleBook b) => b.osisId == book);
    if (value.chapter < books[i].chapters) {
      _show(book, value.chapter + 1);
    } else {
      _show(books[i + 1].osisId, 1);
    }
    return true;
  }

  bool previous() {
    final String? book = value.book;
    if (book == null || !value.ready || !value.hasPrevious) {
      return false;
    }
    final List<BibleBook> books = value.books;
    final int i = books.indexWhere((BibleBook b) => b.osisId == book);
    if (value.chapter > 1) {
      _show(book, value.chapter - 1);
    } else {
      final BibleBook before = books[i - 1];
      _show(before.osisId, before.chapters);
    }
    return true;
  }

  /// Searches the open Bible. The search index is built the first time it is
  /// needed and reused after that.
  Future<void> search(String query) async {
    final BiblePack? pack = _pack;
    final String trimmed = query.trim();
    if (pack == null || !value.ready) {
      return;
    }
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }
    final int token = _loadToken;
    if (_index == null) {
      await Future<void>.delayed(Duration.zero);
      if (token != _loadToken || isDisposed) {
        return;
      }
      _index = ReaderIndex.build(pack);
    }
    final List<SearchHit> hits = _index!.search(trimmed);
    _emit((ReaderState s) => ReaderState(
          status: s.status,
          language: s.language,
          translationId: s.translationId,
          books: s.books,
          book: s.book,
          chapter: s.chapter,
          verses: s.verses,
          focusVerse: s.focusVerse,
          query: trimmed,
          results: hits,
          textScale: s.textScale,
          hasPrevious: s.hasPrevious,
          hasNext: s.hasNext,
        ));
  }

  void clearSearch() {
    if (value.query.isEmpty && value.results.isEmpty) {
      return;
    }
    _emit((ReaderState s) => ReaderState(
          status: s.status,
          language: s.language,
          translationId: s.translationId,
          books: s.books,
          book: s.book,
          chapter: s.chapter,
          verses: s.verses,
          focusVerse: s.focusVerse,
          textScale: s.textScale,
          hasPrevious: s.hasPrevious,
          hasNext: s.hasNext,
        ));
  }

  /// Sets the reader text size (0.8 to 2.0). It is saved with the settings.
  void setTextScale(double scale) {
    final double clamped = scale
        .clamp(SettingsModel.minTextScale, SettingsModel.maxTextScale)
        .toDouble();
    _settings.update((SettingsModel s) => s.copyWith(readerTextScale: clamped));
  }

  /// The licence and credit text that ships with the open Bible.
  Future<String?> notice() async {
    try {
      return await _packs.readNotice(value.language);
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'reader', 'notice unreadable: $error');
      return null;
    }
  }

  Future<void> _readPositions() async {
    if (_positionsRead) {
      return;
    }
    _positionsRead = true;
    try {
      final String? raw = await _storage.getString(positionKey);
      if (raw != null) {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          _positions = decoded;
        }
      }
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'reader', 'saved place unreadable: $error');
    }
  }

  Future<void> _savePosition(String book, int chapter) async {
    _positions = <String, Object?>{
      ..._positions,
      value.language: <String, Object?>{'book': book, 'chapter': chapter},
    };
    try {
      await _storage.setString(positionKey, jsonEncode(_positions));
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'reader', 'could not save the place: $error');
    }
  }

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
    _locale.removeListener(_onLocale);
    _packState.removeListener(_onPacks);
    _settings.removeListener(_onSettings);
    super.dispose();
  }
}
