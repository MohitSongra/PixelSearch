# AI CORE — Production Review (M4.6)

**Scope:** `lib/ai/` (7 files, 685 LOC) — `onnx_encoder`, `image_embedder`, `text_embedder`,
`clip_tokenizer`, `image_preprocess`, `embedding_math`, `ai_logger` — plus `core/ai_contract.dart`.
**Verdict: APPROVED — production-ready.** No critical issues, no functional regressions. Two minor
items deferred to M5 with rationale below.

## Review checklist
| Area | Status | Notes |
|---|---|---|
| Architecture | ✅ | Feature-cohesive AI layer; depends only on `core/ai_contract` + packages, never upward on features/state/UI. |
| SOLID — SRP | ✅ | `OnnxEncoder` owns the ORT session lifecycle; embedders build tensors; tokenizer tokenizes; `image_preprocess`/`embedding_math` are pure. |
| SOLID — OCP/LSP | ✅ | New encoders extend `OnnxEncoder` without modifying it; `OnnxImageEmbedder`/`OnnxTextEmbedder` substitute their interfaces cleanly. |
| SOLID — ISP/DIP | ✅ | Small `ImageEmbedder`/`TextEmbedder` interfaces; tokenizer injected into the text embedder (constructor DI). |
| Dependency graph | ✅ | No cycles. `embedding_math` pure; `image_preprocess` depends only on `image`. `clip_tokenizer` uses `flutter/services` only for the optional `fromAsset` loader (pure `fromVocabText` path is Flutter-free). |
| Resource lifecycle | ✅ | Session + options created once in `load()`; per-call input/run-options/outputs released in a `finally`. Create/release audited: all matched. |
| ONNX session reuse | ✅ | Session created once, reused for every embed (the base's core purpose); verified by the benchmark (load once, then 175 ms/embed). |
| Memory leaks | ✅ | Every ORT handle released; `OrtEnv` intentionally left initialized (per-isolate singleton — releasing it would break other sessions). |
| Exception handling | ✅ | Typed `OnnxEncoderException`; `load()` disposes + rethrows on failure; `runEmbedding()` wraps non-typed errors; missing model → clear message. |
| Logging | ✅ | `AiLog` via `dart:developer` at load (info) and failures (error). No stray `print`. |
| Thread safety | ✅ | Dart statics are per-isolate, so each isolate has its own `OrtEnv` + session; `session.run` is a blocking FFI call, so calls within an isolate serialize. M5 runs indexing in a dedicated isolate. |
| Documentation | ✅ | Every file documented; decisions in ADR-010/011/012; contract mirrored. |
| Code duplication | ✅ | Eliminated via `OnnxEncoder` (ADR-011). Remaining duplication is test-only helpers (`_vec`/`_identical`). |
| Maintainability | ✅ | Small, single-purpose, unit-tested files; bit-faithful preprocessing pinned by a regression fingerprint. |

## Findings & disposition
1. **(Perf — deferred to M5)** `image_preprocess` extracts pixels via `image.getPixel` per pixel
   (TD-9). At 175 ms/image the extraction is a meaningful share. Switch to a raw `getBytes` RGB buffer
   in M5, where indexing throughput matters; values are bit-identical, so parity + the fingerprint hold.
2. **(Operational note)** `session.run` blocks its isolate. M5 must run the embedder in a background
   isolate (already the plan) so the UI thread stays responsive. Documented; no code change now.
3. **(Low)** Test-only helper duplication (`_vec`, `_identical`, cosine) across parity tests — could be a
   shared `test/support/` helper. Non-shipping; left as-is.

## Metrics
- LOC: 685 (AI layer). Tests: 16 unit + 4 integration suites (image parity, text parity, golden, benchmark).
- Parity: image cosine 1.000000, text cosine 1.000000, retrieval 100% (6/6), tokenizer 19/19 exact.
- Analyzer: 0 issues. Regression guards: preprocessing fingerprint + tokenizer parity.

## Sign-off
The AI core meets the engineering bar for a production MVP and a research write-up. Cleared to proceed to
**M5 (Indexing Engine)**. No refactor was required at this milestone; the two deferred items are tracked.
