# PixelSearch App

This is the active Flutter app. Start with the [repository README](../README.md)
and [architecture](docs/ARCHITECTURE.md).

## Development

Use the pinned repository baseline, Flutter 3.44.7 / Dart 3.12.2. Android build
configuration targets Java/Kotlin JVM 17; install the SDK/NDK required by Gradle
and the native plugins. Keep `pubspec.lock` for reproducibility.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Select the intended development device explicitly when more than one is connected.
Do not uninstall, clear storage or run integration installers against a valuable
gallery index as a routine troubleshooting step. Use a disposable test device or
a reviewed, backup-first replacement install.

## Models and fixtures

MobileCLIP's image and text ONNX files are loaded from the app support `models/`
directory, as resolved by `lib/core/model_locator.dart`. Generate and verify them
with [ModelKit](../model_kit/README.md), then provision a known-good pair. The recorded
Android baseline is FP32 CPU. Automatic model download/provisioning is not complete.

Provisioning a debug build by hand (release builds are not debuggable, so `run-as` fails):

1. Inside `model_kit/`, run `python prepare_model.py`. It writes the FP32 files
   `mobileclip_image.onnx` and `mobileclip_text.onnx` (and FP16 files) to `model_kit/out/`.
2. Copy only the two FP32 files to the device: `adb push` them to `/data/local/tmp/`, then
   `adb shell run-as com.pixelsearch.pixelsearch mkdir -p files/models` and
   `adb shell run-as com.pixelsearch.pixelsearch cp /data/local/tmp/<file> files/models/`.
3. Never copy a `*_fp16.onnx` file. The resolver prefers FP16 when it is present, but FP16 has
   never run on Android and no execution provider for it is registered.
4. Re-run indexing in the app; nothing notices new models automatically.

The full command block, including Git Bash notes, is in
[docs/PROJECT_CONTEXT.md §5.1](../docs/PROJECT_CONTEXT.md).

The CLIP vocabulary and licensed SFace FP32 model are bundled. SFace is a deliberate
exception to the repository's ignored ONNX exports, verified against the
[face contract](../model_kit/FACE_CONTRACT.md). Keep its license and numerical fixtures.

The four photos in `assets/samples/` are widget-test fixtures, not a mock gallery
or user data. Runtime gallery contents come from the local index. SFace reference
fixtures in both the app assets and `test/fixtures/` support device and host checks.

An additional host check can exercise the real SFace worker when a compatible
native ONNX Runtime library is installed:

```sh
flutter test --dart-define=SFACE_MODEL_TEST=true
```

MobileCLIP integration tests require separately provisioned models and a supported
native target. Ordinary unit tests do not establish full device acceptance.

## State and source ownership

`lib/state/providers.dart` is the stable export-only API used by screens and tests.
Implementations live in storage, preferences, online, library, query, indexing,
search and People provider files. Provider identity is preserved, including test
overrides. Domain rules stay under `lib/domain/`; device and persistence code stay
behind repositories and adapters.

Generated `lib/data/local/app_database.g.dart` is retained for reproducible builds.
Change the Drift table declarations, then regenerate it rather than editing it.

## Online features and release

All online features are separately consented and disabled by the master offline
policy. See [backend setup](../enhancement_backend/README.md). Never embed provider
credentials in the app.

Release builds need an operator-supplied keystore through four environment
variables and fail without them ([release signing](docs/ANDROID_RELEASE_SIGNING.md));
no release-signed build has been made yet, and one cannot update the debug-signed
install in place. A public release also requires model provisioning, privacy review
and target-device acceptance. Android is the only supported platform: the iOS and web
folders are untested Flutter scaffolds, not a promise of feature parity.
