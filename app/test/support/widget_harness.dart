import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// Wraps a widget the way the app shell will: direction, media (size, text
/// scale, motion, keyboard) and the theme, with no Material anywhere.
Widget harness(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  PaletteMode mode = PaletteMode.light,
  Size size = const Size(360, 720),
  bool reduceMotion = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
  EdgeInsets padding = EdgeInsets.zero,
  bool constrainWidth = true,
}) {
  return Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
        viewInsets: viewInsets,
        padding: padding,
      ),
      child: AppTheme(
        data: AppThemeData.forMode(mode),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
          child: Align(
            alignment: Alignment.topCenter,
            child: constrainWidth ? SizedBox(width: size.width, height: size.height, child: child) : child,
          ),
        ),
      ),
    ),
  );
}
