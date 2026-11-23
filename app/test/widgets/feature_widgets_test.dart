import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/providers/ad_provider.dart' show AdState;
import 'package:tehillah/providers/entitlement_provider.dart' show Entitlement;
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/ad_slot.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/entitlement_badge.dart';
import 'package:tehillah/widgets/nerve_meter_view.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/progress_bar.dart';
import 'package:tehillah/widgets/segmented_control.dart';
import 'package:tehillah/widgets/star_row.dart';
import 'package:tehillah/widgets/stat_pill.dart';
import 'package:tehillah/widgets/toggle_row.dart';
import 'package:tehillah/widgets/verse_card.dart';

import '../support/widget_harness.dart';

const String _long =
    'A rather long label that has to wrap onto several lines at the largest text size';

void main() {
  group('directionForLanguage', () {
    test('right to left languages', () {
      for (final String code in <String>['ar', 'he', 'fa', 'ur', 'AR', 'ar-EG', 'he_IL']) {
        expect(directionForLanguage(code), TextDirection.rtl, reason: code);
      }
    });
    test('everything else is left to right', () {
      for (final String code in <String>['en', 'es', 'ja', 'zh-Hans', 'pt_BR', '']) {
        expect(directionForLanguage(code), TextDirection.ltr, reason: code);
      }
    });
  });

  group('VerseCard', () {
    testWidgets('shows the verse, reference and translation', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const VerseCard(
        text: 'The Lord is my shepherd.',
        reference: 'Psalm 23:1',
        language: 'en',
        translationLabel: 'BSB',
      )));
      expect(find.text('The Lord is my shepherd.'), findsOneWidget);
      expect(find.text('Psalm 23:1 · BSB'), findsOneWidget);
      expect(find.byType(AppChip), findsNothing);
    });

    testWidgets('actions appear only when supplied and fire', (WidgetTester tester) async {
      int read = 0;
      int share = 0;
      await tester.pumpWidget(harness(VerseCard(
        text: 'v',
        reference: 'r',
        language: 'en',
        onReadChapter: () => read++,
        readChapterLabel: 'Read chapter',
        onShare: () => share++,
        shareLabel: 'Share',
      )));
      await tester.tap(find.text('Read chapter'));
      await tester.tap(find.text('Share'));
      expect(read, 1);
      expect(share, 1);
    });

    testWidgets('a Hebrew verse is right to left under an English interface',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(const VerseCard(
        text: 'יהוה רועי',
        reference: 'Psalm 23:1',
        language: 'he',
      )));
      final BuildContext ctx = tester.element(find.text('יהוה רועי'));
      expect(Directionality.of(ctx), TextDirection.rtl);
      final BuildContext card = tester.element(find.byType(VerseCard));
      expect(Directionality.of(card), TextDirection.ltr);
    });

    testWidgets('holds at 3.1x text with an RTL interface', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        VerseCard(
          text: _long,
          reference: _long,
          language: 'ar',
          onShare: () {},
          shareLabel: _long,
        ),
        textScale: 3.1,
        direction: TextDirection.rtl,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AdSlot', () {
    Widget slot(ValueNotifier<AdState> state, List<List<Object>> calls) => AdSlot(
          state: state,
          onMetrics: (int w, bool k) => calls.add(<Object>[w, k]),
          bannerBuilder: (BuildContext c, int w) => const SizedBox.expand(key: Key('banner')),
        );

    testWidgets('is zero height with nothing drawn until a banner is ready',
        (WidgetTester tester) async {
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(const AdState());
      await tester.pumpWidget(harness(slot(state, <List<Object>>[])));
      expect(tester.getSize(find.byType(AdSlot)).height, 0);
      expect(find.byType(DecoratedBox), findsNothing);
      expect(find.byKey(const Key('banner')), findsNothing);
    });

    testWidgets('a ready banner takes its height plus 8 above and 8 below',
        (WidgetTester tester) async {
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(
          const AdState(initialized: true, bannerVisible: true, bannerHeightDp: 50));
      await tester.pumpWidget(harness(slot(state, <List<Object>>[])));
      expect(find.byKey(const Key('banner')), findsOneWidget);
      expect(tester.getSize(find.byType(AdSlot)).height, 50 + 2 * Sp.sm);
      expect(tester.getSize(find.byKey(const Key('banner'))).height, 50);
    });

    testWidgets('collapses completely when the banner goes away', (WidgetTester tester) async {
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(
          const AdState(initialized: true, bannerVisible: true, bannerHeightDp: 50));
      await tester.pumpWidget(harness(slot(state, <List<Object>>[])));
      state.value = const AdState(initialized: true);
      await tester.pump();
      expect(tester.getSize(find.byType(AdSlot)).height, 0);
      expect(find.byKey(const Key('banner')), findsNothing);
    });

    testWidgets('collapses while the keyboard is open, gap and border included',
        (WidgetTester tester) async {
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(
          const AdState(initialized: true, bannerVisible: true, bannerHeightDp: 50));
      await tester.pumpWidget(harness(
        slot(state, <List<Object>>[]),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ));
      expect(tester.getSize(find.byType(AdSlot)).height, 0);
      expect(find.byKey(const Key('banner')), findsNothing);
    });

    testWidgets('a visible state with zero height still draws nothing',
        (WidgetTester tester) async {
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(
          const AdState(initialized: true, bannerVisible: true));
      await tester.pumpWidget(harness(slot(state, <List<Object>>[])));
      expect(tester.getSize(find.byType(AdSlot)).height, 0);
    });

    testWidgets('reports its width and the keyboard once, and again on change',
        (WidgetTester tester) async {
      final List<List<Object>> calls = <List<Object>>[];
      final ValueNotifier<AdState> state = ValueNotifier<AdState>(const AdState());
      await tester.pumpWidget(harness(slot(state, calls)));
      await tester.pump();
      expect(calls, <List<Object>>[<Object>[360, false]]);
      state.value = const AdState(initialized: true);
      await tester.pump();
      expect(calls.length, 1);
      await tester.pumpWidget(harness(
        slot(state, calls),
        viewInsets: const EdgeInsets.only(bottom: 200),
      ));
      await tester.pump();
      expect(calls.last, <Object>[360, true]);
    });
  });

  group('EntitlementBadge', () {
    Future<void> pumpWith(WidgetTester tester, ValueNotifier<Entitlement> e) {
      return tester.pumpWidget(harness(EntitlementBadge(entitlement: e, label: 'Ads removed')));
    }

    testWidgets('draws only when the purchase is owned', (WidgetTester tester) async {
      final ValueNotifier<Entitlement> e = ValueNotifier<Entitlement>(const Entitlement());
      await pumpWith(tester, e);
      expect(find.text('Ads removed'), findsNothing);
      for (final EntitlementStatus s in <EntitlementStatus>[
        EntitlementStatus.unknown,
        EntitlementStatus.notOwned,
        EntitlementStatus.pending,
      ]) {
        e.value = Entitlement(status: s);
        await tester.pump();
        expect(find.text('Ads removed'), findsNothing, reason: '$s');
      }
      e.value = const Entitlement(status: EntitlementStatus.owned);
      await tester.pump();
      expect(find.text('Ads removed'), findsOneWidget);
    });
  });

  group('NerveMeterView', () {
    testWidgets('names the state in words and exposes a percent', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        const NerveMeterView(value: 0.42, label: 'Nerve', stateLabel: 'Calm'),
      ));
      expect(find.text('Nerve · Calm'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(find.byType(NerveMeterView));
      expect(node.label, 'Nerve, Calm');
      expect(node.value, '42%');
      h.dispose();
    });

    testWidgets('bar length follows the value', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const NerveMeterView(value: 0.5, label: 'N', stateLabel: 'S'),
      ));
      await tester.pumpAndSettle();
      final double full = tester.getSize(find.byType(AnimatedFractionallySizedBox)).width;
      final RenderBox track = tester
          .renderObject(find.byType(AnimatedFractionallySizedBox).first)
          .parent! as RenderBox;
      expect(full, closeTo(track.size.width * 0.5, 0.5));
    });

    testWidgets('holds at 3.1x text and RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const NerveMeterView(value: 0.9, label: _long, stateLabel: _long),
        textScale: 3.1,
        direction: TextDirection.rtl,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('StarRow', () {
    testWidgets('draws the total and dims the unearned', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const StarRow(stars: 2, semanticLabel: '2 of 3 stars'),
      ));
      final Iterable<Opacity> ops = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(ops.map((Opacity o) => o.opacity).toList(), <double>[1, 1, 0.3]);
    });

    testWidgets('zero and three', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const StarRow(stars: 0, semanticLabel: 'none')));
      expect(tester.widgetList<Opacity>(find.byType(Opacity)).every((Opacity o) => o.opacity == 0.3),
          isTrue);
      await tester.pumpWidget(harness(const StarRow(stars: 3, semanticLabel: 'all')));
      expect(tester.widgetList<Opacity>(find.byType(Opacity)).every((Opacity o) => o.opacity == 1),
          isTrue);
    });

    testWidgets('semantic label is the caller text', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        const StarRow(stars: 1, semanticLabel: '1 of 3 stars'),
      ));
      expect(tester.getSemantics(find.byType(StarRow)).label, '1 of 3 stars');
      h.dispose();
    });
  });

  group('StatPill', () {
    testWidgets('shows label and value and reads them together', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(const StatPill(label: 'Goals', value: '7')));
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(tester.getSemantics(find.byType(StatPill)).label, 'Goals 7');
      h.dispose();
    });

    testWidgets('holds at 3.1x text', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const StatPill(label: _long, value: '1,234,567'),
        textScale: 3.1,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('ToggleRow', () {
    testWidgets('tapping the row flips the value', (WidgetTester tester) async {
      bool? got;
      await tester.pumpWidget(harness(
        ToggleRow(label: 'Sound', value: false, onChanged: (bool v) => got = v),
      ));
      await tester.tap(find.text('Sound'));
      expect(got, isTrue);
    });

    testWidgets('on shows the thumb at the end, off at the start', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        ToggleRow(label: 'Sound', value: true, onChanged: (_) {}),
      ));
      await tester.pumpAndSettle();
      Rect thumb() => tester.getRect(find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == AppSwitch.thumb && w.height == AppSwitch.thumb));
      final Rect track = tester.getRect(find.byType(AppSwitch));
      expect(thumb().right, closeTo(track.right - Sp.xxs, 0.5));
      await tester.pumpWidget(harness(
        ToggleRow(label: 'Sound', value: false, onChanged: (_) {}),
      ));
      await tester.pumpAndSettle();
      expect(thumb().left, closeTo(track.left + Sp.xxs, 0.5));
    });

    testWidgets('on mirrors under RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        ToggleRow(label: 'Sound', value: true, onChanged: (_) {}),
        direction: TextDirection.rtl,
      ));
      await tester.pumpAndSettle();
      final Rect track = tester.getRect(find.byType(AppSwitch));
      final Rect thumb = tester.getRect(find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == AppSwitch.thumb && w.height == AppSwitch.thumb));
      expect(thumb.left, closeTo(track.left + Sp.xxs, 0.5));
    });

    testWidgets('null onChanged disables it without throwing', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const ToggleRow(label: 'Sound', value: false, onChanged: null),
      ));
      await tester.tap(find.text('Sound'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics report the toggled state', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        ToggleRow(label: 'Sound', value: true, onChanged: (_) {}),
      ));
      expect(
        tester.getSemantics(find.byType(ToggleRow)),
        containsSemantics(hasToggledState: true, isToggled: true),
      );
      h.dispose();
    });

    testWidgets('holds at 3.1x text', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        ToggleRow(label: _long, subtitle: _long, value: true, onChanged: (_) {}),
        textScale: 3.1,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('SegmentedControl', () {
    const List<SegmentOption<int>> opts = <SegmentOption<int>>[
      SegmentOption<int>(value: 1, label: 'Swipe'),
      SegmentOption<int>(value: 2, label: 'Tap'),
      SegmentOption<int>(value: 3, label: 'Hold', icon: AppIcons.star),
    ];

    testWidgets('tapping a segment reports its value', (WidgetTester tester) async {
      int? got;
      await tester.pumpWidget(harness(
        SegmentedControl<int>(options: opts, selected: 1, onChanged: (int v) => got = v),
      ));
      await tester.tap(find.text('Tap'));
      expect(got, 2);
    });

    testWidgets('every segment is at least 48 high', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        SegmentedControl<int>(options: opts, selected: 1, onChanged: (_) {}),
      ));
      for (final Element e in find.byType(Pressable).evaluate()) {
        expect((e.renderObject! as RenderBox).size.height, greaterThanOrEqualTo(Metrics.touchTarget));
      }
    });

    testWidgets('the selected segment is flagged for screen readers', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        SegmentedControl<int>(options: opts, selected: 2, onChanged: (_) {}),
      ));
      expect(tester.getSemantics(find.text('Tap')), containsSemantics(isSelected: true));
      expect(tester.getSemantics(find.text('Swipe')),
          isNot(containsSemantics(isSelected: true)));
      h.dispose();
    });

    testWidgets('holds at 3.1x text in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        SegmentedControl<int>(
          options: const <SegmentOption<int>>[
            SegmentOption<int>(value: 1, label: _long),
            SegmentOption<int>(value: 2, label: _long),
          ],
          selected: 1,
          onChanged: (_) {},
        ),
        textScale: 3.1,
        direction: TextDirection.rtl,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppProgressBar', () {
    testWidgets('shows the percent text and the label', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const AppProgressBar(fraction: 0.42, valueLabel: '42%', label: 'Downloading'),
      ));
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Downloading'), findsOneWidget);
    });

    testWidgets('fill width follows the fraction', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const AppProgressBar(fraction: 0.25, valueLabel: '25%'),
      ));
      await tester.pumpAndSettle();
      final RenderBox track = tester
          .renderObject(find.byType(AnimatedFractionallySizedBox))
          .parent! as RenderBox;
      expect(tester.getSize(find.byType(AnimatedFractionallySizedBox)).width,
          closeTo(track.size.width * 0.25, 0.5));
    });

    testWidgets('semantics carry the value', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        const AppProgressBar(fraction: 1, valueLabel: '100%', label: 'Done'),
      ));
      final SemanticsNode n = tester.getSemantics(find.byType(AppProgressBar));
      expect(n.value, '100%');
      expect(n.label, 'Done');
      h.dispose();
    });

    testWidgets('reduce motion makes the change instant', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const AppProgressBar(fraction: 0, valueLabel: '0%'),
        reduceMotion: true,
      ));
      await tester.pumpWidget(harness(
        const AppProgressBar(fraction: 1, valueLabel: '100%'),
        reduceMotion: true,
      ));
      await tester.pump();
      final RenderBox track = tester
          .renderObject(find.byType(AnimatedFractionallySizedBox))
          .parent! as RenderBox;
      expect(tester.getSize(find.byType(AnimatedFractionallySizedBox)).width, track.size.width);
    });
  });
}
