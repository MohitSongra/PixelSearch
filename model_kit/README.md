# PixelSearch — MobileCLIP Model Kit

Export and verification tooling for PixelSearch's semantic-search model, MobileCLIP-S1 (see SPIKE_REPORT.md).
On Android only the **FP32 CPU** configuration has been accepted on a device (Vivo I2214, from 2026-09-08;
measurements in `../docs/EVIDENCE_LEDGER.md`). The FP16 files have never run on Android; do not provision them.

## Generate the model files
```
pip install -r requirements.txt
python prepare_model.py
```
This writes the FP32 exports `out/mobileclip_image.onnx` and `out/mobileclip_text.onnx` and the FP16 files
`out/mobileclip_image_fp16.onnx` and `out/mobileclip_text_fp16.onnx` (~171 MB together), then re-runs the 6/6
retrieval self-test (host, prints cosines only). The FP16 conversion uses ONNX Runtime's converter, performs a
topological sort, and validates every Cast output type before replacing an artifact.

To repair only existing FP16 artifacts from the preserved FP32 exports without downloading or exporting the
model again, run:
```
python repair_fp16_exports.py
```

The desktop custom-image tester intentionally uses the FP32 artifacts with the CPU provider. FP16 was planned as
the Android NNAPI/XNNPACK artifact, but the app registers no such execution provider and FP16 has never been
validated on a device.

## Files here
- `prepare_model.py` ....... one-command exporter + verifier
- `repair_fp16_exports.py` . rebuilds valid FP16 artifacts from current FP32 exports
- `preprocess_config.json` . image/text constants the Flutter code must match
- `bpe_simple_vocab_16e6.txt.gz` CLIP tokenizer vocab (bundle in the app)
- `reference_vectors.json` .. parity target for the Dart tests
- `SPIKE_REPORT.md` ......... full results + the size decision
