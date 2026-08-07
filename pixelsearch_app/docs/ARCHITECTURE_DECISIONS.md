# ARCHITECTURE DECISIONS (ADR log)

Format: each record is a decision, its context, and its consequences. Newest first.

## ADR-014 — Semantic search: async SearchBackend + hybrid re-ranking (M6)
**Context:** M6 makes search real — query text must be CLIP-embedded (ONNX) and scored against stored image
embeddings. Two frictions with the existing seam: (1) `SearchBackend.search` was **synchronous**, but text
embedding is a `Future`; (2) pure cosine ignores the rich signals the M5 indexer already stored (ML Kit
labels, faces) and the metadata users think in (tags, place, album).
**Decision:**
- Make `SearchBackend.search` **async** (`Future<List<Photo>>`). `KeywordSearchBackend` returns an
  already-complete future; `SemanticSearchBackend` awaits the encoder. The sync signature was a M2-era
  oversight — the seam was always meant to receive semantic search (ADR-009); this is a signature evolution,
  not a redesign (one existing implementor, updated trivially).
- Introduce a pure **`HybridScorer`** (domain policy, no ONNX/IO): `final = wSem·semantic ⊕ wLex·lexical ⊕
  wFace·face`. Semantic strength maps the cosine against a fixed reference band (absolute); lexical is
  min-max normalized across candidates (unbounded counts); face-intent boosts people/portrait queries by
  detected face count. Weights default 0.70 / 0.25 / 0.05, tunable and recorded (not fabricated).
- The `VectorIndex` stays the ANN-swap seam (ADR-009); `SemanticSearchBackend` **degrades to lexical** if the
  model can't load/embed, and web has no ONNX so it uses `KeywordSearchBackend` outright — search never fails.
- Enrich the domain `Photo` with read-only `labels`/`faceCount` (surfaced from the M5 DB columns) so the
  scorer is a pure function of `Photo` + raw signals, fully unit-testable.
**Consequences:** the whole M6 path is testable in-sandbox (14 unit tests with fakes) and was validated on a
**real Flutter ORT** at 6/6 retrieval. The min-cosine precision floor is a *measured*, recall-favoring
default (0.15, below the min observed correct-pair cosine 0.198, above the max distractor 0.146); principled
tuning is deferred to the M14 labeled eval. Async search means the UI renders an `AsyncValue` (spinner/badge)
— a deliberate, honest UX cost of running a real model. See `BENCHMARK_RESULTS.md §M6`.

## ADR-013 — Indexing engine: ports & adapters, reconcile-based resume, batch transactions (M5)
**Context:** the engine must scale to 50k photos, survive interruption/crash/reboot, index incrementally,
and integrate device-only plugins (photo_manager, ML Kit, WorkManager) — while staying testable.
**Decision:** hexagonal architecture. A pure core (`IndexingService` + `IndexPlanner` + `AssetProcessor` +
`IndexStore` + `ModelVersionManager`) depends only on ports (`GallerySource`, `MetadataExtractor`,
`ThumbnailGenerator`, `AssetEmbedder`, `ImageEnricher`, `BackgroundScheduler`). **Resume is structural**:
`run()` re-reconciles and skips up-to-date assets, so committed batches are the recovery unit — no bespoke
resume cursor to corrupt. Writes are **batched in one transaction** (never per-image). Embeddings persist
once, keyed by (photo, model) + tagged `embedding_version` for migrations.
**Consequences:** the entire orchestration + correctness logic is unit-tested in-sandbox with fakes (11
gates incl. cancel/resume/incremental/dedup/deleted/version/stress); device adapters are thin, swappable,
and the only on-device piece. The rest of PixelSearch depends only on the stable core + ports. See
`docs/INDEXING_ARCHITECTURE.md`.

## ADR-012 — Text ArgMax int32 cast for onnxruntime-1.15 compatibility (M4.3)
**Context:** CLIP's text encoder selects the EOT token via argmax over `input_ids` (int64). The Flutter
plugin bundles onnxruntime **1.15**, which has no int64 ArgMax CPU kernel — the real Flutter-ORT text
gate threw `Could not find an implementation for ArgMax(13)`. Python ORT (1.25) ran it, so a Python-only
check would have missed a bug that also **crashes on-device** (the same runtime ships there).
**Decision:** patch the exported text models (fp32 + fp16) to insert a `Cast(int64→int32)` before each
ArgMax. External I/O stays int64; argmax indices — and embeddings — are identical (ids ≪ 2³¹). Bump
`artifact_version` 1→2 (no `embedding_version` change, no re-index). Folded into `prepare_model.py` (§5b)
for reproducibility; standalone `patch_text_argmax.py` also provided.
**Consequences:** the shipped text model runs on the target runtime. Verified: patched model reproduces
the reference at cosine 1.0; the Flutter text gate passes at **cosine 1.000000**. The alternative
(int32 model input) was rejected — it would change the frozen contract dtype.

## ADR-011 — Shared `OnnxEncoder` base for the CLIP encoders (M4.3)
**Context:** the image and text embedders share the whole ORT session lifecycle — load once, reuse the
session, run one input tensor to an L2-normalized 512-d vector, release. Duplicating it invites drift.
**Decision:** extract an abstract `OnnxEncoder` (single responsibility) owning load/dispose/session-reuse
and the extraction + L2; `OnnxImageEmbedder` and `OnnxTextEmbedder` only build their own input tensor.
**Consequences:** one place for the ORT lifecycle; the image parity gate was re-verified after the
refactor (cosine 1.0, no regression). Each concrete embedder stays small and testable.

## ADR-010 — Bit-faithful image preprocessing to guarantee ONNX parity (M4)
**Context:** the M4 gate requires cosine > 0.999 between the Flutter and Python embeddings. The `image`
package's built-in resizes (linear/box) diverged (coffee bottomed at 0.9979).
**Decision:** implement preprocessing bit-faithful to open_clip's PIL/torchvision transform — a
separable **antialiased triangle-filter** resize with **uint8 intermediates**, `int(size*long/short)`
resize dims (truncation), and **round-half-to-even** center-crop offset.
**Consequences:** cosine = **1.000000** across all 6 probe images (max-abs-err ≤ 1.3e-4). The resampler
is pure and unit-tested, independent of ONNX. Per-pixel extraction via `image.getPixel` is not the
fastest path (TD-9); M4.5 profiling optimizes it with a direct byte buffer. This is why the app depends
on the exact model contract, not an approximation.

## ADR-009 — Search behind a `VectorIndex` seam (brute-force now, ANN later)
**Context:** exact brute-force cosine is fine to ~50k photos, but a larger library will want an ANN
backend (sqlite-vec / ObjectBox HNSW). We must be able to swap that in without touching upper layers.
**Decision:** define a `VectorIndex` interface (`upsert` / `remove` / `query topK`) with an in-memory
`BruteForceVectorIndex` implementation now (unit-tested). The M7 semantic-search service will depend
only on the interface, so a `SqliteVecVectorIndex` can replace it later with zero caller changes.
Separately, an app-level `SearchBackend` seam (keyword today → semantic at M7) keeps the search
provider and UI stable across that transition.
**Consequences:** the ANN swap the brief called out is fully insulated (interface + tests). The
keyword→semantic transition will introduce async at the provider once (planned, at M7); the
brute-force→sqlite-vec swap introduces nothing. No vector search is wired into the app yet — that is
M7, gated on the M4 numerical-validation pass.

## ADR-008 — Store embeddings as little-endian float32 BLOBs (M2)
**Context:** cosine search needs float32 in memory; SQLite has no vector type.
**Decision:** persist each 512-d vector as a 2048-byte little-endian float32 BLOB in `EmbeddingRows`.
**Consequences:** simple, lossless, fast to `memcpy` into a `Float32List`. Costs ~2 KB/photo
(~100 MB at 50k). fp16-blob halving is deferred (see `TECHNICAL_DEBT.md`). A brute-force cosine
scan is fine to ~50k; an ANN index (sqlite-vec / ObjectBox HNSW) is a later optimization, not MVP.

## ADR-007 — drift for local persistence, native-only via conditional connection (M2)
**Context:** need a typed, testable store; must not break the web build used for sandbox verification.
**Decision:** use `drift` (+ `sqlite3_flutter_libs`) with a conditional connection — native on
mobile/desktop, an `unsupported` stub on web — mirroring the existing device-gallery pattern.
**Consequences:** type-safe queries + migrations + in-memory tests on the host; web compiles but
has no DB backend for now (acceptable: Android-first, web is a verification/demo target). Adds a
build_runner codegen step (generated file committed).

## ADR-006 — Two separate repositories, ModelKit is source of truth
**Context:** model tooling (Python) and app (Flutter) have different lifecycles and languages.
**Decision:** keep **PixelSearch** (Flutter) and **PixelSearch ModelKit** (Python) separate; Flutter
consumes ModelKit artifacts and never redefines the contract.
**Consequences:** clean ownership; the contract lives in `INTERFACE_CONTRACT.md` (owned by ModelKit,
mirrored to Flutter). Any Flutter/ModelKit mismatch is treated as a critical bug.

## ADR-005 — Provision the model at runtime, don't bundle it in the APK
**Context:** fp16 encoders total ~171 MB.
**Decision:** ship the app without the models; provision them on first run; run in keyword-fallback until present.
**Consequences:** small install; the app is always usable; needs a model-manager UI (M12) and integrity checks.

## ADR-004 — Ship fp16, not int8
**Context:** measured — naive dynamic int8 dropped retrieval to 1/6 (unusable) on the conv-based image encoder;
fp16 is near-lossless.
**Decision:** ship fp16 (~171 MB). Smaller footprint later via MobileCLIP2-S0 or calibrated/QDQ int8.
**Consequences:** fp16 needs NNAPI/XNNPACK (not plain CPU fp32 kernels). See `BENCHMARK_RESULTS.md`.

## ADR-003 — MobileCLIP-S1 / datacompdr as the embedding model
**Context:** need strong image-text retrieval that fits a phone; verified in the spike.
**Decision:** MobileCLIP-S1, 512-d, 256×256 input. Export via legacy ONNX exporter, opset 17.
**Consequences:** frozen in `INTERFACE_CONTRACT.md`; parity verified (cos 1.000000, 6/6 retrieval).

## ADR-002 — Riverpod for state + manual DI
**Context:** need testable, override-able wiring without a heavy DI framework.
**Decision:** Riverpod providers as the composition root; inject repositories via provider overrides in tests.
**Consequences:** simple, idiomatic, no extra DI dependency.

## ADR-001 — Mobile-first pivot (from desktop/web), privacy-first preserved
**Context:** the original PixelSearch was desktop/web; the product thesis is on-device privacy.
**Decision:** pivot to a Flutter mobile app, Android-first, everything on-device by default.
**Consequences:** all subsequent architecture (on-device CLIP, local store, optional cloud) follows from this.
