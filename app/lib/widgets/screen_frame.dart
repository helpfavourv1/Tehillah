import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// The shape of every screen: safe area, nav bar, content, then an optional
/// bottom slot (the ad slot). Chrome stays fixed; only the content scrolls,
/// and only if it chooses to.
///
/// While the keyboard is open the bottom slot is removed completely (no gap,
/// no border), and the content makes room for the keyboard once, so the layout
/// never jumps back.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    required this.child,
    super.key,
    this.navBar,
    this.bottom,
    this.background,
  });

  final Widget? navBar;
  final Widget child;

  /// Shown under the content when there is room (not while the keyboard is
  /// open). It decides its own height; zero height means nothing is drawn.
  final Widget? bottom;

  /// Defaults to the primary background token.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.of(context).palette;
    final MediaQueryData media = MediaQuery.of(context);
    final bool keyboardOpen = media.viewInsets.bottom > 0;
    final double bottomInset = keyboardOpen ? media.viewInsets.bottom : media.padding.bottom;
    return ColoredBox(
      color: background ?? palette.bgPrimary,
      child: Padding(
        padding: EdgeInsets.only(
          top: media.padding.top,
          left: media.padding.left,
          right: media.padding.right,
          bottom: bottomInset,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (navBar != null) navBar!,
                Expanded(child: child),
                if (bottom != null && !keyboardOpen) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
