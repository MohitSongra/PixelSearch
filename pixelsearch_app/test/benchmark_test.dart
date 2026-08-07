import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/benchmark/benchmark.dart';

void main() {
  test('TimingStats computes mean/median/p95/min/max', () {
    final s = TimingStats.fromSamplesUs('t', [10, 20, 30, 40, 50]);
    expect(s.iterations, 5);
    expect(s.meanUs, 30);
    expect(s.medianUs, 30);
    expect(s.minUs, 10);
    expect(s.maxUs, 50);
    expect(s.p95Us, 50); // nearest-rank: round(0.95*4)=4 → 50
  });

  test('measure runs warmup + timed iterations and records one result', () async {
    final b = Benchmark();
    var calls = 0;
    final stats = await b.measure('noop', () => calls++, iterations: 5, warmup: 2);
    expect(calls, 7); // 2 warmup + 5 timed
    expect(b.results.length, 1);
    expect(stats.iterations, 5);
    expect(stats.name, 'noop');
  });
}
