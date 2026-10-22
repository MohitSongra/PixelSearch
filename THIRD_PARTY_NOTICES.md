# Third-party notices

PixelSearch's own work is covered by [LICENSE](LICENSE) (all rights reserved). This file lists the third-party
components that are bundled in this repository or in the Android app, or that are needed to build or run it. Each
component keeps its own licence, and nothing in `LICENSE` changes that.

Checked on 2026-10-22 against the files in this repository, the licence files of the locked Dart and Python package
versions, and the upstream sources linked below. Upstream licences, model cards and terms can change; the upstream
text is authoritative. Where this file summarises a licence, the full text governs.

## Contents

- [Summary](#summary)
- [Bundled in the repository or the app](#bundled-in-the-repository-or-the-app)
- [Needed at run time but not in the repository](#needed-at-run-time-but-not-in-the-repository)
- [Test and parity data](#test-and-parity-data)
- [Optional online services](#optional-online-services)
- [Dart and Flutter packages](#dart-and-flutter-packages)
- [Python packages](#python-packages)
- [Corrections](#corrections)

## Summary

| Component | In the repository | In the Android app | Licence (SPDX) |
|---|---|---|---|
| OpenAI CLIP BPE vocabulary | Yes | Yes (asset) | `MIT` |
| CLIP tokenizer, Dart port of OpenCLIP's `SimpleTokenizer` | Yes (derived code) | Yes | `MIT` |
| OpenCV Zoo SFace face-recognition model | Yes | Yes (asset) | `Apache-2.0` |
| Manrope font | Yes | Yes (font) | `OFL-1.1` |
| Material Icons font | No (Flutter SDK) | Yes (font) | `Apache-2.0` upstream; the Flutter SDK's copy comes with a `CC-BY-4.0` licence file |
| Flutter template icons for iOS and web | Yes | No | `BSD-3-Clause` |
| MobileCLIP-S1 weights and their ONNX exports (Apple) | No (git-ignored) | No (copied to the phone by hand) | No SPDX id: Apple Machine Learning Research Model License Agreement |
| ONNX Runtime 1.15.1 native library | No | Yes (via a plugin) | `MIT` |
| Google ML Kit face detection and image labeling | No | Yes (via plugins) | No SPDX id: ML Kit Terms of Service |
| SQLite | No | Yes (via the `sqlite3` package) | Public domain (`blessing`) |
| OpenStreetMap tiles and data | No | Fetched at run time, with consent | `ODbL-1.0` for the data; OSMF Tile Usage Policy for the tiles |
| scikit-image sample images (parity references) | Yes | No | `CC0-1.0` or public domain, per image |
| Four JPEG test fixtures | Yes | Yes (asset) | Provenance not recorded |
| Groq API, Qwen3.6-27B, Whisper large-v3-turbo | No | No (online only, with consent) | Groq Services Agreement; `Apache-2.0`; `MIT` |
| Dart and Flutter packages | No (resolved by `pub`) | Yes | See [the package table](#dart-and-flutter-packages) |
| Python packages for ModelKit and the backend | No | No | See [the package tables](#python-packages) |

## Bundled in the repository or the app

### OpenAI CLIP byte-pair-encoding vocabulary

- **What it is.** The CLIP byte-pair-encoding merge list `bpe_simple_vocab_16e6.txt.gz`, used to tokenize search text
  for the MobileCLIP text encoder.
- **Where it is used.** `pixelsearch_app/assets/models/bpe_simple_vocab_16e6.txt.gz` (bundled app asset),
  `model_kit/bpe_simple_vocab_16e6.txt.gz` and `model_kit/out/bpe_simple_vocab_16e6.txt.gz`. The three copies are
  byte-identical (SHA-256 `924691ac288e54409236115652ad4aa250f48203de50a9e4722a6ecd48d6804a`).
- **Licence.** `MIT`.
- **Copyright.** Copyright (c) 2021 OpenAI.
- **Source.** <https://github.com/openai/CLIP> (`clip/bpe_simple_vocab_16e6.txt.gz`). The copy installed with
  `open_clip_torch` 3.3.0 is byte-identical.

### CLIP tokenizer (Dart port)

- **What it is.** `pixelsearch_app/lib/ai/clip_tokenizer.dart` is a Dart port of the `SimpleTokenizer` in OpenCLIP,
  as its header states. OpenCLIP's tokenizer module says it was copied from OpenAI CLIP under the MIT License,
  Copyright (c) 2021 OpenAI.
- **Where it is used.** `pixelsearch_app/lib/ai/clip_tokenizer.dart`, checked token by token against Python by
  `pixelsearch_app/test/clip_tokenizer_test.dart`.
- **Licence.** `MIT` (OpenAI CLIP) and `MIT` (OpenCLIP).
- **Copyright.** Copyright (c) 2021 OpenAI for the original tokenizer; the OpenCLIP authors for OpenCLIP (their names
  are in the upstream `LICENSE`).
- **Source.** <https://github.com/openai/CLIP/blob/main/clip/simple_tokenizer.py> and
  <https://github.com/mlfoundations/open_clip/blob/main/src/open_clip/tokenizer.py>.
- **Full licence texts.** Both MIT notices are in `pixelsearch_app/assets/licenses/CLIP_TOKENIZER_LICENSE.txt`, which
  the app adds to its licence page.

### OpenCV Zoo SFace model

- **What it is.** `face_recognition_sface_2021dec.onnx`, an unmodified FP32 face-recognition model (MobileFaceNet
  trained with the SFace loss) that produces 128-value face descriptors for the opt-in, offline People feature.
- **Where it is used.** `pixelsearch_app/assets/models/face_recognition_sface_2021dec.onnx` (bundled; the only ONNX
  file tracked in this repository). The contract, byte size and digest are in `model_kit/FACE_CONTRACT.md`; the file
  matches its SHA-256 `0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79`. The numerical fixtures
  are generated by `model_kit/tool/sface_reference.py`.
- **Licence.** `Apache-2.0`. The upstream folder states that all its files are under Apache 2.0. The full text is
  bundled as `pixelsearch_app/assets/models/SFACE_LICENSE.txt` and shown on the app's licence page.
- **Copyright.** The upstream licence file has no filled-in copyright line. The upstream README credits the SFace
  contribution to an author of SFace and the ONNX conversion from the original SFace code base to a second
  contributor, and links that code base. It describes the model files as MobileFaceNet instances trained with the
  SFace loss.
- **Source.** <https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface>.

### Manrope font

- **What it is.** The Manrope variable font (version 4.505 in its name table), the app's typeface.
- **Where it is used.** `pixelsearch_app/assets/fonts/Manrope.ttf` (declared as the `Manrope` font family in
  `pixelsearch_app/pubspec.yaml`). The licence is `pixelsearch_app/assets/fonts/OFL.txt`, which is bundled and shown
  on the app's licence page. The font file also carries its copyright and OFL notice in its metadata.
- **Licence.** `OFL-1.1` (SIL Open Font License 1.1). No Reserved Font Name is declared.
- **Copyright.** The Manrope Project Authors (`OFL.txt` says 2018; the font metadata says 2019).
- **Source.** <https://github.com/googlefonts/manrope> and <https://fonts.google.com/specimen/Manrope>.

### Material Icons font

- **What it is.** `MaterialIcons-Regular.otf`, which Flutter adds to the app because `pixelsearch_app/pubspec.yaml`
  sets `uses-material-design: true`.
- **Where it is used.** All `Icons.*` glyphs in `pixelsearch_app/lib/`. The font comes from the Flutter SDK's
  `material_fonts` download and is not stored in this repository.
- **Licence.** The upstream `google/material-design-icons` README makes the icons available under `Apache-2.0`. The
  licence file that the Flutter 3.44.7 SDK downloads with the font
  (`bin/cache/artifacts/material_fonts/materialicons_license.txt` in the SDK) contains the Creative Commons
  Attribution 4.0 International licence (`CC-BY-4.0`) instead. Flutter does not put it in the `NOTICES` asset
  (checked in a debug APK built from this tree on 2026-10-22), so the app bundles the SDK's text as
  `pixelsearch_app/assets/licenses/MATERIAL_ICONS_LICENSE.txt` and `pixelsearch_app/lib/core/third_party_licenses.dart`
  adds it to the licence page.
- **Copyright.** Google, the publisher of the upstream repository. The SDK's licence file carries no copyright line.
- **Source.** <https://github.com/google/material-design-icons>.

### Flutter template icons

- **What it is.** The default Flutter app icons and launch images.
- **Where it is used.** `pixelsearch_app/ios/Runner/Assets.xcassets/` and `pixelsearch_app/web/` (`favicon.png` and
  `icons/`). Each file is byte-identical to the Flutter 3.44.7 app template, either in `flutter_tools` or in the
  `flutter_template_images` 5.0.0 package that it uses. They are not part of the Android app, whose launcher icons
  are generated from the project's icon `pixelsearch_app/assets/branding/pixelsearch_icon.png`; that folder's
  `README.md` records that the icon was made with an image-generation tool.
- **Licence.** `BSD-3-Clause`.
- **Copyright.** The Flutter Authors (Copyright 2014 in the Flutter SDK `LICENSE`, Copyright 2013 in the
  `flutter_template_images` `LICENSE`).
- **Source.** <https://github.com/flutter/flutter> (`packages/flutter_tools/templates`) and
  <https://pub.dev/packages/flutter_template_images>.

## Needed at run time but not in the repository

### MobileCLIP-S1 (Apple)

- **What it is.** The image and text encoders behind semantic search. `model_kit/prepare_model.py` loads MobileCLIP-S1
  with `pretrained="datacompdr"` through OpenCLIP, which downloads the weights from the Hugging Face repository
  `apple/MobileCLIP-S1-OpenCLIP`. The vision tower is defined by `timm` (`fastvit_mci1`) and the text tower by OpenCLIP;
  PixelSearch contains no code from `apple/ml-mobileclip`.
- **Where it is used.** `model_kit/prepare_model.py` exports `mobileclip_image.onnx` and `mobileclip_text.onnx` (and
  FP16 variants, which are not accepted on Android) to `model_kit/out/`. `model_kit/parity/gen_reference.py` uses the
  same weights. The app finds the exports through `pixelsearch_app/lib/core/model_locator.dart`, which prefers an FP16
  file when one is present, so only the FP32 files are provisioned.
- **Not in the repository or the app.** `*.onnx` is git-ignored except the SFace model. The FP32 exports are copied
  to a debug build by hand (see `pixelsearch_app/README.md`); the app does not bundle or download them.
- **What the upstream sources say (checked 2026-10-22).**
  - The `apple/ml-mobileclip` README lists three licences: code under MIT (`LICENSE`, Copyright 2024 Apple Inc.), ML
    models under the Apple ML Research Model Terms of Use (`LICENSE_MODELS`), and data under CC BY-NC-ND
    (`LICENSE_DATA`).
  - The repository's history shows an earlier file, `LICENSE_weights_data` ("ML-MobileCLIP Model Weights and Data",
    an Apple sample-code-style licence with no research-only limit). It was added on 2024-07-22 and replaced by
    `LICENSE_MODELS` in the MobileCLIP2 release commit of 2025-08-29.
  - `LICENSE_MODELS` is the Apple Machine Learning Research Model License Agreement (Copyright 2025 Apple Inc.). It
    grants a personal, non-exclusive, non-transferable, revocable licence to use, copy, modify and distribute the
    model and to create Model Derivatives, exclusively for Research Purposes, which it defines as non-commercial
    scientific research and academic development. Commercial exploitation, product development and use in a
    commercial product or service are excluded. Redistribution requires giving the recipient a copy of the
    agreement, including the notice "Apple Machine Learning Research Model is licensed under the Apple Machine
    Learning Research Model License Agreement.", and clearly marking Model Derivatives with their modifications.
    Apple's names and marks may not be used to promote Model Derivatives.
  - The Hugging Face model cards for `apple/MobileCLIP-S1` and `apple/MobileCLIP-S1-OpenCLIP` both carry the licence
    tag `apple-amlr`. Their metadata is not consistent: it also gives the licence name `apple-ascl` and links to
    `LICENSE_weights_data`, which no longer exists in `apple/ml-mobileclip`.
  - This repository does not record which version of Apple's terms was in force when the weights were downloaded.
- **What this means here.** This file follows the current `LICENSE_MODELS`, the stricter of the two texts. The ONNX
  exports hold the Apple model's weights in another format, and the text export is also patched
  (`model_kit/patch_text_argmax.py`), so this file treats them as covered by the agreement, as the model itself or as
  Model Derivatives. Read that way, they may be used only for non-commercial research and academic work, and they
  must not be redistributed, alone or inside an app build, without the agreement, the notice and a description of
  the modifications.
- **Licence.** No SPDX id (Hugging Face tag `apple-amlr`).
- **Copyright.** Apple Inc.
- **Source.** <https://github.com/apple/ml-mobileclip> (`LICENSE`, `LICENSE_MODELS`, `LICENSE_DATA`),
  <https://huggingface.co/apple/MobileCLIP-S1> and <https://huggingface.co/apple/MobileCLIP-S1-OpenCLIP>.

### ONNX Runtime

- **What it is.** The inference engine that runs the MobileCLIP and SFace models on the phone.
- **Where it is used.** Through the Flutter plugin `onnxruntime` 1.4.1 (`pixelsearch_app/pubspec.yaml`), in
  `pixelsearch_app/lib/ai/` (MobileCLIP) and `pixelsearch_app/lib/data/people/face_processor_io.dart` (SFace). The
  plugin bundles the native ONNX Runtime **1.15.1** library for Android (`libonnxruntime.so` for `arm64-v8a` and
  `armeabi-v7a`; its iOS podspec pins `onnxruntime-objc` 1.15.1). ModelKit's Python checks use a different version,
  `onnxruntime` 1.28.0 (see `model_kit/CLAUDE.md`).
- **Licence.** `MIT` for ONNX Runtime; `MIT` for the plugin.
- **Copyright.** Copyright (c) Microsoft Corporation for ONNX Runtime. The plugin's copyright line is in its `LICENSE`
  (an individual author).
- **In the app.** The plugin's own `LICENSE` reaches the licence page through Flutter's `NOTICES`; Microsoft's MIT
  notice for the native library does not, so the app bundles it as
  `pixelsearch_app/assets/licenses/ONNXRUNTIME_LICENSE.txt` (with a pointer to the release's `ThirdPartyNotices.txt`)
  and shows it on the licence page.
- **Source.** <https://github.com/microsoft/onnxruntime> (`LICENSE` and `ThirdPartyNotices.txt` at tag `v1.15.1`) and
  <https://pub.dev/packages/onnxruntime>.

### Google ML Kit

- **What it is.** On-device face detection (with landmarks) and image labeling.
- **Where it is used.** Through the Flutter plugins `google_mlkit_face_detection` 0.14.0 and
  `google_mlkit_image_labeling` 0.15.0 (and their dependency `google_mlkit_commons` 0.12.0). These plugins pull in the
  native Android libraries `com.google.mlkit:face-detection:16.1.7`, `com.google.mlkit:image-labeling:17.0.9`,
  `com.google.mlkit:image-labeling-custom:17.0.3`, `com.google.mlkit:linkfirebase:17.0.0` and
  `com.google.mlkit:vision-common:17.3.0`.
- **Licence.** The plugins are `MIT`. The ML Kit libraries are governed by the ML Kit Terms of Service, which
  incorporate and are subject to the Google APIs Terms of Service. No SPDX id.
- **Note.** The ML Kit terms state that input data is processed on the device and that the ML Kit APIs send metrics
  about API performance and use to Google. They make the app developer responsible for telling the app's users about
  Google's processing of these metrics. The app does so in Settings (Privacy Centre, "Google ML Kit on this device").
- **Copyright.** Google LLC for ML Kit. The plugins' copyright line is in their `LICENSE` files (flutter-ml.dev).
- **Source.** <https://developers.google.com/ml-kit/terms>, <https://developers.google.com/terms> and
  <https://github.com/flutter-ml/google_ml_kit_flutter>.

### SQLite

- **What it is.** The embedded database behind the photo index, embeddings and People data.
- **Where it is used.** Through `drift` 2.34.3, which depends on the `sqlite3` package (3.5.1; `pubspec.yaml` also
  lists it as a dev dependency for host tests). From version 3.0, `sqlite3` loads SQLite through a Dart build hook
  that by default downloads a precompiled SQLite library; its 3.5.1 changelog names SQLite 3.53.4. A debug APK built
  from this tree on 2026-10-22 contains `libsqlite3.so` for three ABIs, and each reports version 3.53.4.
  `sqlite3_flutter_libs` 0.5.42 is still a direct dependency; it declares a SQLite 3.52.0 Android library, which is
  not the version found in that APK.
- **Licence.** Public domain. The SQLite authors have dedicated the code and documentation to the public domain
  (SPDX `blessing` covers the blessing in the source headers).
- **Copyright.** None claimed.
- **Source.** <https://www.sqlite.org/copyright.html>.

### OpenStreetMap tiles and data

- **What it is.** Map tiles for the Map screen, fetched only after the user consents to map loading.
- **Where it is used.** `pixelsearch_app/lib/features/map/map_screen.dart` (tile URL, attribution widget) and
  `pixelsearch_app/lib/data/enhancements/map_tile_client.dart` (GET only, the public OpenStreetMap tile server only,
  with the app's own User-Agent). The map shows "© OpenStreetMap contributors", which links to
  <https://www.openstreetmap.org/copyright>.
- **Licence.** OpenStreetMap data: `ODbL-1.0` (Open Data Commons Open Database License). OpenStreetMap
  documentation: `CC-BY-SA-2.0`. The copyright page does not state a separate licence for the tile cartography.
  Use of `tile.openstreetmap.org` is governed by the OSM Foundation Tile Usage Policy, which requires visible
  attribution and an identifying User-Agent, forbids bulk downloading, prefetching and offline use, asks clients not
  to bypass caches, and gives no guarantee of service.
- **Copyright.** OpenStreetMap contributors (data); the OpenStreetMap Foundation runs the tile servers.
- **Source.** <https://www.openstreetmap.org/copyright> and <https://operations.osmfoundation.org/policies/tiles/>.

## Test and parity data

### scikit-image sample images

- **What it is.** The six PNG images in `model_kit/parity/images/`, saved by `model_kit/parity/gen_reference.py` from
  the scikit-image sample-data functions `astronaut()`, `camera()`, `chelsea()`, `coffee()`, `horse()` and `rocket()`
  (the grayscale and black-and-white images are converted to RGB). They are reference inputs for the CLIP parity
  check and are not part of the app.
- **Licence, per the scikit-image documentation.**
  - `camera()`, `chelsea()` and `coffee()`: no copyright restrictions, CC0 by the photographer (`CC0-1.0`).
  - `horse()`: no copyright restrictions, CC0 given by the owner (`CC0-1.0`); from openclipart.
  - `astronaut()`: NASA image, no known copyright restrictions, released into the public domain.
  - `rocket()`: SpaceX launch photo, released into the public domain.
- **Copyright.** None claimed (CC0 or public domain, as above). The scikit-image library itself is `BSD-3-Clause`,
  Copyright 2009-2022 the scikit-image team.
- **Source.** <https://scikit-image.org/docs/stable/api/skimage.data.html> and
  <https://github.com/scikit-image/scikit-image>.

### JPEG test fixtures

- **What it is.** The four JPEG files in `pixelsearch_app/assets/samples/`, used as fixtures by widget, database,
  timeline, map and People tests. `pixelsearch_app/pubspec.yaml` lists the folder as an asset, so they are also packed
  into the app.
- **Licence and copyright.** Provenance not recorded. They have been in the repository since its first commit, and
  they contain no EXIF or other metadata that identifies a source. Until their origin is confirmed, treat them as of
  unknown licence.

### Generated fixtures

`pixelsearch_app/test/fixtures/sface/*.png` and `pixelsearch_app/test/fixtures/sface/reference.json` are synthetic
patterns and numbers generated by `model_kit/tool/sface_reference.py`.
`pixelsearch_app/assets/models/sface_reference_source.png` and `pixelsearch_app/assets/models/sface_reference.json`
are byte-identical copies of `source.png` and `reference.json`; they are listed as assets in
`pixelsearch_app/pubspec.yaml`, so they are also packed into the app. They contain no third-party content, but the
generator uses OpenCV 4.12.0 as a reference implementation (see [Python packages](#python-packages)).

## Optional online services

These services are used only after the user turns on the matching feature and consents; photo and recording uploads
also need approval for each item. Nothing from them is bundled. The requests go through the self-hosted broker in
`enhancement_backend/` (`enhancement_backend/app.py`).

| Service or model | Used for | Terms or licence | Source |
|---|---|---|---|
| Groq API (GroqCloud) | Hosts the models below; called only by the broker | Groq Services Agreement and the Groq Acceptable Use and Responsible AI Policy. The agreement makes customers comply with the terms of each third-party model they use. | <https://console.groq.com/docs/legal> |
| Qwen3.6-27B (`qwen/qwen3.6-27b` on Groq) | Photo captions, text rewriting and the assistant | `Apache-2.0`, per the model card. Qwen (Alibaba Cloud). | <https://huggingface.co/Qwen/Qwen3.6-27B> |
| Whisper large-v3-turbo (`whisper-large-v3-turbo` on Groq) | Cloud speech transcription | `MIT`, per the model card. OpenAI. | <https://huggingface.co/openai/whisper-large-v3-turbo> |

`render.yaml` can deploy the broker on Render. Render's own terms apply to that hosting; no Render code is bundled.

## Dart and Flutter packages

The Flutter build collects the `LICENSE` file of every Dart package the app depends on, direct or transitive, together
with the Flutter engine's third-party licences, into the `NOTICES` asset inside the app. Flutter's `LicenseRegistry`
reads it, and the app shows it through "View licenses" in the About entry at the bottom of Settings.
`pixelsearch_app/lib/core/third_party_licenses.dart` adds five non-package licences (SFace, the CLIP tokenizer,
Manrope, the Material Icons font and the native ONNX Runtime library) to the same page. The full resolved dependency set is in `pixelsearch_app/pubspec.lock`.

Direct dependencies from `pixelsearch_app/pubspec.yaml`, at the versions in `pixelsearch_app/pubspec.lock`, with the
licence read from each package's `LICENSE` file:

| Package | Locked version | Used for | Licence |
|---|---|---|---|
| [`flutter`](https://github.com/flutter/flutter) (SDK) | Flutter 3.44.7 | Framework and engine | `BSD-3-Clause` |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | 2.6.1 | State management | `MIT` |
| [`go_router`](https://pub.dev/packages/go_router) | 14.8.1 | Navigation | `BSD-3-Clause` |
| [`photo_manager`](https://pub.dev/packages/photo_manager) | 3.11.0 | Gallery access | `Apache-2.0` |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | 11.4.0 | Runtime permissions | `MIT` |
| [`drift`](https://pub.dev/packages/drift) | 2.34.3 | SQLite database layer | `MIT` |
| [`sqlite3_flutter_libs`](https://pub.dev/packages/sqlite3_flutter_libs) | 0.5.42 | Native SQLite library | `MIT` |
| [`path`](https://pub.dev/packages/path) | 1.9.1 | Path handling | `BSD-3-Clause` |
| [`path_provider`](https://pub.dev/packages/path_provider) | 2.1.6 | App directories | `BSD-3-Clause` |
| [`onnxruntime`](https://pub.dev/packages/onnxruntime) | 1.4.1 | ONNX Runtime binding (bundles native ORT 1.15.1) | `MIT` |
| [`image`](https://pub.dev/packages/image) | 4.9.1 | Image decoding and preprocessing | `MIT` |
| [`google_mlkit_image_labeling`](https://pub.dev/packages/google_mlkit_image_labeling) | 0.15.0 | ML Kit image labels | `MIT` (plugin); ML Kit terms for the native SDK |
| [`google_mlkit_face_detection`](https://pub.dev/packages/google_mlkit_face_detection) | 0.14.0 | ML Kit face detection | `MIT` (plugin); ML Kit terms for the native SDK |
| [`workmanager`](https://pub.dev/packages/workmanager) | 0.10.7 | Background task wiring | `MIT` |
| [`exif`](https://pub.dev/packages/exif) | 3.3.0 | EXIF metadata | `MIT` |
| [`crypto`](https://pub.dev/packages/crypto) | 3.0.7 | Hashing | `BSD-3-Clause` |
| [`http`](https://pub.dev/packages/http) | 1.6.0 | Consented online requests and map tiles | `BSD-3-Clause` |
| [`flutter_map`](https://pub.dev/packages/flutter_map) | 8.3.2 | Map view | `BSD-3-Clause` |
| [`flutter_map_marker_cluster`](https://pub.dev/packages/flutter_map_marker_cluster) | 8.2.2 | Map marker clusters | `BSD-3-Clause` |
| [`latlong2`](https://pub.dev/packages/latlong2) | 0.9.1 | Coordinates | `Apache-2.0` |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | 9.2.4 | Backend credential storage | `BSD-3-Clause` |
| [`record`](https://pub.dev/packages/record) | 6.2.1 | Voice recording | `BSD-3-Clause` |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | 6.3.2 | Opening links | `BSD-3-Clause` |

Development and test dependencies. Apart from `sqlite3`, which `drift` also needs at run time (see [SQLite](#sqlite)),
they are not shipped in the app:

| Package | Locked version | Used for | Licence |
|---|---|---|---|
| `flutter_test`, `integration_test` (SDK) | Flutter 3.44.7 | Tests | `BSD-3-Clause` |
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) | 0.14.4 | Generating launcher icons | `MIT` |
| [`sqlite3`](https://pub.dev/packages/sqlite3) | 3.5.1 | Host database tests; also the SQLite binding and library loader that `drift` uses in the app | `MIT` |
| [`path_provider_platform_interface`](https://pub.dev/packages/path_provider_platform_interface) | 2.1.3 | Test fakes | `BSD-3-Clause` |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | 6.0.0 | Lint rules | `BSD-3-Clause` |
| [`drift_dev`](https://pub.dev/packages/drift_dev) | 2.34.5 | Drift code generation | `MIT` |
| [`build_runner`](https://pub.dev/packages/build_runner) | 2.15.1 | Code generation | `BSD-3-Clause` |

## Python packages

None of these packages is needed to run the app.

### ModelKit (`model_kit/requirements.txt`)

Used to export the MobileCLIP encoders, build the parity references and run the metric tests. Licences come from the
installed package metadata and licence files on the development host; where the installed version differs from the
pin, it is noted.

| Package | Pinned version | Licence | Source |
|---|---|---|---|
| `torch` | 2.13.0 | `BSD-3-Clause` for PyTorch itself; the wheel metadata declares `Apache-2.0 AND Apache-2.0 WITH LLVM-exception AND BSD-2-Clause AND BSD-3-Clause AND BSL-1.0 AND MIT` for the wheel with its bundled components | <https://github.com/pytorch/pytorch> |
| `torchvision` | 0.28.0 | `BSD-3-Clause` | <https://github.com/pytorch/vision> |
| `open_clip_torch` | 3.3.0 | `MIT` | <https://github.com/mlfoundations/open_clip> |
| `onnx` | 1.22.0 | `Apache-2.0` | <https://github.com/onnx/onnx> |
| `onnxruntime` | 1.28.0 | `MIT` | <https://github.com/microsoft/onnxruntime> |
| `numpy` | 2.4.4 (checked on 2.5.1) | `BSD-3-Clause AND 0BSD AND MIT AND Zlib AND CC0-1.0` | <https://github.com/numpy/numpy> |
| `pillow` | 12.2.0 (checked on 12.3.0) | `MIT-CMU` | <https://github.com/python-pillow/Pillow> |
| `scikit-image` | 0.26.0 | `BSD-3-Clause` | <https://github.com/scikit-image/scikit-image> |

`open_clip_torch` also installs, among others, `timm` (`Apache-2.0`; defines the MobileCLIP-S1 vision tower) and
`huggingface_hub` (`Apache-2.0`; downloads the weights).

`model_kit/tool/sface_reference.py` also needs OpenCV 4.12.0 as a reference implementation. It is not in
`requirements.txt`; it is installed separately into a git-ignored build folder. The OpenCV library is `Apache-2.0`
(<https://github.com/opencv/opencv>). Which pip wheel was used is not recorded, and the `opencv-python` wheels bundle
other libraries under their own licences.

### Enhancement backend (`enhancement_backend/requirements.txt`)

Direct requirements, at the versions in `enhancement_backend/requirements.lock`, with licences from the installed
package metadata. The lock file lists the full set, transitive packages included.

| Package | Locked version | Licence | Source |
|---|---|---|---|
| `fastapi` | 0.141.1 | `MIT` | <https://github.com/fastapi/fastapi> |
| `starlette` | 1.6.0 | `BSD-3-Clause` | <https://github.com/Kludex/starlette> |
| `uvicorn` | 0.52.4 | `BSD-3-Clause` | <https://github.com/Kludex/uvicorn> |
| `httpx` | 0.28.1 | `BSD-3-Clause` | <https://github.com/encode/httpx> |
| `python-multipart` | 0.0.32 | `Apache-2.0` | <https://github.com/Kludex/python-multipart> |
| `pillow` | 12.3.0 | `MIT-CMU` | <https://github.com/python-pillow/Pillow> |
| `pytest` (tests only) | 9.1.1 | `MIT` | <https://github.com/pytest-dev/pytest> |

## Corrections

If a licence, attribution or source here is wrong or missing, please report it through this repository's issue
tracker.
