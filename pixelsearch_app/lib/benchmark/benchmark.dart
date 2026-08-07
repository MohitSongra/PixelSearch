import 'dart:async';

/// Timing statistics for one benchmarked operation, in microseconds.
class TimingStats {
  const TimingStats({
    required this.name,
    required this.iterations,
    required this.meanUs,
    required this.medianUs,
    required this.p95Us,
    required this.minUs,
    required this.maxUs,
  });

  final String name;
  final int iterations;
  final double meanUs;
  final double medianUs;
  final double p95Us;
  final double minUs;
  final double maxUs;

  Map<String, dynamic> toJson() => {
        'name': name,
        'iterations': iterations,
        'mean_us': meanUs,
        'median_us': medianUs,
        'p95_us': p95Us,
        'min_us': minUs,
        'max_us': maxUs,
      };

  /// Summarize raw per-iteration microsecond [samples] (nearest-rank percentiles).
  static TimingStats fromSamplesUs(String name, List<double> samples) {
    assert(samples.isNotEmpty, 'need at least one sample');
    final s = [...samples]..sort();
    double pct(double p) => s[(p * (s.length - 1)).round()];
    final mean = s.reduce((a, b) => a + b) / s.length;
    return TimingStats(
      name: name,
      iterations: s.length,
      meanUs: mean,
      medianUs: pct(0.50),
      p95Us: pct(0.95),
      minUs: s.first,
      maxUs: s.last,
    );
  }
}

/// Minimal, dependency-free benchmark runner. It is deliberately generic; each
/// milestone registers its own cases: M5 → indexing throughput, M6 → search
/// latency. It only *measures* — it never invents numbers (see BENCHMARK_RESULTS.md).
class Benchmark {
  final List<TimingStats> _results = [];

  List<TimingStats> get results => List.unmodifiable(_results);

  /// Runs [warmup] untimed iterations, then times [fn] [iterations] times and
  /// records the stats. Works for sync or async operations.
  Future<TimingStats> measure(
    String name,
    FutureOr<void> Function() fn, {
    int iterations = 20,
    int warmup = 3,
  }) async {
    for (var i = 0; i < warmup; i++) {
      await fn();
    }
    final samples = <double>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await fn();
      sw.stop();
      samples.add(sw.elapsedMicroseconds.toDouble());
    }
    final stats = TimingStats.fromSamplesUs(name, samples);
    _results.add(stats);
    return stats;
  }

  Map<String, dynamic> toJson() =>
      {'benchmarks': [for (final r in _results) r.toJson()]};
}
