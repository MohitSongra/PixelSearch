# PixelSearch — MobileCLIP Model Kit

Proven on-device semantic-search model for PixelSearch (see SPIKE_REPORT.md for the verification).

## Generate the model files
```
pip install -r requirements.txt
python prepare_model.py
```
This writes `out/mobileclip_image_fp16.onnx` and `out/mobileclip_text_fp16.onnx` (~171 MB total)
plus re-runs the 6/6 retrieval self-test. The FP16 conversion uses ONNX Runtime's converter, performs a
topological sort, and validates every Cast output type before replacing an artifact.

To repair only existing FP16 artifacts from the preserved FP32 exports without downloading or exporting the
model again, run:
```
python repair_fp16_exports.py
```

The desktop custom-image tester intentionally uses the FP32 artifacts with the CPU provider. FP16 is the
Android NNAPI/XNNPACK artifact and must be validated on a real device.

## Files here
- `prepare_model.py` ....... one-command exporter + verifier
- `repair_fp16_exports.py` . rebuilds valid FP16 artifacts from current FP32 exports
- `preprocess_config.json` . image/text constants the Flutter code must match
- `bpe_simple_vocab_16e6.txt.gz` CLIP tokenizer vocab (bundle in the app)
- `reference_vectors.json` .. parity target for the Dart tests
- `SPIKE_REPORT.md` ......... full results + the size decision
