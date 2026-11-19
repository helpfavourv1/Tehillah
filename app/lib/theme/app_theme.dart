import 'package:flutter/widgets.dart';

import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/theme/typography.dart';

/// The palette and type ramp for one mode and language.
@immutable
class AppThemeData {
  const AppThemeData({required this.palette, required this.text});

  factory AppThemeData.forMode(PaletteMode mode, {Locale? locale}) {
    final AppPalette palette = AppPalette.forMode(mode);
    return AppThemeData(
      palette: palette,
      text: TextRoles.forPalette(palette, locale: locale),
    );
  }

  /// Builds data for an already-blended palette (the theme cross-fade).
  factory AppThemeData.forPalette(AppPalette palette, {Locale? locale}) {
    return AppThemeData(
      palette: palette,
      text: TextRoles.forPalette(palette, locale: locale),
    );
  }

  final AppPalette palette;
  final TextRoles text;

  @override
  bool operator ==(Object other) =>
      other is AppThemeData && other.palette == palette;

  @override
  int get hashCode => palette.hashCode;
}

/// Gives every widget below it the palette and type ramp, without Material.
class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required this.data, required super.child});

  final AppThemeData data;

  static AppThemeData of(BuildContext context) {
    final AppTheme? scope =
        context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(scope != null, 'No AppTheme found above this context.');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => data != oldWidget.data;
}
