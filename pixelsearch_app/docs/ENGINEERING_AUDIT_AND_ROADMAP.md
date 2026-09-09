# Engineering Audit and Prioritized Roadmap

**Audit date:** 2026-09-08

**Scope:** current `main` at `a76d3b6be7232cc54c39c40c8bb15c4fd2899b`

**Rule:** Source evidence wins over documentation. Device outcomes remain device-only until recorded.

## Current Baseline

**Later device follow-up, same day:** the baseline below records the pre-device audit.
A connected Vivo I2214 subsequently passed FP32 model loading/inference, discovery of all
19,260 MediaStore images, 140 saved photos with labels and thumbnails, cold restart and
incremental resume (103 already indexed photos skipped), and displayed semantic search.
The current app uses CPU execution; no NNAPI/XNNPACK provider is registered. Full-library,
sustained-performance, background, retrieval-quality, and FP16 acceptance remain open.
See [the device report](ANDROID_SMOKE_TEST_2026-09-08.md) for measured results and limits.

| Check | Result | Status |
|---|---:|---|
| `flutter analyze` | No issues, 117.8 s | VERIFIED on this checkout |
| `flutter test` | 58 passed | VERIFIED on this checkout |
| Android debug APK | Built successfully in 28.1 s after this iteration | VERIFIED on this checkout |
| Real-ORT parity integrations | Fixture resolver is portable; no supported runner is configured locally | PARTIAL: Windows desktop project absent and no Android device attached |
| Full Android gallery and search acceptance | Requires real-device evidence | UNVERIFIED |

The Android build still warns that several plugins apply the Kotlin Gradle Plugin
and may require migration for a future Flutter release. The current build passes.

## Verified Runtime Map

```text
Foreground UI
  Onboarding / Search / Settings
    -> IndexingController
      -> runDeviceIndexing (permission + model selection)
        -> buildDeviceIndexingService
          -> PhotoManagerGallerySource (MediaStore via photo_manager)
          -> AssetProcessor
             -> originBytes
             -> EXIF metadata
             -> pure-Dart JPEG decode
             -> thumbnail JPEG write
             -> exact MobileCLIP preprocessing
             -> ONNX image embedding
             -> ML Kit labels + face detection
          -> Drift / SQLite photo + embedding batch commit

Search UI
  query (300 ms debounce)
    -> CLIP BPE tokenizer
    -> ONNX text embedding
    -> BruteForceVectorIndex cosine candidates
    -> HybridScorer (semantic + lexical metadata + face intent)
    -> ranked Photo grid
```

### Runtime-Path Classification

| Path | Classification | Evidence |
|---|---|---|
| Foreground indexing | Real production path, device acceptance pending | `IndexingController` -> native bridge -> `IndexingService` |
| M1 80-photo gallery loader | Removed legacy path | Deleted in commit history; regression test indexes 1,500 assets |
| Synthetic `photo`/`portrait`/date tags | Removed legacy path | Current rows map ML Kit `labelsJson` to `Photo.labels` |
| Semantic search | Real production path when a text model is provisioned | `SemanticSearchBackend` in providers/UI |
| Keyword search | Intended fallback for web/missing/unusable text model | `KeywordSearchBackend` |
| WorkManager background path | Callback is registered; work is still unscheduled | Android-only bootstrap calls `Workmanager.initialize`; no UI schedules a task |
| Model manager | Partial | Resolver exists; provisioning/downloader UI does not |
| Real-ORT host integration tests | Partial | `ModelKitPaths` defaults to sibling `model_kit` or `PIXELSEARCH_MODELKIT`; this checkout has no supported runner |

## Performance Diagnosis

The user-reported sluggish phone behavior has a source-supported cause: the
foreground indexing path executes its CPU-heavy stages on the app isolate.
`AssetProcessor` performs full-resolution pure-Dart decode, thumbnail encoding,
exact antialiased MobileCLIP preprocessing, and a synchronous `OrtSession.run`
in one sequential per-photo flow. ML Kit follows in that same flow.

Recorded device profiling on Realme RMX3092 / Android 12, over 40 images around
1200x1600, shows the sequential stages total 1,694 ms/photo after the existing
decode-once improvement:

| Stage | Recorded time/photo | Interpretation |
|---|---:|---|
| `originBytes` | 75 ms | I/O overhead |
| EXIF | 1 ms | Not a bottleneck |
| JPEG decode | 465 ms | CPU-heavy and resolution-sensitive |
| Thumbnail | 31 ms | Secondary |
| Preprocess + ONNX | 660 ms | Largest combined stage |
| ML Kit labels + faces | 462 ms | Major native compute stage |

This establishes a real bottleneck, not an assumed one. It does **not** prove
that every proposed concurrency change improves phone responsiveness; such
changes require device profiling before and after.

## Semantic Retrieval Diagnosis

The current search architecture is semantic-first, not label-first:

1. CLIP text embedding retrieves up to 60 cosine neighbors.
2. Neighbors below cosine 0.15 are removed.
3. Lexical metadata hits are unioned with semantic candidates.
4. Hybrid ranking applies 0.70 semantic, 0.25 lexical, and 0.05 face-intent
   weight.

ML Kit labels can affect final order but do not replace semantic candidate
retrieval. The architecture can still weaken sentence-level behavior when a
query's correct image is below the top-60 semantic candidate set, below the
0.15 gate, or receives a strong lexical boost for a partial concept. The current
six-image parity corpus cannot distinguish these hypotheses. Do not retune
weights, gate, or preprocessing until the device checklist supplies a labeled
failure set.

## Prioritized Roadmap

### P0 - Establish a Trustworthy Android Baseline

**Problem:** Current documentation conflicts on test counts, device verification,
and FP16 status.

**Root cause:** The source, changelog, and benchmark documents evolved at
different times; device tests were not captured as a repeatable acceptance run.

**Evidence:** Current test run is 58 passed, while docs contain older 46/49
counts. `DEVICE_TEST_CHECKLIST.md` did not previously exist.

**Proposed solution:** Use the device checklist on a full-permission device run,
record discovery/plan/SQLite/progress counts and semantic-query evidence, then
turn representative failures into regression cases.

**Files/components affected:** Documentation, device logs, future test fixtures.

**Risk:** Low. This changes no behavior.

**How to verify:** Completed checklist plus logs and screenshots.

### P0 - Repair the Production Model Path

**Problem:** The source conversion defect is repaired in artifact v3, but no
automatic model provisioning or Android fp16 acceptance evidence exists.

**Root cause:** `onnxconverter_common` produced invalid Cast metadata. The new
ModelKit converter validates graph structure and Cast types, while Flutter still
only bundles the BPE vocabulary and expects ONNX files in application-support storage.

**Evidence:** KI-9; both v3 graphs pass `onnx.checker`, the image graph now
creates a CPU session, and the ModelKit regression suite passes. CPU cannot
validate target fp16 inference.

**Next solution:** Install v3 on Android, run image/text load and numerical
parity checks, then implement a single provisioning flow shared by
foreground/background work.

**Files/components affected:** ModelKit exporter/artifacts; `ModelLocator`;
future M12 provisioning UI.

**Risk:** High compatibility risk. Any preprocessing/model-weight change must
bump `embedding_version` and re-index. A numerically identical artifact change
must not silently change embeddings.

**How to verify:** Graph load, parity gate, device model-selection log, and
fresh/incremental indexing on Android.

### P0 - Make Indexing Responsive Before Making It Faster

**Problem:** Foreground indexing makes the phone feel hung.

**Root cause:** Heavy pure-Dart CPU work and synchronous ONNX inference run in
the foreground flow. Current code has no explicit worker isolate for that path.

**Evidence:** `AssetProcessor`, `preprocessForClip`, and `OrtSession.run` source;
recorded 1,694 ms/photo profile; TD-17 and TD-18.

**Current iteration:** Cooperative yielding between assets, configurable profiling, and deterministic native
resource disposal are implemented and compile/test verified. They are not a substitute for a worker strategy:
the measured CPU work within one asset is unchanged.

**Next solution:** Measure the current behavior on device, then design a bounded worker strategy
only after measuring interaction latency and memory. Keep one or two model
sessions at most until device memory proves more is safe. Do not replace the
frozen preprocessing with a lower-resolution thumbnail without explicit model
versioning and re-index policy.

**Files/components affected:** `IndexingService`, `AssetProcessor`, indexing
config/progress, diagnostics and tests.

**Risk:** Medium to high. Dart isolate/plugin behavior and duplicate ONNX session
memory must be validated on a device.

**How to verify:** Same-gallery before/after duration, responsiveness checklist,
stage profile, peak-memory observation, cancellation, and parity regression.

### P1 - Activate Reliable Background Indexing

**Problem:** WorkManager callback registration is now present, but no current UI
schedules work. ColorOS is documented as freezing the foreground app with the
screen off.

**Root cause:** The prior missing bootstrap and inconsistent background model path
are fixed in source; scheduling policy and physical-device lifecycle verification
remain absent.

**Evidence:** `main.dart` now awaits the Android-only bootstrap and
`runBackgroundIndex()` uses `ModelLocator` candidates, but no caller invokes
`WorkManagerScheduler` to submit a task.

**Proposed solution:** Add native-safe WorkManager initialization, reuse model
candidate resolution, schedule deliberately, and test restart/reboot/screen-off
behavior. Consider a supported foreground-service/notification path only after
the basic scheduler works.

**Files/components affected:** `main.dart`, conditional native bootstrap,
`indexing_wiring.dart`, `workmanager_scheduler.dart`, Android tests/docs.

**Risk:** Medium. Background Flutter plugins and Android OEM policies require
physical-device validation.

**How to verify:** Scheduled task logs, app restart, screen off, reboot/backoff,
and persisted index progress.

### P1 - Make Semantic Failures Observable, Then Calibrate

**Problem:** Complex sentence retrieval is reported weak, but the source cannot
show whether the cause is model retrieval, the 0.15 gate, top-60 truncation, or
hybrid lexical reranking.

**Root cause:** The current six-item parity set validates compatibility, not
real-gallery sentence-level quality; there is no user-query evaluation corpus or
per-result score diagnostics in the UI.

**Evidence:** Device observation; current `SemanticSearchBackend` and
`HybridScorer`; documented 0.70/0.25/0.05 heuristic weights.

**Proposed solution:** Record 10-20 device queries from the checklist. Add
debug-safe explainability for semantic/lexical/face contributions and a labeled
evaluation fixture. Tune only after measuring dense-only versus hybrid results.

**Files/components affected:** Search diagnostics, tests, benchmark/evaluation
fixtures, later hybrid policy.

**Risk:** Medium. Changing weights/gates can regress simple retrieval.

**How to verify:** R1/R3 measured P@K/mAP/nDCG and a regression set of observed
complex queries.

### P2 - Repository and Test Hygiene

**Problem:** The repository contains a tracked generated Android build report,
stale test paths, stale counts, and legacy documentation.

**Root cause:** Historical handoff/demo and later production work coexist.

**Evidence:** The tracked generated `android/build/reports/problems/problems-report.html`
has been removed and real-ORT tests now use `ModelKitPaths`; a supported local
runner and stale root handoff documentation remain open.

**Proposed solution:** Keep the generated report deleted, document the portable
fixture resolver and supported-runner requirement, update stale project-status/
benchmark wording, and leave ambiguous sample assets until a release/demo
decision is documented.

**Files/components affected:** Git-tracked build report, tests, docs.

**Risk:** Low for build-report cleanup; medium for moving test fixtures.

**How to verify:** Clean checkout, analyzer/test/build, and portable host parity
command documented for this workspace.

## Constraints That Must Remain Intact

- Keep ModelKit and Flutter repositories separate; ModelKit owns artifacts.
- Preserve MobileCLIP-S1, `datacompdr`, 512 dimensions, 256px RGB/CHW
  preprocessing, tokenizer, normalization, and ONNX external contracts.
- Treat fp16 as the production target but repair it rather than hiding the
  defect behind permanent fp32 use.
- Preserve incremental reconciliation and batched transactional persistence.
- Keep semantic retrieval primary; ML Kit metadata is secondary enrichment.
- Never claim device speed or retrieval improvements without measured evidence.
