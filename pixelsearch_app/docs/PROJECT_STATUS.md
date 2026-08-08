# PROJECT_STATUS

**As of:** 2026-08-08 · **Phase:** M5 indexing **wired to the app** (ADR-015) on top of a complete & verified M6. The M1 demo gallery loader is deleted; the library is now the on-device index. Next: M12 (model manager — indexing needs the provisioned encoder, KI-8) or M9 (filters). · **Build:** analyzer 0 issues, **49 unit tests** + golden + 2 parity + **M6 semantic** + benchmark suites green, web + **Android debug APK** build OK.

**Architectural improvements landed (2026-08-06):** interface versioning + migration policy (schema v2);
`VectorIndex` search seam (brute-force now, ANN-swappable); benchmark + eval framework. All verified, no fabricated results.

## One-line status
The app now runs **real on-device semantic search over a real on-device index**: the M5 pipeline is invoked
from the UI (`IndexingController` → `index_bridge` → `IndexingService`), persists ML Kit labels + CLIP
embeddings + thumbnail paths, and the photo library reads straight from that store — no demo data, no import
cap anywhere on the path. Search ranks by embedding cosine + hybrid signals with a keyword fallback, verified
in-sandbox on a real ONNX Runtime (6/6). Runtime provisioning of the fp16 image encoder is the remaining
blocker for indexing on a device (KI-8, M12); photo_manager/ML Kit runtime behaviour is still device-verified
only (TD-11).

## Milestone ledger
| ID | Milestone | Status | Evidence |
|----|-----------|--------|----------|
| M0 | Flutter scaffold, theme, routing, shell | ✅ done | `lib/core`, `lib/app.dart`, analyzer clean |
| M1 | Gallery: device photos (Android) + bundled samples | ⚠️ superseded | the demo loader + `samplePhotos` were **deleted** in the M5 wiring (ADR-015); gallery access now runs through `PhotoManagerGallerySource` |
| M3 | UI shell: search, viewer, timeline, map, settings, onboarding | ✅ done | `lib/features/*` |
| — | Mock keyword search (stand-in, now the M6 lexical fallback) | ✅ done | `lib/data/search_engine.dart` |
| — | ModelKit spike: export + verify MobileCLIP | ✅ done | `PixelSearch_ModelKit/SPIKE_REPORT.md` (6/6, cos 1.0) |
| M2 | SQLite/drift store for photos + embeddings | ✅ done | `lib/data/local/*`, `photo_repository.dart`; 5 DB tests; native + web-stub connection |
| **M4** | **Flutter ONNX (preflight -> ImageEmbedder -> parity gate)** | ✅ done | M4.2–M4.6 COMPLETE (parity, golden 100%, benchmarks, review APPROVED) |
| **M5** | **Production indexing engine (reconcile, batch, resume, incremental, versioned)** | ✅ core (16 tests) + 6 adapters + **now wired to the UI** (19 tests); on-device runtime pending | ports+adapters; ADR-013, **ADR-015**; `INDEXING_ARCHITECTURE.md`; `test/indexing_integration_test.dart` |
| **M6** | **Semantic search: real CLIP text→image cosine + hybrid re-rank, replacing the mock** | ✅ done | `SemanticSearchBackend`, `HybridScorer`; 14 unit tests + real-ORT **6/6**; ADR-014 |
| M9 | Filters (date/place/album) over the store | ⏳ pending | |
| M10 | Timeline backed by the DB | ⏳ pending | |
| M11 | Real map tiles (flutter_map + OSM) | ⏳ pending | |
| M12 | Model manager + privacy controls (provisioning UI) | ⏳ pending | fp16 ~171 MB provisioned at runtime |
| M13 | Optional FastAPI cloud backend (privacy-gated) | ⏳ pending | off by default |
| M14 | Faces (ML Kit) + polish + evaluation | ⏳ pending | |

## M2 outcome (done)
Persistence layer exists and is tested: photos + embeddings persist, embedding bytes
round-trip losslessly, the analyzer is clean, and **web still compiles** (native-only DB
via a conditional connection). The mock search path is untouched — swapping it is M7.
Delivered: `AppDatabase` (3 tables), conditional connection (native + web stub),
`PhotoRepository` with a little-endian float32 vector codec, `appDatabaseProvider` /
`photoRepositoryProvider`, and `test/database_test.dart` (5 tests). Verified: 6/6 tests, web build OK.

## M4.2 outcome (done) — ImageEmbedder + numerical parity GATE PASSED
`lib/ai/`: `OnnxImageEmbedder` (reused ORT session, error handling, logging, defensive L2) +
bit-faithful preprocessing. A **real Flutter ONNX Runtime** integration test (run on Linux desktop
via xvfb) reproduces the open_clip/fp32-ONNX reference at **cosine 1.000000** on all 6 probe images
(max-abs-err ≤ 1.3e-4), retrieval ranking 6/6 — all four acceptance criteria met. The gate uses the
fp32 model (the CPU EP cannot run fp16; fp16 is the on-device artifact).

## M4.3 outcome (done) — TextEmbedder + text parity GATE PASSED
CLIP BPE tokenizer in Dart (token ids match open_clip on 19 cases) + `OnnxTextEmbedder` on a shared
`OnnxEncoder` base. Real Flutter ORT text parity: **cosine 1.000000** on all 6 queries. Fixed an
onnxruntime-1.15 int64-ArgMax incompatibility in the text model (artifact_version→2, embeddings
identical, ADR-012) — a device-crashing bug the real gate caught.

## M4.4 outcome (done) — Golden Validation Suite PASSED
`integration_test/golden_validation_test.dart` validates the full image+text pipeline via real Flutter
ORT: **100% retrieval (6/6)**, cosine 1.0, all embeddings L2-normalized, Top-K ranking stable vs
reference, repeatable across runs, `reference_vectors.json` diagonal 6/6. Auto-writes `VALIDATION_REPORT.md`.
Regression guards: preprocessing fingerprint + 19-case tokenizer parity.

## M4.5 outcome (done) — Host benchmarks
Real Flutter ORT on the build host (x86/fp32): image embed **175 ms** mean, text **42 ms**; loads
588/961 ms; RSS **+612 MB** (both fp32); **6.1 img/s** → single-isolate 50k ≈ 2.4 h. Auto-writes
`BENCHMARK_REPORT.md`; full table in `BENCHMARK_RESULTS.md §8`. Device fp16/NNAPI numbers pending hardware.

## M4.6 outcome (done) — AI Core review APPROVED
Full audit in `docs/AI_CORE_REVIEW.md`: architecture, SOLID, lifecycle, session reuse, leaks, exceptions,
logging, thread safety, duplication, maintainability — all clean. No refactor required; TD-9 (getBytes
preprocessing) and run-in-isolate deferred to M5 with rationale. **M4 (AI Core) is complete.**

## M5 outcome (core done) — Indexing engine, all logic gates green
Ports-and-adapters pipeline (`lib/indexing/`): `IndexPlanner` (reconcile), `AssetProcessor`, `IndexStore`
(batch txn + checkpoints), `IndexingService` (scan→plan→index, cancel, resume, progress), `ModelVersionManager`.
DB schema v3. **16 tests** cover reconcile, full/incremental/200-stress, dedup/embed-once, deleted, changed,
model-version migration, cancel+resume, failure isolation. Diagrams + scalability in `INDEXING_ARCHITECTURE.md`; ADR-013.

## M5 device adapters (written, compile-verified) — runtime on-device
All six adapters + WorkManager isolate entrypoint + DI wiring are in `lib/indexing/adapters/` and compile
clean (web + linux builds unaffected): `PhotoManagerGallerySource`, `ExifMetadataExtractor`,
`FileThumbnailGenerator`, `MlKitImageEnricher`, `WorkManagerScheduler`, `OnnxAssetEmbedder`, plus
`buildDeviceIndexingService` + `indexCallbackDispatcher`. Only their **runtime** (Android + plugin native
side: reboot/backoff, ML Kit inference, MediaStore scale, latency/memory) is exercised on a device.

## M6 outcome (done) — Semantic search, real-ORT verified
Query → `OnnxTextEmbedder` (CLIP text) → cosine over stored image embeddings (`VectorIndex`, brute-force
now, ANN-swappable) → **hybrid re-rank** (`HybridScorer`: CLIP semantic ⊕ ML Kit labels/tags ⊕ face-intent)
→ ranked `Photo`s. The `SearchBackend` seam is now **async** (ADR-014); `KeywordSearchBackend` is the web /
model-not-ready fallback, and the semantic backend **degrades to lexical** on any model failure, so search
never breaks. UI renders an `AsyncValue` (spinner + "Semantic/Keyword" badge); queries are debounced.

**Verification (measured, real Flutter ORT on Linux, fp32):** `integration_test/semantic_search_test.dart`
embeds the 6 parity images, indexes them, and runs the real text queries through the **entire** M6 path:
**Top-1 retrieval 6/6 (100%)** with *no* lexical hints (pure CLIP); min correct-pair cosine 0.198 vs max
distractor 0.146; end-to-end **35 ms/query**; brute-force scan+rank **3.4 ms @1k, 8.1 ms @10k** vectors.
Plus **14 new unit tests** (`hybrid_scorer_test.dart`, `semantic_search_backend_test.dart`) covering fusion,
normalization, face-intent, min-cosine gating, browse, and keyword degradation. No fabricated results.

## Next milestone — M9 (Filters over the store)
Date / place / album / people facets layered on top of M6 results (and browse), sourced from the DB and the
M5 indexing metadata. Then M10 (timeline-from-DB), M11 (real map). See `ROADMAP.md`.

## Risks currently tracked
See `KNOWN_ISSUES.md`. No blocking risks open. M6 precision threshold is a measured, recall-favoring default;
principled tuning on a larger labeled set is deferred to M14 eval (tracked, not fabricated).
