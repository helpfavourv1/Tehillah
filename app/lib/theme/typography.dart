import 'package:flutter/widgets.dart';

import 'package:tehillah/theme/tokens.dart';

/// Font family names, as declared in pubspec.yaml.
abstract final class AppFonts {
  /// Brand, buttons, menus and every other piece of interface chrome.
  static const String chrome = 'Inter';

  /// Verses, reader text and other reading copy.
  static const String reading = 'TehillahReadingSans';
}

/// The type ramp. Each role has one job: display for the brand and scores,
/// chrome for interface labels, reading for verses and long copy.
@immutable
class TextRoles {
  const TextRoles({
    required this.display,
    required this.score,
    required this.headline,
    required this.title1,
    required this.title2,
    required this.body,
    required this.callout,
    required this.footnote,
    required this.caption,
    required this.sectionHeader,
  });

  /// Builds the ramp for a palette. Scripts without a bundled face use the
  /// platform's system font; their line height is scaled for taller glyphs.
  factory TextRoles.forPalette(AppPalette palette, {Locale? locale}) {
    final double k = heightScaleFor(locale);
    TextStyle style(
      String family,
      double size,
      FontWeight weight,
      double height,
      Color color, {
      double? letterSpacing,
      List<FontFeature>? features,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height * k,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: features,
      );
    }

    return TextRoles(
      display: style(AppFonts.chrome, 34, FontWeight.w700, 1.1,
          palette.textPrimary,
          letterSpacing: -0.7),
      score: style(AppFonts.chrome, 34, FontWeight.w700, 1.1,
          palette.textPrimary,
          letterSpacing: -0.7,
          features: const <FontFeature>[FontFeature.tabularFigures()]),
      headline: style(AppFonts.chrome, 28, FontWeight.w600, 1.2,
          palette.textPrimary,
          letterSpacing: -0.4),
      title1: style(
          AppFonts.chrome, 22, FontWeight.w600, 1.3, palette.textPrimary),
      title2: style(
          AppFonts.chrome, 17, FontWeight.w600, 1.3, palette.textPrimary),
      body: style(
          AppFonts.reading, 17, FontWeight.w400, 1.5, palette.textPrimary),
      callout: style(
          AppFonts.chrome, 16, FontWeight.w500, 1.4, palette.textPrimary),
      footnote: style(
          AppFonts.chrome, 13, FontWeight.w400, 1.4, palette.textSecondary),
      caption: style(
          AppFonts.chrome, 12, FontWeight.w400, 1.3, palette.textTertiary),
      sectionHeader: style(
          AppFonts.chrome, 12, FontWeight.w600, 1.3, palette.textTertiary,
          letterSpacing: 0.8),
    );
  }

  /// Multiplier applied to every line height for a language's script.
  static double heightScaleFor(Locale? locale) {
    switch (locale?.languageCode) {
      case 'hi':
        return 1.15;
      case 'ar':
        return 1.1;
      case 'ja':
      case 'ko':
      case 'zh':
        return 1.08;
      case 'he':
        return 1.05;
      default:
        return 1.0;
    }
  }

  /// Brand and large headings.
  final TextStyle display;

  /// Match score digits: display with tabular figures so they do not jump.
  final TextStyle score;

  final TextStyle headline;
  final TextStyle title1;
  final TextStyle title2;

  /// Verses, reader text and reading copy.
  final TextStyle body;

  /// Buttons, row labels and chips.
  final TextStyle callout;

  /// Secondary lines.
  final TextStyle footnote;

  /// Timestamps and fine print.
  final TextStyle caption;

  /// Small letter-spaced group headings. The widget upper-cases the text.
  final TextStyle sectionHeader;

  /// Reader text at the user's chosen size factor (1.0 is the default size).
  TextStyle readerBody(double sizeFactor) =>
      body.copyWith(fontSize: body.fontSize! * sizeFactor);
}
