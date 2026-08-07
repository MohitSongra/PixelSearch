# PixelSearch — MobileCLIP Model Kit

Proven on-device semantic-search model for PixelSearch (see SPIKE_REPORT.md for the verification).

## Generate the model files
```
pip install torch torchvision open_clip_torch onnx onnxruntime onnxconverter_common scikit-image
python prepare_model.py
```
This writes `out/mobileclip_image_fp16.onnx` and `out/mobileclip_text_fp16.onnx` (~171 MB total)
plus re-runs the 6/6 retrieval self-test.

## Files here
- `prepare_model.py` ....... one-command exporter + verifier
- `preprocess_config.json` . image/text constants the Flutter code must match
- `bpe_simple_vocab_16e6.txt.gz` CLIP tokenizer vocab (bundle in the app)
- `reference_vectors.json` .. parity target for the Dart tests
- `SPIKE_REPORT.md` ......... full results + the size decision
