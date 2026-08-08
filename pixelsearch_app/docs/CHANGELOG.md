# CHANGELOG

Format based on Keep a Changelog. Dates are ISO-8601.

## [Unreleased]
### Performance — indexing throughput (measured on device, Realme RMX3092 / Android 12)
First on-device profile of the M5 pipeline, per stage, over 40 assets at ~1200x1600:

| stage | before | after |
|---|---|---|
| loadBytes | 75 ms | 75 ms |
| exif | 1 ms | 1 ms |
| JPEG decode | ~850 ms (**decoded twice**) | **465 ms (once)** |
| thumbnail | 494 ms | **31 ms** |
| embed (preprocess + ONNX) | 845 ms | **660 ms** |
| ML Kit (labels + faces) | 493 ms | 462 ms |
| **total** | **2325 ms/photo** | **1694 ms/photo** |

**1.37x (23 → 35 photos/min).** Per-photo cost scales with resolution — the same build measures
~1956 ms on 12 MP frames — so quote throughput with the resolution. Changes, all embedding-preserving:
- **Decode once per photo.** `AssetProcessor` now decodes and hands the same `img.Image` to the thumbnail
  and embed stages; `ThumbnailGenerator`/`AssetEmbedder` take a decoded image instead of bytes. Both stages
  previously decoded the same JPEG independently. ML Kit still receives the original bytes.
- **TD-9 paid down.** `preprocessForClip` reads the packed RGB buffer instead of calling `getPixel` for every
  one of w×h pixels. Same uint8 samples, same Float64 accumulation, **fingerprint unchanged**
  (`sum=100051.464714 a=0.623529 b=0.207843 c=0.956863`) — embeddings are bit-identical.
- **ONNX intra-op threads** set to half the cores (clamped 1–4); the session was single-threaded on an
  8-core device. Affects only summation order inside the graph.

Deliberately **not** done, to protect quality: face detection still runs on every photo (it feeds M6
people-query ranking), and full-resolution decode is retained rather than substituting a native downscaled
thumbnail — that would change the pixels CLIP sees (TD-18, needs an `embedding_version` bump + re-index).
### Fixed
- **Every photo now gets tags.** ML Kit labelling used a hard 0.5 confidence floor, so photos where nothing
  cleared it were stored with *no* labels — measured at **5 of 800 (0.62%)** on a real library, mostly
  screenshots and documents, leaving them unsearchable by keyword. `selectLabels` keeps the ≥0.5 set exactly
  as before and, only when that set is empty, falls back to the best 3 candidates. ML Kit is queried once at
  the lower floor and the threshold is applied in Dart, so there is **no extra inference**. Confident photos
  are bit-identically labelled. Re-measured on device: **0 of 512 newly-indexed photos unlabelled (0.00%)**,
  with fallbacks like `["Paper","Screenshot","Poster"]`. 5 new unit tests.
- **M5 indexing is now actually on the app's path — the two reported integration bugs.** The app was still
  running the M1 demo loader (`lib/data/device_gallery*`), so the completed M5 pipeline was never invoked:
  `buildDeviceIndexingService`/`IndexingService.run()` had no caller outside tests. Symptoms and causes:
  **(1) only ~80 photos imported** — the demo loader hard-capped at `load({int limit = 80})` and issued a
  single `getAssetListRange(0, 80)`; the real `PhotoManagerGallerySource` already paginates the whole
  gallery (`getAssetListPaged`, 500/page) and `IndexingService` has no cap at all.
  **(2) labels were `photo`/`portrait`/`landscape`/`<year>`** — those were synthesized by the demo loader's
  `_deriveTags()` from EXIF dimensions and dates; ML Kit's real labels were being persisted to
  `photo_rows.labelsJson` by `IndexStore` all along, but nothing read them back onto the display path.
  **No file under `lib/indexing/**` or `lib/ai/**` changed** — the fix is wiring plus removal of the demo.
  Regression cover: `test/indexing_integration_test.dart` (1500 assets → 1500 indexed; ML Kit labels
  survive DB → `Photo.labels` and the synthetic tags are gone; thumbnail path reaches `Photo`).
### Added
- **Indexing on the UI path (M5 wiring).** `IndexingController` (`indexingControllerProvider`) runs one
  incremental pass at a time with live `IndexProgress`, cancellation, and — on completion — a refresh of the
  photo library and an invalidation of `indexWarmupProvider` so new embeddings become searchable in-session.
  The native-only pipeline sits behind a conditional-import boundary (`lib/state/index_bridge*.dart` +
  `IndexCancelToken`, ADR-015) that also requests media permission before scanning — `PhotoManagerGallerySource`
  reports an *empty* gallery rather than an error when access was never granted, so an unprompted run would
  have silently indexed zero photos. Web gets a `unsupported` stub, keeping the web build green.
  UI: an index status card on the empty search screen and a Library section in Settings, both sharing
  `IndexingStatus` (status line + determinate progress bar); onboarding's primary action is now
  "Index my photos".
### Changed
- **`PhotoLibrary` is DB-backed.** It reads `PhotoRepository.loadPhotos()` (the M5 index) instead of seeding
  from bundled samples, and is refreshed by `IndexingController`. `Photo` gained `thumbPath` (the indexed
  thumbnail *file* — paths, never blobs) plus `displayTitle`/`displayTags` so indexed rows, which carry no
  authored title or tags, render their ML Kit labels. `Photo.image` resolves the thumbnail file through a new
  web-safe `fileImage()` boundary (`lib/core/platform_image*.dart`) and falls back to a transparent
  placeholder instead of a bundled sample photo. Photo tiles prefer the top ML Kit label for their chip.
### Removed
- The M1 demo gallery loader — `lib/data/device_gallery.dart`, `device_gallery_io.dart`,
  `device_gallery_stub.dart` — and the hardcoded `samplePhotos` list (`sample_data.dart` keeps only the
  generic `suggestedQueries` search hints). Resolves TD-5.

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
