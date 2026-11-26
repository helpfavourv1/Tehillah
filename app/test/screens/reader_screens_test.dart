import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/download_prompt_sheet.dart';
import 'package:tehillah/screens/reader_picker_sheet.dart';
import 'package:tehillah/screens/reader_screen.dart';
import 'package:tehillah/screens/verse_library_screen.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/progress_bar.dart';
import 'package:tehillah/widgets/segmented_control.dart';
import 'package:tehillah/widgets/verse_card.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

const VerseLibraryLabels libLabels = VerseLibraryLabels(
  title: 'Verses',
  back: 'Back',
  filterLabel: 'Filter by moment',
  emptyTitle: 'No verses here',
  emptySubtitle: 'Try another moment',
  readChapter: 'Read chapter',
  share: 'Share',
);

const List<LibraryFilter> filters = <LibraryFilter>[
  LibraryFilter(id: null, label: 'All'),
  LibraryFilter(id: 'goal', label: 'Goal'),
  LibraryFilter(id: 'miss', label: 'Miss'),
];

List<LibraryVerse> manyVerses(int n) => <LibraryVerse>[
      for (int i = 0; i < n; i++)
        LibraryVerse(
          id: 'v$i',
          text: 'Verse text number $i',
          reference: 'Psalm ${i + 1}:1',
          language: 'en',
        ),
    ];

String _chapterLabel(String book, int c) => '$book chapter $c';
String _num(int n) => '$n';
String _pct(double f) => '${(f * 100).round()}%';
String _verseLabel(int v, String t) => 'Verse $v. $t';

const ReaderLabels readerLabels = ReaderLabels(
  back: 'Back',
  chooseChapter: 'Choose chapter',
  search: 'Search',
  theme: 'Theme',
  language: 'Language',
  settings: 'Reading settings',
  previous: 'Previous',
  next: 'Next',
  loading: 'Opening the Bible',
  missingTitle: 'Bible not downloaded',
  missingSubtitle: 'Download it once to read offline',
  download: 'Download',
  failedTitle: 'Could not open',
  failedSubtitle: 'Please try again',
  retry: 'Try again',
  verseNumber: _num,
  bookmarked: 'Bookmarked',
  verseLabel: _verseLabel,
);

Widget reader({
  ReaderView view = ReaderView.ready,
  List<String> verses = const <String>['First verse', 'Second verse', 'Third verse'],
  Map<int, VerseMark> marks = const <int, VerseMark>{},
  bool hasPrevious = true,
  bool hasNext = true,
  String language = 'en',
  List<String>? log,
}) {
  return ReaderScreen(
    labels: readerLabels,
    view: view,
    title: 'Genesis 1',
    language: language,
    verses: verses,
    marks: marks,
    textScale: 1,
    hasPrevious: hasPrevious,
    hasNext: hasNext,
    onBack: () => log?.add('back'),
    onPickChapter: () => log?.add('pick'),
    onSearch: () => log?.add('search'),
    onTheme: () => log?.add('theme'),
    onLanguage: () => log?.add('language'),
    onSettings: () => log?.add('settings'),
    onVerseTap: (int v) => log?.add('verse$v'),
    onPrevious: () => log?.add('prev'),
    onNext: () => log?.add('next'),
    onDownload: () => log?.add('download'),
    onRetry: () => log?.add('retry'),
  );
}

DownloadPromptLabels dlLabels() => const DownloadPromptLabels(
      title: 'Download the English Bible',
      explain: 'Only the Bible is downloaded; the game never needs it.',
      networkLabel: 'Network',
      wifiOnly: 'Wi-Fi only',
      wifiAndData: 'Wi-Fi and mobile data',
      download: 'Download',
      notNow: 'Not now',
      downloading: 'Downloading',
      cancel: 'Cancel',
      retry: 'Try again',
      percent: _pct,
    );

Widget sheet(
  DownloadPhase phase, {
  bool wifiOnly = true,
  double fraction = 0,
  String? message,
  List<String>? log,
}) {
  return DownloadPromptSheet(
    labels: dlLabels(),
    phase: phase,
    wifiOnly: wifiOnly,
    onWifiOnlyChanged: (bool v) => log?.add('wifi:$v'),
    onDownload: () => log?.add('download'),
    onCancel: () => log?.add('cancel'),
    onClose: () => log?.add('close'),
    fraction: fraction,
    sizeLabel: 'About 4 MB',
    message: message,
  );
}

const ReaderPickerLabels pickLabels = ReaderPickerLabels(
  oldTestament: 'Old Testament',
  newTestament: 'New Testament',
  books: 'Books',
  chapterLabel: _chapterLabel,
  number: _num,
);

const List<PickerBook> pickBooks = <PickerBook>[
  PickerBook(id: 'Gen', name: 'Genesis', chapters: 50, isNewTestament: false),
  PickerBook(id: 'Matt', name: 'Matthew', chapters: 28, isNewTestament: true),
];

void main() {
  group('VerseLibraryScreen', () {
    Widget build({String? selected, List<LibraryVerse>? verses, List<String>? log}) {
      return harness(
        VerseLibraryScreen(
          labels: libLabels,
          filters: filters,
          selectedFilter: selected,
          verses: verses ?? manyVerses(3),
          onFilter: (String? id) => log?.add('filter:$id'),
          onReadChapter: (LibraryVerse v) => log?.add('read:${v.id}'),
          onShare: (LibraryVerse v) => log?.add('share:${v.id}'),
          onBack: () => log?.add('back'),
        ),
      );
    }

    testWidgets('shows a card per verse and marks the chosen filter', (WidgetTester tester) async {
      await tester.pumpWidget(build(selected: 'goal'));
      expect(find.byType(VerseCard), findsNWidgets(3));
      final List<AppChip> chips = tester.widgetList<AppChip>(find.byType(AppChip)).toList();
      expect(chips.where((AppChip c) => c.selected).map((AppChip c) => c.label), <String>['Goal']);
    });

    testWidgets('tapping a filter reports its id; All reports null', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(selected: 'goal', log: log));
      await tester.tap(find.text('Miss'));
      await tester.tap(find.text('All'));
      expect(log, <String>['filter:miss', 'filter:null']);
    });

    testWidgets('Read chapter and Share report their verse', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(verses: manyVerses(1), log: log));
      await tester.tap(find.text('Read chapter'));
      await tester.tap(find.text('Share'));
      expect(log, <String>['read:v0', 'share:v0']);
    });

    testWidgets('no verses shows the empty state and no card', (WidgetTester tester) async {
      await tester.pumpWidget(build(verses: <LibraryVerse>[]));
      expect(find.text('No verses here'), findsOneWidget);
      expect(find.byType(VerseCard), findsNothing);
    });

    testWidgets('a long list is built lazily', (WidgetTester tester) async {
      await tester.pumpWidget(build(verses: manyVerses(300)));
      expect(find.byType(VerseCard).evaluate().length, lessThan(30));
    });

    testWidgets('survives 3x text and right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          VerseLibraryScreen(
            labels: libLabels,
            filters: filters,
            selectedFilter: null,
            verses: manyVerses(3),
            onFilter: (String? id) {},
            onReadChapter: (LibraryVerse v) {},
            onShare: (LibraryVerse v) {},
            onBack: () {},
          ),
          textScale: 3,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DownloadPromptSheet', () {
    Widget wrap(Widget child) => harness(child, scroll: true);

    testWidgets('asking shows the network choice, size and both buttons', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(sheet(DownloadPhase.ask)));
      expect(find.byType(SegmentedControl<bool>), findsOneWidget);
      expect(find.text('About 4 MB'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('choices and buttons call back', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(sheet(DownloadPhase.ask, log: log)));
      await tester.tap(find.text('Wi-Fi and mobile data'));
      await tester.tap(find.text('Download'));
      await tester.tap(find.text('Not now'));
      expect(log, <String>['wifi:false', 'download', 'close']);
    });

    testWidgets('downloading shows progress and Cancel only', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(sheet(DownloadPhase.downloading, fraction: 0.42, log: log)));
      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.byType(SegmentedControl<bool>), findsNothing);
      expect(find.text('Download'), findsNothing);
      await tester.tap(find.text('Cancel'));
      expect(log, <String>['cancel']);
    });

    testWidgets('out-of-range progress is clamped', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(sheet(DownloadPhase.downloading, fraction: 1.7)));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('failed shows the message and Try again', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(
        wrap(sheet(DownloadPhase.failed, message: 'No connection', log: log)),
      );
      expect(find.text('No connection'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(log, <String>['download']);
    });

    testWidgets('blocked shows the message and only Not now', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(sheet(DownloadPhase.blocked, message: 'Downloads are switched off')),
      );
      expect(find.text('Downloads are switched off'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
      expect(find.text('Not now'), findsOneWidget);
    });
  });

  group('ReaderPickerSheet', () {
    Widget build(List<String> log, {String? book, int? chapter}) {
      return harness(
        ReaderPickerSheet(
          labels: pickLabels,
          books: pickBooks,
          currentBook: book,
          currentChapter: chapter,
          onPick: (String b, int c) => log.add('$b:$c'),
        ),
        scroll: true,
      );
    }

    testWidgets('lists books under both testaments', (WidgetTester tester) async {
      await tester.pumpWidget(build(<String>[]));
      expect(find.text('Old Testament'), findsOneWidget);
      expect(find.text('New Testament'), findsOneWidget);
      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Matthew'), findsOneWidget);
    });

    testWidgets('choosing a book shows its chapters; a chapter is picked', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 1400));
      final List<String> log = <String>[];
      await tester.pumpWidget(build(log));
      await tester.tap(find.text('Matthew'));
      await tester.pump();
      expect(find.text('28'), findsOneWidget);
      expect(find.text('29'), findsNothing);
      await tester.tap(find.text('3'));
      expect(log, <String>['Matt:3']);
    });

    testWidgets('Books goes back to the list', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 1400));
      await tester.pumpWidget(build(<String>[]));
      await tester.tap(find.text('Genesis'));
      await tester.pump();
      await tester.tap(find.text('Books'));
      await tester.pump();
      expect(find.text('Old Testament'), findsOneWidget);
    });

    testWidgets('the open book carries a check', (WidgetTester tester) async {
      await tester.pumpWidget(build(<String>[], book: 'Gen'));
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check),
        findsOneWidget,
      );
    });

    testWidgets('chapter cells announce book and number', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 1400));
      await tester.pumpWidget(build(<String>[]));
      await tester.tap(find.text('Genesis'));
      await tester.pump();
      expect(find.bySemanticsLabel('Genesis chapter 7'), findsOneWidget);
    });
  });

  group('ReaderScreen', () {
    Widget wrap(Widget child, {TextDirection d = TextDirection.ltr, double scale = 1}) =>
        harness(child, direction: d, textScale: scale);

    testWidgets('ready shows every verse with its number', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(reader()));
      expect(find.text('First verse'), findsOneWidget);
      expect(find.text('Third verse'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('nav actions and the title chip call back', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(reader(log: log)));
      await tester.tap(find.bySemanticsLabel('Search'));
      await tester.tap(find.bySemanticsLabel('Theme'));
      await tester.tap(find.bySemanticsLabel('Language'));
      await tester.tap(find.bySemanticsLabel('Reading settings'));
      await tester.tap(find.text('Genesis 1'));
      await tester.tap(find.bySemanticsLabel('Back'));
      expect(log, <String>['search', 'theme', 'language', 'settings', 'pick', 'back']);
    });

    testWidgets('tapping a verse reports its number', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(reader(log: log)));
      await tester.tap(find.text('Second verse'));
      expect(log, <String>['verse2']);
    });

    testWidgets('previous and next work when allowed', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(reader(log: log)));
      await tester.tap(find.text('Previous'));
      await tester.tap(find.text('Next'));
      expect(log, <String>['prev', 'next']);
    });

    testWidgets('previous and next do nothing at the ends', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(reader(log: log, hasPrevious: false, hasNext: false)));
      await tester.tap(find.text('Previous'), warnIfMissed: false);
      await tester.tap(find.text('Next'), warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('a bookmark shows an icon and is announced', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(reader(marks: <int, VerseMark>{2: const VerseMark(bookmarked: true)})),
      );
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.bookmark),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Verse 2. Second verse. Bookmarked'), findsOneWidget);
    });

    testWidgets('a highlight fills behind the verse', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(reader(marks: <int, VerseMark>{1: const VerseMark(highlight: MarkTone.sun)})),
      );
      final Iterable<DecoratedBox> filled = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((DecoratedBox b) {
        final Decoration d = b.decoration;
        return d is BoxDecoration && d.color != null && d.color!.a > 0 && d.color!.value == 0xFFFFF1B8;
      });
      expect(filled, isNotEmpty);
    });

    testWidgets('loading shows its message and no pager', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(reader(view: ReaderView.loading, verses: <String>[])));
      expect(find.text('Opening the Bible'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('missing pack offers Download', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(
        wrap(reader(view: ReaderView.missingPack, verses: <String>[], log: log)),
      );
      expect(find.text('Bible not downloaded'), findsOneWidget);
      await tester.tap(find.text('Download'));
      expect(log, <String>['download']);
    });

    testWidgets('failed offers Try again', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(wrap(reader(view: ReaderView.failed, verses: <String>[], log: log)));
      await tester.tap(find.text('Try again'));
      expect(log, <String>['retry']);
    });

    testWidgets('verses take the Bible language direction, not the app direction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(reader(language: 'ar', verses: <String>['بسم']), d: TextDirection.ltr),
      );
      final BuildContext ctx = tester.element(find.text('بسم'));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('survives 3x text, right-to-left and a small screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          reader(),
          textScale: 3,
          direction: TextDirection.rtl,
          size: const Size(320, 568),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long chapter scrolls and builds without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(reader(verses: <String>[for (int i = 0; i < 176; i++) 'Verse body number $i'])),
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the focus verse is scrolled into view', (WidgetTester tester) async {
      final List<String> verses = <String>[for (int i = 1; i <= 80; i++) 'Body $i'];
      await tester.pumpWidget(
        wrap(
          ReaderScreen(
            labels: readerLabels,
            view: ReaderView.ready,
            title: 'Psalm 119',
            language: 'en',
            verses: verses,
            focusVerse: 60,
            textScale: 1,
            onBack: () {},
            onPickChapter: () {},
            onSearch: () {},
            onTheme: () {},
            onLanguage: () {},
            onSettings: () {},
            onVerseTap: (int v) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final Rect r = tester.getRect(find.text('Body 60'));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.bottom, lessThanOrEqualTo(720));
    });
  });
}
