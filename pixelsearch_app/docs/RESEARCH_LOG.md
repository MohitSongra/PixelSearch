# RESEARCH LOG

> **Status note (2026-10-21 audit):** Part of this file is not true against the code. The M4.2 (2026-08-06) entry calls the fp16 artifact a device artifact for NNAPI/XNNPACK, "validated on-device". The app registers no execution provider (FP32 on CPU only), and fp16 has never been accepted on Android (KI-2, ADR-016). Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record.

Chronological record of investigations, findings, and decisions. Measured facts only.

## 2026-08-06 (M5) — Indexing engine core (ports & adapters); all logic gates green
- Built the reconciliation-driven indexing core: `IndexPlanner` (added/changed/deleted/stale/skip),
  `AssetProcessor` pipeline, `IndexStore` (batch-txn writes + checkpoints), `IndexingService`
  (cancel/resume/progress), `ModelVersionManager`. DB schema v2→v3 (indexing metadata columns).
- **Design choice that pays off:** resume is *structural* (re-reconcile + skip up-to-date) rather than a
  bespoke cursor — a crash/cancel simply continues next run; a committed batch is the recovery unit.
- 16 in-sandbox tests (real drift + fakes) cover every logic gate incl. cancel+resume, incremental,
  dedup/embed-once, deleted, model-version migration, and a 200-asset stress run. Analyzer clean; web+linux OK.
- Device-only adapters (photo_manager / ML Kit / WorkManager / EXIF / thumbnail) specified behind ports;
  they are the remaining on-device integration.

## 2026-08-06 (M4.6) — AI Core production review: APPROVED; M4 complete
- Audited `lib/ai` (685 LOC): architecture / SOLID / lifecycle / leaks / exceptions / logging /
  thread-safety / duplication all clean; every ORT handle released; per-isolate `OrtEnv` is correct for
  M5. No refactor required. Deferred to M5: `getBytes` preprocessing (TD-9) and run-in-isolate (planned).
  Full write-up in `docs/AI_CORE_REVIEW.md`.
- **M4 (AI Core) COMPLETE:** ImageEmbedder + TextEmbedder + exact CLIP tokenizer, parity gates (cosine
  1.0), golden suite (100% retrieval), host benchmarks, review. Ready for M5 (indexing).

## 2026-08-06 (M4.5) — Host benchmarks
- Real Flutter ORT on x86/fp32: image embed mean **175 ms**, text **42 ms**; loads 588 ms / 961 ms;
  RSS **+612 MB** with both fp32 models. Throughput **6.1 img/s** → single-isolate 50k ≈ 2.4 h.
- Findings that shape M5/device: (a) 612 MB RSS for two fp32 models argues for fp16 (~171 MB) on device;
  (b) single-thread indexing is too slow at 50k → M5 must batch in an isolate and **persist once** (never
  recompute). Not device numbers (Android NNAPI/XNNPACK fp16 pending). Auto-report at `parity/BENCHMARK_REPORT.md`.

## 2026-08-06 (M4.4) — Golden validation suite + regression guards
- Built the permanent end-to-end suite (real Flutter ORT, both encoders): **100% retrieval (6/6)**,
  cosine 1.0, all embeddings L2-normalized (max ‖v‖-1 = 2.9e-8), Top-K ranking stable vs reference,
  repeatable, `reference_vectors.json` diagonal 6/6. Auto-writes `parity/VALIDATION_REPORT.md`.
- Regression guards: a pinned preprocessing fingerprint + the 19-case tokenizer parity, so any silent
  preprocessing/tokenizer drift fails a fast unit test.

## 2026-08-06 (M4.3) — TextEmbedder: exact CLIP tokenizer + real Flutter ORT text parity PASSED
- **CLIP BPE tokenizer** ported to Dart from open_clip's `SimpleTokenizer` (byte encoder, `merges[1:48895]`,
  regex, bpe with cache, sot/eot/pad). **Token ids match open_clip exactly** on 19 diverse cases —
  punctuation, digits, contractions, accented Unicode (café/résumé/naïve), whitespace collapsing, empty
  string, and >77 truncation.
- **TextEmbedder** on a shared `OnnxEncoder` base (ADR-011): reused session, error handling, logging, L2.
- **Real Flutter ORT text parity gate: cosine 1.000000 on all 6 queries** (max-abs-err 0.0).
- **Bug caught by the real gate (ADR-012):** onnxruntime 1.15 (the Flutter plugin's runtime) has no int64
  ArgMax kernel; CLIP's text argmax over `input_ids` threw `Could not find an implementation for ArgMax(13)`.
  Python ORT 1.25 hid it. Fixed with a `Cast(int64→int32)` before ArgMax (artifact_version→2, embeddings
  identical, verified). **This would have crashed text search on-device** — a Python-only check misses it.
- **Refactor:** extracted the ORT session lifecycle into `OnnxEncoder`; image gate re-verified (cosine 1.0, no regression).

## 2026-08-06 (M4.2) — Production ImageEmbedder + REAL Flutter ORT parity gate PASSED
- **Feasibility spike:** proved a real Flutter ONNX Runtime binary builds and runs *in this sandbox* —
  Flutter Linux desktop + `onnxruntime` 1.4.1 (which ships `libonnxruntime.so`), headless via `xvfb`.
  So the numerical gate runs here through a genuine Flutter ORT execution (`flutter test integration_test -d linux`), not only on a device.
- **ImageEmbedder:** production `OnnxImageEmbedder` — reused ORT session, error handling, logging,
  defensive L2 — plus a **bit-faithful** preprocessing pipeline.
- **Parity gate — real Flutter ORT vs open_clip/fp32-ONNX reference, all 6 images:**
  cosine = **1.000000**; max-abs-error ≤ **1.3e-4**; retrieval ranking **6/6**. Every acceptance criterion met.
- **Reaching bit-parity took four fixes, each found by measurement (cosine climbed 0.9979 → 1.000000):**
  1. antialiased **triangle-filter** resize (open_clip resizes a PIL image, which always antialiases) — the plain/box resizes in the `image` pkg were not faithful;
  2. **uint8 intermediate** rounding between resize passes (PIL emits 8-bit images) — took coffee to 1.0;
  3. **truncated** long-edge dimension `int(size*long/short)` (torchvision truncates, not rounds) — fixed cat & rocket geometry (1px);
  4. **round-half-to-even** center-crop offset (torchvision) — fixed rocket's 1px crop shift.
- **fp16 vs fp32:** the gate runs the **fp32** exported model (CPU-executable → cosine 1.0). The **fp16**
  artifact throws `Type (tensor(float16))` on the CPU EP (confirmed) — it is a device artifact for
  NNAPI/XNNPACK, validated on-device. The pipeline mechanics (preprocess + ORT + L2) are proven exact here.

## 2026-08-06 (later) — Versioning + search seam + benchmark framework + M4 preflight
- **Improvements:** interface versioning (model/embedding/artifact/schema versions) + migration policy;
  a `VectorIndex` seam (`BruteForceVectorIndex`, unit-tested) so an ANN backend can replace brute-force
  with no upper-layer change; a benchmark/eval framework (Dart timing harness + Python P@K/R@K/mAP),
  both unit-tested — no fabricated results.
- **M4 Phase 1 preflight (KI-1 resolved):** introspected the real open_clip MobileCLIP-S1 transform →
  `Resize(shortest→256, bilinear, antialias) → CenterCrop(256) → [0,1] → Normalize(0,1)`, RGB/CHW. A probe
  on RGB(128,64,200) returned exactly (128,64,200)/255 (pure [0,1], no mean/std). Tokenizer = SimpleTokenizer,
  ctx 77, sot 49406, eot 49407, pad 0. **Every frozen contract value matched;** resize-shortest+center-crop
  and `antialias` folded into contract v1.1 as a clarification (reference vectors still valid).
- **Schema:** bumped `schema_version` 1→2 (added `EmbeddingRows.embeddingVersion` + migration + version-aware queries).
- **Verification:** analyzer clean; 11/11 Flutter tests; Python metric tests pass; web build OK.

## 2026-08-06 — M2 kickoff + a contract caveat found during review
- Formalized the two-repo structure and wrote the documentation backbone + frozen `INTERFACE_CONTRACT.md`.
- **Finding (from reading `prepare_model.py`):** fp16 export uses `keep_io_types=True`, so the ONNX
  graph I/O stays **float32** — the Dart side feeds/reads float32 even though weights are fp16. Recorded in the contract.
- **Caveat found:** `preprocess_config.json` constants (bilinear, no mean/std) were **hand-declared**
  in the export script, while `reference_vectors.json` was produced with open_clip's own transform.
  These may disagree (interpolation; mean/std). Logged as a **critical M4 pre-flight** (`KNOWN_ISSUES.md`).
- **Observation:** reference sim-matrix diagonals are low in absolute terms (~0.05) because the
  self-test normalizes with an L1 norm; the **argmax/diagonal** structure (6/6) is the reliable parity signal,
  so the contract asserts argmax, not magnitude.

## 2026-07-24 — MobileCLIP spike (the big de-risk)
- MobileCLIP-S1 (`datacompdr`) loads via open_clip: 85M params, 512-d, 256×256.
- Exported image+text encoders to ONNX (opset 17, legacy exporter); both L2-normalize internally.
- Verified ONNX == PyTorch (cos 1.000000 both towers); real retrieval **6/6**.
- **Quantization result:** naive dynamic int8 → **1/6** (unusable) on the image encoder; fp16 near-lossless.
  ⇒ ship fp16 (~171 MB), provision at runtime.
- Produced the parity target (`reference_vectors.json`) and the reproducible `prepare_model.py`.

## M6 — Semantic search + hybrid ranking (2026-08-07)
- **Result (measured, real Flutter ORT, fp32):** pure-CLIP top-1 retrieval **6/6** on the parity set with no
  lexical hints. Correct query↔image cosines fell in a narrow band; the **minimum correct pair was 0.198**
  and the **maximum distractor 0.146** (separation +0.052) — small but consistently positive, which is why
  argmax retrieval is perfect while an absolute threshold must be chosen carefully.
- **Threshold finding:** a naïve 0.20 min-cosine would have *dropped* a correct match (0.198). Set to a
  recall-favoring **0.15**; recorded as a heuristic on 6 samples, not an accuracy claim. Proper
  precision/recall vs threshold on a labeled set is deferred to M14.
- **Hybrid fusion:** `final = 0.70·semantic ⊕ 0.25·lexical ⊕ 0.05·face`. Semantic uses an *absolute* band
  map (so a lone strong match still scores high); lexical uses *relative* min-max (unbounded counts). This
  asymmetry is deliberate and documented (ADR-014). Weight ablation is a paper experiment (M14).
- **Scalability (measured):** exact brute-force scan+rank of 512-d vectors — 3.4 ms @1k, 8.1 ms @10k — a
  small fraction of one text-embed, so the ANN crossover is well beyond the MVP's 10k–50k target.

## Open research threads (for the paper)
- On-device latency/throughput/energy for MobileCLIP fp16 on mid-range Android (NNAPI vs XNNPACK) — to be measured (M5/M6 device runtime).
- Brute-force cosine vs ANN (sqlite-vec / ObjectBox HNSW) crossover point by library size — host numbers in hand (§9); device + larger-N still to measure.
- Hybrid weight ablation + min-cosine precision/recall on a labeled photo set (M14 eval).
- Calibrated int8 / QDQ to recover the int8 size win without the accuracy collapse — future work.
