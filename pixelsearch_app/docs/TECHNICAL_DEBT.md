# TECHNICAL DEBT

Tracked, intentional shortcuts. Each has a trigger for when it must be paid down.

| # | Debt | Why it's OK for now | Pay down when |
|---|------|---------------------|---------------|
| TD-1 | Search is a keyword **mock** (`search_engine.dart`) | lets the UI demo end-to-end pre-AI | M7 (real cosine search) |
| TD-2 | Embeddings stored as **float32** blobs (~2 KB/photo) | simple, lossless, fast to load | if DB size hurts at 50k → fp16 blobs (halves it) |
| TD-3 | Brute-force cosine scan (planned M7), no ANN index | fine to ~50k photos | if query latency exceeds budget → sqlite-vec / ObjectBox HNSW |
| TD-4 | **Web has no DB backend** (native-only drift connection) | Android-first; web is a verification/demo target | if web becomes a real target → drift-wasm worker |
| TD-5 | Sample photos are **hardcoded** in `sample_data.dart` | deterministic demo | when device indexing is the default path (post-M5) |
| TD-6 | Thumbnails re-decoded on demand (not cached to disk) | avoids storing large blobs for 50k photos | if scroll perf needs it → bounded thumbnail cache |
| TD-7 | Manual DI via Riverpod (no formal DI container) | idiomatic, testable, light | only if wiring complexity grows materially |
| TD-8 | preprocessing constants hand-declared, unverified — **RESOLVED 2026-08-06** | verified vs open_clip in the M4 preflight (contract v1.1) | done |
| TD-9 | image preprocessing extracts pixels via `image.getPixel` (per-pixel object alloc) | fine for the gate (6 imgs) | M4.5 profiling — switch to a direct `getBytes` buffer for indexing throughput |
| TD-10 | CLIP tokenizer `basic_clean` approximates ftfy as identity + minimal HTML unescape | verified exact on 19 cases incl. accented Unicode; real queries don't need ftfy | add an ftfy-equivalent only if a real query ever mismatches |
| TD-11 | M5 device adapters written + compile-verified but **not runtime-tested** (needs Android + plugin native side) | core is fully tested; adapters are thin port impls that compile clean | run on a device: WorkManager reboot/backoff, ML Kit inference, MediaStore scale, latency/memory |
| TD-12 | M6 `searchBackendProvider` rebuilds when `indexWarmupProvider` lands (loading→data), rebuilding the `SemanticSearchBackend` (embedder + tokenizer re-created via the conditional-import factory) | at most one transition; the ORT session is lazy, so no model reload unless a search was already in flight, and the old session is reclaimed at process exit | if it ever matters: cache the tokenizer + expose `SearchBackend.dispose()` to release the prior embedder |
| TD-13 | M6 in-memory `VectorIndex` isn't incrementally updated when the M5 indexer writes new embeddings mid-session (KI-6) | indexing/searching are usually separate sessions; warm-up covers session start | subscribe the index to the indexer's progress/commit stream and `upsert` deltas |
| TD-14 | M6 `semanticMinCosine` (0.15) + hybrid weights (0.70/0.25/0.05) are measured/heuristic defaults, not tuned on a labeled set (KI-5) | measured on the 6-image parity set; ranking (argmax) is unaffected | M14: precision/recall + weight ablation on a labeled photo corpus |

None of these block current work. TD-8/KI-1 (preprocessing verification) was resolved in the M4 preflight.
