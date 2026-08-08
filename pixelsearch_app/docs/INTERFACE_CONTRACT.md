# INTERFACE_CONTRACT.md — PixelSearch ↔ ModelKit

**Status:** FROZEN v1.1 · Model: MobileCLIP-S1 / `datacompdr`
**Owner:** ModelKit (source of truth). The Flutter repo carries a mirror at `PixelSearch/docs/INTERFACE_CONTRACT.md`; keep them identical.
**Change control:** any change to a value marked *frozen* requires explicit human approval, a version bump, and re-verification on both sides. v1.1 = documentation clarification only (resize semantics + antialias made explicit; versioning section added). **No frozen value changed from v1.0; reference vectors remain valid.**

## Why this file exists
ModelKit produces the model artifacts; the Flutter app consumes them. If the app's
preprocessing, tokenization, or tensor handling deviates from what the model was
exported with, embeddings diverge **silently** — no crash, just degraded search.
Per `CLAUDE.md`, any such mismatch is a **critical bug**. This is the exact, testable
spec both sides implement against.

## 0. Versions *(frozen — see §9 for the change/migration policy)*
| Version field | Current | Governs | Bump ⇒ |
|---|---|---|---|
| `model_version` | `1.0` | model architecture + weights (MobileCLIP-S1/datacompdr) | full re-index |
| `embedding_version` | `1` | the **stored image-embedding** pipeline = model + image preprocessing | full re-index |
| `artifact_version` | `2` | the physical exported files (ONNX + vocab), even if numerically identical | re-provision model, no re-index |
| `schema_version` | `2` | the on-device SQLite schema | DB migration, no re-index |

## 1. Model identity *(frozen)*
| Field | Value |
|---|---|
| Architecture | MobileCLIP-S1 |
| Weights (open_clip `pretrained`) | `datacompdr` |
| Embedding dimension | **512** |
| ONNX opset | **17**, legacy exporter (`dynamo=False`) |
| fp16 conversion | `keep_io_types=True` → **graph I/O stays float32**; only internal weights are fp16 |

> **fp16 remains the production artifact** (ADR-004). Note that the fp16 *image*
> export produced by the current `onnxconverter_common` build does not load —
> see KNOWN_ISSUES KI-9. Until ModelKit reissues it, the app's resolver falls
> back to the fp32 export, which is verified at cosine 1.000000 against this
> contract's reference. The contract itself is unchanged.

## 2. Artifacts
| File | Role | Size | Disposition |
|---|---|---|---|
| `mobileclip_image_fp16.onnx` | image encoder | ~44 MB | **production** — provisioned to device at runtime (not in APK) |
| `mobileclip_text_fp16.onnx` | text encoder | ~127 MB | **production** — provisioned to device at runtime |
| `mobileclip_image.onnx` | image encoder, fp32 | ~87 MB | development / CPU-testing fallback; accepted by the app's model resolver, never the production target |
| `mobileclip_text.onnx` | text encoder, fp32 | ~254 MB | development / CPU-testing fallback |
| `bpe_simple_vocab_16e6.txt.gz` | CLIP BPE vocab | ~1.4 MB | bundled in app |
| `preprocess_config.json` | constants + versions | <1 KB | bundled in app |
| `reference_vectors.json` | Dart parity target | ~1 KB | test asset |

## 3. Image encoder ONNX contract *(frozen)*
- **Input:** name `pixel_values` · dtype **float32** · shape **[B, 3, 256, 256]** · layout **CHW** · channel order **RGB** · batch axis dynamic (`b`).
- **Output:** name `image_embeds` · dtype **float32** · shape **[B, 512]** · **L2-normalized**.

### Image preprocessing — VERIFIED against open_clip (preflight 2026-08-06). Dart must match exactly:
1. Decode to **RGB** (drop alpha).
2. **Resize** so the **shorter** side = **256 px**, preserving aspect ratio, **bilinear** interpolation, **antialias = true**.
3. **Center-crop** the central **256 × 256** region.
4. Scale pixels **/255 → [0,1]**.
5. **No** mean/std normalization (Normalize mean `[0,0,0]`, std `[1,1,1]` — a no-op, confirmed).
6. Emit **CHW** float32, add batch dim → `[1,3,256,256]`.

> ✅ **KI-1 resolved.** The preflight (`preflight/PREFLIGHT_REPORT.json`) introspected the real
> `open_clip.create_model_and_transforms('MobileCLIP-S1','datacompdr')` transform:
> `Resize(256, bilinear, antialias) → CenterCrop(256) → toTensor([0,1]) → Normalize(0,1)`,
> `resize_mode='shortest'`. A probe on RGB(128,64,200) produced exactly (128,64,200)/255, confirming
> pure [0,1] scaling and RGB/CHW. The only Dart-side parity risk is that `antialias=true` bilinear must
> match torchvision closely; residual interpolation delta is bounded and checked numerically in §6.

## 4. Text encoder ONNX contract *(frozen)*
- **Input:** name `input_ids` · dtype **int64** · shape **[B, 77]** · batch axis dynamic.
- **Output:** name `text_embeds` · dtype **float32** · shape **[B, 512]** · **L2-normalized**.

### Tokenization — CLIP BPE (VERIFIED against open_clip `SimpleTokenizer`, preflight 2026-08-06):
- Vocab: `bpe_simple_vocab_16e6.txt.gz` (49,408 tokens).
- Lowercase, clean whitespace/HTML, byte-pair encode.
- Wrap: `[sot] … [eot]` with **sot = 49406**, **eot = 49407**.
- Context length **77**: if longer, truncate content to 75 tokens (keep sot/eot); else pad with **0** to length 77.
- Emit int64. (Reference: `"a photo of a cat"` → `[49406, 320, 1125, 539, 320, 2368, 49407, 0…]`.)

> **Runtime note:** the shipped text artifact inserts a `Cast(int64→int32)` before the internal ArgMax
> so it runs on onnxruntime 1.15 (the Flutter plugin's bundled runtime, on device and in CI). External
> I/O is unchanged (`input_ids` stays int64) and embeddings are identical. This was caught by the real
> Flutter-ORT text parity gate — a Python-only check misses it. See ADR-012.

## 5. Similarity *(frozen)*
Both encoders emit **L2-normalized** vectors ⇒ cosine similarity is a **plain dot product**.
Do **not** normalize a second time in the app.

## 6. Parity test — definition of "Dart matches the model"
Two levels, both runnable off-device except where noted:
1. **Tokenizer parity (in-sandbox):** Dart token ids == open_clip ids for a fixed sample set (see `PixelSearch/test/parity/`).
2. **Preprocessing parity (in-sandbox):** Dart input tensor ≈ Python reference tensor for fixed images, max-abs-diff within a documented tolerance (interpolation delta).
3. **Retrieval parity (`reference_vectors.json`):** for each query row *i*, `argmax` over images == *i* (diagonal → **6/6**). Absolute magnitudes are not the target; the argmax structure is.
4. **On-device golden (device only):** the Flutter ONNX Runtime session, given a reference input tensor, returns the reference embedding within ~1e-3. Provided as a bundled golden test; executed on a real device/desktop, since the Flutter ORT plugin does not run in `flutter test`.

## 7. Runtime notes for the consumer (Flutter)
- fp16 weights need a fp16-capable EP: **NNAPI / XNNPACK** on Android. Plain CPU fp32 kernels
  cannot run fp16 (numerical parity is therefore validated at **fp32** on the build host — a CPU limitation, not a device one).
- Load each session **once**; never reload per query (see `CLAUDE.md` performance rules).

## 8. Version history
- **v1.2** (2026-08-06) — text model patched with `Cast(int64→int32)` before the internal ArgMax for
  onnxruntime-1.15 compatibility (the Flutter plugin's runtime). **artifact_version → 2**; external I/O
  and embeddings unchanged (no re-index). CLIP BPE tokenizer implemented in Dart and verified id-exact
  against open_clip. No frozen value changed. See ADR-012.
- **v1.1** (2026-08-06) — resize semantics (shortest-side + center-crop) and `antialias` made explicit; §0 versioning + §9 migration added; KI-1 closed. No frozen value changed.
- **v1.0** — MobileCLIP-S1 / `datacompdr`. Verified: image cos 1.000000, text cos 1.000000 vs PyTorch; retrieval 6/6.

## 9. Versioning & migration policy
The four versions in §0 exist so the app can decide, deterministically, **when to regenerate what**.

### When must stored embeddings be regenerated?
Regenerate (full re-index of all image embeddings) **iff `embedding_version` changes**. `embedding_version`
is a pure function of: the model weights/architecture (`model_version`) **and** the image preprocessing
(steps in §3). Concretely, bump `embedding_version` — and re-index — when any of these change:
- model weights or architecture,
- image size, interpolation, resize/crop semantics, pixel scaling, normalization, or channel order.

Do **not** re-index for: a re-export that is numerically identical (bump `artifact_version` only),
a tokenizer change (affects only the **query/text** path, which is computed on the fly — no stored image
embedding is affected), a DB schema change (bump `schema_version`, run a migration), or a search-backend
swap (brute-force ↔ sqlite-vec) — embeddings are reused unchanged.

### How migrations work
- **Embeddings** are stored per `(photo_id, model_id)` and **tagged** with the `embedding_version` that
  produced the stored vector. On launch the indexer computes the "stale/missing" set as *photos whose
  stored row is absent or whose `embedding_version` ≠ current*; it re-embeds only those, overwriting in
  place. A version bump therefore makes every photo stale and triggers a full, resumable re-index; a
  partial change re-embeds only the gaps.
- **DB schema** migrations are handled by drift's `MigrationStrategy` keyed on `schema_version`
  (see `PixelSearch/docs/MIGRATIONS.md` for the runbook and the per-version steps).
- **Artifacts**: the model manager (M12) compares the on-device `artifact_version` to the contract and
  re-provisions the ONNX/vocab files when it differs; this never forces a re-index unless `embedding_version` also moved.
