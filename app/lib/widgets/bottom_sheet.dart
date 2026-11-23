import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// The sheet surface: secondary fill, 20 radius on the top corners only, a
/// grabber, an optional title and scrolling content. It keeps clear of the
/// home indicator and the keyboard, and never grows past 90% of the screen.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.child, super.key, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Metrics.contentMaxWidth, maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheetTop)),
            border: Border(top: BorderSide(color: p.borderSubtle, width: Metrics.hairline)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom > keyboard ? safeBottom : keyboard),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: Sp.sm),
                ExcludeSemantics(
                  child: Center(
                    child: SizedBox(
                      width: Metrics.grabberWidth,
                      height: Metrics.grabberHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.borderSubtle,
                          borderRadius: BorderRadius.circular(Radii.pill(Metrics.grabberHeight)),
                        ),
                      ),
                    ),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, 0),
                    child: Semantics(
                      header: true,
                      child: Text(title!, style: theme.text.title2),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Sp.md),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A modal route for sheets: scrim behind, slide up in 400 ms ease-out, slide
/// down in 280 ms. With Reduce Motion on it appears and leaves instantly.
class _SheetRoute<T> extends PopupRoute<T> {
  _SheetRoute({
    required this.builder,
    required this.label,
    required this.scrim,
    required this.instant,
  });

  final WidgetBuilder builder;
  final String label;
  final Color scrim;
  final bool instant;

  @override
  Color? get barrierColor => scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => instant ? Duration.zero : Motion.sheet;

  @override
  Duration get reverseTransitionDuration => instant ? Duration.zero : Motion.pop;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (instant) {
      return child;
    }
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Motion.out)),
      child: child,
    );
  }
}

/// Presents [builder]'s content in a bottom sheet and completes with whatever
/// is passed to `Navigator.pop`. [barrierLabel] is the localized label for the
/// dismiss area behind the sheet.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String barrierLabel,
  required WidgetBuilder builder,
  String? title,
}) {
  final bool instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      builder: (BuildContext c) => AppBottomSheet(title: title, child: builder(c)),
      label: barrierLabel,
      scrim: AppTheme.of(context).palette.scrim,
      instant: instant,
    ),
  );
}
