# MobileCLIP Spike — Results

**Goal:** before writing any Flutter, prove that real on-device semantic search works with MobileCLIP, and produce verified model assets. **Result: success.**

## What was proven

| Check | Result |
|---|---|
| MobileCLIP-S1 loads (open_clip, `datacompdr` weights) | ✅ 85M params, 512-d embeddings, 256×256 input |
| Real semantic retrieval (6 photos, 6 natural-language queries) | ✅ **6/6 top-1** (cat, coffee, rocket, astronaut, camera, horse all matched) |
| ONNX export == PyTorch (image encoder) | ✅ cosine **1.000000**, max diff 3.3e-06 |
| ONNX export == PyTorch (text encoder) | ✅ cosine **1.000000**, max diff 1.1e-07 |
| Reproducible one-command script (`prepare_model.py`) | ✅ runs end-to-end, re-verifies 6/6 |

So: the model understands image content, and our ONNX export is a faithful copy of it. The hardest unknown in the whole project is now de-risked.

## The model contract (what the Flutter side must match)

- **Image preprocessing:** RGB → resize to **256×256** (bilinear) → scale pixels to **[0,1]** → **no** mean/std normalization (mean 0, std 1) → CHW float tensor `[1,3,256,256]`.
- **Text:** standard **CLIP BPE tokenizer** (49,408 vocab), context length **77**, start-token **49406**, end-token **49407**, pad **0** → int64 tensor `[1,77]`.
- **Both encoders output L2-normalized 512-d vectors**, so similarity = a plain dot product.
- Reference similarity matrix saved in `reference_vectors.json` so the Dart implementation can be asserted against it.

## Size finding (a real deployment decision)

| Precision | Image enc | Text enc | Total | Accuracy |
|---|---|---|---|---|
| fp32 | 87 MB | 254 MB | 341 MB | 6/6 (reference) |
| **fp16 (recommended)** | **44 MB** | **127 MB** | **171 MB** | near-lossless* |
| int8 dynamic | 23 MB | 64 MB | 87 MB | ❌ **1/6 — unusable** |

\* fp16 is the standard on-device precision and is numerically near-lossless; it runs on Android via NNAPI/XNNPACK. (It can't run on this sandbox's onnxruntime **CPU** kernels, which is why accuracy was verified at fp32 — an expected CPU-only limitation, not a device one.)

**Takeaway:** naive int8 destroys accuracy on this conv-based image encoder, so we ship **fp16 (~171 MB)**. Because that's large, the model should be **provisioned to the device on first run** (downloaded, or pushed during development) rather than bundled inside the APK. If a smaller footprint becomes important, the levers are: **MobileCLIP2-S0** (smaller towers) or **static/QDQ int8 with calibration** (future work).

## Files produced (`out/`)
- `mobileclip_image_fp16.onnx`, `mobileclip_text_fp16.onnx` — ship to device
- `bpe_simple_vocab_16e6.txt.gz` — CLIP tokenizer vocab (bundle in app, ~1.4 MB)
- `preprocess_config.json` — the constants above
- `reference_vectors.json` — parity target for Dart tests
- `prepare_model.py` — regenerate everything in one command

## Next
Wire this into Flutter: (M2) SQLite/drift store for embeddings → (M4/M6) ONNX image+text services + the CLIP BPE tokenizer in Dart → (M7) cosine search that replaces the mock, with graceful fallback to keyword search when the model isn't present yet.
