# Benchmark harness (PixelSearch)

`lib/benchmark/benchmark.dart` is a dependency-free timing harness that grows with the project:
- **M5** registers indexing-throughput cases (photos/sec, batched, in an isolate).
- **M7** registers search-latency cases (tokenize + text-embed + cosine over N embeddings).

## Run
Benchmarks execute as Dart/Flutter tests or a small driver that calls `Benchmark.measure(name, fn)`.
Timing is wall-clock via `Stopwatch`; `Benchmark.toJson()` serializes results for archiving.

```dart
final b = Benchmark();
await b.measure('cosine_scan_10k', () => index.query(q, topK: 50), iterations: 30);
print(b.toJson());
```

## Scope
- **Measures here:** per-operation latency (mean / median / p95 / min / max).
- **Captured out of band** (recorded in `docs/BENCHMARK_RESULTS.md`): APK/model size (build artifacts),
  peak memory (DevTools / `ProcessInfo.currentRss` on device), and retrieval quality (ModelKit `eval/`).

## Rule
Only record **measured** values. Never hand-write a number into `docs/BENCHMARK_RESULTS.md`.
