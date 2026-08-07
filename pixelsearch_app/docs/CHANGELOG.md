# CHANGELOG

Format based on Keep a Changelog. Dates are ISO-8601.

## [Unreleased]
### Added
- **M6 Semantic Search — complete & real-ORT verified:** on-device CLIP semantic search wired end-to-end
  behind the `SearchBackend` seam. New `SemanticSearchBackend` (`lib/data/search/`) = `OnnxTextEmbedder`
  (query→CLIP text embedding) → `VectorIndex` cosine → **`HybridScorer`** (`lib/domain/search/`, pure) that
  fuses CLIP semantics ⊕ lexical (tags/ML Kit labels/caption/place/album) ⊕ face-intent into a ranked list.
  The `Photo` model gained read-only `labels`/`faceCount` (surfaced from the M5 DB columns) for hybrid
  ranking. Async provider graph: `vectorIndexProvider`, `indexWarmupProvider` (DB→index), cached
  `clipTokenizerProvider`, semantic-vs-keyword `searchBackendProvider` (web→keyword), debounced query, and an
  `AsyncValue` `searchResultsProvider`. Search UI now renders loading/empty/results states with a
  **"Semantic/Keyword" mode badge**. **Verification:** `integration_test/semantic_search_test.dart` (real
  Flutter ORT) — **6/6 top-1 retrieval** on the parity images with *no* lexical hints (pure CLIP), 35 ms/query
  end-to-end, brute-force scan 3.4 ms@1k / 8.1 ms@10k; **14 new unit tests** (fusion, normalization,
  face-intent, min-cosine gating, browse, keyword degradation). **46 unit tests total.** Docs: ADR-014,
  `BENCHMARK_RESULTS.md §M6`, `RESEARCH_LOG.md`.
### Changed
- `SearchBackend.search` is now **async** (`Future<List<Photo>>`) so semantic ranking can run the text
  encoder off the caller's stack; `KeywordSearchBackend` wraps synchronously (ADR-014). Lexical scoring was
  factored into a shared `keywordScore()` (single source of truth for the keyword backend and the hybrid
  lexical component) and extended to include ML Kit labels.
### Fixed
- `AiContract.schemaVersion` mirror corrected `2 → 3` to match the actual DB schema (drifted since the M5 v3 migration; the constant is documentary — no runtime effect).
- **M5 Production Indexing Engine — core complete & verified:** ports-and-adapters pipeline
  (`lib/indexing/`) — `IndexPlanner` (reconcile), `AssetProcessor`, `IndexStore` (batch txn + checkpoints),
  `IndexingService` (scan→plan→index, cancel, resume, progress stream), `ModelVersionManager`; DB **schema
  v3** (indexing metadata). **16 tests green:** reconcile, full/incremental/200-stress index,
  dedup/embed-once, deleted, changed, model-version migration, cancel+resume, per-asset failure isolation.
  All six device adapters (photo_manager, ML Kit labeling+faces, WorkManager, EXIF, thumbnail) + the
  WorkManager isolate entrypoint + DI wiring are written and **compile clean** (web+linux builds unaffected);
  only their on-device runtime is pending. Docs: `INDEXING_ARCHITECTURE.md` (architecture/class/sequence
  diagrams + scalability), ADR-013.
- **M4.6 AI Core Production Review — APPROVED:** full audit (`docs/AI_CORE_REVIEW.md`) of architecture,
  SOLID, resource lifecycle, session reuse, leaks, exceptions, logging, thread safety, duplication,
  maintainability. No critical issues, no refactor required; 2 minor items deferred to M5 with rationale.
  Certified: analyzer 0 issues, 16 unit tests, golden suite green. **M4 (AI Core) is complete.**
- **M4.5 Performance & Benchmarking:** `integration_test/benchmark_test.dart` measures model load,
  image (175 ms) / text (42 ms) embed latency, session reuse, throughput (6.1 img/s), and RSS (+612 MB,
  both fp32) on the build host; projects indexing for 100–50k; auto-writes `BENCHMARK_REPORT.md`.
  Recorded as host (x86/fp32) numbers — device fp16/NNAPI pending (BENCHMARK_RESULTS §8).
- **M4.4 Golden Validation Suite (PASSED):** permanent end-to-end validation
  (`integration_test/golden_validation_test.dart`) over both encoders via real Flutter ORT —
  **100% retrieval (6/6)**, cosine 1.0, L2-normalized, stable Top-K ranking, repeatable — auto-writes
  `VALIDATION_REPORT.md`. Regression guards: preprocessing fingerprint (`test/preprocessing_golden_test.dart`)
  + 19-case tokenizer parity, so preprocessing/tokenizer drift fails loudly.
- **M4.3 production TextEmbedder + text parity GATE (PASSED):** exact CLIP BPE tokenizer in Dart
  (`clip_tokenizer.dart` — token ids match open_clip on 19 cases) + `OnnxTextEmbedder` on a shared
  `OnnxEncoder` base (ADR-011). Real Flutter ORT text parity at **cosine 1.000000** (6 queries); vocab
  bundled as an asset. **artifact_version → 2:** text model patched with `Cast(int64→int32)` before ArgMax
  for onnxruntime-1.15 compatibility — embeddings identical, no re-index (ADR-012). Image embedder
  refactored onto the shared base (image gate re-verified, no regression).
- **M4.2 production ImageEmbedder + numerical parity GATE (PASSED):** `OnnxImageEmbedder` (reused ORT
  session, error handling, logging) + bit-faithful preprocessing (`lib/ai/`). A **real Flutter ONNX
  Runtime** integration test (`integration_test/image_parity_test.dart`, run on Linux desktop via xvfb)
  reproduces the open_clip/fp32-ONNX reference at **cosine 1.000000** on all 6 probe images
  (max-abs-err ≤ 1.3e-4), retrieval ranking 6/6. Added `onnxruntime` + `image` deps and Linux platform.
- **Interface versioning (Improvement 1):** `model_version` / `embedding_version` / `artifact_version` /
  `schema_version` in the contract (v1.1), `AiContract`, and `preprocess_config.json`; `docs/MIGRATIONS.md`
  policy; DB **schema v2** adds `EmbeddingRows.embeddingVersion` (+ migration + version-aware queries).
- **Search seam (Improvement 2):** `VectorIndex` + `BruteForceVectorIndex` (unit-tested) and a
  `SearchBackend` seam (`KeywordSearchBackend` wraps the mock, behavior unchanged); ADR-009.
- **Benchmark framework (Improvement 3):** Dart timing harness (`lib/benchmark/`) + Python retrieval
  metrics (`eval/`, P@K/R@K/AP/mAP), both unit-tested; empty result tables (no fabricated numbers).
- **M4 Phase 1 preflight:** verified the real open_clip preprocessing + tokenizer; contract clarified to
  v1.1 (resize-shortest + center-crop + antialias made explicit); **KI-1 resolved**, no frozen value changed.
- Two-repo structure formalized: **PixelSearch** (Flutter) and **PixelSearch ModelKit** (Python).
- `CLAUDE.md` operating guide in both repos.
- Documentation backbone under `docs/`: PROJECT_STATUS, ROADMAP, ARCHITECTURE, ARCHITECTURE_DECISIONS,
  CHANGELOG, TECHNICAL_DEBT, TEST_PLAN, KNOWN_ISSUES, RESEARCH_LOG, BENCHMARK_RESULTS.
- Frozen `INTERFACE_CONTRACT.md` (owned by ModelKit, mirrored to Flutter).
- **M2 (done):** drift-based local store — `PhotoRows`, `EmbeddingRows`, `IndexStateRows`;
  conditional DB connection (native + web stub); `PhotoRepository` with a little-endian
  float32 vector codec; `appDatabaseProvider` / `photoRepositoryProvider`; 5 unit tests.
  **Verified:** analyzer 0 issues, 6/6 tests pass, `flutter build web` compiles.

### Notes
- Mock keyword search (`search_engine.dart`) is unchanged; it is replaced in M7.
- M2 is additive: the store is not on the UI/search path yet (M5 indexer + M7 search consume it).

## [0.1.0] — 2026-07-22  (project-review build)
### Added
- Flutter scaffold, Material 3 theme, go_router shell (M0).
- Gallery: real device photos on Android + 18 bundled samples, web-safe via conditional imports (M1).
- UI: onboarding, search, photo viewer, timeline, map, settings (M3).
- Mock semantic search as an end-to-end stand-in for the review.
- Verified: analyzer clean, widget test passing, web build succeeds.

## [ModelKit] — 2026-07-24
### Added
- `prepare_model.py`: one-command MobileCLIP-S1 export + verification + fp16 conversion.
- Verified parity (cos 1.000000 both towers) and 6/6 retrieval; fp16/int8 size+accuracy findings.
- Artifacts: fp16 encoders, BPE vocab, `preprocess_config.json`, `reference_vectors.json`.
