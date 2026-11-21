/// Calendar-day keys in the form `2026-11-19`, used for Daily Bread and Seven
/// Days. The key is built from the device's local year, month and day, so
/// "today" is the player's own day. Arithmetic uses UTC dates, which have no
/// daylight-saving gaps.
abstract final class DateKey {
  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// The key for the calendar day of [date], read as written (no time-zone
  /// conversion).
  static String of(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// The day a key names, as a UTC date. Throws [FormatException] for anything
  /// that is not a real calendar day.
  static DateTime parse(String key) {
    final RegExpMatch? m = _pattern.firstMatch(key);
    if (m == null) {
      throw FormatException('"$key" is not a date key');
    }
    final int y = int.parse(m.group(1)!);
    final int mo = int.parse(m.group(2)!);
    final int d = int.parse(m.group(3)!);
    final DateTime date = DateTime.utc(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d) {
      throw FormatException('"$key" is not a real day');
    }
    return date;
  }

  /// Whole days from [from] to [to]; negative if [to] is earlier.
  static int daysBetween(String from, String to) =>
      parse(to).difference(parse(from)).inDays;

  /// The key [days] days after [key] (before it, when negative).
  static String addDays(String key, int days) =>
      of(parse(key).add(Duration(days: days)));
}
