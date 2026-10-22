# PixelSearch

Private, on-device semantic photo search for Android.

Describe a photo you remember ("dog on a beach", or "photos of me with `<name>` at the beach") and PixelSearch
ranks the photos on your phone. Indexing, image and text embeddings, ranking and face data stay on the device. A
few optional online features exist; each is off by default and needs its own consent.

This is a final-year undergraduate project. It is a working research prototype, not a released app.

> [!NOTE]
> **Status (2026-10-22)**
>
> **Works on a real phone.** On the test phone (Vivo I2214, Android API 36, debug build, MobileCLIP FP32 on CPU)
> the app indexed a 1,916-photo library, searches it by description, and runs offline People search. Typed person
> searches passed device acceptance on 2026-10-22. Evidence: [Evidence ledger §4.2](docs/EVIDENCE_LEDGER.md#42-vivo-i2214-android-api-36-arm64-main-acceptance-device).
>
> **Not done.** In-app model provisioning (M12; models are copied in by hand), background indexing, worker-isolate
> indexing, FP16 or NNAPI acceleration, a judged retrieval benchmark and a release-signed build.
>
> **Not measured.** Retrieval quality has been judged on only two queries, face-grouping accuracy has never been
> measured, and no end-to-end query latency has been measured on a phone.

Screenshots will be added once a non-personal demo library exists. None are published here, because the only
library used so far is a private one.

## Contents

- [Problem and motivation](#problem-and-motivation)
- [Features and status](#features-and-status)
- [How search works](#how-search-works)
- [Architecture](#architecture)
- [Privacy model](#privacy-model)
- [Measured results](#measured-results)
- [Getting started](#getting-started)
- [Testing and CI](#testing-and-ci)
- [Optional backend](#optional-backend)
- [Limitations and known issues](#limitations-and-known-issues)
- [Roadmap](#roadmap)
- [Repository layout and documentation](#repository-layout-and-documentation)
- [Team and credits](#team-and-credits)
- [Licence](#licence)

## Problem and motivation

People keep thousands of photos on their phones, and finding one remembered photo usually means scrolling by date.
Searching by meaning ("a birthday cake", "sunset over water") needs a vision-language model. Running that model on
a server means sending a private photo library off the phone.

PixelSearch tests a different approach: do the whole search path on the phone. It indexes the gallery with
MobileCLIP-S1 through ONNX Runtime, stores 512-dimensional embeddings in a local SQLite database and answers
text queries with an exact cosine scan. Offline People support adds user-confirmed names, so a query can combine a
scene with the people in it. The target users are everyday people finding memories in a large personal library.

Design rules for the project:

- **Offline first.** Search works with no network. Online features are optional extras that fail closed.
- **Privacy first.** The index, embeddings, face data and names stay on the phone. A photo or a recording leaves
  the phone only through an optional online feature, after the user approves that item. Person names and person
  filters never go to any online service.
- **Measured results only.** Every measurement in the [evidence ledger](docs/EVIDENCE_LEDGER.md) carries its
  date, device or host, precision and sample size. Unmeasured things are marked as such.
- **One model contract.** `model_kit/` is the source of truth for preprocessing, the tokenizer and the ONNX
  interface. Any mismatch between ModelKit and the app is treated as a critical bug.

Background: [docs/PROJECT_CONTEXT.md §1](docs/PROJECT_CONTEXT.md#1-what-pixelsearch-is).

## Features and status

"Accepted on a phone" means the feature was exercised on the test phone and recorded in a dated report.
"Implemented" means it exists in code and is covered by host tests, but has not been accepted on a phone.

| Feature | Status | Notes and evidence |
|---|---|---|
| Incremental gallery indexing: scan, plan, commit in batches of 32, cancel, resume, folder scope | Accepted on a phone (partly) | A 1,916-photo library was indexed (2026-09-09). A full gallery of 19,260 assets was never indexed to completion. Folder scope accepted 2026-09-08. |
| MobileCLIP-S1 image and text embeddings, FP32 on CPU | Accepted on a phone | Smoke test 2026-09-08; device and host vectors agree on the rows checked. |
| Semantic search with hybrid reranking and filters (date, album, place, people) | Implemented; used on a phone | Retrieval quality judged on two queries only (see [Measured results](#measured-results)). |
| Keyword fallback when no text model is available | Implemented | The current mode is shown only in a tooltip. |
| "Why this matched" explanations and in-app search diagnostics | Implemented; diagnostics used on a phone | Diagnostics use the same ranking function as real search. |
| Indexed gallery home, calendar-day timeline and memory stories | Accepted on a phone | 215 daily events over 1,916 photos (2026-09-10). |
| Map from EXIF GPS with consented OpenStreetMap tiles | Implemented; partly accepted | Tiles loaded, but the EXIF pass located 0 of 1,916 photos (not proof that the originals lack GPS), so no photo pin has been seen on a phone (2026-09-10). |
| ML Kit image labels with a label editor | Implemented | Labels are kept only at confidence ≥ 0.5; otherwise a photo has no labels. |
| Offline voice search (Android on-device recognizer, API 33 or later) | Implemented | Recognition accuracy never measured. |
| **People:** ML Kit face detection, SFace 128-d descriptors, user-confirmed naming, aliases, "This is me" | Accepted on a phone (2026-10-22) | Opt-in. On 2026-10-22 all 1,916 photos were processed: 2,642 detected faces, 397 with descriptors (faces of at least 100 px under FaceContract v1); 864 after the FaceContract v2 re-scan the same day. |
| **Person search:** "photos of me with `<name>`", "`<A>` or `<B>`", "`<A>` without `<B>`", a name plus a scene | Accepted on a phone (typed queries, 2026-10-22) | 8 typed queries matched the values expected from a backup. Voice person queries not exercised on a phone. |
| Similar-face suggestions | Implemented; viewed on a phone | Suggestions only order faces: no threshold, no score shown, and nothing is assigned until the user confirms that face. Confirm and reject are host-tested only. |
| Validated automatic grouping behind a photo-disjoint review gate | Implemented; ran on a phone | Grouping runs only after the user's review round passes (zero false joins on held-out pairs). The round that passed (under FaceContract v1) had only 4 "different" pairs in its holdout. Since the v2 install (2026-10-22) grouping is off on the phone until the user's review round under v2 passes. Grouping accuracy has never been measured. |
| "Same person?" questions (Yes / No / Not sure) | Implemented; answered by the user on a phone | Every answer is the user's decision; the software never answers for the user. |
| FaceContract v2: faces compared from 64 px instead of 100 px (2026-10-22) | Implemented; installed and re-scanned on a phone (2026-10-22) | Every photo is re-scanned and earlier names carry over. Automatic grouping stays off until a new review round passes. A host rehearsal on a copy of a phone backup (2026-10-22) showed no visible change before the re-scan. On the phone the same day all 1,916 photos were re-scanned with the app open; all 2,642 earlier faces kept their ids, 864 can now be compared (397 under v1), earlier decisions and names were unchanged, and the assignments that changed were all changed by the user's own answers during the re-scan. The grouping threshold was cleared; no review round under v2 had been started by the last backup that day, so v2 grouping quality is unmeasured. |
| Reviewed photos remembered by photo id (KI-16 fix, schema v7, 2026-10-22) | Implemented; migration ran on a phone (2026-10-22) | Keeps review rounds photo-disjoint after a reviewed photo is edited. The same host rehearsal filled all 140 review rows with photo ids, and so did the migration on the phone (140 of 140, otherwise unchanged). |
| Optional online features: AI captions, search assistant, cloud speech transcription | Implemented | The assistant was live-tested on 2026-09-09 (3 authenticated requests). Captions and cloud transcription were not independently live-tested. |

**Not done:**

- **M12 model manager.** Provisioning is manual: the MobileCLIP files are copied into the app by hand (see
  [Model provisioning](#model-provisioning-debug-builds)). A fresh install cannot index until they are present.
- **Background indexing.** WorkManager is initialized but never scheduled. Some phones freeze the app when the
  screen turns off (KI-10), which stops a foreground run.
- **Worker-isolate indexing.** Decoding, preprocessing and ONNX inference run on the UI isolate.
- **FP16 / NNAPI.** ModelKit also writes FP16 exports, but the app registers no execution provider, no recorded
  Android run has used FP16, and FP16 is not accepted on Android.
- **A judged retrieval benchmark.**
- **A release-signed build.**

## How search works

Each constant below was checked in the source on 2026-10-22.

**Model and embeddings**

| Item | Value | Source |
|---|---|---|
| Model | MobileCLIP-S1 (`datacompdr` weights), loaded through OpenCLIP and exported with PyTorch | `lib/core/ai_contract.dart`, `model_kit/prepare_model.py` |
| Image input | shorter side resized to 256 with antialiasing, 256 × 256 centre crop, RGB scaled to [0, 1], no mean/std, CHW | `lib/ai/image_preprocess.dart`, `model_kit/INTERFACE_CONTRACT.md` |
| Text input | CLIP byte-pair tokenizer, 77 tokens, a Dart port of OpenCLIP's `SimpleTokenizer` (id-exact on 19 reference cases) | `lib/ai/clip_tokenizer.dart` |
| Embedding | 512-d, L2-normalized | `AiContract.embeddingDim` |
| ONNX | opset 17; inputs `pixel_values` and `input_ids`, outputs `image_embeds` and `text_embeds` | `model_kit/INTERFACE_CONTRACT.md` |
| Runtime | ONNX Runtime on CPU, FP32, intra-op threads = half the cores, between 1 and 4; no execution provider. This is the only accepted configuration. | `lib/ai/onnx_encoder.dart` |

Paths in the Source column are relative to `pixelsearch_app/` unless they start with `model_kit/`.

**Query path**

1. **People first.** Registered names, aliases and "me" are resolved locally
   (`lib/domain/people/people_query.dart`). A name-only query skips CLIP and returns that person's photos, newest
   first. A query that refers to "me" when nobody is marked "This is me", or that uses an ambiguous name, runs no
   search at all: the app asks the user instead of guessing.
2. **Filters before Top-K.** Date, album, place and person eligibility restrict the candidate set before the vector
   scan, so the best matches are always taken from photos that pass the filters.
3. **Exact cosine.** The remaining text is embedded and compared with every current-version image embedding by dot
   product (`lib/data/search/brute_force_vector_index.dart`). There is no approximate index and no cloud vector
   database.
4. **Top-K and gate.** The 60 best matches are kept, then any match with a raw cosine below 0.15 is dropped
   (`lib/data/search/semantic_search_backend.dart`, `search_ranking.dart`).
5. **Hybrid rerank** (`lib/domain/search/hybrid_scorer.dart`):

   ```text
   final = 0.70 · clamp(cosine / 0.35, 0, 1) + 0.25 · (lexical / max lexical) + 0.05 · face
   ```

   The face term is `min(faceCount, 3) / 3`, applied only when the query asks for people ("selfie", "group",
   "family" and similar words). Ties go to the newer photo. In normal semantic mode there is no lexical-only union,
   ML Kit labels are not used in lexical scoring, and the articles "a", "an" and "the" are ignored. Search and the
   diagnostics screen share the same function, `rankSearchCandidates`.
6. **Keyword fallback.** Without a usable text model, or with an empty index, search falls back to keyword
   matching, which does use labels.

**These are policy constants, not calibrated values.** The 0.15 gate comes from six host parity probes
(minimum correct cosine 0.1983, maximum distractor 0.1463; host, FP32, 2026-08-07). The 0.35 ceiling and the
0.70 / 0.25 / 0.05 weights have never been tuned on judged data. Any change to them needs judged, held-out evidence.

## Architecture

| Component | Role |
|---|---|
| [`pixelsearch_app/`](pixelsearch_app/README.md) | The Flutter app (Riverpod, go_router, Drift/SQLite, ONNX Runtime, ML Kit, photo_manager, flutter_map). Android is the only supported runtime. |
| [`model_kit/`](model_kit/README.md) | Python tooling: MobileCLIP export, FP16 repair, the ArgMax patch for ONNX Runtime 1.15, parity references, metrics and SFace fixtures. Source of truth for the model contracts. |
| [`enhancement_backend/`](enhancement_backend/README.md) | Optional, stateless FastAPI broker to Groq for captions, the assistant and cloud transcription. It never receives the gallery, the index or face data. |
| `tool/` | `check_repository.py`: the CI check for repository layout and publication boundaries. It rejects tracked model exports (except SFace), APKs, databases, keystores and `.env` files, and scans text files for common shapes of private data. It cannot prove that no private data or secret is present. |

Inside the app, `lib/` is split into `features/` (screens), `state/` (Riverpod composition), `domain/` (pure
search, people and timeline rules), `data/` (repositories, Drift, online clients), `indexing/` (a ports-and-adapters
pipeline), `ai/` (tokenizer, preprocessing, encoders), `core/` (router, theme, contracts) and `evaluation/`
(retrieval metrics). Heavy work (indexing, People scans) holds a SQLite processing lease; search never takes it.
The code has been at Drift schema 7 since 2026-10-22, and the build on the test phone has used it since the same day.

The layer and state-ownership overview, with indexing and search flow diagrams, is
[pixelsearch_app/docs/ARCHITECTURE.md](pixelsearch_app/docs/ARCHITECTURE.md).

## Privacy model

**Stays on the phone** (apart from a single photo or recording that the user approves for an online feature
below): photos, thumbnails, the SQLite index, MobileCLIP embeddings, ML Kit labels and face boxes,
SFace descriptors, face crops, person names and aliases, review answers, preferences, label corrections and
evaluation judgments.

**Optional online features.** The app starts in offline-only mode. Each feature needs its own consent, and requests
fail closed. The client uses HTTPS only, follows no redirects and makes no silent retries.

| Feature | Goes to | What is sent | Consent needed |
|---|---|---|---|
| AI caption | Self-hosted FastAPI broker, then Groq | One photo, re-encoded as a metadata-free JPEG of at most 1280 px | Feature consent plus approval of each photo after a preview |
| Caption rewrite | Broker, then Groq | The caption text and a style | Feature consent |
| Search assistant | Broker, then Groq | The message, the current query, the language, today's date and date/album/place filters. Never photos, vectors, filenames or person ids. | Feature consent |
| Cloud speech transcription | Broker, then Groq | One recording (AAC, at most 30 s) | Feature consent plus approval of each recording |
| Map tiles | The public OpenStreetMap tile server, directly (not through the broker) | Tile requests (GET only), which reveal the IP address and the map area viewed. Tiles are not cached on disk. | Map consent |

Offline voice search uses Android's on-device recognizer and has no cloud fallback.

**People data never goes online.** Typed person names, face data and person filters are not sent to any service.
The assistant refuses a query that mentions any saved name (hidden people included) or uses a person filter, before
any network call. One limit: cloud transcription sends audio, so a name the user speaks in an approved recording
reaches the transcription service. That path has no person-name guard.

**Accepted limits:**

- The app does not encrypt its local data itself; it relies on Android's app-private storage.
- Deletion is logical (database rows and files), not forensic erasure.
- Android backup is disabled for the app (`allowBackup="false"`).

Security review: [docs/SECURITY_REVIEW_2026-09-18.md](docs/SECURITY_REVIEW_2026-09-18.md) (seven findings and their
fixes). How to report a vulnerability: [SECURITY.md](SECURITY.md).

## Measured results

The most important rows from the [evidence ledger](docs/EVIDENCE_LEDGER.md), which lists every measurement with its
caveats. "Host" is an x86-64 build machine, never an Android result. The phone is the Vivo I2214 (Android API 36,
arm64), running debug builds.

| Date | Measurement | Value | Where, precision | Sample |
|---|---|---|---|---|
| 2026-08-07 | Retrieval on parity probes (the basis of the 0.15 gate) | Top-1 6/6; minimum correct cosine 0.1983, maximum distractor 0.1463 | Host, FP32 | 6 probe images and queries |
| 2026-08-07 | Brute-force vector query (scan, sort and slice only) | 3.40 ms at 1,000 vectors; 8.07 ms at 10,000 | Host, random unit vectors | Median of 5 runs |
| 2026-09-08 | Model load / first inference (excluding preprocessing) | Image 939 / 251 ms; text 1,822 / 82 ms | Phone, FP32 CPU | One cold sample each |
| 2026-09-08 | Indexing time per photo | 2,366 ms (first 40 photos); 1,813 ms (first 100) | Phone, FP32 CPU, with screen mirroring | 40 and 100 photos, different image mixes |
| 2026-09-08 | Phone vs host embedding parity | Text and image cosine 1.0 (max abs difference 1.2e-7 and 2.67e-7); 5 more stored image vectors ≥ 0.9999999999966 | Phone vectors vs host recomputation, FP32 | 2 text queries, 1 + 5 image rows |
| 2026-09-09 | Judged retrieval quality | "a dog": P@5 0.20, nDCG@5 0.438. "a car": P@5 0.40, nDCG@5 0.345 | Phone library of 1,916 photos, FP32 | **2 queries** (20 and 21 judgments, private and non-exhaustive) |
| 2026-09-10 | SFace numerical check on Android | Cosine ≥ 0.99999638 against the reference | Phone, SFace FP32 | 4 synthetic fixtures; parity only, not recognition accuracy |
| 2026-10-22 (read from a backup) | People review gate, fresh round (its own date is not recorded) | Passed: 0 false joins and 16 true joins on held-out pairs; threshold ≈ 0.462 | Phone, SFace FP32, pairs judged by the user | 60 calibration + 20 validation pairs; only 4 "different" pairs in the holdout |
| 2026-10-22 | People processing pass | 1,431 photos in about 20 minutes (about 1.2 photos/s) | Phone, SFace FP32, app in the foreground, screen on, charging | One run |
| 2026-10-22 | Faces large enough to compare (FaceContract v1, 100 px) | 397 of 2,642 detected faces | Phone, all 1,916 photos processed | One library |
| 2026-10-22 | People re-scan under FaceContract v2 | All 1,916 photos; about 1,889 of them in under 32 minutes (about 1.0 photo/s) | Phone, SFace FP32, app in the foreground, screen on, charging | One run |
| 2026-10-22 | Faces large enough to compare (FaceContract v2, 64 px) | 864 of 2,642 detected faces (about 33 %); all 2,642 earlier faces kept | Phone, all 1,916 photos re-scanned | One library |
| — | Face-grouping accuracy | **Never measured** | — | Covers the 266 + 85 automatic assignments made on 2026-10-22 |

Never measured (ledger §10): end-to-end query latency on a phone, full-library indexing, peak memory, anything with
FP16 on Android, face recognition accuracy, offline and cloud speech accuracy, and a release-signed install.

## Getting started

### Prerequisites

- Flutter 3.44.7 (stable) with Dart 3.12.2. Keep `pubspec.lock`.
- The Android SDK and NDK that Gradle and the plugins ask for; the Android build targets JVM 17.
- An arm64 Android phone for real use. The ONNX Runtime plugin ships native libraries for arm64-v8a and
  armeabi-v7a only, so x86_64 emulators cannot run the models.
- Python 3.12 for the backend (in its own virtual environment) and Python 3.11 for ModelKit.
- The whole repository: the app's tokenizer tests read fixtures from the sibling `model_kit/` folder.

### Build and test the app

```sh
cd pixelsearch_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/
flutter build apk --debug
```

`flutter test --dart-define=SFACE_MODEL_TEST=true` adds the test that runs the real SFace model; it needs a native
ONNX Runtime library on the host.

Upgrade an installed debug build in place with `adb install -r` and the same signing key. A release-signed build
cannot replace a debug-signed install in place. Release builds need an operator-supplied keystore; see
[ANDROID_RELEASE_SIGNING.md](pixelsearch_app/docs/ANDROID_RELEASE_SIGNING.md).

### Repository, ModelKit and backend checks

```sh
python tool/check_repository.py
cd model_kit && python eval/test_metrics.py
```

The backend tests need the project virtual environment (a newer system Python with an older `starlette` fails at
collection):

```sh
cd enhancement_backend
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt -c requirements.lock    # Windows; use .venv/bin/python elsewhere
.venv/Scripts/python -m pytest -q
```

### Model provisioning (debug builds)

The MobileCLIP files are not in the repository and are not downloaded by the app. Copy them in by hand. This works
only on debug builds, because `run-as` fails on a release build. The MobileCLIP weights are Apple's, under the Apple
Machine Learning Research Model License (non-commercial research and academic use; redistribution only with the
agreement): see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md#mobileclip-s1-apple) before sharing
an export or an app build that contains one.

1. Generate the exports. From `model_kit/`, install `requirements.txt` and run `python prepare_model.py`. It
   downloads the weights and writes the FP32 files `mobileclip_image.onnx` and `mobileclip_text.onnx` (and FP16
   files) to `model_kit/out/`.
2. Copy **only the two FP32 files**. Run these from the repository root. On Windows use PowerShell; in Git Bash,
   set `MSYS_NO_PATHCONV=1` first, or every `/data/...` argument is rewritten into a Windows path:

   ```sh
   adb push model_kit/out/mobileclip_image.onnx /data/local/tmp/
   adb push model_kit/out/mobileclip_text.onnx  /data/local/tmp/
   adb shell chmod 644 /data/local/tmp/mobileclip_image.onnx /data/local/tmp/mobileclip_text.onnx
   adb shell run-as com.pixelsearch.pixelsearch mkdir -p files/models
   adb shell run-as com.pixelsearch.pixelsearch cp /data/local/tmp/mobileclip_image.onnx files/models/
   adb shell run-as com.pixelsearch.pixelsearch cp /data/local/tmp/mobileclip_text.onnx  files/models/
   adb shell rm /data/local/tmp/mobileclip_image.onnx /data/local/tmp/mobileclip_text.onnx
   # remove any leftover FP16 files
   adb shell run-as com.pixelsearch.pixelsearch ls files/models
   adb shell run-as com.pixelsearch.pixelsearch rm -f files/models/mobileclip_image_fp16.onnx files/models/mobileclip_text_fp16.onnx
   # the device and host hashes must match (on Windows, use Get-FileHash for the host files)
   adb shell run-as com.pixelsearch.pixelsearch sha256sum files/models/mobileclip_image.onnx files/models/mobileclip_text.onnx
   sha256sum model_kit/out/mobileclip_image.onnx model_kit/out/mobileclip_text.onnx
   ```

3. Start indexing again in the app. Nothing notices new model files automatically.

> [!WARNING]
> **Never provision `*_fp16.onnx` to a device.** The model resolver prefers FP16 when the file is present, but FP16
> has never been accepted on Android and no execution provider for it is registered. Text model selection has no
> fallback, and embedding rows do not record precision, so FP16 and FP32 vectors would mix silently. The app's
> missing-model status line lists the FP16 file names first, and some older documents say to ship FP16; follow
> neither.

The full procedure, with the reasons behind each step, is in
[docs/PROJECT_CONTEXT.md §5.1](docs/PROJECT_CONTEXT.md#51-first-run-and-model-provisioning).

### Device safety

> [!CAUTION]
> **Never uninstall the app, clear its data, or run a bare `flutter test integration_test/... -d <device>` against
> a phone with a real index.** Flutter uninstalls the app after an integration test. On 2026-09-08 this destroyed a
> 144-photo private index, which could not be recovered (KI-12).

For device evaluation, use `pixelsearch_app/tool/run_search_evaluation.ps1`. It is written for Windows and needs
PowerShell 7; pass `-Flutter` and `-Adb` if your Flutter and adb paths differ from its defaults:

```sh
pwsh -File pixelsearch_app/tool/run_search_evaluation.ps1 -Device <serial>              # backup, test, reinstall
pwsh -File pixelsearch_app/tool/run_search_evaluation.ps1 -Device <serial> -BackupOnly  # backup only
```

Force-stop PixelSearch first; the script refuses to run while the app is running. It backs up the app's data into
the git-ignored `pixelsearch_app/local_evaluation/`, runs the test with `--no-uninstall`, then rebuilds and
reinstalls a debug APK in place. Only its backup-only mode has been exercised on a device. The in-app search
diagnostics are the other safe option.

## Testing and CI

- **Host tests.** The newest recorded full run is **535 passed, 1 skipped** (`flutter test --no-pub test/`,
  Windows host, 2026-10-22, at the tip of the branch `review-ready-2026-10-22`, after the KI-16 fix and
  FaceContract v2). The skipped test runs the real SFace model and needs `--dart-define=SFACE_MODEL_TEST=true`.
  `flutter analyze` reported no issues on 2026-10-22. History:
  [ledger §8](docs/EVIDENCE_LEDGER.md#8-test-count-history) and [TEST_PLAN.md](pixelsearch_app/docs/TEST_PLAN.md).
- **Backend.** 51 passed (project virtual environment, Python 3.12; 2026-10-21 and again 2026-10-22).
- **ModelKit.** The metric tests passed (2026-10-22).
- **CI.** [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs four jobs on Ubuntu for pushes to `main`
  and for pull requests: the repository check, the backend tests, Flutter analyze and unit tests, and the ModelKit
  metric tests. CI never builds an APK and never runs `integration_test/`, the real SFace model test or the FP16
  conversion test.
- **CI is not green yet.** Every push from 2026-09-09 to 2026-09-18 failed (four runs). On the last pushed commit
  only the Flutter job failed, with 3 of 328 tests failing on the Linux runner while the same commit passed on
  Windows. A simulation on the Windows host reproduced the failure counts and traced them to two host-dependent
  test problems (KI-17), both fixed on the branch on 2026-10-22: widget tests loaded a Windows system font as
  "Roboto" (on Linux the wider fallback font made 320 px layouts overflow), and one test built Windows-only path
  literals. The fix has not yet run on Linux: the branch has not been pushed, and a local Linux run in Docker did
  not start. It is therefore not yet confirmed that the fix explains all three failures, and this README shows no
  CI badge.
- **Parity.** Host Flutter-ONNX Runtime parity has not been re-run since commit `a76d3b6` (2026-08-08), which
  changed how preprocessing reads pixels.

## Optional backend

`enhancement_backend/` is a small, stateless FastAPI service that the operator deploys for their own installs (a
`render.yaml` for the Render free plan is included). The app does all searching itself; the backend is not a
gallery or a vector database.

- Endpoints: `GET /health`, `POST /caption`, `/rewrite`, `/assistant` and `/transcribe`.
- Each install has its own bearer token; the server stores only SHA-256 hashes of the tokens. Ten requests per
  minute per token.
- Pinned models: `qwen/qwen3.6-27b` (a preview model on Groq) and `whisper-large-v3-turbo`. No automatic retry, no
  paid fallback and no model substitution. Model requests return 503 unless the operator has set the provider key
  and attested that Groq zero data retention is enabled.
- The 2026-09-18 hardening (authentication and size checks before the request body is read, a 6 MiB body cap,
  request and provider deadlines) is in this repository but **not deployed**. The deployment last checked, on
  2026-09-09, ran older code.
- FastAPI's default `/docs`, `/redoc` and `/openapi.json` routes are enabled and unauthenticated in the code.

Setup, API and limits: [enhancement_backend/README.md](enhancement_backend/README.md).

## Limitations and known issues

- **Search quality is uncalibrated.** On the private 1,916-photo library, a photo judged relevant for "a dog" has
  a lower MobileCLIP cosine (about 0.1625) than two photos judged irrelevant (0.1687 and 0.2073; computed on the
  host from the phone's stored FP32 vectors, 2026-09-08), so no gate value can fix that ordering. The cause is classified
  as a model limitation (partial evidence).
- **Folder deselection** keeps already-indexed photos visible and searchable. Folder scope controls scanning only;
  it is not a privacy control.
- **Change detection** uses the modification time only, and assets that fail to decode (HEIC is expected to fail)
  are retried on every run.
- **Person search** counts only faces assigned to a person in processed photos (KI-14). Faces too small for a
  descriptor must be named by hand.
- **Map and details.** The viewer's details GPS is always empty on Android 10 and later; the map uses a separate
  EXIF scan.
- **A text model session leaks** each time the search backend is rebuilt after an indexing run.

Full lists: [pixelsearch_app/docs/KNOWN_ISSUES.md](pixelsearch_app/docs/KNOWN_ISSUES.md) (a dated note at the
top names its stale entries; KI-16 is fixed in code, and KI-17, the Linux-only CI failures, is fixed on the branch
pending a Linux run) and the prioritized register in
[docs/PROJECT_CONTEXT.md §9](docs/PROJECT_CONTEXT.md#9-known-issues-register).

## Roadmap

From [docs/PROJECT_CONTEXT.md §12](docs/PROJECT_CONTEXT.md#12-next-steps-highest-priority-first), with the
2026-10-22 changes applied:

1. Confirm the CI fix on GitHub's Linux runner.
2. Deploy the backend hardening and verify the live service.
3. Re-run host Flutter-ONNX Runtime parity for the current preprocessing code, and add a PIL-generated
   preprocessing fixture to ModelKit.
4. Make model selection safe before any FP16 work: load-tested text selection with an FP32 fallback and precision
   recorded per embedding. Only then try an FP16-capable execution provider and accept it against FP32 on a phone.
5. M12 model provisioning (at least in-app guidance when models are missing), then indexing that survives screen-off
   and a worker isolate for decoding and inference.
6. A judged retrieval benchmark (20 to 50 scene queries with a held-out set) before any change to the gate, the
   weights or the lexical policy. Judgments stay private, because they name private photos.
7. People: the FaceContract v2 build is installed and every photo re-scanned (2026-10-22). Next: the user's larger
   review round under v2, which turns automatic grouping back on if it passes; then measure grouping accuracy, and
   check suggestion confirm/reject, the "Same person?" rounds and voice person queries on the phone.
8. Refresh the stale documents and write the missing architecture decision records.

## Repository layout and documentation

| Path | Contents |
|---|---|
| `pixelsearch_app/` | Flutter app: `lib/`, `test/`, `integration_test/`, `android/`, app docs in `pixelsearch_app/docs/` |
| `model_kit/` | Model export, contracts (`INTERFACE_CONTRACT.md`, `FACE_CONTRACT.md`), parity references, metrics |
| `enhancement_backend/` | Optional FastAPI broker and its tests |
| `tool/` | Repository publication check |
| `docs/` | Documentation index, project handbook, evidence ledger, file map, security review, archive |
| `render.yaml` | Optional backend deployment blueprint |

Start with the [documentation index](docs/README.md). It has a 15-minute reading path for reviewers, the
contracts, the dated evidence records and the engineering history. Contributors should read
[CONTRIBUTING.md](CONTRIBUTING.md).

## Team and credits

A four-member student team (final-year undergraduate project). Names are withheld until every member agrees to be
listed.

**Acknowledgements.** PixelSearch builds on:

- [MobileCLIP](https://github.com/apple/ml-mobileclip) (Apple) for the image and text encoders.
- [CLIP](https://github.com/openai/CLIP) and [OpenCLIP](https://github.com/mlfoundations/open_clip) for the
  model family, the byte-pair tokenizer and the export path.
- [OpenCV Zoo SFace](https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface) for face
  descriptors (Apache 2.0; the licence is bundled with the model).
- [Google ML Kit](https://developers.google.com/ml-kit) for face detection and image labels.
- [ONNX Runtime](https://onnxruntime.ai/) for on-device inference.
- [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors for map data and tiles.
- [Manrope](https://fonts.google.com/specimen/Manrope) (SIL Open Font License) for the app's typeface.
- [Flutter](https://flutter.dev/) and the Dart package ecosystem.

**AI assistance.** Parts of the code and documentation were written with an AI coding assistant (Claude).

## Licence

All rights reserved; the code is published for academic evaluation. See [LICENSE](LICENSE). Third-party
components keep their own licences; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

To cite this project, see [CITATION.cff](CITATION.cff).
