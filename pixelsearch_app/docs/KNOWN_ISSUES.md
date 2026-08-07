# KNOWN ISSUES

Ranked by severity. "Critical" = must be resolved before the dependent milestone is trusted.

## KI-1 (RESOLVED 2026-08-06) — preprocessing constants verified against open_clip
The M4 preflight (`PixelSearch_ModelKit/preflight/`) introspected the real
`open_clip.create_model_and_transforms('MobileCLIP-S1','datacompdr')` transform:
`Resize(shortest→256, bilinear, antialias) → CenterCrop(256) → toTensor([0,1]) → Normalize(0,1)`, RGB/CHW.
A probe on RGB(128,64,200) returned exactly (128,64,200)/255 — pure [0,1] scaling, no mean/std.
**Every frozen contract value matched.** The contract (v1.1) now states the resize/crop semantics and
`antialias=true` explicitly (a clarification; no frozen value changed, reference vectors still valid).
Residual (low) risk: Dart bilinear+antialias must match torchvision closely — bounded and checked by
the §6 preprocessing-parity test in Phase 3.

## KI-2 (Info, by design) — fp16 models don't run on plain CPU
fp16 encoders require an fp16-capable EP (NNAPI/XNNPACK). On a CPU-only fp32 runtime they won't
execute; that's why spike parity was validated at fp32. Not a bug; a device/EP requirement to honor in M4.

## KI-3 (Low, by design) — web build has no database backend
The M2 drift connection is native-only; on web the DB resolves to an `unsupported` stub. Web still
**compiles** (our sandbox verification path) but cannot persist. Acceptable while Android-first;
revisit with drift-wasm if web becomes a real target (TD-4).

## KI-4 (Low, informational) — reference sim-matrix magnitudes are small
Diagonal similarities in `reference_vectors.json` are ~0.05 due to the self-test's L1 normalization.
Retrieval is still correct (6/6 by argmax). Parity assertions must use **argmax/diagonal**, not absolute magnitude.

## KI-5 (Low, by design) — M6 semantic min-cosine is a small-sample heuristic
`SemanticSearchBackend.semanticMinCosine` defaults to 0.15, chosen from the 6-image parity set (min correct
0.198, max distractor 0.146). It favors recall and is **not** a validated operating point. On a real, diverse
library it may admit weak matches or (less likely) drop borderline ones. Principled precision/recall tuning
is M14 eval work. Mitigation today: it only gates the *semantic* candidate set; lexical hits are unaffected,
and ranking (argmax) is unchanged.

## KI-6 (Low, by design) — index warm-up is one-shot; not auto-refreshed mid-session
`indexWarmupProvider` loads embeddings from the DB into the in-memory `VectorIndex` once. If the M5 indexer
adds embeddings later in the same session, the index won't reflect them until it is invalidated/rebuilt.
Acceptable for MVP (indexing and searching are typically distinct sessions); wiring an incremental
index-update hook off the indexer's progress stream is a small follow-up (tracked in TECHNICAL_DEBT TD-13).
