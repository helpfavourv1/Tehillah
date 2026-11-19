import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware number, percent, date and score formatting.
///
/// Date formats for languages other than English need the intl date data to be
/// initialised once at startup with `initializeDateFormatting()`.
class Formatters {
  Formatters(Locale locale) : _name = intlName(locale);

  final String _name;

  /// Maps an app locale to the name intl uses.
  static String intlName(Locale locale) {
    if (locale.languageCode == 'pt') {
      return 'pt_BR';
    }
    return locale.languageCode;
  }

  /// A whole number with the locale's digits and grouping.
  String integer(int value) => NumberFormat.decimalPattern(_name).format(value);

  /// A fraction between 0 and 1 as a percentage, for example 0.5 gives 50%.
  String percent(double fraction) =>
      NumberFormat.percentPattern(_name).format(fraction);

  /// A calendar date, for example Nov 18, 2026.
  String date(DateTime value) => DateFormat.yMMMd(_name).format(value);

  /// A short weekday name, for the Daily Bread streak row.
  String weekdayShort(DateTime value) => DateFormat.E(_name).format(value);

  /// A match score, for example 3 - 2. The separator is a plain en dash so it
  /// reads the same in every language, and each number uses the locale digits.
  String score(int home, int away) => '${integer(home)} – ${integer(away)}';
}
