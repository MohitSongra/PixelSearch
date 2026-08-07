# TEST PLAN

Testing scales with the milestone. Principle: every milestone lands with the tests that prove it.

## Layers
- **Unit** — pure logic and data. DB round-trip & migrations (M2), embedding-blob codec (M2),
  BPE tokenizer parity (M6), cosine ranking (M7), Photo⇆row mapper (M2).
- **Parity** — the Dart pipeline vs `reference_vectors.json`: for each query row, argmax == diagonal (6/6).
  This is the guardrail against silent ModelKit/Flutter drift (M6/M7).
- **Widget** — key screens render and respond (search, viewer, onboarding).
- **Integration** — index a small fixture set → query → assert ranked results (M5+M7).
- **Golden (optional)** — image preprocessing output vs a reference tensor, once M4 preprocessing is verified.

## Current coverage
- Baseline: analyzer clean; widget smoke test passes; `flutter build web` succeeds.

## M2 adds (this milestone)
- `test/database_test.dart`:
  - insert → read back a `PhotoRows` row (all fields survive).
  - upsert an `EmbeddingRows` vector; read back; assert the `Float32List` is **bit-identical** (blob codec is lossless).
  - `IndexStateRows` read/write single-row semantics.
  - runs against `NativeDatabase.memory()` on the host (no device needed).
- Gate: `flutter analyze` = 0 issues; `flutter test` green; `flutter build web` still compiles.

## Added with the architectural improvements (2026-08-06)
- `test/brute_force_vector_index_test.dart` — cosine ranking, topK, upsert/remove/clear.
- `test/benchmark_test.dart` — `TimingStats` math + harness warmup/iteration accounting.
- `test/database_test.dart` — added the `embedding_version` staleness case (schema v2).
- ModelKit `eval/test_metrics.py` — Precision@K / Recall@K / AP / mAP on synthetic inputs.
- **Totals:** Flutter **11** tests green; ModelKit metric tests green; analyzer 0 issues; web build OK.

## M4 parity tests (the numerical gate)
- **Image gate — DONE (real Flutter ORT):** `integration_test/image_parity_test.dart` runs the full
  production pipeline through onnxruntime on Linux desktop (`xvfb-run flutter test integration_test -d linux`)
  and asserts dims=512, cosine>0.999, max-abs-err<0.02, retrieval 6/6. **Result: cosine 1.000000 on all 6.**
- **Preprocessing unit tests** (in-sandbox `flutter test`): shape / [0,1] range / CHW / crop — ORT-independent.
- **Tokenizer parity — DONE:** Dart token ids == open_clip ids on 19 diverse cases (`test/clip_tokenizer_test.dart`).
- **Text gate — DONE (real Flutter ORT):** `integration_test/text_parity_test.dart` — query → tokenizer →
  Flutter ORT → L2 vs reference; **cosine 1.000000** on all 6 queries.
- **Golden suite — DONE (real Flutter ORT):** `integration_test/golden_validation_test.dart` — full
  image+text pipeline: 100% retrieval, cosine parity, normalization, stable Top-K ranking, repeatability;
  auto-writes `VALIDATION_REPORT.md`.
- **Regression guards — DONE:** `test/preprocessing_golden_test.dart` (pinned preprocessing fingerprint)
  + the 19-case tokenizer parity — silent preprocessing/tokenizer drift fails loudly.
- **Benchmark suite:** `integration_test/benchmark_test.dart` — model load, embed latency, throughput
  on real Flutter ORT (build host); auto-writes `BENCHMARK_REPORT.md` (BENCHMARK_RESULTS §8).
- **On-device fp16 golden** (device): the fp16 artifacts on NNAPI/XNNPACK (the CPU EP cannot execute fp16).

## M5 indexing tests (core — real drift DB + fakes, in-sandbox)
- `test/index_planner_test.dart` (7) — reconcile: added / changed / deleted / stale-version / no-embedding /
  idempotent-skip / mixed.
- `test/indexing_service_test.dart` (9) — full index + embed-once, incremental (no duplicate work), new-only,
  deleted (+embedding removed), changed re-embed, model-version migration, cancel→resume, per-asset failure
  isolation, 200-asset stress + checkpoint.
- **On device (pending):** device adapters (photo_manager, ML Kit, WorkManager, EXIF, thumbnail),
  WorkManager reboot/backoff, and real latency/memory.

## M6 — semantic search (added 2026-08-07)
Unit (in-sandbox, no ONNX):
- `test/hybrid_scorer_test.dart` (8) — semantic-dominates-lexical, lexical boost on near-ties, min-max
  normalization, face-intent gating (boost only on people queries), zero-signal drop, empty input, `reason`
  attribution, fixed-band cosine mapping.
- `test/semantic_search_backend_test.dart` (6) — nearest-first retrieval, semantic hit with zero keyword
  overlap, empty-query browse (newest-first), `semanticMinCosine` gating, graceful keyword degradation on
  model-load failure (no embed calls after), empty-index → pure-lexical.

Integration (real Flutter ORT, `-d linux` via xvfb):
- `integration_test/semantic_search_test.dart` — embeds the 6 parity images, runs real text queries through
  the **entire** `SemanticSearchBackend` path: asserts **6/6** top-1 retrieval; measures diagonal/off-diagonal
  cosine, end-to-end query latency, and brute-force scan latency @1k/10k → `SEMANTIC_SEARCH_REPORT.md`.

## Tracked follow-ups
- A drift **schema-migration test** (v1→v2) using drift's schema-verification harness (not yet added).
- A widget test asserting the async search states (spinner → results, Semantic/Keyword badge).

## Deferred (need a physical device — tracked in BENCHMARK_RESULTS as PENDING)
On-device latency, indexing throughput, memory, and end-to-end search quality on real libraries (M5/M6 runtime).
Hybrid-weight + threshold precision/recall on a labeled set (M14).
