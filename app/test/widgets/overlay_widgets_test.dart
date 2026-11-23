import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/providers/feedback_provider.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_dialog.dart';
import 'package:tehillah/widgets/bottom_sheet.dart';
import 'package:tehillah/widgets/error_state_view.dart';
import 'package:tehillah/widgets/feedback_banner.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/warning_banner.dart';

import '../support/widget_harness.dart';

const String _long =
    'A rather long label that has to wrap onto several lines at the largest text size';

/// A harness with a real Navigator so sheets and dialogs can be pushed.
Widget navHarness(
  Widget Function(BuildContext context) home, {
  bool reduceMotion = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return harness(
    SizedBox.expand(
      child: Navigator(
        onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) =>
              Builder(builder: home),
        ),
      ),
    ),
    reduceMotion: reduceMotion,
    viewInsets: viewInsets,
  );
}

bool _hasIcon(Widget w, IconData symbol) => w is AppIcon && w.symbol == symbol;

void main() {
  group('FeedbackProvider', () {
    test('show gives each message a new id', () {
      final FeedbackProvider f = FeedbackProvider();
      f.show('a');
      final int first = f.value!.id;
      f.show('a');
      expect(f.value!.id, isNot(first));
      expect(f.value!.tone, FeedbackTone.success);
      f.show('b', tone: FeedbackTone.failure);
      expect(f.value!.tone, FeedbackTone.failure);
    });

    test('clearIf ignores a stale id', () {
      final FeedbackProvider f = FeedbackProvider();
      f.show('a');
      final int old = f.value!.id;
      f.show('b');
      f.clearIf(old);
      expect(f.value?.text, 'b');
      f.clearIf(f.value!.id);
      expect(f.value, isNull);
    });

    test('writes after dispose are ignored', () {
      final FeedbackProvider f = FeedbackProvider();
      f.dispose();
      expect(() => f.show('late'), returnsNormally);
      expect(() => f.clear(), returnsNormally);
    });
  });

  group('FeedbackBanner and FeedbackHost', () {
    testWidgets('success and failure differ by icon, not only colour', (WidgetTester tester) async {
      await tester.pumpWidget(harness(FeedbackBanner(
        message: const FeedbackMessage(id: 1, text: 'Saved', tone: FeedbackTone.success),
        dismissLabel: 'Dismiss',
        onDismiss: () {},
      )));
      expect(find.byWidgetPredicate((Widget w) => _hasIcon(w, AppIcons.check)), findsOneWidget);
      await tester.pumpWidget(harness(FeedbackBanner(
        message: const FeedbackMessage(id: 2, text: 'Failed', tone: FeedbackTone.failure),
        dismissLabel: 'Dismiss',
        onDismiss: () {},
      )));
      expect(find.byWidgetPredicate((Widget w) => _hasIcon(w, AppIcons.warning)), findsOneWidget);
      expect(find.byWidgetPredicate((Widget w) => _hasIcon(w, AppIcons.check)), findsNothing);
    });

    testWidgets('is a live region', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(FeedbackBanner(
        message: const FeedbackMessage(id: 1, text: 'Saved', tone: FeedbackTone.success),
        dismissLabel: 'Dismiss',
        onDismiss: () {},
      )));
      expect(tester.getSemantics(find.text('Saved')), containsSemantics(isLiveRegion: true));
      h.dispose();
    });

    testWidgets('host shows a success for 3 seconds', (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
      ));
      expect(find.text('Saved'), findsNothing);
      fb.show('Saved');
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('a failure stays for 6 seconds', (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
      ));
      fb.show('Could not save', tone: FeedbackTone.failure);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Could not save'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Could not save'), findsNothing);
    });

    testWidgets('a newer message restarts the time and is not removed early',
        (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
      ));
      fb.show('A');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      fb.show('B');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('B'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('B'), findsNothing);
    });

    testWidgets('dismiss removes it at once', (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
      ));
      fb.show('Saved');
      await tester.pump();
      await tester.tap(find.byType(IconChip));
      await tester.pump();
      expect(find.text('Saved'), findsNothing);
      expect(fb.value, isNull);
    });

    testWidgets('sits below the top safe area', (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
        padding: const EdgeInsets.only(top: 40),
      ));
      fb.show('Saved');
      await tester.pump();
      expect(tester.getTopLeft(find.byType(FeedbackBanner)).dy, 40 + Sp.sm);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('holds at 3.1x text in RTL', (WidgetTester tester) async {
      final FeedbackProvider fb = FeedbackProvider();
      await tester.pumpWidget(harness(
        FeedbackHost(feedback: fb, dismissLabel: 'Dismiss', child: const SizedBox.expand()),
        textScale: 3.1,
        direction: TextDirection.rtl,
      ));
      fb.show(_long, tone: FeedbackTone.failure);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('WarningBanner', () {
    testWidgets('shows the message and fires action and dismiss', (WidgetTester tester) async {
      int retried = 0;
      int dismissed = 0;
      await tester.pumpWidget(harness(WarningBanner(
        message: 'Progress is not being saved',
        actionLabel: 'Retry',
        onAction: () => retried++,
        dismissLabel: 'Dismiss',
        onDismiss: () => dismissed++,
      )));
      expect(find.text('Progress is not being saved'), findsOneWidget);
      expect(find.byWidgetPredicate((Widget w) => _hasIcon(w, AppIcons.warning)), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.tap(find.byType(IconChip));
      expect(retried, 1);
      expect(dismissed, 1);
    });

    testWidgets('without action or dismiss it is only the message', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const WarningBanner(message: 'Recovered')));
      expect(find.byType(IconChip), findsNothing);
      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('is not a live region', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(const WarningBanner(message: 'Recovered')));
      expect(tester.getSemantics(find.text('Recovered')),
          isNot(containsSemantics(isLiveRegion: true)));
      h.dispose();
    });

    testWidgets('holds at 3.1x text in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        WarningBanner(
          message: _long,
          actionLabel: _long,
          onAction: () {},
          dismissLabel: 'x',
          onDismiss: () {},
        ),
        textScale: 3.1,
        direction: TextDirection.rtl,
        scroll: true,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('ErrorStateView', () {
    testWidgets('shows everything and fires both buttons', (WidgetTester tester) async {
      int retry = 0;
      int report = 0;
      await tester.pumpWidget(harness(ErrorStateView(
        title: 'Something went wrong',
        message: 'Please try again.',
        detail: 'E-42',
        retryLabel: 'Retry',
        onRetry: () => retry++,
        reportLabel: 'Report',
        onReport: () => report++,
      )));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('E-42'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Report'));
      expect(retry, 1);
      expect(report, 1);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
    });

    testWidgets('detail is optional', (WidgetTester tester) async {
      await tester.pumpWidget(harness(ErrorStateView(
        title: 't',
        message: 'm',
        retryLabel: 'Retry',
        onRetry: () {},
        reportLabel: 'Report',
        onReport: () {},
      )));
      expect(find.text('E-42'), findsNothing);
    });

    testWidgets('fills the screen and holds at 3.1x text in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        ErrorStateView(
          title: _long,
          message: _long,
          detail: _long,
          retryLabel: _long,
          onRetry: () {},
          reportLabel: _long,
          onReport: () {},
        ),
        textScale: 3.1,
        direction: TextDirection.rtl,
      ));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ErrorStateView)), const Size(360, 720));
    });
  });

  group('bottom sheet', () {
    Widget host({
      required void Function(BuildContext) onTap,
      bool reduceMotion = false,
      EdgeInsets viewInsets = EdgeInsets.zero,
    }) {
      return navHarness(
        (BuildContext c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(c),
          child: const Center(child: Text('open')),
        ),
        reduceMotion: reduceMotion,
        viewInsets: viewInsets,
      );
    }

    testWidgets('opens with its title and content and has 20 top corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        onTap: (BuildContext c) => unawaited(showAppBottomSheet<void>(
          context: c,
          barrierLabel: 'Close',
          title: 'Options',
          builder: (BuildContext _) => const Text('Hello'),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      final bool rounded = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any(
            (DecoratedBox d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).borderRadius ==
                    const BorderRadius.vertical(top: Radius.circular(Radii.sheetTop)),
          );
      expect(rounded, isTrue);
    });

    testWidgets('slides up over 400 ms: off screen at the start, in place at the end',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        onTap: (BuildContext c) => unawaited(showAppBottomSheet<void>(
          context: c,
          barrierLabel: 'Close',
          builder: (BuildContext _) => const Text('Hello'),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final double early = tester.getTopLeft(find.text('Hello')).dy;
      await tester.pump(const Duration(milliseconds: 400));
      final double late = tester.getTopLeft(find.text('Hello')).dy;
      expect(early, greaterThan(late));
      expect(late, lessThan(720));
    });

    testWidgets('reduce motion places it instantly', (WidgetTester tester) async {
      await tester.pumpWidget(host(
        reduceMotion: true,
        onTap: (BuildContext c) => unawaited(showAppBottomSheet<void>(
          context: c,
          barrierLabel: 'Close',
          builder: (BuildContext _) => const Text('Hello'),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      expect(tester.getTopLeft(find.text('Hello')).dy, lessThan(720));
    });

    testWidgets('tapping the scrim dismisses it with a null result', (WidgetTester tester) async {
      Object? result = 'unset';
      await tester.pumpWidget(host(
        onTap: (BuildContext c) async {
          result = await showAppBottomSheet<String>(
            context: c,
            barrierLabel: 'Close',
            builder: (BuildContext _) => const Text('Hello'),
          );
        },
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('pop returns the chosen value', (WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(host(
        onTap: (BuildContext c) async {
          result = await showAppBottomSheet<String>(
            context: c,
            barrierLabel: 'Close',
            builder: (BuildContext sheet) => GestureDetector(
              onTap: () => Navigator.of(sheet).pop('picked'),
              child: const Text('Pick'),
            ),
          );
        },
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(result, 'picked');
    });

    testWidgets('tall content scrolls inside 90% of the screen', (WidgetTester tester) async {
      await tester.pumpWidget(host(
        onTap: (BuildContext c) => unawaited(showAppBottomSheet<void>(
          context: c,
          barrierLabel: 'Close',
          builder: (BuildContext _) => const SizedBox(height: 3000, child: Text('Tall')),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final Size scroll = tester.getSize(find.byType(SingleChildScrollView));
      expect(scroll.height, lessThanOrEqualTo(720 * 0.9));
    });

    testWidgets('content stays above the keyboard', (WidgetTester tester) async {
      await tester.pumpWidget(host(
        viewInsets: const EdgeInsets.only(bottom: 300),
        onTap: (BuildContext c) => unawaited(showAppBottomSheet<void>(
          context: c,
          barrierLabel: 'Close',
          builder: (BuildContext _) => const Text('Hello'),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.text('Hello')).dy, lessThanOrEqualTo(420));
    });
  });

  group('dialog', () {
    Widget host(void Function(BuildContext) onTap) {
      return navHarness(
        (BuildContext c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(c),
          child: const Center(child: Text('open')),
        ),
      );
    }

    testWidgets('confirm completes true', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(host((BuildContext c) async {
        result = await showConfirmDialog(
          context: c,
          barrierLabel: 'Close',
          title: 'Delete?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
        );
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('Delete?'), findsNothing);
    });

    testWidgets('cancel and scrim dismissal complete false', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(host((BuildContext c) async {
        result = await showConfirmDialog(
          context: c,
          barrierLabel: 'Close',
          title: 'Delete?',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
        );
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('a destructive confirm uses the destructive button', (WidgetTester tester) async {
      await tester.pumpWidget(host((BuildContext c) {
        unawaited(showConfirmDialog(
          context: c,
          barrierLabel: 'Close',
          title: 'Delete?',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
          destructive: true,
        ));
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(DestructiveButton), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    });

    testWidgets('a non-dismissible dialog ignores the scrim', (WidgetTester tester) async {
      await tester.pumpWidget(host((BuildContext c) {
        unawaited(showAppDialog<void>(
          context: c,
          barrierLabel: 'Close',
          dismissible: false,
          builder: (BuildContext _) => const AppDialog(
            title: 'Wait',
            actions: <Widget>[],
          ),
        ));
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text('Wait'), findsOneWidget);
    });

    testWidgets('has a 16 radius and holds at 3.1x text in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        AppDialog(
          title: _long,
          message: _long,
          icon: AppIcons.info,
          actions: <Widget>[
            PrimaryButton(label: _long, onPressed: () {}),
            SecondaryButton(label: _long, onPressed: () {}),
          ],
        ),
        textScale: 3.1,
        direction: TextDirection.rtl,
      ));
      expect(tester.takeException(), isNull);
      final bool rounded = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any(
            (DecoratedBox d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(Radii.dialog),
          );
      expect(rounded, isTrue);
    });
  });
}
