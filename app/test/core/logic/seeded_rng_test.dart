import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';

void main() {
  test('matches the reference sequence for a known seed', () {
    final SeededRng rng = SeededRng(42);
    expect(<int>[rng.nextUint32(), rng.nextUint32(), rng.nextUint32()],
        <int>[2581720956, 1925393290, 3661312704]);
    final SeededRng ints = SeededRng(123456789);
    expect(<int>[ints.nextInt(1000), ints.nextInt(1000), ints.nextInt(1000)],
        <int>[257, 970, 785]);
    expect(SeededRng(7).nextDouble(), closeTo(0.0117047532, 1e-9));
    expect(SeededRng(5).nextGaussian(), closeTo(0.5290722686, 1e-9));
  });

  test('the same seed gives the same sequence and different seeds differ', () {
    final SeededRng a = SeededRng(99);
    final SeededRng b = SeededRng(99);
    expect(<int>[for (int i = 0; i < 20; i++) a.nextUint32()],
        <int>[for (int i = 0; i < 20; i++) b.nextUint32()]);
    expect(SeededRng(1).nextUint32(), isNot(SeededRng(2).nextUint32()));
  });

  test('seeds wrap to 32 bits', () {
    expect(SeededRng(0x1FFFFFFFF).seed, 0xFFFFFFFF);
    expect(SeededRng(-1).seed, 0xFFFFFFFF);
  });

  test('nextInt stays in range and rejects a non-positive limit', () {
    final SeededRng rng = SeededRng(3);
    for (int i = 0; i < 500; i++) {
      final int v = rng.nextInt(6);
      expect(v, inInclusiveRange(0, 5));
    }
    expect(() => rng.nextInt(0), throwsArgumentError);
  });

  test('gaussian draws have mean near 0 and deviation near 1', () {
    final SeededRng rng = SeededRng(11);
    final List<double> v = <double>[for (int i = 0; i < 20000; i++) rng.nextGaussian()];
    final double mean = v.reduce((double a, double b) => a + b) / v.length;
    final double variance =
        v.map((double x) => (x - mean) * (x - mean)).reduce((double a, double b) => a + b) / v.length;
    expect(mean.abs(), lessThan(0.05));
    expect(variance, closeTo(1.0, 0.08));
  });

  test('fork depends on the seed and label, not on how much was drawn', () {
    final SeededRng a = SeededRng(42);
    final SeededRng b = SeededRng(42);
    for (int i = 0; i < 10; i++) {
      a.nextUint32();
    }
    expect(a.fork('keeper').seed, b.fork('keeper').seed);
    expect(a.fork('keeper').seed, 1822910153);
    expect(a.fork('shooter').seed, 555913309);
    expect(a.fork('keeper').seed, isNot(a.fork('shooter').seed));
  });

  test('fork works for seeds whose bytes are above 127', () {
    expect(SeededRng(0xFFFFFFFF).fork('shot').seed, isNot(SeededRng(0xFFFFFFFE).fork('shot').seed));
  });

  test('fork rejects a non-ASCII label', () {
    expect(() => SeededRng(1).fork('é'), throwsArgumentError);
  });
}
