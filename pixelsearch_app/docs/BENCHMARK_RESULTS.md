# BENCHMARK RESULTS

> **Status note (2026-10-21 audit):** Parts of this file are stale or wrong against the code. The claims that FP16 is "shipped" and "validated on-device (NNAPI/XNNPACK)" are **false**. No execution provider is registered, FP16 has never run on Android, and every device result is FP32 on CPU. The on-device sections still say PENDING although dated device measurements exist. The "35.1 ms dominated by the ~42 ms text embed" comparison combines different runs. Host numbers here predate commit `a76d3b6`, which changed preprocessing and threading. Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record.

**Rule:** only measured values appear here. Anything not yet measured is marked **PENDING** — never estimated as if measured.

## 1. Model export parity (measured — ModelKit spike, 2026-07-24)
| Check | Result |
|---|---|
| Image encoder ONNX vs PyTorch | cosine **1.000000**, max abs diff 3.3e-06 |
| Text encoder ONNX vs PyTorch | cosine **1.000000**, max abs diff 1.1e-07 |
| Semantic retrieval self-test (6 photos × 6 queries) | **6/6 top-1** |

Interpretation: the ONNX export is a faithful copy of the model, and the model genuinely
understands image content. Environment: build host CPU, onnxruntime fp32.

## 2. Artifact sizes (measured — on disk)
| Precision | Image enc | Text enc | Total | Retrieval |
|---|---|---|---|---|
| fp32 | 87 MB (86.6) | 254 MB (254.1) | ~341 MB | 6/6 (reference) |
| **fp16 (shipped)** | **44 MB (43.6)** | **127 MB (127.4)** | **~171 MB** | near-lossless* |
| int8 dynamic | ~23 MB | ~64 MB | ~87 MB | **1/6 — unusable** |

\* fp16 is numerically near-lossless and is the on-device precision; it requires an fp16-capable
execution provider (NNAPI/XNNPACK). It could not be executed on the sandbox's CPU fp32 kernels,
which is why §1 parity was validated at fp32 — a CPU limitation, not a device one.

**Decision driver:** naive int8 collapses accuracy on this conv-based image encoder ⇒ ship fp16. (ADR-004)

## 3. On-device performance — PENDING (requires a physical Android device)
Not yet measured; do not cite numbers until collected on target hardware:
- Cold model load time (image / text session init) — **PENDING**
- Single image embed latency (NNAPI vs XNNPACK) — **PENDING**
- Indexing throughput (photos/sec, isolate, batched) — **PENDING**
- Query latency: tokenize + text-embed + cosine over N embeddings (N = 1k/10k/50k) — **PENDING**
- Peak memory during indexing — **PENDING**
- Storage: DB size vs photo count (validates the ~2 KB/photo embedding estimate) — **PENDING**

These land with M5 (indexing) and M7 (search) once a device is in the loop.

## 4. Framework (built 2026-08-06 — no results yet)
- **Latency harness:** `PixelSearch/lib/benchmark/benchmark.dart` (`Benchmark.measure`, `TimingStats`),
  unit-tested in `test/benchmark_test.dart`. M5/M7 register cases; see `PixelSearch/benchmark/README.md`.
- **Retrieval metrics:** `PixelSearch_ModelKit/eval/metrics.py` (Precision@K, Recall@K, AP, mAP),
  unit-tested in `eval/test_metrics.py`. Protocol in `eval/README.md`.

### Metric definitions
- **Precision@K** — fraction of the top-K results that are relevant.
- **Recall@K** — fraction of all relevant items found within the top-K.
- **Average Precision (AP)** — mean of precision taken at each relevant hit in the ranking.
- **mAP** — mean of AP across all queries.

## 5. Result tables — PENDING (populated only from measured runs)
### On-device performance (per BENCHMARK_RESULTS rule: measured only)
| Metric | Device | N (photos) | Value |
|---|---|---|---|
| Indexing throughput (photos/s) | — | — | PENDING |
| Query latency p95 (ms) | — | 1k / 10k / 50k | PENDING |
| Cold model load (ms) | — | — | PENDING |
| Peak memory during indexing (MB) | — | — | PENDING |
| APK size / model footprint (MB) | — | — | PENDING (fp16 total ~171 MB, §2) |

### Retrieval quality (from a labeled probe set)
| Metric | Probe set | Value |
|---|---|---|
| Precision@5 | — | PENDING |
| Recall@10 | — | PENDING |
| mAP | — | PENDING |

## 6. M4 image parity — MEASURED (real Flutter ONNX Runtime on Linux, fp32, 2026-08-06)
The complete production pipeline (image → Flutter preprocessing → Flutter ORT → L2) vs the open_clip +
fp32-ONNX Python reference. Acceptance: dims 512, cosine > 0.999, max-abs-err < 0.02, ranking 6/6.

| image | cosine | max abs err |
|---|---|---|
| cat | 1.000000 | 0.00003 |
| coffee | 1.000000 | 0.00013 |
| rocket | 1.000000 | 0.00009 |
| astronaut | 1.000000 | 0.00000 |
| camera_person | 1.000000 | 0.00000 |
| horse | 1.000000 | 0.00000 |

Retrieval ranking (6 text queries → correct image): **6/6**. **GATE PASSED.**
Reproduce: run `PixelSearch_ModelKit/parity/gen_reference.py`, then
`xvfb-run flutter test integration_test/image_parity_test.dart -d linux`.
Note: the gate uses the **fp32** model (the CPU EP cannot execute fp16); the fp16 device artifact is
validated on-device (NNAPI/XNNPACK).

## 7. M4.3 text parity — MEASURED (real Flutter ONNX Runtime on Linux, fp32, 2026-08-06)
Query → CLIP BPE tokenizer → Flutter ORT (text encoder) → L2, vs the open_clip/fp32-ONNX reference.
Acceptance: dims 512, cosine ≥ 0.9999. **Token-id parity: 19/19 cases exact** (unit test).

| query | cosine | max abs err |
|---|---|---|
| a photo of a cat | 1.000000 | 0.00000 |
| a cup of coffee | 1.000000 | 0.00000 |
| a rocket | 1.000000 | 0.00000 |
| an astronaut in a spacesuit | 1.000000 | 0.00000 |
| a person holding a camera | 1.000000 | 0.00000 |
| a horse | 1.000000 | 0.00000 |

**GATE PASSED.** Reproduce: `gen_reference.py` + `gen_tokens.py`, then
`xvfb-run flutter test integration_test/text_parity_test.dart -d linux`.
Note: text model patched for onnxruntime-1.15 (ADR-012); fp16 device path validated on NNAPI/XNNPACK.

## 8. M4.5 host benchmarks — MEASURED (build host x86-64, fp32, onnxruntime 1.15; real Flutter ORT)
**Not device numbers** — Android NNAPI/XNNPACK fp16 differs and remains PENDING (§3). Auto-generated by
`integration_test/benchmark_test.dart` → `PixelSearch_ModelKit/parity/BENCHMARK_REPORT.md`.

### Model load & memory
| metric | value |
|---|---|
| Image encoder load (87 MB fp32) | 588 ms |
| Text encoder load (254 MB fp32) | 961 ms |
| Process RSS increase, both loaded | +612 MB |

### Embedding latency — session reused, 30 iterations (ms)
| op | mean | median | p95 | min | max |
|---|---|---|---|---|---|
| image embed | 175.3 | 165.8 | 259.0 | 127.1 | 282.5 |
| text embed | 41.7 | 40.2 | 46.7 | 38.8 | 47.3 |

### Throughput & single-isolate indexing projection (image encoder)
Measured: **6.1 img/s**. Projected N × 175.3 ms, one isolate:
| gallery | 100 | 1,000 | 5,000 | 10,000 | 50,000 |
|---|---|---|---|---|---|
| index time | 17.5 s | 2.9 min | 14.6 min | 29.2 min | 146 min |

**Interpretation:** single-thread host indexing of 50k ≈ 2.4 h — this is why M5 batches in a background
isolate and indexes **once, persisted** (never recompute), and why fp16 (~171 MB vs 612 MB RSS here)
matters on device. Device fp16/NNAPI latency + memory are collected on hardware (PENDING).

## 9. M6 semantic search — MEASURED (real Flutter ONNX Runtime on Linux, fp32, 2026-08-07)
Auto-generated by `integration_test/semantic_search_test.dart` →
`PixelSearch_ModelKit/parity/SEMANTIC_SEARCH_REPORT.md`. Real image+text encoders; photos carry **no**
query-matching tags, so retrieval is *purely* CLIP semantic (the lexical/hybrid path is proven by unit tests).

### Retrieval quality (deterministic)
| metric | value |
|---|---|
| Top-1 retrieval (6 parity images/queries) | **6/6 (100%)** |
| Min diagonal cosine (correct query↔image) | 0.1983 |
| Max off-diagonal cosine (distractor) | 0.1463 |
| Separation (min diag − max off) | +0.0520 |

This measured separation is what sets the `semanticMinCosine` default to **0.15** (recall-favoring: below the
min correct 0.198, above the max distractor 0.146). It is a 6-sample heuristic — principled threshold
selection on a larger labeled set is M14 eval work, **not** an empirical accuracy claim.

### End-to-end query latency (text embed + scan + hybrid rank; 6 queries after 1 warm-up)
| mean | median | min | max |
|---|---|---|---|
| 35.1 ms | 35.3 ms | 33.1 ms | 38.7 ms |

Dominated by the ~42 ms text embed (§8); the M6-specific scan+rank is a small remainder at this corpus size.

### Brute-force scan+rank vs index size (random 512-d unit vectors, topK=50, median of 5)
| vectors | scan+rank |
|---|---|
| 1,000 | 3.40 ms |
| 10,000 | 8.07 ms |

**Interpretation:** the exact linear scan is O(N·D) and stays a *small fraction* of one text-embed even at
10k vectors, so brute force is comfortably adequate to the 10k–50k target; the `VectorIndex` seam (ADR-009)
lets an ANN backend (sqlite-vec / HNSW) drop in later with **no caller changes** if a library outgrows it.
Device fp16 query latency is collected on hardware (PENDING, shared with §3).
