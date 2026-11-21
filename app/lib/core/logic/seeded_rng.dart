/// A small deterministic random generator (mulberry32). The same seed gives the
/// same sequence on every device and every run, which is what lets a match, a
/// Daily Bread challenge and the balance simulation replay exactly.
///
/// All arithmetic stays below 2^53, so results are identical on the Dart VM and
/// on the web.
final class SeededRng {
  SeededRng(int seed)
      : seed = seed & _mask32,
        _state = seed & _mask32;

  static const int _mask32 = 0xFFFFFFFF;

  /// The seed this generator started from.
  final int seed;
  int _state;

  /// 32-bit multiply with the same wrap-around as a C `Math.imul`.
  static int _imul(int a, int b) =>
      ((a & 0xFFFF) * b + ((((a >> 16) * b) & 0xFFFF) << 16)) & _mask32;

  /// The next raw 32-bit value, 0 to 4294967295.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    int t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ (t >> 14)) & _mask32;
  }

  /// A value from 0 (included) to 1 (excluded).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// A whole number from 0 (included) to [max] (excluded).
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return (nextDouble() * max).floor();
  }

  /// True with probability [p].
  bool chance(double p) => nextDouble() < p;

  /// A bell-shaped value with mean 0 and standard deviation 1 (sum of four
  /// uniform draws, which is close enough for execution noise and needs no
  /// logarithm).
  double nextGaussian() {
    final double sum =
        nextDouble() + nextDouble() + nextDouble() + nextDouble() - 2.0;
    return sum * 1.7320508075688772;
  }

  /// A new generator for a named purpose. It depends only on this generator's
  /// seed and the label, never on how much has been drawn, so adding a draw in
  /// one part of the game cannot shift the sequence in another. Labels must be
  /// ASCII.
  SeededRng fork(String label) {
    int h = 0x811C9DC5;
    final List<int> bytes = <int>[
      seed & 0xFF,
      (seed >> 8) & 0xFF,
      (seed >> 16) & 0xFF,
      (seed >> 24) & 0xFF,
      ...label.codeUnits,
    ];
    for (final int b in bytes) {
      if (b > 0x7F) {
        throw ArgumentError.value(label, 'label', 'must be ASCII');
      }
      h ^= b;
      h = _imul(h, 0x01000193);
    }
    return SeededRng(h);
  }
}
