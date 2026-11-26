import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/screens/bookmarks_screen.dart';
import 'package:tehillah/screens/reader_language_sheet.dart';
import 'package:tehillah/screens/reader_screen.dart';
import 'package:tehillah/screens/reader_search_screen.dart';
import 'package:tehillah/screens/reader_settings_sheet.dart';
import 'package:tehillah/screens/reader_theme_sheet.dart';
import 'package:tehillah/screens/verse_actions_sheet.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/search_field.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _count(int n) => '$n verses';
String _pct(double f) => '${(f * 100).round()}%';
String _size(double s) => '${(s * 100).round()}%';
String _tone(MarkTone t) => t.name;

const ReaderSearchLabels searchLabels = ReaderSearchLabels(
  title: 'Search',
  back: 'Back',
  hint: 'Search the Bible',
  clear: 'Clear',
  idleTitle: 'Search a word',
  idleSubtitle: 'Find any verse',
  noResultsTitle: 'Nothing found',
  noResultsSubtitle: 'Try another word',
  resultCount: _count,
  searching: 'Searching',
);

void main() {
  group('AppSearchField', () {
    testWidgets('shows the hint while empty and a clear button once typed', (WidgetTester tester) async {
      useSurface(tester);
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      final List<String> log = <String>[];
      await tester.pumpWidget(
        harness(
          AppSearchField(
            controller: c,
            hint: 'Search the Bible',
            clearLabel: 'Clear',
            onChanged: log.add,
          ),
        ),
      );
      expect(find.text('Search the Bible'), findsOneWidget);
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      await tester.enterText(find.byType(EditableText), 'grace');
      await tester.pump();
      expect(log, <String>['grace']);
      expect(find.text('Search the Bible'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();
      expect(c.text, isEmpty);
      expect(log.last, '');
    });
  });

  group('ReaderSearchScreen', () {
    Widget build({
      String query = '',
      List<SearchResult> results = const <SearchResult>[],
      bool busy = false,
      List<String>? log,
      TextEditingController? controller,
    }) {
      return harness(
        ReaderSearchScreen(
          labels: searchLabels,
          controller: controller ?? TextEditingController(),
          query: query,
          results: results,
          language: 'en',
          busy: busy,
          onQueryChanged: (String q) => log?.add('q:$q'),
          onOpen: (SearchResult r) => log?.add('open:${r.id}'),
          onBack: () => log?.add('back'),
        ),
      );
    }

    testWidgets('idle shows the prompt', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      expect(find.text('Search a word'), findsOneWidget);
    });

    testWidgets('no results shows the empty message and a count of zero', (WidgetTester tester) async {
      await tester.pumpWidget(build(query: 'zzz'));
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('0 verses'), findsOneWidget);
    });

    testWidgets('busy shows searching and no count', (WidgetTester tester) async {
      await tester.pumpWidget(build(query: 'a', busy: true));
      expect(find.text('Searching'), findsOneWidget);
      expect(find.text('0 verses'), findsNothing);
    });

    testWidgets('results list opens on tap', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(
        build(
          query: 'love',
          log: log,
          results: const <SearchResult>[
            SearchResult(id: 'a', reference: 'John 3:16', text: 'For God so loved'),
            SearchResult(id: 'b', reference: '1 John 4:8', text: 'God is love'),
          ],
        ),
      );
      expect(find.text('2 verses'), findsOneWidget);
      await tester.tap(find.text('God is love'));
      expect(log, <String>['open:b']);
    });

    testWidgets('a long result list is built lazily', (WidgetTester tester) async {
      await tester.pumpWidget(
        build(
          query: 'x',
          results: <SearchResult>[
            for (int i = 0; i < 500; i++)
              SearchResult(id: '$i', reference: 'Ps $i:1', text: 'Verse $i'),
          ],
        ),
      );
      expect(find.textContaining('Verse ').evaluate().length, lessThan(30));
    });

    testWidgets('typing reports the query', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(log: log));
      await tester.enterText(find.byType(EditableText), 'peace');
      expect(log, <String>['q:peace']);
    });

    testWidgets('survives 3x text and right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          ReaderSearchScreen(
            labels: searchLabels,
            controller: TextEditingController(),
            query: 'x',
            results: const <SearchResult>[SearchResult(id: 'a', reference: 'Ps 1:1', text: 'Blessed')],
            language: 'ar',
            onQueryChanged: (String q) {},
            onOpen: (SearchResult r) {},
            onBack: () {},
          ),
          textScale: 3,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ReaderSettingsSheet', () {
    const ReaderSettingsLabels l = ReaderSettingsLabels(
      textSize: 'Text size',
      smaller: 'Smaller',
      larger: 'Larger',
      sizeValue: _size,
      preview: 'In the beginning',
      bookmarks: 'Bookmarks',
    );

    Widget build(double scale, List<String> log) => harness(
          ReaderSettingsSheet(
            labels: l,
            textScale: scale,
            language: 'en',
            onTextScale: (double v) => log.add('scale:$v'),
            onOpenBookmarks: () => log.add('bookmarks'),
          ),
          scroll: true,
        );

    testWidgets('steps by a tenth', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(1, log));
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.text('Larger'));
      await tester.tap(find.text('Smaller'));
      expect(log, <String>['scale:1.1', 'scale:0.9']);
    });

    testWidgets('stops at both ends', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(2, log));
      await tester.tap(find.text('Larger'), warnIfMissed: false);
      expect(log, isEmpty);
      await tester.pumpWidget(build(0.8, log));
      await tester.tap(find.text('Smaller'), warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('opens bookmarks', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(1, log));
      await tester.tap(find.text('Bookmarks'));
      expect(log, <String>['bookmarks']);
    });
  });

  group('ReaderThemeSheet', () {
    const ReaderThemeLabels l = ReaderThemeLabels(
      light: 'Light',
      dark: 'Dark',
      sepia: 'Paper',
      sepiaDetail: 'Warm and soft',
      selected: 'Selected',
    );

    testWidgets('marks the current theme and reports a pick', (WidgetTester tester) async {
      useSurface(tester);
      final List<ReaderTheme> log = <ReaderTheme>[];
      await tester.pumpWidget(
        harness(ReaderThemeSheet(labels: l, current: ReaderTheme.dark, onPick: log.add)),
      );
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Dark. Selected'), findsOneWidget);
      expect(find.text('Warm and soft'), findsOneWidget);
      await tester.tap(find.text('Paper'));
      expect(log, <ReaderTheme>[ReaderTheme.sepia]);
    });
  });

  group('ReaderLanguageSheet', () {
    const ReaderLanguageLabels l = ReaderLanguageLabels(
      reading: 'Reading now',
      notDownloaded: 'Not downloaded',
      downloaded: 'Downloaded',
      failed: 'Failed',
      percent: _pct,
      download: 'Download',
    );

    const List<ReaderLanguage> langs = <ReaderLanguage>[
      ReaderLanguage(code: 'en', name: 'English', state: LanguagePackState.installed),
      ReaderLanguage(code: 'es', name: 'Español', state: LanguagePackState.notInstalled),
      ReaderLanguage(
        code: 'fr',
        name: 'Français',
        state: LanguagePackState.downloading,
        progress: 0.4,
      ),
      ReaderLanguage(code: 'de', name: 'Deutsch', state: LanguagePackState.failed),
    ];

    testWidgets('shows each state in words', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          ReaderLanguageSheet(labels: l, languages: langs, current: 'en', onPick: (ReaderLanguage x) {}),
          scroll: true,
        ),
      );
      expect(find.text('Not downloaded'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.bySemanticsLabel('English. Downloaded. Reading now'), findsOneWidget);
    });

    testWidgets('pick reports any row except one that is downloading', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(
        harness(
          ReaderLanguageSheet(
            labels: l,
            languages: langs,
            current: 'en',
            onPick: (ReaderLanguage x) => log.add(x.code),
          ),
          scroll: true,
        ),
      );
      await tester.tap(find.text('Español'));
      await tester.tap(find.text('Deutsch'));
      await tester.tap(find.text('Français'), warnIfMissed: false);
      expect(log, <String>['es', 'de']);
    });
  });

  group('VerseActionsSheet', () {
    const VerseActionsLabels l = VerseActionsLabels(
      bookmark: 'Bookmark',
      removeBookmark: 'Remove bookmark',
      highlight: 'Highlight',
      removeHighlight: 'Remove highlight',
      share: 'Share',
      tone: _tone,
      chosen: 'In use',
    );

    Widget build({bool bookmarked = false, MarkTone? highlight, List<String>? log}) => harness(
          VerseActionsSheet(
            labels: l,
            bookmarked: bookmarked,
            highlight: highlight,
            onToggleBookmark: () => log?.add('bm'),
            onHighlight: (MarkTone? t) => log?.add('hl:${t?.name}'),
            onShare: () => log?.add('share'),
          ),
          scroll: true,
        );

    testWidgets('bookmark row flips its words', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      expect(find.text('Bookmark'), findsOneWidget);
      await tester.pumpWidget(build(bookmarked: true));
      expect(find.text('Remove bookmark'), findsOneWidget);
    });

    testWidgets('colours, remove and share report', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(highlight: MarkTone.leaf, log: log));
      await tester.tap(find.bySemanticsLabel('sky'));
      await tester.tap(find.text('Remove highlight'));
      await tester.tap(find.text('Share'));
      await tester.tap(find.text('Bookmark'));
      expect(log, <String>['hl:sky', 'hl:null', 'share', 'bm']);
    });

    testWidgets('the colour in use carries a check and is announced', (WidgetTester tester) async {
      await tester.pumpWidget(build(highlight: MarkTone.rose));
      expect(find.bySemanticsLabel('rose. In use'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check),
        findsOneWidget,
      );
    });

    testWidgets('Remove highlight is absent when there is none', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      expect(find.text('Remove highlight'), findsNothing);
    });
  });

  group('BookmarksScreen', () {
    const BookmarksLabels l = BookmarksLabels(
      title: 'Bookmarks',
      back: 'Back',
      emptyTitle: 'Nothing saved',
      emptySubtitle: 'Tap a verse to save it',
      bookmarked: 'Bookmarked',
      remove: 'Remove',
    );

    Widget build(List<SavedVerse> items, {List<String>? log}) => harness(
          BookmarksScreen(
            labels: l,
            items: items,
            onOpen: (SavedVerse v) => log?.add('open:${v.id}'),
            onRemove: (SavedVerse v) => log?.add('rm:${v.id}'),
            onBack: () => log?.add('back'),
          ),
        );

    const List<SavedVerse> two = <SavedVerse>[
      SavedVerse(
        id: 'a',
        reference: 'John 3:16',
        text: 'For God so loved',
        language: 'en',
        bookmarked: true,
      ),
      SavedVerse(
        id: 'b',
        reference: 'Psalm 23:1',
        text: 'The Lord is my shepherd',
        language: 'en',
        highlight: MarkTone.sun,
      ),
    ];

    testWidgets('empty shows the message', (WidgetTester tester) async {
      await tester.pumpWidget(build(<SavedVerse>[]));
      expect(find.text('Nothing saved'), findsOneWidget);
    });

    testWidgets('open and remove report the right row', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(two, log: log));
      await tester.tap(find.text('The Lord is my shepherd'));
      await tester.tap(find.bySemanticsLabel('Remove: John 3:16'));
      expect(log, <String>['open:b', 'rm:a']);
    });

    testWidgets('a bookmark shows an icon and is announced', (WidgetTester tester) async {
      await tester.pumpWidget(build(two));
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.bookmark),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('John 3:16. For God so loved. Bookmarked'), findsOneWidget);
    });

    testWidgets('survives 3x text, right-to-left and many rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          BookmarksScreen(
            labels: l,
            items: <SavedVerse>[
              for (int i = 0; i < 200; i++)
                SavedVerse(id: '$i', reference: 'Ps $i:1', text: 'Verse $i', language: 'he'),
            ],
            onOpen: (SavedVerse v) {},
            onRemove: (SavedVerse v) {},
            onBack: () {},
          ),
          textScale: 3,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
