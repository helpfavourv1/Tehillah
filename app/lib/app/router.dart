import 'package:flutter/widgets.dart';
import 'package:tehillah/app/pages/home_page.dart';
import 'package:tehillah/app/pages/onboarding_page.dart';
import 'package:tehillah/theme/tokens.dart';

/// Every route name in the app, in one place.
abstract final class AppRoutes {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String journey = '/journey';
  static const String modes = '/modes';
  static const String daily = '/daily';
  static const String verses = '/verses';
  static const String achievements = '/achievements';
  static const String settings = '/settings';
}

/// Page transitions: a fade with a 20 px slide, 350 ms in and 280 ms out.
/// With Reduce Motion on, an instant opacity change.
PageRoute<T> appRoute<T>(RouteSettings settings, WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) => builder(context),
    transitionDuration: Motion.push,
    reverseTransitionDuration: Motion.pop,
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondary, Widget child) {
      final bool reduce = MediaQuery.disableAnimationsOf(context);
      final Animation<double> curved =
          CurvedAnimation(parent: animation, curve: Curves.easeInOut, reverseCurve: Curves.easeInOut);
      final Widget faded = FadeTransition(opacity: curved, child: child);
      if (reduce) {
        return faded;
      }
      final bool rtl = Directionality.of(context) == TextDirection.rtl;
      return SlideTransition(
        position: Tween<Offset>(begin: Offset(rtl ? -0.05 : 0.05, 0), end: Offset.zero).animate(curved),
        child: faded,
      );
    },
  );
}

/// Builds the route for [settings], or null for a name the app does not own.
Route<Object?>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.onboarding:
      return appRoute<Object?>(settings, (BuildContext c) => const OnboardingPage());
    case AppRoutes.home:
      return appRoute<Object?>(settings, (BuildContext c) => const HomePage());
    default:
      return null;
  }
}

/// A name nobody owns lands on Home, never on a blank screen.
Route<Object?> onUnknownRoute(RouteSettings settings) =>
    appRoute<Object?>(settings, (BuildContext c) => const HomePage());
