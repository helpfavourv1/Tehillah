import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/app_row.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/section_header.dart';

import '../support/widget_harness.dart';

const String _long =
    'A rather long label that has to wrap onto several lines at the largest text size';

void main() {
  group('Pressable', () {
    testWidgets('a tiny child still gets a 48 by 48 hit area and taps', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(harness(
        Pressable.opacity(onTap: () => taps++, child: const SizedBox.square(dimension: 10)),
      ));
      final Size size = tester.getSize(find.byType(Pressable));
      expect(size.width, greaterThanOrEqualTo(Metrics.touchTarget));
      expect(size.height, greaterThanOrEqualTo(Metrics.touchTarget));
      await tester.tapAt(tester.getTopLeft(find.byType(Pressable)) + const Offset(40, 40));
      expect(taps, 1);
    });

    testWidgets('opacity drops while pressed and returns on release', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        Pressable.opacity(onTap: () {}, child: const SizedBox.square(dimension: 60)),
      ));
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(Pressable)));
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, Metrics.pressedOpacity);
      await g.up();
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    });

    testWidgets('a null onTap is disabled: no press feedback, no tap, semantics say so',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        const Pressable(builder: _plain, semanticLabel: 'Off'),
      ));
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(Pressable)));
      await tester.pump();
      expect(find.text('pressed'), findsNothing);
      await g.up();
      expect(tester.getSemantics(find.bySemanticsLabel('Off')).flagsCollection.isEnabled.name, isNot('isTrue'));
      handle.dispose();
    });

    testWidgets('long press fires its own callback', (WidgetTester tester) async {
      int longs = 0;
      await tester.pumpWidget(harness(
        Pressable(
          onTap: () {},
          onLongPress: () => longs++,
          builder: _plain,
        ),
      ));
      await tester.longPress(find.byType(Pressable));
      expect(longs, 1);
    });

    testWidgets('reduce motion makes the press animation instant', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        Pressable.opacity(onTap: () {}, child: const SizedBox.square(dimension: 60)),
        reduceMotion: true,
      ));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration, Duration.zero);
    });
  });

  group('AppCard', () {
    testWidgets('shows label, second line and value, and taps', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(harness(
        AppCard(label: 'Journey', subtitle: 'Garden', value: '3 of 12', leading: AppIcons.journey, chevron: true, onTap: () => taps++),
      ));
      expect(find.text('Journey'), findsOneWidget);
      expect(find.text('Garden'), findsOneWidget);
      expect(find.text('3 of 12'), findsOneWidget);
      await tester.tap(find.byType(AppCard));
      expect(taps, 1);
      expect(tester.getSize(find.byType(AppCard)).height, greaterThanOrEqualTo(Metrics.rowMinHeight));
    });

    testWidgets('without onTap it is a plain surface', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const AppCard(label: 'Info')));
      expect(find.byType(Pressable), findsNothing);
    });

    testWidgets('the chevron sits at the end in both directions', (WidgetTester tester) async {
      Future<double> chevronOffset(TextDirection d) async {
        await tester.pumpWidget(harness(AppCard(label: 'Go', chevron: true, onTap: () {}), direction: d));
        return tester.getCenter(find.byType(Icon)).dx - tester.getCenter(find.byType(AppCard)).dx;
      }

      expect(await chevronOffset(TextDirection.ltr), greaterThan(0));
      expect(await chevronOffset(TextDirection.rtl), lessThan(0));
    });

    testWidgets('long text wraps at 3.1x text scale without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const AppCard(label: _long, subtitle: _long, value: 'Value that is long too', leading: AppIcons.star, chevron: true),
        textScale: 3.1,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the surface uses tokens: secondary fill and hairline border', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const AppCard(label: 'Tokens')));
      final DecoratedBox box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(CardSurface), matching: find.byType(DecoratedBox)).first);
      final BoxDecoration d = box.decoration as BoxDecoration;
      expect(d.color, AppPalette.light.bgSecondary);
      expect((d.border! as Border).top.width, Metrics.hairline);
      expect(d.borderRadius, BorderRadius.circular(Radii.card));
      expect(d.boxShadow, isNull);
    });
  });

  group('AppRow', () {
    testWidgets('shows a tint while pressed', (WidgetTester tester) async {
      await tester.pumpWidget(harness(AppRow(label: 'Sound', onTap: () {})));
      bool tinted() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .any((DecoratedBox b) => (b.decoration as BoxDecoration).color == AppPalette.light.bgTertiary);
      expect(tinted(), isFalse);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(AppRow)));
      await tester.pump();
      expect(tinted(), isTrue);
      await g.up();
    });

    testWidgets('a trailing control replaces the chevron, and no onTap means no chevron',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(AppRow(label: 'A', onTap: () {}, trailing: const Text('switch'))));
      expect(find.text('switch'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      await tester.pumpWidget(harness(const AppRow(label: 'B')));
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Pressable), findsNothing);
    });

    testWidgets('is at least 56 high and survives 3.1x text', (WidgetTester tester) async {
      await tester.pumpWidget(harness(AppRow(label: _long, subtitle: _long, value: 'v', leading: AppIcons.sound, onTap: () {}), textScale: 3.1));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppRow)).height, greaterThanOrEqualTo(Metrics.rowMinHeight));
    });
  });

  group('AppChip', () {
    testWidgets('the pill is 32 high inside a 48 hit area when tappable', (WidgetTester tester) async {
      await tester.pumpWidget(harness(AppChip(label: 'Easy', onTap: () {})));
      expect(tester.getSize(find.byType(Pressable)).height, greaterThanOrEqualTo(Metrics.touchTarget));
      final Finder pill = find.descendant(of: find.byType(AppChip), matching: find.byType(DecoratedBox));
      expect(tester.getSize(pill.first).height, Metrics.chipHeight);
    });

    testWidgets('a plain chip is not a control', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const AppChip(label: 'Level 2', icon: AppIcons.star)));
      expect(find.byType(Pressable), findsNothing);
      expect(find.text('Level 2'), findsOneWidget);
    });

    testWidgets('selected fills with the accent and taps', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(harness(AppChip(label: 'Dark', selected: true, onTap: () => taps++)));
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(AppChip), matching: find.byType(DecoratedBox)).first,
      );
      expect((box.decoration as BoxDecoration).color, AppPalette.light.accent);
      await tester.tap(find.byType(AppChip));
      expect(taps, 1);
    });
  });

  group('Buttons', () {
    testWidgets('PrimaryButton is a filled accent button at least 48 high', (WidgetTester tester) async {
      await tester.pumpWidget(harness(PrimaryButton(label: 'Play', onPressed: () {})));
      expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(Metrics.buttonHeight));
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(PrimaryButton), matching: find.byType(DecoratedBox)).first,
      );
      final BoxDecoration d = box.decoration as BoxDecoration;
      expect(d.color, AppPalette.light.accent);
      expect(d.border, isNull);
      expect(d.borderRadius, BorderRadius.circular(Radii.button));
    });

    testWidgets('pressing scales to 0.97 and darkens to the pressed fill', (WidgetTester tester) async {
      await tester.pumpWidget(harness(PrimaryButton(label: 'Play', onPressed: () {})));
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(PrimaryButton)));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, Metrics.pressedScale);
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(PrimaryButton), matching: find.byType(DecoratedBox)).first,
      );
      expect((box.decoration as BoxDecoration).color, AppPalette.light.accentDim);
      await g.up();
    });

    testWidgets('disabled is dimmed to 40% and does not fire', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const PrimaryButton(label: 'Play', onPressed: null)));
      expect(
        tester.widget<AnimatedOpacity>(find.descendant(of: find.byType(PrimaryButton), matching: find.byType(AnimatedOpacity))).opacity,
        Metrics.disabledOpacity,
      );
    });

    testWidgets('secondary is filled with the tertiary surface, destructive with error', (WidgetTester tester) async {
      Color fillOf(Type type) => (tester
              .widget<DecoratedBox>(find.descendant(of: find.byType(type), matching: find.byType(DecoratedBox)).first)
              .decoration as BoxDecoration)
          .color!;
      await tester.pumpWidget(harness(Column(children: <Widget>[
        SecondaryButton(label: 'Cancel', onPressed: () {}),
        DestructiveButton(label: 'Delete', onPressed: () {}),
      ])));
      expect(fillOf(SecondaryButton), AppPalette.light.bgTertiary);
      expect(fillOf(DestructiveButton), AppPalette.light.error);
    });

    testWidgets('expanded false hugs its content; long labels wrap at 3.1x', (WidgetTester tester) async {
      await tester.pumpWidget(harness(PrimaryButton(label: 'OK', expanded: false, onPressed: () {})));
      expect(tester.getSize(find.byType(PrimaryButton)).width, lessThan(200));
      await tester.pumpWidget(harness(PrimaryButton(label: _long, icon: AppIcons.play, onPressed: () {}), textScale: 3.1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires on tap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(harness(PrimaryButton(label: 'Go', onPressed: () => taps++)));
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
    });
  });

  group('SectionHeader and EmptyState', () {
    testWidgets('the header is uppercase and a semantic header', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(const SectionHeader('Appearance')));
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(tester.getSemantics(find.text('APPEARANCE')).flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('empty state shows icon, title, subtitle and action', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        EmptyState(
          icon: AppIcons.offline,
          title: 'Nothing here',
          subtitle: 'Try again later',
          action: PrimaryButton(label: 'Retry', onPressed: () {}),
        ),
      ));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('subtitle and action are optional', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const EmptyState(icon: AppIcons.list, title: 'Empty')));
      expect(find.byType(PrimaryButton), findsNothing);
      expect(find.text('Empty'), findsOneWidget);
    });
  });

  group('IconChip and NavBar', () {
    testWidgets('the chip is 40 square inside a 48 hit area and has a semantic label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(IconChip(icon: AppIcons.settings, semanticLabel: 'Settings', onTap: () {})));
      expect(tester.getSize(find.byType(Pressable)), const Size.square(Metrics.touchTarget));
      expect(tester.getSize(find.byType(SizedBox).last), const Size.square(Metrics.iconChip));
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('active fills with the accent', (WidgetTester tester) async {
      await tester.pumpWidget(harness(IconChip(icon: AppIcons.sound, semanticLabel: 'Sound', active: true, onTap: () {})));
      final DecoratedBox box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(IconChip), matching: find.byType(DecoratedBox)).first);
      expect((box.decoration as BoxDecoration).color, AppPalette.light.accent);
    });

    testWidgets('back goes back; the title is shown; actions sit at the end', (WidgetTester tester) async {
      int backs = 0;
      await tester.pumpWidget(harness(
        NavBar.back(
          onBack: () => backs++,
          backLabel: 'Back',
          title: 'Settings',
          actions: <Widget>[IconChip(icon: AppIcons.search, semanticLabel: 'Search', onTap: () {})],
        ),
      ));
      expect(find.text('Settings'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      expect(backs, 1);
      final double searchX = tester.getCenter(find.byType(IconChip).last).dx;
      final double backX = tester.getCenter(find.byType(IconChip).first).dx;
      expect(searchX, greaterThan(backX));
    });

    testWidgets('in right-to-left the back chip is on the right and actions on the left', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        NavBar.back(
          onBack: () {},
          backLabel: 'Back',
          title: 'Settings',
          actions: <Widget>[IconChip(icon: AppIcons.search, semanticLabel: 'Search', onTap: () {})],
        ),
        direction: TextDirection.rtl,
      ));
      expect(tester.getCenter(find.byType(IconChip).first).dx, greaterThan(tester.getCenter(find.byType(IconChip).last).dx));
    });

    testWidgets('brand shows the name once with actions at the end', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        NavBar.brand(name: 'Tehillah Soccer', actions: <Widget>[IconChip(icon: AppIcons.settings, semanticLabel: 'Settings', onTap: () {})]),
      ));
      expect(find.text('Tehillah Soccer'), findsOneWidget);
      expect(find.byType(BrandWordmark), findsOneWidget);
    });

    testWidgets('a long title and large text never overflow', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        NavBar.back(onBack: () {}, backLabel: 'Back', title: _long, actions: <Widget>[IconChip(icon: AppIcons.search, semanticLabel: 'Search', onTap: () {})]),
        textScale: 3.1,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('ScreenFrame', () {
    testWidgets('lays out nav bar, content and bottom slot on the primary background', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const ScreenFrame(
        navBar: Text('nav'),
        bottom: SizedBox(height: 50, child: Text('ad')),
        child: Text('content'),
      )));
      expect(find.text('nav'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      expect(find.text('ad'), findsOneWidget);
      expect(tester.getTopLeft(find.text('ad')).dy, greaterThan(tester.getTopLeft(find.text('content')).dy));
      final ColoredBox bg = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
      expect(bg.color, AppPalette.light.bgPrimary);
    });

    testWidgets('the bottom slot is removed entirely while the keyboard is open', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const ScreenFrame(bottom: SizedBox(height: 50, child: Text('ad')), child: Text('content')),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ));
      expect(find.text('ad'), findsNothing);
    });

    testWidgets('content makes room for system bars and the keyboard', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const ScreenFrame(child: Align(alignment: Alignment.bottomCenter, child: Text('end'))),
        padding: const EdgeInsets.only(top: 24, bottom: 34),
      ));
      expect(tester.getBottomLeft(find.text('end')).dy, lessThanOrEqualTo(720 - 34));
      await tester.pumpWidget(harness(
        const ScreenFrame(child: Align(alignment: Alignment.bottomCenter, child: Text('end'))),
        padding: const EdgeInsets.only(top: 24, bottom: 34),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ));
      expect(tester.getBottomLeft(find.text('end')).dy, lessThanOrEqualTo(720 - 300));
    });

    testWidgets('content never grows wider than the content width on wide screens', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const ScreenFrame(child: SizedBox(key: Key('wide'), width: double.infinity, height: 10)),
        size: const Size(1000, 600),
      ));
      expect(tester.getSize(find.byKey(const Key('wide'))).width, Metrics.contentMaxWidth);
    });

    testWidgets('dark mode uses the dark background', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const ScreenFrame(child: SizedBox()), mode: PaletteMode.dark));
      expect(tester.widget<ColoredBox>(find.byType(ColoredBox).first).color, AppPalette.dark.bgPrimary);
    });
  });
}

Widget _plain(BuildContext context, bool pressed) =>
    SizedBox.square(dimension: 60, child: Text(pressed ? 'pressed' : 'idle'));
