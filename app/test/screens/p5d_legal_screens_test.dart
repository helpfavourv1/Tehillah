import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/license_notice.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/screens/licenses_screen.dart';
import 'package:tehillah/screens/onboarding_screen.dart';
import 'package:tehillah/screens/upgrade_screen.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _buyWith(String p) => 'Remove ads, $p';

const OnboardingLabels onLabels = OnboardingLabels(
  appName: 'Tehillah Soccer',
  promise: 'Penalty shootouts with a verse for every kick',
  languageHeader: 'Language',
  play: 'Play',
  selected: 'Selected',
);

const UpgradeLabels upLabels = UpgradeLabels(
  title: 'Remove ads',
  back: 'Back',
  headline: 'Remove ads for good',
  benefits: <String>['No banner on the menus', 'No ads between matches'],
  notSold: 'Nothing in the game is sold. Watching an ad for a bonus stays your choice.',
  buy: 'Remove ads',
  buyWithPrice: _buyWith,
  restore: 'Restore purchase',
  restoring: 'Restoring',
  owned: 'Ads removed',
  ownedDetail: 'Thank you for supporting the game',
  pending: 'Your purchase is pending',
  unavailable: 'The store is not available right now',
);

const LicensesLabels liLabels = LicensesLabels(
  title: 'Licenses',
  back: 'Back',
  intro: 'These texts and fonts are used under their licenses.',
  openLink: 'Read the license',
  emptyTitle: 'No notices',
  emptySubtitle: 'Nothing to show',
);

Widget upgrade(
  EntitlementStatus status, {
  String? price = r'$2.99',
  bool restoring = false,
  List<String>? log,
}) {
  return harness(
    UpgradeScreen(
      labels: upLabels,
      status: status,
      restoring: restoring,
      priceLabel: price,
      onBuy: () => log?.add('buy'),
      onRestore: () => log?.add('restore'),
      onBack: () => log?.add('back'),
    ),
  );
}

void main() {
  group('OnboardingScreen', () {
    const List<OnboardingLanguage> langs = <OnboardingLanguage>[
      OnboardingLanguage(code: 'en', name: 'English'),
      OnboardingLanguage(code: 'es', name: 'Español'),
      OnboardingLanguage(code: 'ar', name: 'العربية'),
    ];

    Widget build(List<String> log, {String selected = 'en'}) => harness(
          OnboardingScreen(
            labels: onLabels,
            languages: langs,
            selectedCode: selected,
            onLanguage: (String c) => log.add('lang:$c'),
            onPlay: () => log.add('play'),
          ),
        );

    testWidgets('shows the brand once, the promise and every language', (WidgetTester tester) async {
      await tester.pumpWidget(build(<String>[]));
      expect(find.text('Tehillah Soccer'), findsOneWidget);
      expect(find.text('Penalty shootouts with a verse for every kick'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('the chosen language carries a check and is announced', (WidgetTester tester) async {
      await tester.pumpWidget(build(<String>[], selected: 'es'));
      expect(find.bySemanticsLabel('Español. Selected'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check),
        findsOneWidget,
      );
    });

    testWidgets('choosing a language and Play report', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(log));
      await tester.tap(find.text('Español'));
      await tester.tap(find.text('Play'));
      expect(log, <String>['lang:es', 'play']);
    });

    testWidgets('Play stays on screen at 3x text on a small phone', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          OnboardingScreen(
            labels: onLabels,
            languages: langs,
            selectedCode: 'en',
            onLanguage: (String c) {},
            onPlay: () {},
          ),
          textScale: 3,
          size: const Size(320, 568),
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Play')).bottom, lessThanOrEqualTo(568));
    });
  });

  group('UpgradeScreen', () {
    testWidgets('not owned shows Buy with the price and Restore', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(upgrade(EntitlementStatus.notOwned, log: log));
      expect(find.text(r'Remove ads, $2.99'), findsOneWidget);
      await tester.tap(find.text(r'Remove ads, $2.99'));
      await tester.tap(find.text('Restore purchase'));
      expect(log, <String>['buy', 'restore']);
    });

    testWidgets('owned hides Buy but keeps Restore visible', (WidgetTester tester) async {
      await tester.pumpWidget(upgrade(EntitlementStatus.owned));
      expect(find.text('Ads removed'), findsOneWidget);
      expect(find.textContaining('Remove ads,'), findsNothing);
      expect(find.text('Restore purchase'), findsOneWidget);
    });

    testWidgets('pending disables Buy and says why', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(upgrade(EntitlementStatus.pending, log: log));
      expect(find.text('Your purchase is pending'), findsOneWidget);
      await tester.tap(find.text(r'Remove ads, $2.99'), warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('no price means no purchase and an honest note', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(upgrade(EntitlementStatus.unknown, price: null, log: log));
      expect(find.text('The store is not available right now'), findsOneWidget);
      await tester.tap(find.text('Remove ads').last, warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('restoring disables both buttons and changes the words', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(upgrade(EntitlementStatus.notOwned, restoring: true, log: log));
      expect(find.text('Restoring'), findsOneWidget);
      await tester.tap(find.text('Restoring'), warnIfMissed: false);
      await tester.tap(find.text(r'Remove ads, $2.99'), warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('states the benefits and that nothing in the game is sold', (WidgetTester tester) async {
      await tester.pumpWidget(upgrade(EntitlementStatus.notOwned));
      expect(find.text('No banner on the menus'), findsOneWidget);
      expect(find.textContaining('Nothing in the game is sold'), findsOneWidget);
    });

    testWidgets('survives 3x text and right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          UpgradeScreen(
            labels: upLabels,
            status: EntitlementStatus.notOwned,
            restoring: false,
            priceLabel: r'$2.99',
            onBuy: () {},
            onRestore: () {},
            onBack: () {},
          ),
          textScale: 3,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('LicensesScreen', () {
    const List<LicenseNotice> notices = <LicenseNotice>[
      LicenseNotice(
        id: 'pt_BR',
        title: 'Bíblia Livre',
        license: 'CC BY 4.0',
        attribution: 'Bíblia Livre (BLIVRE), Copyright 2018 Diego Santos, Mario Sérgio e Marco Teles',
        link: 'https://creativecommons.org/licenses/by/4.0/',
      ),
      LicenseNotice(
        id: 'en',
        title: 'Berean Standard Bible',
        license: 'Public domain',
        attribution: 'The Holy Bible, Berean Standard Bible',
      ),
    ];

    Widget build(List<LicenseNotice> list, {List<String>? log}) => harness(
          LicensesScreen(
            labels: liLabels,
            notices: list,
            onOpenLink: (String u) => log?.add(u),
            onBack: () => log?.add('back'),
          ),
        );

    testWidgets('shows every notice with its exact attribution', (WidgetTester tester) async {
      await tester.pumpWidget(build(notices));
      expect(find.text('Bíblia Livre'), findsOneWidget);
      expect(
        find.text('Bíblia Livre (BLIVRE), Copyright 2018 Diego Santos, Mario Sérgio e Marco Teles'),
        findsOneWidget,
      );
      expect(find.text('Public domain'), findsOneWidget);
    });

    testWidgets('a link chip appears only when there is a link', (WidgetTester tester) async {
      await tester.pumpWidget(build(notices));
      expect(find.text('Read the license'), findsOneWidget);
    });

    testWidgets('the link chip opens the license', (WidgetTester tester) async {
      useSurface(tester);
      final List<String> log = <String>[];
      await tester.pumpWidget(build(notices, log: log));
      await tester.tap(find.text('Read the license'));
      expect(log, <String>['https://creativecommons.org/licenses/by/4.0/']);
    });

    testWidgets('no notices shows the empty state', (WidgetTester tester) async {
      await tester.pumpWidget(build(<LicenseNotice>[]));
      expect(find.text('No notices'), findsOneWidget);
    });

    testWidgets('many notices are built lazily and survive 3x text', (WidgetTester tester) async {
      await tester.pumpWidget(
        harness(
          LicensesScreen(
            labels: liLabels,
            notices: <LicenseNotice>[
              for (int i = 0; i < 60; i++)
                LicenseNotice(id: 'n$i', title: 'Notice $i', license: 'MIT', attribution: 'Credit $i'),
            ],
            onOpenLink: (String u) {},
            onBack: () {},
          ),
          textScale: 3,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Notice ').evaluate().length, lessThan(20));
    });
  });
}
