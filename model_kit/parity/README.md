# M4 parity gate (ModelKit ↔ Flutter)

Proves the Flutter production pipeline reproduces the ModelKit reference numerically, through a
**real Flutter ONNX Runtime execution**.

## Files
- `gen_reference.py` — canonical reference: saves the 6 probe PNGs + open_clip/fp32-ONNX **image** and
  **text** embeddings to `reference_embeddings.json`.
- `images/` — the exact PNGs the Flutter gate loads.
- Flutter gate: `PixelSearch/integration_test/image_parity_test.dart`.

## Run
```bash
cd PixelSearch_ModelKit/parity && python3 gen_reference.py
cd ../../PixelSearch && xvfb-run -a flutter test integration_test/image_parity_test.dart -d linux
```

## Acceptance criteria
dims = 512 · cosine > 0.999 · max-abs-err < 0.02 · retrieval ranking 6/6.
Current result: **cosine 1.000000 on all 6 images**, max-abs-err ≤ 1.3e-4, ranking 6/6 → see
`PixelSearch/docs/BENCHMARK_RESULTS.md` §6.

## Notes
- The gate runs the **fp32** model — the CPU execution provider cannot run fp16
  (`Type (tensor(float16))`). The fp16 artifact is for on-device NNAPI/XNNPACK and is validated on-device.
- Flutter preprocessing is **bit-faithful** to open_clip (antialiased triangle-filter resize, uint8
  intermediates, `int(size*long/short)` dims, round-half-to-even crop). See `docs/RESEARCH_LOG.md`.
