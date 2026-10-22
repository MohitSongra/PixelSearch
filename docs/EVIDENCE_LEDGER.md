# PixelSearch Evidence Ledger

**As of:** 2026-10-21, updated 2026-10-22 (People search: host runs §1, Vivo install, acceptance, grouping, the
"Same person?" questions, the user's answers and the resumed processing pass §4.2 and §6, test counts §8) · **Repository state:** `main` at `4a7c81f` (2026-09-18)
plus a large uncommitted working tree.

This ledger lists every measured result found in the repository, with its date, device, precision, scope and the
quality of its evidence. It exists so that future work cites measurements correctly instead of copying numbers
from summaries.

Rules for using it:

- **Only measured values are recorded.** Projections and targets are labelled as such.
- **Host is not device.** "Host" means an x86-64 build machine. Host numbers are never Android results.
- **FP32 CPU is the only accepted device configuration.** No FP16, NNAPI or XNNPACK measurement exists anywhere.
- **Evidence quality** is one of:
  - *raw log*: a log or report file exists in the repo.
  - *private raw*: the raw data exists only in git-ignored `pixelsearch_app/local_evaluation/` or
    `pixelsearch_app/docs/RAW_SEMANTIC_DIAGNOSIS.md`.
  - *prose*: the number appears only in a dated document.
  - *re-run today*: reproduced during this audit.
- **Code changes since the measurement are noted.** Many host numbers predate commit `a76d3b6` (2026-08-08), which
  changed image preprocessing (packed-buffer pixel reads) and added ONNX intra-op threads. Those numbers do not
  describe the current code.

Personal data rule: this ledger cites files and aggregate numbers only. It never reproduces personal photo
filenames, person names, device serials, deployment URLs or backup paths. Some older tracked documents do contain
them; see [PROJECT_CONTEXT.md §11](PROJECT_CONTEXT.md#11-security-privacy-and-publication-exposure).

---

## 1. Verification runs made during this audit (2026-10-21)

All runs were read-only with respect to tracked files: `git status --porcelain` hashed identically before and after.
No dependency was installed.

| Command (cwd) | Tree | Result |
|---|---|---|
| `flutter analyze --no-pub` (`pixelsearch_app/`) | working tree | No issues found (138.7 s) |
| `flutter test --no-pub test/` (`pixelsearch_app/`) | working tree | **372 passed, 1 skipped**. The skip is `test/sface_reference_test.dart:80`, gated by `--dart-define=SFACE_MODEL_TEST=true`. |
| `flutter test --no-pub test/` on a `git archive HEAD` export, with the working tree's `.dart_tool/package_config.json` copied into the export (`--no-pub` cannot resolve packages on a bare export) | committed HEAD `4a7c81f`, committed generated code | **327 passed, 1 skipped, 0 failed** (Windows host, +05:30 timezone) |
| `python tool/check_repository.py` (root) | working tree | Passed |
| `python eval/test_metrics.py` (`model_kit/`) | working tree | All metric tests passed |
| `.venv/Scripts/python -m pytest -q -p no:cacheprovider` (`enhancement_backend/`) | working tree | **51 passed**, 2 upstream deprecation warnings (Python 3.12.14, starlette 1.6.0) |
| `python -m pytest` with the system Python 3.14 (`enhancement_backend/`) | working tree | **Collection error**: the installed starlette 1.3.1 lacks `starlette.middleware.body_limit`, while `requirements.txt` requires `starlette>=1.6`. This is an environment mismatch, not a code defect; use the project venv. |

Toolchain observed: Flutter 3.44.7 stable (revision `84fc5cbb`, matching `pixelsearch_app/.metadata`), Dart 3.12.2.

Not re-run (needs hardware or provisioned models): `integration_test/` parity, golden, benchmark and semantic-search
suites; `flutter test --dart-define=SFACE_MODEL_TEST=true`; any Android build or install.

### Later host runs (2026-10-22, People-search wave, Windows host, working tree)

These runs follow code changes, so they are not read-only like the audit runs above.

| Command (cwd) | Result |
|---|---|
| `flutter analyze --no-pub` (`pixelsearch_app/`) | No issues found (after every change below) |
| `flutter test --no-pub test/` (`pixelsearch_app/`) | First implementation: **496 passed, 2 skipped**. After the grouping and naming-list change: **499 passed, 2 skipped** (`people_suggestions_test.dart` +3). After the "Same person?" change: **512 passed, 2 skipped** (the new `people_same_person_test.dart`, then 13). With rounds: 516 + 2; with the first review fixes: 522 + 2; with the home-prompt fix: 523 + 2; with the second verification pass's fixes: **526 passed, 2 skipped (current)** (`people_same_person_test.dart` now 24). The skips are the real SFace worker test (needs `--dart-define=SFACE_MODEL_TEST=true`) and the documented KI-16 bug test. |
| `python -I tool/check_repository.py` (root) | Passed (each time) |
| `flutter build apk --debug --no-pub` (`pixelsearch_app/`) | Built; versionCode 1, debuggable. Its signing certificate matches the app installed on the phone (compared with apksigner; digest not recorded). Later builds for the second to ninth installs used the same signer. |
| Independent review of the first implementation | 8 agents over 4 dimensions (each verified): 24 issues, fixed (among them Undo applied to the wrong action, a stale New-faces selection, a hidden "This is me" treated as missing, over-stripped words and small-screen overflow) |
| Review of grouping, the naming list and "Same person?" | Each finding verified: 14 issues, fixed (among them a Yes confirming faces the user never saw, an Unsure blocking a carried-over reject, concurrent grouping runs, decoder face sizes, duplicates returning, question building on the UI isolate) |
| Second verification pass over the final code and docs (8 agents: 4 checkers, each with a skeptical verifier) | 55 findings, 54 confirmed. 3 code issues (a pair answerable twice through "Open full screen" during a save, an answered pair shown again after a failed reload, a group-pair answer not checking the compared faces), each fixed with a test that fails without the fix; about 40 stale or wrong doc statements, fixed; 12 privacy findings in files from earlier waves, listed for the owner (PROJECT_CONTEXT §11) and not changed. A fourth code fix followed from the device check: a name-only search now says "Matched by assigned faces". |

No 2026-10-22 run is recorded for the backend and ModelKit suites, the SFace-enabled suite or `integration_test/`.

## 2. CI history (GitHub Actions, public repository)

Checked on 2026-10-21 through unauthenticated, read-only GitHub API requests. Job logs require authentication and
were not read.

| Run | Commit | Date (UTC) | Result |
|---|---|---|---|
| 1 | `ce7bf55` | 2026-08-07 | success |
| 2 | `930a413` | 2026-08-08 | failure |
| 3 | `a76d3b6` | 2026-08-08 | success |
| 4 | `5f6f074` | 2026-09-09 | failure |
| 5 | `a4081f3` | 2026-09-09 | failure |
| 6 | `f38a72c` | 2026-09-09 | failure |
| 7 | `4a7c81f` (HEAD) | 2026-09-18 | failure: only the Flutter job failed, at `flutter test test/`, with "324 tests passed, 3 failed, 1 skipped". The repository, backend and ModelKit jobs passed. |

The same HEAD passes locally on Windows with the committed generated code (327 + 1 skip, §1). CI differs in OS,
timezone, run date (2026-09-18 vs 2026-10-21) and a `build_runner` regeneration step, so the cause of the three
failures is not established. Which tests fail, and why, is **unknown**. A UTC-versus-local-timezone dependence in
date or timeline tests is plausible but unproven. To find out, read the run 7 log while signed in, or run
`flutter test test/` on a Linux machine.

## 3. Model and parity evidence (host)

| Date | What | Value | Conditions / caveats | Evidence |
|---|---|---|---|---|
| 2026-07-24 | ONNX export vs PyTorch | image cosine 1.000000, max diff 3.3e-6; text cosine 1.000000, max diff 1.1e-7 | ModelKit spike, Python ORT, one random image tensor and one fixed text input ("a photo"). `prepare_model.py` now prints cosine only. | prose (`model_kit/SPIKE_REPORT.md`) |
| 2026-07-24 | Spike retrieval by precision | fp32 6/6; int8 dynamic 1/6; fp16 "near-lossless" | fp16 accuracy was never measured (CPU could not run it). The int8 result has no script or artifact. | prose |
| 2026-08-06 | Flutter-ORT image parity (6 probes) | cosine 1.000000 on all 6; max abs error ≤ 1.3e-4; ranking 6/6 | Linux desktop via xvfb, fp32, real Flutter ORT. Predates `a76d3b6`. | prose (`BENCHMARK_RESULTS.md` §6) |
| 2026-08-06 | Flutter-ORT text parity | cosine 1.000000 on 6 queries; tokenizer 19/19 id-exact | fp32, ArgMax-patched text model (artifact v2) | prose; the tokenizer part is re-checked by every unit-test run |
| 2026-08-06 | Golden validation | 6/6, minimum cosine 1.000000, max ‖v‖−1 = 2.9e-8 | fp32 host; the report is overwritten on each run and carries no date | raw log (`model_kit/parity/VALIDATION_REPORT.md`) |
| 2026-08-06 | Host encoder benchmark | image load 588 ms, text load 961 ms, RSS +612 MB; image embed mean 175.3 / median 165.8 / p95 259.0 ms (includes Dart preprocessing); text mean 41.7 ms; 6.1 images/s | x86-64, fp32, ORT 1.15, 30 iterations on one image and one query. Platform strings are hard-coded. Predates `a76d3b6`. | raw log (`model_kit/parity/BENCHMARK_REPORT.md`) |
| 2026-08-07 | Semantic retrieval on probes | top-1 6/6; minimum correct cosine 0.1983; maximum distractor 0.1463 | Host fp32, gate set to 0 in the test. **These two values are the sole basis of the production gate `semanticMinCosine = 0.15`.** Re-derived from `reference_embeddings.json` during this audit. | raw log (`model_kit/parity/SEMANTIC_SEARCH_REPORT.md`) + re-run today |
| 2026-08-07 | End-to-end query latency | mean 35.1 ms (median 35.3, min 33.1, max 38.7) | 6 queries after 1 warm-up over a 6-photo corpus | raw log |
| 2026-08-07 | Brute-force query | 3.40 ms at 1,000 vectors; 8.07 ms at 10,000 | Random unit vectors, topK 50, median of 5. Measures `index.query` only (scan, sort and slice), not hybrid ranking. | raw log |
| 2026-08-08 | fp32 re-export vs frozen reference | cosine 1.000000, max\|err\| 3.46e-07, ‖v‖ = 1.00000 on all 6 parity probes | Python ORT, not Flutter. The current fp32 image artifact dates from this re-export. | prose (`KNOWN_ISSUES.md` KI-9, added in `a76d3b6`) |
| 2026-09-10 (desktop) | SFace crop parity vs OpenCV | MAE: identity 0, scale 0, rotation 0.00308, border 0.00234 (max 8); descriptor cosine ≥ 0.9999963 | Synthetic non-person fixtures, OpenCV 4.12.0; recorded with a full suite including the real SFace worker (316 passed) | prose (`pixelsearch_app/docs/OFFLINE_PEOPLE_2026-09-10.md` §Measured Local Results; `model_kit/FACE_CONTRACT.md`) |

Caveats that apply to the whole section:

- `reference_vectors.json` `sim_matrix` values are about 0.1876 × the true cosine. `prepare_model.py:91` divides by
  a matrix 1-norm scalar. Only the argmax diagonal is meaningful.
- The preprocessing fingerprint test (`sum = 100051.464714`) was captured from Dart output. It was not compared with
  a PIL tensor. It proves Dart self-consistency, not bit-exact PIL parity. Measured on 2026-09-08: PIL-decoded
  probes of 5 real photos gave cosine 0.989805–0.999859 against the stored Android vectors, so PIL/Python
  preprocessing is not interchangeable with the production Dart path. Host replays must use production Dart tensors
  (`USABILITY_AND_SEARCH_PRECISION.md`).
- Flutter-ORT parity has **not** been re-run since `a76d3b6` (2026-08-08), so parity of the current preprocessing and
  threading code with the Python reference is unverified on host.
- Both current fp32 artifacts post-date the 2026-08-06 Flutter-ORT parity run: the image export was regenerated on
  2026-08-08 (checked only in Python ORT, table above), and the text artifact was re-saved on 2026-09-08 by the
  ArgMax patch step. The 2026-08-06 parity ran on earlier serializations; the graphs are presumed identical.
- ModelKit's Python environment pins `onnxruntime==1.28.0`. The app's Flutter plugin (`onnxruntime` 1.4.1) bundles
  native ORT **1.15.1**, the same runtime that ADR-012 assumes. Python-only checks do not represent the device runtime.

## 4. Android device evidence

### 4.1 Realme RMX3092, Android 12 (ColorOS)

| Date | What | Value | Caveats | Evidence |
|---|---|---|---|---|
| ~2026-08-08 (inferred from commit `a76d3b6`) | Indexing stage profile, 40 assets at ~1200×1600 | Reported totals 2,325 → 1,694 ms/photo after decode-once, TD-9 and 4 intra-op threads (reported 1.37×; about 26 → 35 photos/min, computed from the totals). After: load bytes 75, EXIF 1, decode 465, thumbnail 31, embed 660, ML Kit 462 ms. | Section undated, precision not stated (fp32 CPU inferred). "23 photos/min" in CHANGELOG is wrong (60000/2325 ≈ 25.8). The before-column stages sum to 1,908 ms without the ~850 ms "decoded twice" row, or 2,758 ms with it; neither equals the reported 2,325 ms, so the before total and the 1.37× cannot be reconciled from the table. Only the after total matches its stages. About 1,956 ms/photo on 12 MP frames. | prose (`pixelsearch_app/docs/CHANGELOG.md`) |
| 2026-08-08 | Screen-off freeze (KI-10) | The OEM froze the app on screen-off and indexing stopped | Workaround while testing: `adb shell svc power stayon true` | prose (`KNOWN_ISSUES.md`) |
| ~2026-08-08 | Label coverage | 5 of 800 unlabelled at a 0.5 threshold; 0 of 512 with a best-3 fallback | **The fallback was removed in `5f6f074` (committed 2026-09-09; the work is described in docs dated 2026-09-08).** These numbers no longer describe current behaviour. | prose |

### 4.2 Vivo I2214, Android API 36, arm64 (main acceptance device)

All runs: debug APK, MobileCLIP **FP32 on CPU**, 4 intra-op threads, models provisioned by hand.

| Date | What | Value | Caveats | Evidence |
|---|---|---|---|---|
| 2026-09-08 | Model load / first inference | image 939 / 251 ms; text 1,822 / 82 ms; after a cold restart, image 1,024 / 366 ms and text 1,634 / 76 ms; norm 1.000000 | Single cold samples; inference excludes preprocessing | prose (`ANDROID_SMOKE_TEST_2026-09-08.md`) |
| 2026-09-08 | Indexing per asset | 2,366 ms/photo (first 40: decode 948, preprocessing + inference 619, ML Kit 683); 1,813 ms/photo (first 100) | Debug build with screen mirroring; different image mixes | prose |
| 2026-09-08 | Discovery and partial runs | 19,260 assets discovered; run 1 embedded 103 (0 failed) in 209,514 ms; run 2 after a cold restart embedded 37 (103 up to date) in 54,431 ms | Full-library completion never tested | prose |
| 2026-09-08 | Memory during indexing | total PSS 1,081,280 KB and 1,071,962 KB | Two spot readings, not peak | prose |
| 2026-09-08 | Folder-scoped runs | 4 indexed in 31,699 ms; rerun with 0 to index in 34,437 ms | Dominated by gallery-wide existence enumeration | prose (`FOLDER_INDEXING.md`) |
| 2026-09-08 | Text model (first diagnostic device attempt, separate from the smoke test) | load 1,752 ms; first inference 83 ms | One cold sample. The same attempt's cleanup caused the KI-12 uninstall (§5) | prose (`SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md`) |
| 2026-09-08 | Device/host parity on the personal corpus | text vector cosine 1.0 (max abs ≈ 1.2e-7); stored vs host image cosine 1.0 (max abs 2.67e-7); host replay matches the Android top-200. Separately, 5 stored Android image vectors matched host recomputation (production Dart decoder/preprocessor, FP32 ONNX) at cosine ≥ 0.9999999999966 | 2 text queries plus 1 image row, and the separate 5-row check; fp32. The strongest Android parity evidence, but its scope is only the checked rows. | private raw (`RAW_SEMANTIC_DIAGNOSIS.md`, git-ignored); prose (`USABILITY_AND_SEARCH_PRECISION.md`) |
| 2026-09-09 | Gallery | 1,916 indexed photos; folder picker reported 16,720 available | — | prose (`INDEXED_GALLERY_2026-09-09.md`) |
| 2026-09-09 | Memory (gallery) | PSS 381,068 KB at start; 841,515 KB after jumps, viewer, search, picker and settings | Two uncontrolled samples, debug build | prose |
| 2026-09-10 | EXIF GPS pass | 1,916 checked: 0 located, 1,916 GPS not found, 0 inaccessible, 0 unreadable | Not proof that the originals lack GPS. No positive pin acceptance exists. | prose (`VOICE_MAP_TIMELINE_2026-09-10.md`) |
| 2026-09-10 | Timeline after the calendar-day fix | 215 daily events, 1,916 memberships, 0 multi-day events; the earlier 48-hour chain had produced one 1,193-photo event | Device in +05:30 | prose |
| 2026-09-10 | v5 → v6 migration | 8 pre-existing tables preserved; 1,916 photos/embeddings, 215 memories, 1,916 location rows | From private backups | private raw + prose |
| 2026-09-10 | Android "Check face model" (SFace) | cosine: identity 0.999999965, scale 1.0, rotation 0.99999638, border 0.99999786; 2,186 ms for the whole check | Synthetic fixtures; numerical parity only, not recognition accuracy | prose (`NEW_FACES_DEVICE_2026-09-10.md`) |
| 2026-09-18 | People scan and review | see §6 | — | private raw + prose |
| 2026-09-18 | Redesign Home scroll | pinned search-field bounds verified after swipes | In-place update of the uncommitted redesign build | raw log (`.impeccable/review/`, untracked) |
| 2026-10-22 | Backup B0 (before any install) | installed debug build versionCode 1, last updated 2026-09-18; SQLite integrity ok, schema 6; 1,916 photos with 1,916 embeddings; People state in §6 | Aggregate only | private raw |
| 2026-10-22 | In-place install of the People-search build | Backup B0b identical to B0 in every table → `adb install -r` → first-install time unchanged, signature unchanged, installed binary identical to the built APK, `run-as` works. Backup B1 after the first launch: every table identical to B0b (only app assets, the image cache, the WorkManager database and shader-cache files changed). Two later builds were installed the same way; backup B2, taken before the second install, has tables identical to B1, so the acceptance searches wrote nothing. | Three installs of the People-search build on 2026-10-22 (nine in all with the later builds below); never uninstalled or cleared | private raw |
| 2026-10-22 | People-search acceptance | 8 typed person queries matched the values expected from backup B1 (table below); hidden person, suggestions view, grouping and persistence checked | Driven over adb through the accessibility tree at the user's request, with no screenshots; the assistant confirmed or rejected no identity | prose (`PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`, untracked) |
| 2026-10-22 | "Group similar faces" (user-approved) | 266 automatic assignments, 137 new unnamed groups; see §6 | One run; processing stayed paused | private raw (backup B3) |
| 2026-10-22 | In-place installs of the "Same person?" build | Two more installs the same way; backups B4 and B5 taken before them; tables identical from B3 to B5, so viewing the questions wrote nothing | Same signer, versionCode 1 | private raw |
| 2026-10-22 | "Same person?" questions on the phone | People tile "Same person? \| 122 quick questions": 3 verify questions and 119 group pairs at or above the user's lowest "same" review score (≈ 0.398); see §6 | View only, read over adb through the accessibility tree; the assistant answered no question | observed on the phone; private raw (host simulation on a copy of backup B3) |
| 2026-10-22 | The user's answers and naming (B5 → B6) | persons 142 → 127, manual 6 → 35, automatic 266 → 239, accept 6 → 35, reject 1 → 736, "me" photos 1 → 11; only `people_decisions`, `people_faces` and `people_persons` changed; must-be-zero checks 0; "photos of me with `<P3>`" then 2 results | Done by the user on the phone; the assistant made no identity decision and checked only aggregates | private raw (backups B5, B6) |
| 2026-10-22 | Rounds build (sixth install) | B7 identical to B6; no prompt and no People tile, because 0 questions were left (host simulation on a copy of B7: 79 pairs answered No or Not sure, 104 share a photo, 7,319 below the floor, 1 joins two named people) | Same in-place checks as above | private raw (backup B7) |
| 2026-10-22 | Resumed People processing (user's decision) | About 10:41 to 11:02: 1,431 photos, about 1.2 photos/s (1,321 photos in 1,104 s between two readings); then the validated `applyGrouping` ran. Backup B8: 1,916 of 1,916 photos processed, faces 2,342 → 2,642, descriptors 336 → 397, automatic 239 → 324, groups 127 → 152; only `people_faces`, `people_persons` and `people_scans` changed (11 other tables identical); manual 35, decisions, reviews and threshold unchanged; must-be-zero checks 0 | App in the foreground, screen on, phone charging over USB; progress read every 2 minutes from read-only database copies (which may slow the scan slightly). Debug FP32 build, Vivo I2214. | private raw (backup B8) |
| 2026-10-22 | Questions after the pass | People tile "Same person? \| 70 quick questions"; header "1916 of 1916 photos processed \| 2642 faces \| 152 groups"; "1497 to name"; main screen "Help improve face groups · 1 of 20" with No / Not sure / Yes. Host simulation on a copy of B8: 70 = 0 verify + 70 group pairs, 5 offering a named person, closest-face scores 0.399–0.983 (15 ≥ 0.5) | View only; none answered by the assistant | observed on the phone; private raw (B8) |
| 2026-10-22 | Seventh to ninth installs (the later fixes) | Backups before each: B8 → B9 identical in every table; B9 → B10 differs only by one People processing-lease row taken after launch and left by the force-stop for the backup (leases expire). After the ninth install, "photos of me with `<P3>`" and "`<P3>`" each gave 2 results labelled "Matched by assigned faces", and the prompt showed. | Same in-place checks | private raw (B9, B10) |

#### People-search acceptance on the Vivo (2026-10-22)

Expected values come from backup B1. Persons are slot labels P0–P4; P1 is the "This is me" person. The named
persons had 1, 1, 1, 2 and 1 photos, and none shares a photo with P1. The People header read "485 of 1916 photos
processed | Paused | 2342 faces | 5 groups" after the install (unchanged).

| Query | Result on the phone | Expected | Verdict |
|---|---|---|---|
| "photos of me with `<P3>`" | chips "You" and "`<P3>`"; "No photos of you and `<P3>` together" | not together | PASS |
| "`<P3>`" | 2 results | 2 | PASS |
| "`<P3>` at the beach" | "2 photos of `<P3>`, none match "the beach"", then "Show all 2 photos" gives 2 results with a People filter chip | scene miss | PASS |
| "Photos of me with `<P3>`." | same as without the full stop | same | PASS |
| "show me photos of `<P3>`" | 2 results, no "You" chip | 2 | PASS |
| "`<P3>` without me" | 2 results; chips "`<P3>`" and "not You" | 2 | PASS |
| "`<P0>` or `<P3>`" | 3 results; chips "either …" | 3 | PASS |
| "me" | 1 result; chip "You" | 1 | PASS |

- **Hidden person.** After hiding `<P3>`, typing "`<P3>`" showed no person chip and searched the words as text
  (60 results by image meaning). People ⋮ Show hidden people → `<P3>` → "Search photos of `<P3>`" gave 2 results.
  Unhide restored the person.
- **Suggestions (view only).** For the person with one large manual face: "Review similar faces (58)", the
  explanation ("This is not recognition…"), the paused note and "1994 unnamed faces are too small to compare"
  rendered; tiles expose "Unnamed face N, not selected" to screen readers. People whose only faces are small see
  "Needs a clear, large face of `<name>` first." Nothing was confirmed or rejected.
- **Grouping.** After "Group similar faces" the header read "2342 faces | 142 groups"; New faces showed "1402 to
  name" (was 2,329 face entries) with "Show small faces (798)"; one named person went from 1 to 4 photos.
- **Persistence.** After a force-stop and relaunch: "`<P3>`" 2, "me" 1, "`<P0>`" 4 results, unchanged.
- **After the third install:** the grouping menu item is enabled on first open, and New faces lists groups largest
  first (16, 9, 9, 9, 9, 8 photos).
- **"Same person?" (view only, on the builds of the fourth and fifth installs).** The People screen shows "Same
  person? | 122 quick questions"; the first card is "Is this `<P0>`?" with "Added automatically" under the right-hand
  face. No question was answered by then.
- **The user's answers (B5 to B6)** and **resumed processing (B7 to B8)**: see the table above. After the user's
  answers, "photos of me with `<P3>`" returned 2 results (chips "You" and "`<P3>`").
- **Not done by the assistant:** naming faces, confirming or rejecting suggestions and answering "Same person?"
  questions (identity decisions). The user's naming and answers were checked only through aggregate backup counts.
  Not exercised on the phone: suggestion confirm/reject, answering through the main-screen rounds, and voice input
  (typed queries only).

## 5. Search-quality evidence (1,916-photo personal library indexed on the Vivo, FP32)

The stored cosines and vectors come from the phone. Rows 1, 3 and 4 are host computations on those frozen Android
vectors, not device inference.

| Date | What | Value | Caveats | Evidence |
|---|---|---|---|---|
| 2026-09-08 | Lexical-bypass bug | 20 of 24 saved queries admitted the whole library ("a dog": 1,916 → 9 results after the fix) | Host replay of frozen Android cosines (production Dart); fewer results ≠ better relevance | prose (`USABILITY_AND_SEARCH_PRECISION.md`) |
| 2026-09-08 | Raw MobileCLIP ordering for "a dog" | judged relevant photo has cosine ≈ 0.1625; irrelevant photos 0.1687 and 0.2073 | No single cosine gate can fix this ordering. Root cause classified [PARTIAL] as an embedding limitation (parity, tokenizer and candidate loss ruled out). | prose (`USABILITY_AND_SEARCH_PRECISION.md`, cosines); private raw (`RAW_SEMANTIC_DIAGNOSIS.md`, classification) |
| 2026-09-08 | Prompt-template ablation | known dog rank 5 / 5 / 12 / 8 across four templates | Host experiment on frozen Android vectors (FP32 CPU text artifact); not adopted | prose (`USABILITY_AND_SEARCH_PRECISION.md`) |
| 2026-09-08 | Spatial tile probe | best tile 0.1839 vs irrelevant 0.2073 | Host experiment on frozen Android vectors (FP32 CPU artifacts), five photos; not adopted | prose (`USABILITY_AND_SEARCH_PRECISION.md`) |
| 2026-09-09 | Judged metrics | "a dog" P@5 0.20, nDCG@5 0.438 (20 judgments); "a car" P@5 0.40, nDCG@5 0.345 (21 judgments); unchanged by the article policy | Private, non-exhaustive judged pools. One dog judgment has ambiguous provenance. **The only judged quality numbers that exist.** | prose (`SPEECH_SEARCH_FOLLOWUP_2026-09-09.md`) |

Production ranking is otherwise uncalibrated. The gate (0.15) comes from six probes (§3). The semantic band
[0, 0.35] and the weights 0.70 / 0.25 / 0.05 are policy constants.

### KI-12 incident (2026-09-08)

A bare `flutter test integration_test/... -d <device>` run uninstalled the app at the end of the run. That
destroyed a 144-photo private index, which was not recovered; gallery originals were unaffected. Since then device
evaluation must go through `pixelsearch_app/tool/run_search_evaluation.ps1` (backup first, `--no-uninstall`). Only
its backup-only branch has been exercised on a device.

## 6. People (offline faces) evidence — Vivo, 2026-09-18 and 2026-10-22

| Item | Value |
|---|---|
| Scan coverage | 485 of 1,916 photos processed; 2,342 detections; **336 ready descriptors** (2,006 "small face" observations below 100 px). Unchanged in backup B0 (2026-10-22) and up to B7. After the user resumed processing (backup B8, 2026-10-22): **1,916 of 1,916** photos processed, 2,642 detections, **397 ready descriptors**. |
| Original review, 2026-09-18 (failed) | calibration 31 Same / 9 Different; cutoff 0.4307765197209109; validation 16 Same / 4 Different; 15/16 Same accepted; **1 false join** (pair 55, cosine 0.5594) |
| Final corrected snapshot, 2026-09-18 | validation 15 Same / 5 Different; conflict pair 56 (Different, cosine 0.4392 > cutoff). **Gate still failed on that date. Automatic grouping was OFF. People processing was left paused by the user.** Superseded by the fresh round below. |
| Note | The documentation says "correcting a rating" (singular). The private before/after reports show three ratings changed (pairs 55, 56, 57). The uncommitted working-tree test `pixelsearch_app/test/people_domain_test.dart:193-212` (not in HEAD `4a7c81f`) encodes the *original* review, not the corrected one. The People-validation fix described in `PEOPLE_VALIDATION_2026-09-18.md` is also uncommitted. |
| Fresh round (backup B0, 2026-10-22) | An archived round (40 calibration + 20 validation pairs) and a current round (60 calibration + 20 fresh validation pairs). Saved calibration **passed**: calibration 46 Same / 14 Different; validation 16 Same / 4 Different; **0 false joins**, 16 true joins; threshold ≈ 0.462. The app says "Passed this reviewed sample; not a general accuracy guarantee". The holdout has only 4 Different pairs. |
| People data before grouping (backups B0 to B2, 2026-10-22) | People enabled and paused; 5 named persons (1 "This is me", 0 hidden); assignments 6 manual, 0 automatic; 7 faces marked Not a face; decisions 6 accept / 1 reject. No named person shared a photo with the "This is me" person. |
| Face sizes and duplicates (backup analysis, 2026-10-22) | 2,342 detected faces in 430 photos; 336 at least 100 px (descriptor); 2,006 smaller, which the current contract can never group; 67 photos with 10 or more faces; 26 overlapping same-photo detection pairs and about 20 near-identical cross-photo pairs (the same image saved twice). Duplicates are a minor factor. |
| User-requested grouping (backup B3, 2026-10-22) | **266 faces assigned `automatic`**: 3 to a named person (1 → 4 photos), the rest into **137 new unnamed groups** (142 persons in all). Only `people_faces` and `people_persons` changed; reviews, scans, decisions, photos and embeddings identical; threshold unchanged; 0 faces assigned to a rejected person; 0 orphans; processing still paused. |
| Host prediction of the grouping | The same code run on a copy of backup B1 predicted exactly 266 grouped, 137 unnamed groups and 3 into a named person. |
| Review score ranges, current round (backup B3, 2026-10-22) | Calibration Same 46 (cosine 0.398–0.996), Different 14 (0.307–0.439); validation Same 16 (0.478–0.997), Different 4 (0.329–0.399). The Same and Different ranges overlap. |
| "Same person?" questions (2026-10-22) | On the phone after grouping: **122** = 3 verify questions (the 3 automatic faces in a named person) + 119 group pairs whose closest faces score at or above the lowest "same" review score (≈ 0.398, the calibration Same minimum above). A host simulation on a copy of backup B3 counted 9,347 possible group pairs, of which only 11 score ≥ 0.5. The floor selects questions only: because the ranges overlap, pairs above it can still be different people. No question was answered by B5 (backups B4 and B5: tables unchanged from B3). The user then answered questions and named faces (B5 to B6, §4.2); on B7 none was left. |
| After the resumed pass (backup B8, 2026-10-22) | Automatic 239 → 324 (+85), groups 127 → 152, nothing added to a named person; manual 35, decisions 35 accept / 736 reject, reviews and threshold unchanged; 0 faces assigned to a rejected person; 0 orphans. 70 new questions, all group pairs (§4.2). |
| Recognition accuracy | Never measured (including the 266 automatic assignments of the grouping run and the 85 after the resumed pass) |

Evidence: `pixelsearch_app/docs/PEOPLE_VALIDATION_2026-09-18.md` and
`pixelsearch_app/docs/PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md` (both untracked). Raw anonymised before/after
JSON and backups are in the git-ignored `local_evaluation/`.

## 7. Online / backend evidence

| Date | What | Value | Caveats |
|---|---|---|---|
| 2026-09-09 | Groq organisation limits (Qwen) | 30 requests/min, 1,000 requests/day, 8,000 tokens/min, 200,000 tokens/day, plus an enforced 1,000 output tokens/min | Read from the user's console; may change |
| 2026-09-09 | Output budget fix | `max_completion_tokens` 2048 → 512 (commit `f38a72c`) after an HTTP 429 | — |
| 2026-09-09 | One assistant request | 208 input / 38 output tokens; provider latency 0.154 s | Provider side, not phone end-to-end |
| 2026-09-09 | Live checks | 3 authenticated requests OK; an unauthenticated POST got 401; "only last year" produced a **rolling** year | Smoke tests only. Live service last verified on the `f38a72c` code. |
| 2026-09-18 | Dependency advisories | pip-audit: 24 lock packages, no advisories; OSV: 160 Dart package/version pairs, no advisories | Cannot prove the absence of vulnerabilities |

Never independently live-tested: caption generate or rewrite with a real photo (the user reported checking captions
on 2026-09-10, but this was not re-verified or recorded), the cloud transcription round trip, and offline speech
recognition accuracy (English, Hindi, Hinglish).

## 8. Test-count history

Flutter unit/widget suite counts as reported by dated docs (prose unless noted):

`11 → 46 → 58 → 76 → 93 → 107 → 125 → 130 → 142 → 154 → 275 → 316 → 327 → 339 → 353 → 358`
(2026-08-06 to 2026-09-18). On 2026-09-18 the raw logs record 327 + 1 skip, 339 + 1, 353 (with SFace) and
358 + 1 (`.impeccable/build/*.log`, `pixelsearch_app/build/*.log`). The 337 in `SECURITY_REVIEW_2026-09-18.md` was
run in a separate verification copy.

2026-10-21 audit: 372 passed + 1 skipped (working tree, re-run that day). The rise from 359 to 373 comes from the
untracked `people_name_search_test.dart` (13 tests) and edits made on 2026-10-18. A static grep count of
`test(`/`testWidgets(` (333) is not a runtime count, because parameterised loops expand at run time.

2026-10-22 (Windows host, working tree): 496 passed + 2 skipped for the first People-search implementation, then
499 passed + 2 skipped after the grouping and naming-list change, 512 passed + 2 skipped after the "Same person?"
change, 516 + 2 with rounds, 522 + 2 with the review fixes, 523 + 2 with the home-prompt fix, and **526 passed
+ 2 skipped (current)** with the second verification pass's fixes. The 155 tests added since 2026-10-21 (154
passed, 1 skipped) are the untracked `people_query_parser_test.dart` (52), `people_membership_test.dart` (21),
`people_suggestions_test.dart` (27) and `people_same_person_test.dart` (24), plus additions to
`people_validation_recovery_test.dart` (+3, one of them the skipped KI-16 bug test), `people_widgets_test.dart` (+21)
and `voice_search_widgets_test.dart` (+7).

Backend: 14 → 19 → 27 → 51 (the 51 includes the untracked `test_security.py`) → **51 on 2026-10-21** (no later backend run recorded).

## 9. Contradicted or unsupported claims (do not repeat)

| Claim | Where | Reality |
|---|---|---|
| fp16 "validated on-device (NNAPI/XNNPACK)", fp16 "shipped" | `pixelsearch_app/docs/BENCHMARK_RESULTS.md` §2/§6/§7; `model_kit/parity/README.md` | No execution provider is registered (`lib/ai/onnx_encoder.dart:62-73`). No recorded device run used an fp16 artifact, and Android fp16 load, inference and parity have never been accepted (KI-2, KI-9). Whether an fp16 file was ever copied to a phone is not documented. |
| "Both precisions are numerically verified" | `lib/core/model_locator.dart:35-41` (code comment) | fp16 parity was never measured |
| On-device performance "PENDING" | `BENCHMARK_RESULTS.md` §3/§5 | Device fp32 numbers exist (§4). The file was never updated. |
| End-to-end query "dominated by the ~42 ms text embed" | `BENCHMARK_RESULTS.md` | The end-to-end mean (35.1 ms) is below the text-embed mean (41.7 ms). These were separate runs and cannot be combined. |
| "Results in under two seconds" | onboarding UI copy (`onboarding_screen.dart:89-90`) | No device end-to-end query latency has been measured. This is a target from the archived plan. |
| Every photo gets tags (best-3 fallback; 0 of 512 unlabelled) | `CHANGELOG.md` | The fallback was removed in `5f6f074`. Current policy: confidence ≥ 0.5 or no labels. |
| Blackbook figure "6 samples"; raw-cosine ×0.70 formula; name-dependent face term | `reports/blackbook/` (untracked) | 30 iterations; the code uses `clamp(cos/0.35)`; the face term is min(faceCount, 3) / 3, applied only when the query contains a face-intent keyword (people, person, selfie, group, family, etc.) and faceCount > 0; it does not depend on person names |
| 358 tests (October) | blackbook evidence notes | No October log existed at the 2026-10-21 audit (372 + 1 skip that day). The current count is 526 + 2 skipped (2026-10-22). |
| "The People review gate failed", "threshold null", "automatic grouping is off" | `PEOPLE_VALIDATION_2026-09-18.md`; status lines written before 2026-10-22 | True for the first round (2026-09-18) only. Backup B0 (2026-10-22) shows that a fresh 20-pair round passed (threshold ≈ 0.462), and on 2026-10-22 the user ran one grouping (266 automatic assignments, §6). |
| "Device acceptance of the 2026-10-22 build is pending" | notes written earlier on 2026-10-22 | Superseded the same day: the build was installed in place and accepted (§4.2). |

## 10. Never measured (known gaps)

- Android fp16 load, inference or parity, with any execution provider.
- Full-library indexing to completion, sustained throughput, peak memory, thermal behaviour.
- Device end-to-end query latency (p50/p95 at 1k/10k/50k).
- Retrieval quality on a labelled scene set (the 24 bundled queries in `assets/evaluation/scene_queries.json` have no labels).
- Face recognition accuracy (including the 266 + 85 automatic assignments of 2026-10-22). The People scan time was
  measured once (§4.2: 1,431 photos in about 20 minutes, foreground, screen on).
- On-device suggestion confirm/reject, answering through the main-screen rounds and voice person queries
  (host-tested only).
- Background (WorkManager) indexing on any device.
- Positive GPS pins; offline and cloud speech accuracy; live caption flows.
- Release-signed build or install.
