/// Typed reads from decoded JSON. Bad data is reported as a [FormatException]
/// so the storage layer can treat it as corruption and recover, never crash.
Map<String, Object?> jsonMap(Object? value, String what) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw FormatException('$what must be a JSON object');
}

List<Object?> jsonList(Object? value, String what) {
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('$what must be a JSON array');
}

int readInt(Map<String, Object?> map, String key, {int? min, int? max}) {
  final Object? value = map[key];
  if (value is! int) {
    throw FormatException('"$key" must be an integer');
  }
  if ((min != null && value < min) || (max != null && value > max)) {
    throw FormatException('"$key" is out of range');
  }
  return value;
}

double readDouble(
  Map<String, Object?> map,
  String key, {
  double? min,
  double? max,
}) {
  final Object? value = map[key];
  if (value is! num) {
    throw FormatException('"$key" must be a number');
  }
  final double result = value.toDouble();
  if (result.isNaN ||
      (min != null && result < min) ||
      (max != null && result > max)) {
    throw FormatException('"$key" is out of range');
  }
  return result;
}

String readString(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('"$key" must be a non-empty string');
  }
  return value;
}

bool readBool(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value is! bool) {
    throw FormatException('"$key" must be true or false');
  }
  return value;
}

T readEnum<T extends Enum>(List<T> values, Map<String, Object?> map, String key) {
  final Object? value = map[key];
  for (final T candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  throw FormatException('"$key" has an unknown value');
}

bool listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<K, V> entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int hashMap<K, V>(Map<K, V> map) {
  int sum = 0;
  for (final MapEntry<K, V> entry in map.entries) {
    sum += Object.hash(entry.key, entry.value);
  }
  return sum;
}
