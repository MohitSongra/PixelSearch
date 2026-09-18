# Offline People Contract

Contract ID: `sface-2021dec-mlkit-landmarks-v1`.
This supplements MobileCLIP. CLIP model/artifact/embedding versions are unchanged.

## Artifact and Geometry

- OpenCV Zoo `face_recognition_sface_2021dec.onnx`, unmodified FP32, opset 11.
- 38,696,353 bytes; SHA-256 `0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79`.
- Apache 2.0 license is bundled as `assets/models/SFACE_LICENSE.txt`.
- Input `data`: float32 `[1,3,112,112]`, RGB CHW, original 0..255 pixel range.
- The graph itself applies `(x - 127.5) * 0.0078125`. Do not normalize again.
- Output `fc1`: float32 `[1,128]`. L2-normalize, reject non-finite/zero/wrong-shape vectors.
- Store 128 little-endian float32 values (512 bytes) in `people_faces.vector`,
  never in `embedding_rows`. These are descriptors, not irreversible hashes.

## Detection and Alignment

Use bundled ML Kit accurate detection with landmarks, no tracking/contours/classifications.
Existing indexer boxes/counts are retained but cannot supply five-point alignment.
Re-detect all accessible indexed still photos, including those with no previous faces.
Decode EXIF orientation on Android, power-of-two downsample to longest side <=2048.
Use image-left eye, image-right eye, nose base, image-left mouth and image-right mouth.
Fit a non-reflecting least-squares similarity transform to:

```text
38.2946 51.6963
73.5318 51.5014
56.0252 71.7366
41.5493 92.3655
70.7299 92.2041
```

Warp to 112x112 with bilinear interpolation and constant-black borders.
Faces smaller than 100 pixels on either prepared-image dimension, missing landmarks
or invalid vectors remain manually assignable but cannot seed automatic assignments.
This is a quality safeguard, not a calibrated recognition threshold.

## Reference Tests

`tool/sface_reference.py` generates numerical fixtures using OpenCV 4.12.0
FaceRecognizerSF.alignCrop/feature and ONNX Runtime CPU. These patterns contain no
people and measure preprocessing/engine agreement, not identity accuracy.
Run from `pixelsearch_app`:

```powershell
py -3.14 ../model_kit/tool/sface_reference.py --app .
flutter test test/sface_reference_test.dart --dart-define=SFACE_MODEL_TEST=true
```

The generator expects reference-only OpenCV under `build/face_reference_deps`,
plus NumPy, onnx and onnxruntime in the selected Python. Windows Dart tests need
`onnxruntime.dll` on PATH. The plugin's Windows filename API incorrectly passes
UTF-8 to ORT's UTF-16 API; Windows parity uses fromBuffer, Android uses fromFile.
People > options > Check face model runs the same numerical fixtures on Android,
without gallery access, network calls or identity assignments.

Desktop measured crop mean absolute errors: identity 0, scale 0, rotation
0.003082482993197279, border 0.00233843537414966 (0..255 channels). Maximum 8.
Production-worker/reference descriptor cosine: identity 0.9999999686938639,
scale 1.0, rotation 0.9999963760713015, border 0.9999978648745064.
Android measurements must be recorded separately after device verification.

## Local Grouping Gate

No default identity threshold. Freeze up to 40 calibration and 20 validation
pairs, split by photo before user judgments; total must reach at least 40.
Unsure is excluded. Require both classes in each subset, nonzero same-person
recall, and zero calibration false joins. Maximize calibration true joins,
breaking ties toward stricter thresholds. Check that fixed threshold on held-out
validation: zero false joins and at least one true join. Never tune on validation.
Only a passing result permits complete-link admission. Ambiguous faces stay
separate; established groups are never auto-merged. All existing same-photo
assignments, including faces without descriptors, block automatic same-photo joins.
Manual corrections remain authoritative. Passing a small local sample does not
establish general accuracy or eliminate grouping mistakes.

## Sources

- [OpenCV SFace and license](https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface)
- [OpenCV reference alignment](https://github.com/opencv/opencv/blob/4.x/modules/objdetect/src/face_recognize.cpp)
- [ML Kit detects faces, not identities](https://developers.google.com/ml-kit/vision/face-detection)
- [Google Photos grouping and correction controls](https://support.google.com/photos/answer/6128838?hl=en)
