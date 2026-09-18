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

The current Android release configuration still uses debug signing. A public
release requires dedicated signing, model provisioning, privacy review and target
device acceptance. Platform scaffolds are not a promise of iOS/web feature parity.
