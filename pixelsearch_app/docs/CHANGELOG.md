# CHANGELOG

> **Status note (2026-10-21 audit):** The "Every photo now gets tags" best-3 label fallback described below was **removed** in `5f6f074` (committed 2026-09-09; work dated 2026-09-08). New indexing keeps labels only at confidence ≥ 0.5, otherwise none; rows indexed earlier keep any fallback labels until re-indexed. The undated performance section was measured on a Realme RMX3092 around 2026-08-08; its "23 photos/min" should read about 26. Apart from the two 2026-10-22 entries at the top (People search, then the review-ready cleanup, which supersedes the People-search entry's "minimum face size (100 px)", "schema v6" and KI-16 statements), with which entries resume, the newest entries are dated 2026-09-08; later changes are not recorded here, including the 2026-09-09 five-feature work (timeline, explainability, map, captions, voice), the enhancement backend and the speech follow-up, and the later People, security-review and redesign work. Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record.

Format based on Keep a Changelog. Dates are ISO-8601.

## [Unreleased]
### Review-ready cleanup, smaller faces (FaceContract v2) and schema v7 (2026-10-22, later)
- **Smaller faces (owner decision; ADR-023).** `FaceContract` v2 compares faces from 64 px instead of 100 px. A re-scan continues each matching earlier face (box overlap) with its id, name, assignment, "Not a face" and decisions; until a photo is re-scanned its earlier faces stay visible. Reviews under v1 cannot validate a v2 cutoff, so automatic grouping stays off ("Face settings changed") until a new review round passes; existing automatic assignments stay. The "Same person?" floor falls back to archived "same" answers while a new round is unjudged.
- **KI-16 fixed (ADR-024, schema v7).** Review rows store the reviewed photo ids; the v6 -> v7 step fills them from existing faces. `AppDatabase` and `AiContract` schema versions are 7; MIGRATIONS has the row; a migration test covers the backfill; the former skipped bug test passes.
- **Privacy and publication (owner decisions; ADR-025).** Forward redaction of personal identifiers in tests, dated reports, the archived roster and untracked docs (history unchanged); a private-data scan in `tool/check_repository.py`; deliverable folders ignored; an interim "all rights reserved, academic evaluation" LICENSE with THIRD_PARTY_NOTICES.md; in-app licences for SFace, the CLIP vocabulary, Manrope, the Material Icons font and the native ONNX Runtime; a Privacy Centre notice that ML Kit sends usage metrics to Google (required by the ML Kit terms); consented map tiles are never cached on disk.
- **CI (KI-17).** Widget tests load the bundled Manrope on every host instead of a Windows system font, and the path test builds host-rooted paths. The workflow pins ubuntu-24.04, uses a read-only token, enforces the lockfile, checks that regenerated drift code matches and, after a formatting-only commit (`f1c7f9d`, listed in `.git-blame-ignore-revs`), checks `dart format` on every non-generated Dart file. Not yet run on GitHub; the workflow runs on pushes to `main`/`master` and on pull requests, so pushing the branch alone does not run it.
- **Hygiene.** Dead code removed; the WorkManager scheduler is marked as not wired; FP16 is described as unaccepted on Android in both contract copies (dated note, no frozen value changed), the model resolver comments, the ModelKit README and `prepare_model.py`; onboarding no longer claims "under two seconds"; only listed model files are bundled; `cupertino_icons` removed; FP32-only provisioning steps in the app README.
- **Verification (Windows host, 2026-10-22).** `flutter analyze --no-pub`: no issues. `flutter test --no-pub test/`: 535 passed, 1 skipped (the SFace worker test). `tool/check_repository.py`: passed. Backend: 51 passed (project venv). ModelKit metrics: passed. Each landed commit was built and tested in a clean worktree; the suite gave the same 535 passed, 1 skipped after the formatting commits (`9bea6d4`). Debug APK built at 12:33, before `99433c5` (it lacks that commit's Material Icons and ONNX Runtime licence texts and, from the same commit, the ML Kit notice), so rebuild from the branch tip before installing. Device install and the v2 re-scan: see the evidence ledger.

### People search: assisted naming, person queries, user-requested grouping and "Same person?" confirmations and rounds (2026-10-22)
- **Person queries.** `resolvePeopleQuery` is still the only parser. Names now take a role: required (AND, the default), any-of (names joined only by "or" or commas) or excluded (after "without", "except", "excluding", "but not", "no", "neither … nor" and similar). Mixed and/or wording falls back to AND. "me" and "myself" share one self key and are not a subject after a request verb ("show me photos of X") unless coordinated or placed. Possessives, edge punctuation and fillers are stripped only in person queries; a query that names nobody passes through byte-identical. `matchPeoplePhotos` applies required ∩ any-of − excluded and fails closed. Name-only queries list the person's photos newest first without the text model, and membership comes from the cached People snapshot.
- **Assisted naming.** A "Similar faces" review orders unnamed detailed faces by their closest cosine to the person's manually named faces, one face per photo, with no threshold and no scores shown. Each face needs the user's "Add" or "Not X"; Undo restores the exact previous rows, and faces marked "Not X" are never suggested for that person again. The screen states that this is not recognition. New faces are shown newest photo first, with multi-select naming, bulk "Not a face" with Undo, and a restore screen. "This is me" belongs to one person, and the naming dialog shows who currently holds it. A person page adds "Search photos of X", "Review similar faces" and "Delete person".
- **User-requested grouping and a smaller naming list (later the same day; user decisions; ADR-020).** The same person was listed many times in New faces: on the test phone 2,006 of 2,342 detected faces are below the 100 px SFace descriptor minimum and can never be compared, and automatic grouping had never run because processing was paused. `PeopleRepository.groupNow()`, behind People ⋮ "Group similar faces" and a confirmation dialog, runs the existing validated `groupFaces` (complete-link, the saved review cutoff) once at the user's request while processing stays paused. It assigns nothing unless the review gate passed, and the automatic `applyGrouping()` after a processing pass still never runs while paused. New faces hides unassigned faces under 40 px and a second detection overlapping a larger face in the same photo (IoU > 0.5) behind "Show small faces (N)"; nothing is deleted, and they can still be named from the photo. Each unnamed group counts once in "N to name", and unnamed groups are listed largest first.
- **"Same person?" confirmations (later still the same day; user request; ADR-021).** Google-style cards ask "Is this `<name>`?" (when the left group is named) or "Same or different person?" beside two face crops (capped at 160 px, each with "Open photo") and offer No, Not sure and Yes; an entry tile on the People screen shows "N quick questions to make grouping more accurate". `buildSamePersonQuestions` (`lib/domain/people/same_person.dart`) first asks about every face automatic grouping put into a named person, shown beside a face the user confirmed for that person, then about pairs of groups (never two named people) ordered by the cosine of their closest faces, which is used for ordering only and never shown. Pairs that share a photo, pairs already answered No or Not sure, and pairs less alike than the lowest-scoring review pair the user judged "same" are not asked; that floor selects questions and never decides identity. `PeopleRepository.samePersonQuestions` is read-only. `answerSamePerson`: Yes confirms an automatic face as a manual assignment or merges the second group into the named (or larger) one; No unassigns the face or keeps the groups apart, recorded as `reject` decisions so they are never suggested or regrouped together; Not sure stores a new decision value, `unsure`, in the existing `people_decisions` table (no schema change), which grouping and suggestions ignore, which never overwrites an earlier decision and which a later explicit naming replaces. A stale question (a person gone, or a compared or automatic face that has left its person) fails closed and writes nothing; answers stay on the device and never resume processing. Questions only cover faces with an SFace descriptor (at least 100 px).
- **"Same person?" rounds on the main screen (later the same day; user request; ADR-022).** Questions now come in rounds of 20 per app launch and are never repeated, as in Google Photos' face-group prompts (sources in ADR-022). The Search home shows one question at a time in a "Help improve face groups · k of N" card, answered in place, with "Not now" (hidden until the next launch) and "Open full screen". The full screen shows "Question k of N" and, after a round, "Keep going (20 more)". Answer buttons (and "Open full screen") stay disabled while an answer saves, through a flag shared by the prompt and the full screen, and until the next question has loaded; if that reload fails, no question is shown. At the user's choice, only pairs at or above the floor are asked. A name-only search now says "Matched by assigned faces" in the results header tooltip instead of "Matched by on-device semantic search".
- **Review fixes for grouping and "Same person?".** An independent review confirmed 14 issues; all are fixed. A Yes to two groups now confirms only the two faces compared, and other automatically grouped faces stay automatic and can be asked about. A carried-over reject replaces an earlier Not sure. The grouping run advances the generation, creates a person row only after a face joins it, and holds the processing lease. Face-size estimates follow the decoder's power-of-two scaling. Duplicate detections stay hidden after grouping. Questions are built off the UI isolate above 20,000 pairwise comparisons. Grouping copy states the holdout sizes. The answer buttons sit in a fixed bottom bar. "Group similar faces" has a busy guard. The small-or-duplicate set is computed once per People snapshot. A second verification pass over the final code and docs (each finding checked by a skeptic) found three more code issues, fixed with tests that fail without the fix: answering the same pair twice through "Open full screen" while a save is running, an answered pair shown again after a failed reload, and a group-pair answer that did not check that the compared faces were still in their groups.
- **Search screen.** Person chips ("You", name, "either X", "not X"), a People filter chip (All of them / Any of them), and empty states that explain the result: no "This is me" person ("Which person is you?" with "Open People" and 'Search without "me"'), People off, no assigned photos, not together, everyone excluded, none within the filters, and no scene match. Spoken punctuation is removed before a local search.
- **Privacy.** The online guard checks every saved name, hidden people included, and blocks any query with a person filter, a person mention, "or" or "without". Online payloads never include person ids. Hidden people are not matched from typed text; "me" still resolves to a hidden This-is-me person.
- **Safety fix.** `AppDatabase.deleteAssets` now keeps the review pairs of a deleted reviewed photo, so calibration fails closed ("A reviewed photo changed or is unavailable. Start a new review.") instead of re-scoring the remaining pairs and possibly passing the gate.
- **Unchanged.** Suggestions never assign a face without the user's explicit confirmation of that face, and no new code resumes processing (the user resumed it with the existing button); the only new automatic assignment path is the user-requested `groupNow()` above, and "Same person?" answers change assignments only on the user's Yes or No. The grouping and calibration rules (`groupFaces`, `calibrateFaces`), `FaceContract`, the minimum face size (100 px), the ranking constants (top-K 60, gate 0.15, weights 0.70/0.25/0.05), the CLIP model and schema v6 are unchanged; there is no schema change.
- **Verification (Windows host, 2026-10-22).** `flutter analyze --no-pub`: no issues. `flutter test --no-pub test/`: 526 passed, 2 skipped after the rounds and all review fixes (512 + 2 on the first "Same person?" build, which added 13 tests in `test/people_same_person_test.dart`, now 24; 499 + 2 before it; 496 + 2 before the grouping change; 372 + 1 on 2026-10-21). `tool/check_repository.py` passed. The debug APK builds (versionCode 1) and its signer matches the installed app. An independent review of the first implementation found 24 issues; the fixes are included.
- **Device acceptance (Vivo I2214, API 36, 2026-10-22; aggregate).** Driven over adb through the accessibility tree at the user's request, with no screenshots and no identity decisions by the assistant. In-place `adb install -r`: firstInstallTime and signature unchanged, installed binary identical to the built APK, and backups before and after the first launch identical in every table. Eight typed person queries (not together, name only, scene miss, trailing full stop, request verb, "without me", "or", "me") matched the counts expected from the backup; the hidden-person flow and restart persistence passed; similar-face suggestions were only viewed. At the user's request "Group similar faces" assigned 266 faces automatically: 3 joined one named person and the rest formed 137 new unnamed groups (142 groups in total). New faces went from 2,329 face entries to 1,402 to name, with 798 small or duplicate faces behind "Show small faces". Only the People faces and persons tables changed, and processing stayed paused. Two more builds, for "Same person?", were installed in place with `adb install -r`, each after a fresh backup; the database tables in the backup after the grouping run and in both later backups are identical (viewing the questions writes nothing). The tile read "122 quick questions": 3 about the faces grouping added to a named person and 119 group pairs at or above the user's lowest "same" review score (about 0.398). The first card asked whether an automatically added face is that named person. The assistant answered no question. The user then named faces and answered the questions on the device (142 to 127 groups, 35 manual assignments, 736 rejects; "photos of me with" a named person then returned 2 results). The rounds build was installed in place (backups before it identical; no question left). At the user's choice People processing was resumed: all 1,916 photos were scanned in about 20 minutes (about 1.2 photos per second, app open), faces went from 2,342 to 2,642 and descriptors from 336 to 397, and the validated automatic grouping assigned 85 more faces (127 to 152 groups, none added to a named person; manual assignments, decisions, reviews and threshold unchanged). The phone then offered 70 questions and showed "Help improve face groups · 1 of 20" on the main screen. Three more builds with the later fixes were installed in place (nine installs in all), each after a backup: the second of those backups is identical to the first in every table, and the third differs only by one processing-lease row. Confirming or rejecting suggestions and voice input were not exercised on the device. See `PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`. Known limits: KI-14, KI-15 and KI-16 in `KNOWN_ISSUES.md`.

### Scene retrieval diagnostics (2026-09-08)
- Added raw cosine versus unchanged production ranking, score breakdowns, candidate/gate sweeps, a non-default whole-word lexical experiment, 24 unlabelled queries and private relevance-feedback JSON. No default weights, model, embedding version or indexing behavior changed.
- Host verification: analyzer clean and 93 tests pass. No quality improvement is claimed without user judgments. See `SEARCH_EVALUATION.md` and `SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md`.
- Device-test incident: Flutter's default post-test uninstall removed the existing 144-photo private index and models. Original gallery photos were untouched. App/models were restored with identical model hashes; the index was not recovered and the user will select folders to rebuild it. A backup-first `--no-uninstall` wrapper was added; full corrected device evaluation remains pending.

### Folder-scoped indexing (2026-09-08)
- Every foreground Index/Re-index action now opens a folder picker with checkboxes, photo counts, an explicit All folders option, and saved selection. Duplicate Android folder names include relative paths. No choice is preselected on first use.
- Folder IDs and all-folders mode persist in a new schema-v4 preferences table; background indexing reads the same preference. Existing photos/embeddings survive migration unchanged.
- As requested, deselected folders' indexed photos remain searchable. Reconciliation separates selected candidates from gallery-wide existence metadata; original photo bytes are loaded only for selected candidates. Limited photo access disables missing-photo deletion, and unavailable selected folders never fall back to indexing everything.
- Permission requests/checks now explicitly use images, avoiding a false limited-access state caused by checking unrequested video access.
- See `FOLDER_INDEXING.md` for behavior, verification, and limits. Model artifacts, preprocessing, embedding version, ML Kit and search ranking are unchanged.

### Android provisioning smoke test (2026-09-08)
- Manually provisioned both FP32 models on Vivo I2214/API 36 and verified their SHA-256 checksums. Both image and text inference ran with 512-d, unit-normalized outputs. The current app configures CPU execution; NNAPI/XNNPACK is not registered.
- Discovered 19,260 photos, matching MediaStore; indexed 103 before intentional cancellation. After USB reconnection and a cold app restart, reconciliation skipped those 103 and added 37 more before a second cancellation: 140 saved photos with labels, thumbnails, and embeddings; zero failures. The same full-sentence semantic query displayed 118 results, and the photo viewer displayed ML Kit labels. Full completion and retrieval-quality scoring remain untested.
- Verified SQLite integrity and all 140 vector shapes/norms, removed temporary model transfer copies, and recorded that onboarding reappears after a cold restart despite the saved index. No source fix was attempted during this test.
- Recorded measured timings, database checks, and limits in `ANDROID_SMOKE_TEST_2026-09-08.md`. Application code and ranking policy were unchanged.

### Current engineering iteration (2026-09-08)
- **Verified on this checkout:** `flutter analyze` reports no issues, `flutter test` passes **58** tests, and the Android debug APK builds successfully. Real-ORT tests now resolve the sibling `model_kit` checkout by default or honor `PIXELSEARCH_MODELKIT`; this Windows checkout has no desktop project and no Android device attached, so their fresh execution remains pending a supported runner.
- **FP16 artifact repair:** ModelKit v3 replaces the invalid `onnxconverter_common` conversion with ONNX Runtime's converter, topological sorting, ONNX checking, and explicit Cast-type validation. Both rebuilt graphs pass the checker, the image graph creates a CPU session, and the ModelKit regression suite passes. The desktop custom-image tester now deliberately uses its verified fp32 CPU path; Android NNAPI/XNNPACK fp16 inference and parity are still device work.
- **Foreground responsiveness:** `IndexingService` now yields once between assets. This gives Flutter an opportunity to paint, deliver progress, and process a cancel action before the next photo begins. It deliberately does not change the frozen MobileCLIP preprocessing, per-photo ordering, or transactional persistence, and it does not remove the measured synchronous work within one asset.
- **Native resource lifecycle:** the device composition root now disposes ML Kit detectors and the ONNX image session after an indexing service is disposed. Profiling cadence is configurable; automated tests disable profile log emission while the device default remains every 20 assets.
- **Background bootstrap:** Android startup now registers the existing WorkManager callback through a conditional native boundary, and the background path uses the same fp16-then-fp32 load-and-fallback policy as foreground indexing. No job is scheduled automatically yet; screen-off, retry, and OEM behavior remain physical-device validation work.
- **Repository hygiene:** removed the tracked generated Gradle problems report.

### Performance — indexing throughput (measured on device, Realme RMX3092 / Android 12)
First on-device profile of the M5 pipeline, per stage, over 40 assets at ~1200x1600:

| stage | before | after |
|---|---|---|
| loadBytes | 75 ms | 75 ms |
| exif | 1 ms | 1 ms |
| JPEG decode | ~850 ms (**decoded twice**) | **465 ms (once)** |
| thumbnail | 494 ms | **31 ms** |
| embed (preprocess + ONNX) | 845 ms | **660 ms** |
| ML Kit (labels + faces) | 493 ms | 462 ms |
| **total** | **2325 ms/photo** | **1694 ms/photo** |

**1.37x (23 → 35 photos/min).** Per-photo cost scales with resolution — the same build measures
~1956 ms on 12 MP frames — so quote throughput with the resolution. Changes, all embedding-preserving:
- **Decode once per photo.** `AssetProcessor` now decodes and hands the same `img.Image` to the thumbnail
  and embed stages; `ThumbnailGenerator`/`AssetEmbedder` take a decoded image instead of bytes. Both stages
  previously decoded the same JPEG independently. ML Kit still receives the original bytes.
- **TD-9 paid down.** `preprocessForClip` reads the packed RGB buffer instead of calling `getPixel` for every
  one of w×h pixels. Same uint8 samples, same Float64 accumulation, **fingerprint unchanged**
  (`sum=100051.464714 a=0.623529 b=0.207843 c=0.956863`) — embeddings are bit-identical.
- **ONNX intra-op threads** set to half the cores (clamped 1–4); the session was single-threaded on an
  8-core device. Affects only summation order inside the graph.

Deliberately **not** done, to protect quality: face detection still runs on every photo (it feeds M6
people-query ranking), and full-resolution decode is retained rather than substituting a native downscaled
thumbnail — that would change the pixels CLIP sees (TD-18, needs an `embedding_version` bump + re-index).
### Fixed
- **Every photo now gets tags.** ML Kit labelling used a hard 0.5 confidence floor, so photos where nothing
  cleared it were stored with *no* labels — measured at **5 of 800 (0.62%)** on a real library, mostly
  screenshots and documents, leaving them unsearchable by keyword. `selectLabels` keeps the ≥0.5 set exactly
  as before and, only when that set is empty, falls back to the best 3 candidates. ML Kit is queried once at
  the lower floor and the threshold is applied in Dart, so there is **no extra inference**. Confident photos
  are bit-identically labelled. Re-measured on device: **0 of 512 newly-indexed photos unlabelled (0.00%)**,
  with fallbacks like `["Paper","Screenshot","Poster"]`. 5 new unit tests.
- **M5 indexing is now actually on the app's path — the two reported integration bugs.** The app was still
  running the M1 demo loader (`lib/data/device_gallery*`), so the completed M5 pipeline was never invoked:
  `buildDeviceIndexingService`/`IndexingService.run()` had no caller outside tests. Symptoms and causes:
  **(1) only ~80 photos imported** — the demo loader hard-capped at `load({int limit = 80})` and issued a
  single `getAssetListRange(0, 80)`; the real `PhotoManagerGallerySource` already paginates the whole
  gallery (`getAssetListPaged`, 500/page) and `IndexingService` has no cap at all.
  **(2) labels were `photo`/`portrait`/`landscape`/`<year>`** — those were synthesized by the demo loader's
  `_deriveTags()` from EXIF dimensions and dates; ML Kit's real labels were being persisted to
  `photo_rows.labelsJson` by `IndexStore` all along, but nothing read them back onto the display path.
  **No file under `lib/indexing/**` or `lib/ai/**` changed** — the fix is wiring plus removal of the demo.
  Regression cover: `test/indexing_integration_test.dart` (1500 assets → 1500 indexed; ML Kit labels
  survive DB → `Photo.labels` and the synthetic tags are gone; thumbnail path reaches `Photo`).
### Added
- **Indexing on the UI path (M5 wiring).** `IndexingController` (`indexingControllerProvider`) runs one
  incremental pass at a time with live `IndexProgress`, cancellation, and — on completion — a refresh of the
  photo library and an invalidation of `indexWarmupProvider` so new embeddings become searchable in-session.
  The native-only pipeline sits behind a conditional-import boundary (`lib/state/index_bridge*.dart` +
  `IndexCancelToken`, ADR-015) that also requests media permission before scanning — `PhotoManagerGallerySource`
  reports an *empty* gallery rather than an error when access was never granted, so an unprompted run would
  have silently indexed zero photos. Web gets a `unsupported` stub, keeping the web build green.
  UI: an index status card on the empty search screen and a Library section in Settings, both sharing
  `IndexingStatus` (status line + determinate progress bar); onboarding's primary action is now
  "Index my photos".
### Changed
- **`PhotoLibrary` is DB-backed.** It reads `PhotoRepository.loadPhotos()` (the M5 index) instead of seeding
  from bundled samples, and is refreshed by `IndexingController`. `Photo` gained `thumbPath` (the indexed
  thumbnail *file* — paths, never blobs) plus `displayTitle`/`displayTags` so indexed rows, which carry no
  authored title or tags, render their ML Kit labels. `Photo.image` resolves the thumbnail file through a new
  web-safe `fileImage()` boundary (`lib/core/platform_image*.dart`) and falls back to a transparent
  placeholder instead of a bundled sample photo. Photo tiles prefer the top ML Kit label for their chip.
### Removed
- The M1 demo gallery loader — `lib/data/device_gallery.dart`, `device_gallery_io.dart`,
  `device_gallery_stub.dart` — and the hardcoded `samplePhotos` list (`sample_data.dart` keeps only the
  generic `suggestedQueries` search hints). Resolves TD-5.

### Added
- **M6 Semantic Search — complete & real-ORT verified:** on-device CLIP semantic search wired end-to-end
  behind the `SearchBackend` seam. New `SemanticSearchBackend` (`lib/data/search/`) = `OnnxTextEmbedder`
  (query→CLIP text embedding) → `VectorIndex` cosine → **`HybridScorer`** (`lib/domain/search/`, pure) that
  fuses CLIP semantics ⊕ lexical (tags/ML Kit labels/caption/place/album) ⊕ face-intent into a ranked list.
  The `Photo` model gained read-only `labels`/`faceCount` (surfaced from the M5 DB columns) for hybrid
  ranking. Async provider graph: `vectorIndexProvider`, `indexWarmupProvider` (DB→index), cached
  `clipTokenizerProvider`, semantic-vs-keyword `searchBackendProvider` (web→keyword), debounced query, and an
  `AsyncValue` `searchResultsProvider`. Search UI now renders loading/empty/results states with a
  **"Semantic/Keyword" mode badge**. **Verification:** `integration_test/semantic_search_test.dart` (real
  Flutter ORT) — **6/6 top-1 retrieval** on the parity images with *no* lexical hints (pure CLIP), 35 ms/query
  end-to-end, brute-force scan 3.4 ms@1k / 8.1 ms@10k; **14 new unit tests** (fusion, normalization,
  face-intent, min-cosine gating, browse, keyword degradation). **46 unit tests total.** Docs: ADR-014,
  `BENCHMARK_RESULTS.md §M6`, `RESEARCH_LOG.md`.
### Changed
- `SearchBackend.search` is now **async** (`Future<List<Photo>>`) so semantic ranking can run the text
  encoder off the caller's stack; `KeywordSearchBackend` wraps synchronously (ADR-014). Lexical scoring was
  factored into a shared `keywordScore()` (single source of truth for the keyword backend and the hybrid
  lexical component) and extended to include ML Kit labels.
### Fixed
- `AiContract.schemaVersion` mirror corrected `2 → 3` to match the actual DB schema (drifted since the M5 v3 migration; the constant is documentary — no runtime effect).
- **M5 Production Indexing Engine — core complete & verified:** ports-and-adapters pipeline
  (`lib/indexing/`) — `IndexPlanner` (reconcile), `AssetProcessor`, `IndexStore` (batch txn + checkpoints),
  `IndexingService` (scan→plan→index, cancel, resume, progress stream), `ModelVersionManager`; DB **schema
  v3** (indexing metadata). **16 tests green:** reconcile, full/incremental/200-stress index,
  dedup/embed-once, deleted, changed, model-version migration, cancel+resume, per-asset failure isolation.
  All six device adapters (photo_manager, ML Kit labeling+faces, WorkManager, EXIF, thumbnail) + the
  WorkManager isolate entrypoint + DI wiring are written and **compile clean** (web+linux builds unaffected);
  only their on-device runtime is pending. Docs: `INDEXING_ARCHITECTURE.md` (architecture/class/sequence
  diagrams + scalability), ADR-013.
- **M4.6 AI Core Production Review — APPROVED:** full audit (`docs/AI_CORE_REVIEW.md`) of architecture,
  SOLID, resource lifecycle, session reuse, leaks, exceptions, logging, thread safety, duplication,
  maintainability. No critical issues, no refactor required; 2 minor items deferred to M5 with rationale.
  Certified: analyzer 0 issues, 16 unit tests, golden suite green. **M4 (AI Core) is complete.**
- **M4.5 Performance & Benchmarking:** `integration_test/benchmark_test.dart` measures model load,
  image (175 ms) / text (42 ms) embed latency, session reuse, throughput (6.1 img/s), and RSS (+612 MB,
  both fp32) on the build host; projects indexing for 100–50k; auto-writes `BENCHMARK_REPORT.md`.
  Recorded as host (x86/fp32) numbers — device fp16/NNAPI pending (BENCHMARK_RESULTS §8).
- **M4.4 Golden Validation Suite (PASSED):** permanent end-to-end validation
  (`integration_test/golden_validation_test.dart`) over both encoders via real Flutter ORT —
  **100% retrieval (6/6)**, cosine 1.0, L2-normalized, stable Top-K ranking, repeatable — auto-writes
  `VALIDATION_REPORT.md`. Regression guards: preprocessing fingerprint (`test/preprocessing_golden_test.dart`)
  + 19-case tokenizer parity, so preprocessing/tokenizer drift fails loudly.
- **M4.3 production TextEmbedder + text parity GATE (PASSED):** exact CLIP BPE tokenizer in Dart
  (`clip_tokenizer.dart` — token ids match open_clip on 19 cases) + `OnnxTextEmbedder` on a shared
  `OnnxEncoder` base (ADR-011). Real Flutter ORT text parity at **cosine 1.000000** (6 queries); vocab
  bundled as an asset. **artifact_version → 2:** text model patched with `Cast(int64→int32)` before ArgMax
  for onnxruntime-1.15 compatibility — embeddings identical, no re-index (ADR-012). Image embedder
  refactored onto the shared base (image gate re-verified, no regression).
- **M4.2 production ImageEmbedder + numerical parity GATE (PASSED):** `OnnxImageEmbedder` (reused ORT
  session, error handling, logging) + bit-faithful preprocessing (`lib/ai/`). A **real Flutter ONNX
  Runtime** integration test (`integration_test/image_parity_test.dart`, run on Linux desktop via xvfb)
  reproduces the open_clip/fp32-ONNX reference at **cosine 1.000000** on all 6 probe images
  (max-abs-err ≤ 1.3e-4), retrieval ranking 6/6. Added `onnxruntime` + `image` deps and Linux platform.
- **Interface versioning (Improvement 1):** `model_version` / `embedding_version` / `artifact_version` /
  `schema_version` in the contract (v1.1), `AiContract`, and `preprocess_config.json`; `docs/MIGRATIONS.md`
  policy; DB **schema v2** adds `EmbeddingRows.embeddingVersion` (+ migration + version-aware queries).
- **Search seam (Improvement 2):** `VectorIndex` + `BruteForceVectorIndex` (unit-tested) and a
  `SearchBackend` seam (`KeywordSearchBackend` wraps the mock, behavior unchanged); ADR-009.
- **Benchmark framework (Improvement 3):** Dart timing harness (`lib/benchmark/`) + Python retrieval
  metrics (`eval/`, P@K/R@K/AP/mAP), both unit-tested; empty result tables (no fabricated numbers).
- **M4 Phase 1 preflight:** verified the real open_clip preprocessing + tokenizer; contract clarified to
  v1.1 (resize-shortest + center-crop + antialias made explicit); **KI-1 resolved**, no frozen value changed.
- Two-repo structure formalized: **PixelSearch** (Flutter) and **PixelSearch ModelKit** (Python).
- `CLAUDE.md` operating guide in both repos.
- Documentation backbone under `docs/`: PROJECT_STATUS, ROADMAP, ARCHITECTURE, ARCHITECTURE_DECISIONS,
  CHANGELOG, TECHNICAL_DEBT, TEST_PLAN, KNOWN_ISSUES, RESEARCH_LOG, BENCHMARK_RESULTS.
- Frozen `INTERFACE_CONTRACT.md` (owned by ModelKit, mirrored to Flutter).
- **M2 (done):** drift-based local store — `PhotoRows`, `EmbeddingRows`, `IndexStateRows`;
  conditional DB connection (native + web stub); `PhotoRepository` with a little-endian
  float32 vector codec; `appDatabaseProvider` / `photoRepositoryProvider`; 5 unit tests.
  **Verified:** analyzer 0 issues, 6/6 tests pass, `flutter build web` compiles.

### Notes
- Mock keyword search (`search_engine.dart`) is unchanged; it is replaced in M7.
- M2 is additive: the store is not on the UI/search path yet (M5 indexer + M7 search consume it).

## [0.1.0] — 2026-07-22  (project-review build)
### Added
- Flutter scaffold, Material 3 theme, go_router shell (M0).
- Gallery: real device photos on Android + 18 bundled samples, web-safe via conditional imports (M1).
- UI: onboarding, search, photo viewer, timeline, map, settings (M3).
- Mock semantic search as an end-to-end stand-in for the review.
- Verified: analyzer clean, widget test passing, web build succeeds.

## [ModelKit] — 2026-07-24
### Added
- `prepare_model.py`: one-command MobileCLIP-S1 export + verification + fp16 conversion.
- Verified parity (cos 1.000000 both towers) and 6/6 retrieval; fp16/int8 size+accuracy findings.
- Artifacts: fp16 encoders, BPE vocab, `preprocess_config.json`, `reference_vectors.json`.
