# PixelSearch Project Context

**As of 2026-10-21.** This handbook preserves the full working context of PixelSearch so a new session can continue
without re-deriving it. It was built from a read-only audit of the tracked and untracked text files in its
inventory (§14). Each subsystem was mapped independently and its key claims were checked by two adversarial
verifiers: one against the code, one for currency against later code, diffs and docs. Where a statement is inferred
rather than read from code, it says so.

**Update 2026-10-22:** the People-search wave (§3.3 Wave 3, §5.3, §5.4, ADR-018 to ADR-022), its in-place install
and device acceptance on the Vivo, the user-requested grouping there, the "Same person?" confirmations and their
rounds on the main screen, the user's own answers, and the user's decision to resume People processing (backups
B0 to B10; §5.4).

**Update 2026-10-22, later:** the review-ready cleanup on the local branch `review-ready-2026-10-22` (§3 note, §5.4,
§6, §7, ADR-023 to ADR-025, §9, §11, §12): forward redaction, CI fix, KI-16 fixed with schema v7, FaceContract v2
(64 px), hygiene, interim licence and README.

Companion documents:

- [EVIDENCE_LEDGER.md](EVIDENCE_LEDGER.md): every measured number, with date, device, precision and caveats.
- [FILE_MAP.md](FILE_MAP.md): one line per file.
- [`pixelsearch_app/docs/ARCHITECTURE.md`](../pixelsearch_app/docs/ARCHITECTURE.md): the concise layer and ownership
  overview. It is accurate, except that it still says "schema 6" (the code is at schema 7 since 2026-10-22); this
  file adds verified detail rather than repeating it.
- [`model_kit/INTERFACE_CONTRACT.md`](../model_kit/INTERFACE_CONTRACT.md) and
  [`model_kit/FACE_CONTRACT.md`](../model_kit/FACE_CONTRACT.md): the frozen model contracts.

---

## 1. What PixelSearch is

PixelSearch is an Android-first Flutter app for semantic search over a personal photo gallery. The user describes a
remembered scene ("dog on a beach"), optionally adds registered people's names, and the app ranks the
**locally indexed** photos.

- **On the device:** gallery indexing, MobileCLIP-S1 image and text embeddings (ONNX Runtime), exact cosine retrieval,
  hybrid reranking, ML Kit labels and faces, SFace face descriptors and People data.
- **Optional online features**, each separately consented and off by default: AI captions, query rewrite or
  translation (assistant), cloud speech transcription, and OpenStreetMap tiles. The first three go through a
  self-hosted FastAPI broker that calls Groq.
- **Academic context:** a final-year B.Tech major project (blackbook report, copyright filing, research poster and
  paper drafts exist locally). Engineering standards come from
  [`pixelsearch_app/CLAUDE.md`](../pixelsearch_app/CLAUDE.md): research-grade, measured results only, ModelKit as
  the contract source of truth.

Platforms: Android is the only runtime that matters. The iOS, Linux and web scaffolds exist for platform seams and
host testing; they are not a parity claim. There is no Windows (or macOS) runner, so `flutter run -d windows` fails,
but host unit tests still run on Windows via `flutter test`. Web compiles but has no database and no models.

## 2. Status at a glance

Legend:

- **Impl**: implemented in code.
- **Commit**: in `HEAD` (C), partly uncommitted (C+U), or uncommitted only (U).
- **Device**: accepted on a physical phone (Y), partly (P), or never (N).

> **Update (2026-10-22, later):** the Commit column records the 2026-10-21/22 working-tree state. Everything marked
> U or C+U is now committed on the local branch `review-ready-2026-10-22` (not pushed), so read C as "on `main`
> (`4a7c81f`)", U as "on the branch only" and C+U as "partly on the branch only"; "HEAD" in the notes means `main`.

| Capability | Impl | Commit | Device | Notes |
|---|---|---|---|---|
| Incremental gallery indexing (scan, plan, batch commit, cancel, resume) | ✅ | C+U | P | Vivo: 140 assets on 2026-09-08, then a 1,916-photo library. Full 19k-photo completion was never run. |
| MobileCLIP image/text embedding, FP32 CPU | ✅ | C | Y | Android parity evidence is private (2 queries, 1 image row) |
| MobileCLIP FP16 / NNAPI / XNNPACK | ❌ | — | N | No execution provider is registered. FP16 v3 artifacts exist on the host only. |
| In-app model provisioning (M12) | ❌ | — | N | Models are copied in by hand (§5.1) |
| Semantic search + hybrid rerank + filters | ✅ | C | P | Only 2 judged queries (P@5 0.20 and 0.40) |
| Keyword fallback | ✅ | C | P | Visible only through a tooltip in the redesign (branch only) |
| Search diagnostics / evaluation harness | ✅ | C | P | In-app diagnostics used. The device integration test was never accepted. |
| Background indexing (WorkManager) | ⚠️ | C | N | Initialized but **never scheduled** |
| Folder-scoped indexing | ✅ | C | Y | Accepted with a small selection on 2026-09-08 |
| Indexed gallery (Home) | ✅ | C+U | Y | Redesign on the branch only, installed on the Vivo |
| Timeline (calendar-day memories, stories) | ✅ | C+U | Y | 215 events / 1,916 photos on 2026-09-10 |
| Map (EXIF GPS + consented OSM tiles) | ✅ | C+U | P | Tiles worked. 0/1,916 photos located, so no positive pin was ever seen. |
| Viewer (labels editor, caption, explanation) | ✅ | C+U | P | Live cloud caption never tested |
| Offline People (SFace, New Faces, naming, name search) | ✅ | C+U | P | Gate: the first round **failed** (2026-09-18); a fresh 20-pair round **passed** (backup B0, 2026-10-22; threshold ≈ 0.462). On 2026-10-22 the user ran "Group similar faces" once (266 automatic assignments, 137 new unnamed groups, backup B3), then resumed processing: all 1,916 photos processed and the validated automatic grouping ran after the pass (backup B8). |
| People search (query grammar, similar-face suggestions, multi-select naming, delete person, user-requested grouping, smaller naming list, "Same person?" confirmations and rounds), 2026-10-22 | ✅ | U | P | Host: 526 + 2 skipped tests on the 2026-10-22 working tree; 535 + 1 skipped at the branch tip. Installed in place on the Vivo 2026-10-22; typed person searches, hidden person, suggestions view, grouping and persistence accepted; the "Same person?" card rendered (122 questions); the user named faces and answered the questions on the phone (B5 to B6); after the resumed pass the main-screen prompt showed (70 questions, none answered by the assistant). Suggestion confirm/reject and voice input not exercised on the phone. |
| Online assistant / captions / transcription | ✅ | C+U | P | Assistant live-tested 2026-09-09. Others never live-tested. The client credential binding (`backend_credentials.dart`) and the backend hardening are on the branch only; the deployed backend runs the `f38a72c` code. |
| Backend security hardening (2026-09-18 review) | ✅ | U | N | On the branch only (`b8c3310`), not deployed |
| Release signing with an operator key | ✅ | U | N | `main` still signs release builds with the debug key; the branch requires an operator key (`c49f2d2`). No release-signed build made. |
| UI redesign (teal theme, Manrope, Privacy Centre) | ✅ | U | Y | Installed on the Vivo 2026-09-18 |
| Reviewed photo ids (schema v7, KI-16) and FaceContract v2 (64 px), 2026-10-22 | ✅ | U | N | Host-tested (535 + 1 at the branch tip); migration and upgrade rehearsed on a copy of backup B10 (v7, integrity ok, 140 of 140 review rows filled, nothing visible changes before the re-scan). Not installed: the phone still runs schema 6 and FaceContract v1. |

## 3. Repository and working-tree state

> **Update (2026-10-22, later):** everything this section calls *uncommitted* or *untracked* is now committed on the
> **local branch `review-ready-2026-10-22`** (not pushed; `main` = `origin/main` = `4a7c81f`). On top of it the branch
> adds: forward redaction and a private-data scan (ADR-025), the CI test-portability fix and workflow hardening
> (KI-17), KI-16's fix with schema v7 (ADR-024), FaceContract v2 with a 64 px minimum (ADR-023), hygiene (dead code,
> FP16 wording, onboarding claims, map tile cache, explicit assets, in-app licences), an interim LICENSE with
> THIRD_PARTY_NOTICES.md, a rewritten README and community files, then a formatting-only commit (`f1c7f9d`, listed
> in `.git-blame-ignore-revs`) and a CI `dart format` check (`9bea6d4`); 22 commits in all on 2026-10-22.
> `git log 4a7c81f..review-ready-2026-10-22` is the authoritative list. The rest of this section is kept as the
> 2026-10-21 audit record.

### 3.1 Layout (monorepo)

| Path | What it is |
|---|---|
| `pixelsearch_app/` | The Flutter app (Riverpod, go_router, Drift, `onnxruntime` 1.4.1, ML Kit, photo_manager, flutter_map) |
| `model_kit/` | Python model tooling: MobileCLIP export, fp16 conversion/repair, ArgMax patch, parity references, metrics, SFace reference fixtures. **Source of truth for the contracts.** |
| `enhancement_backend/` | Optional FastAPI broker (Groq) for captions, rewrite, assistant and transcription. `render.yaml` at the root deploys it. |
| `tool/check_repository.py` | CI publication-boundary check |
| `docs/` | Index, security review, architecture overview (untracked), archive, and these handbook files |
| `.github/workflows/ci.yml` | 4 CI jobs (§3.4) |
| `reports/`, `PIXELSEARCH_COPYRIGHT_SOURCE/`, `.impeccable/` | Local deliverables (blackbook report, copyright package, redesign tooling): untracked and not git-ignored at the audit; **git-ignored since 2026-10-22** and never committed (the note above does not apply to them). Do not `git add -A`. |
| `output/`, `tmp/` | Ignored local deliverables (posters, presentation, handbook builds) |
| `pixelsearch_app/local_evaluation/`, `pixelsearch_app/docs/RAW_SEMANTIC_DIAGNOSIS.md` | **Ignored private device data**: backups, judgments, traces. Never publish. |

ADR-006 ("two separate repositories") is superseded in layout. ModelKit is a folder in this repository, but it still
owns the contracts. `model_kit/INTERFACE_CONTRACT.md` and `pixelsearch_app/docs/INTERFACE_CONTRACT.md` are
identical apart from line endings and must stay identical.

### 3.2 History

| Commit | Date | Content |
|---|---|---|
| `14ed4c2` | 2026-07-24 | Core project code, handbook, docs |
| `ce7bf55` | 2026-08-07 | Initial handoff import (M0–M6 state) |
| `930a413` | 2026-08-08 | Remove the M1 demo gallery loader |
| `a76d3b6` | 2026-08-08 | Decode once per photo, stage profiling, `getBytes` preprocessing (TD-9), ONNX intra-op threads |
| `5f6f074` | 2026-09-09 | Android indexing and search usability fixes: eligibility gate, label policy, folder scope (schema v4), onboarding, diagnostics/evaluation, label editor |
| `a4081f3` | 2026-09-09 | Optional backend deployment (Render) |
| `f38a72c` | 2026-09-09 | Groq output budget (`max_completion_tokens` 512) |
| `8c7293e` | 2026-09-18 | The five features (schema v5: memories/timeline, explainability, OSM map, captions, voice/assistant client) plus offline People/SFace (schema v6) and New Faces. Developed 2026-09-09/10, committed 2026-09-18. |
| `4a7c81f` | 2026-09-18 | Repository layout cleanup; state-ownership split (`providers.dart` becomes an export-only barrel). **HEAD = `origin/main`.** |

Milestones in plain terms:

- **2026-07-22:** v0.1.0 (M0/M1/M3 with mock search).
- **2026-07-24:** ModelKit spike.
- **2026-08-06:** M2 persistence, M4 AI core with Flutter-ORT parity, M5 indexing core.
- **2026-08-07:** M6 hybrid semantic search.
- **2026-08-08:** M5 wired to the UI; demo removed.
- **2026-09-08:** FP16 v3 repair (ADR-016), first Vivo FP32 smoke test, folder scope (schema v4, ADR-017),
  diagnostics, and the **KI-12 uninstall incident**.
- **2026-09-09:** five features (schema v5: memories, explainability, map, captions, voice/assistant) and backend
  deploy. The backend was committed that day (`a4081f3`, `f38a72c`); the app-side features were committed only in
  `8c7293e` (2026-09-18).
- **2026-09-10:** calendar-day timeline, offline People/SFace (schema v6), New Faces (also committed in `8c7293e`).
- **2026-09-18:** security review, People validation recovery, UI redesign (uncommitted).
- **2026-09-23:** copyright package.
- **2026-10-16 to 2026-10-20:** blackbook report.
- **2026-10-18:** people name-search acceptance doc, tests and an empty-state UI (uncommitted).
- **2026-10-22:** People search (uncommitted), installed in place and accepted on the Vivo; at the user's request,
  one validated grouping run on the phone, then "Same person?" confirmations (answered by the user) and rounds of
  20 questions on the main screen; at the end of the day the user resumed People processing.

Against the original handbook: M9–M11 and M13 are implemented. M14 (faces) is implemented. Automatic grouping is
gated by a photo-disjoint review: on the Vivo the first round failed (2026-09-18) and a fresh round passed (backup
B0, 2026-10-22; its holdout has only 4 Different pairs). Grouping first ran once at the user's explicit request
(`groupNow`, 2026-10-22, §5.4); later that day the user resumed processing, so `applyGrouping` now runs after each
full pass. **Still missing:** M12 model
manager, FP16 acceptance, background scheduling, and a judged retrieval benchmark.

### 3.3 Uncommitted work

The modified tracked files are:

- 32 files from the 2026-09-18 and 2026-10-18 waves below (+3149/−1204 on 2026-10-21): code, config and tests,
  plus `enhancement_backend/README.md`. Wave 3 (2026-10-22) first modified 8 more tracked files, about 40 in all.
- the 2026-10-21 audit's documentation edits: status notes in about 17 stale docs (§10), `docs/README.md` and both
  subproject `CLAUDE.md` files

The total keeps changing while the audit adds status notes, so check `git status` for the live count. The untracked
files include the audit's root `CLAUDE.md`, `docs/PROJECT_CONTEXT.md`, `docs/EVIDENCE_LEDGER.md` and
`docs/FILE_MAP.md` (§14).

**Wave 1 (2026-09-18):**

1. **Backend hardening** (`enhancement_backend/app.py`, `requirements.txt`, `render.yaml`; untracked
   `test_security.py`).
   - ASGI `AdmissionMiddleware` authenticates and size-checks before any body bytes are read.
   - Starlette `RequestBodyLimitMiddleware` caps the body at 6 MiB; at most 2 active POSTs.
   - 60 s request deadline; the provider stream has a 45 s deadline and a 64 KiB cap; 422 responses do not echo
     input; `Cache-Control: no-store`.
   - Uvicorn `--limit-concurrency 32 --timeout-keep-alive 5`.
2. **App credential and egress hardening.**
   - Untracked `lib/data/enhancements/backend_credentials.dart`: the token is bound to the exact HTTPS origin.
   - `enhancement_client.dart` and `online_settings.dart` updated to match.
   - `map_tile_client.dart`: 2 MiB per tile, 20 s deadline.
   - `android/app/build.gradle.kts`: release signing from 4 env vars, debug fallback removed.
3. **Biometric deletion.**
   - `app_database.dart deleteAssets` also deletes the photos' People faces and scans, orphaned decisions and
     reviews, and dangling cover faces. It resets the People threshold and calibration only if a face or review row
     was removed. (Changed in Wave 3, 2026-10-22: review rows are now kept, and the reset happens when a face was
     removed.)
   - `indexing_wiring.dart` `onDispose` runs People `reconcile()` and `pruneCrops()`.
4. **People validation recovery.** Diagnostic candidate cutoff, false-join and missed-same ids; "Check 20 new pairs"
   (`prepareFreshValidation`); rowid ordering; results sheet; `peopleCalibrationProvider`.
5. **UI redesign** ("Impeccable" process):
   - teal seed `#176B62`, bundled Manrope (untracked `assets/fonts/`; the pubspec font entry is uncommitted)
   - Privacy Centre settings
   - single-scroll Home with a pinned search field and a floating date thumb
   - dark viewer
   - navigation rail at ≥ 700 dp
   - map photo pins
6. **Untracked Wave 1 tests and tools:** `test/backend_credentials_test.dart`, `test/redesign_widgets_test.dart`,
   `test/people_validation_recovery_test.dart`, `test/home_scroll_widgets_test.dart`, `tool/audit_people_review.py`,
   and `docs/architecture/pixelsearch-all-in-one.eraser`.

**Wave 2 (2026-10-18):** a "No confirmed photos of X / Review new faces" empty state (`search_screen.dart`,
`empty_state.dart`); changes to the tracked `test/people_widgets_test.dart`; the untracked
`test/people_name_search_test.dart`; and `docs/PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md`.

**Wave 3 (2026-10-22): People search.** Host-verified (ledger §1), then installed in place on the Vivo and accepted
the same day (ledger §4.2). No schema, model, ranking-constant or `FaceContract` change (ADR-018 to ADR-022).

- New, untracked lib files (7): `lib/domain/people/people_membership.dart`, `face_suggestions.dart`,
  `people_search_state.dart`, `same_person.dart`; `lib/domain/search/query_text.dart`;
  `lib/features/people/person_suggestions_screen.dart`, `same_person_screen.dart`.
- New, untracked tests (4): `test/people_query_parser_test.dart` (52), `test/people_membership_test.dart` (21),
  `test/people_suggestions_test.dart` (27, including 5 for `groupNow`, grouping safety and the naming list),
  `test/people_same_person_test.dart` (24, including 4 for rounds and the home prompt and 3 from the second
  verification pass). Extended:
  `people_validation_recovery_test.dart` (+3),
  `people_widgets_test.dart` (+21), `voice_search_widgets_test.dart` (+7); `people_repository_test.dart` now expects
  `deleteAssets` to keep review rows.
- Rewritten tracked `lib/domain/people/people_query.dart`. Changed: `people_repository.dart`, `app_database.dart`
  (`deleteAssets`), `people_providers.dart`, `search_providers.dart`, `search_response.dart`, `people_screen.dart`,
  `people_widgets.dart`, `search_screen.dart`, `conversation_sheet.dart`, `search_explanation.dart`,
  `empty_state.dart`.
- Added later the same day at the user's request (ADR-020): `PeopleRepository.groupNow()` behind People ⋮ "Group
  similar faces", and a smaller naming list (`PeopleSnapshot.facePixels`, `smallOrDuplicateFaces`, `namingQueue`,
  `toName`) with "Show small faces (N)" (§5.4).
- Added last, also at the user's request (ADR-021): Google-style "Same person?" confirmations
  (`buildSamePersonQuestions`, `PeopleRepository.samePersonQuestions` and `answerSamePerson`,
  `samePersonQuestionsProvider`, `SamePersonScreen`, and an entry tile on the People screen) (§5.4). Then rounds of
  20 per launch with a prompt on the Search home (`SamePersonPrompt`; ADR-022) and the fixes from an independent
  review (14 confirmed issues).
- New dated doc: `pixelsearch_app/docs/PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md` (untracked).

Untracked docs that matter: `docs/SECURITY_REVIEW_2026-09-18.md`, `docs/architecture/README.md`, `DESIGN.md`,
`PRODUCT.md`, `pixelsearch_app/docs/{ANDROID_RELEASE_SIGNING,PEOPLE_VALIDATION_2026-09-18,PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE}.md`.

Commit-hygiene traps:

- Committing `pubspec.yaml` without `assets/fonts/` breaks CI.
- Committing `build.gradle.kts` without `docs/ANDROID_RELEASE_SIGNING.md` leaves its error message pointing at a
  missing file.
- Committing `enhancement_client.dart` or `online_settings.dart` without the untracked `backend_credentials.dart`
  (and its test) breaks compilation in CI: both import it. Likewise `redesign_widgets_test.dart` and
  `home_scroll_widgets_test.dart` import helpers from the modified `indexed_gallery_widgets_test.dart`. Wave 3's
  tracked files import its seven untracked lib files (for example `search_providers.dart` imports
  `people_membership.dart`, and `people_screen.dart` imports `same_person_screen.dart`). Commit each wave's
  untracked files together with the tracked files that import them.
- The untracked tests and `test_security.py` do not run in CI until they are committed.
- All three waves are **installed on the Vivo** although uncommitted. Until 2026-10-22 only Wave 1 was (backup B0
  showed a build last updated on 2026-09-18); on 2026-10-22 a debug build of the working tree replaced it in place.

### 3.4 CI

`.github/workflows/ci.yml` runs four jobs:

- **repository:** Python 3.12, `tool/check_repository.py`.
- **backend:** Python 3.12, `pip install -r requirements.txt -c requirements.lock`, then `pytest -q`.
- **flutter:** 3.44.7, `pub get`, `build_runner`, `analyze`, `flutter test test/`.
- **modelkit:** Python 3.11, `eval/test_metrics.py`.

It never builds an APK and never runs `integration_test/`, the SFace model test or `test_fp16_conversion.py`.

**CI has failed on the last four pushes, including HEAD.** At HEAD the Flutter job reports 3 failures out of 328.
HEAD passes locally (Windows, +05:30), so the 3 CI failures depend on something that differs in the CI environment:
the OS, the timezone, the Flutter SDK version or freshly generated code. The cause has not been identified because
the run 7 log has not been read. See
[EVIDENCE_LEDGER §2](EVIDENCE_LEDGER.md#2-ci-history-github-actions-public-repository).

> **Update (2026-10-22, later):** the cause was found by a Windows-host simulation (KI-17: a Windows-only test font
> loaded as 'Roboto', and Windows-only path literals in one test) and fixed on the branch. The branch's workflow
> also runs on `ubuntu-24.04` with a read-only token, enforces the lockfile, checks that regenerated Drift code
> matches, and checks `dart format`. None of this has run on GitHub yet (nothing pushed), and a local Linux run
> failed because Docker Desktop did not start.

## 4. Architecture

### 4.1 Layers

The layer list is in [`ARCHITECTURE.md`](../pixelsearch_app/docs/ARCHITECTURE.md). Its main rules:

- `features/` are screens.
- `state/` holds the Riverpod composition.
- `domain/` holds the hybrid scorer, query terms, people query parsing and grouping, face alignment, gallery and
  timeline. It is mostly pure (`face_alignment.dart` imports `package:image`). The production ranking policy and
  semantic gating live in `data/search/search_ranking.dart` and `semantic_search_backend.dart`.
- `data/` holds repositories, Drift and online clients.
- `indexing/` is a hexagonal pipeline.
- `ai/` holds the tokenizer, preprocessing and encoders.
- `core/` holds the router, theme, model locator, contract and platform seams.
- `evaluation/` holds the retrieval metrics.

### 4.2 State ownership

- `lib/state/providers.dart` must contain **only `export` lines** (and `//` comments); CI checks this through
  `check_repository.py`. It re-exports seven owner files: `storage`, `preferences`, `online`, `library`, `query`,
  `indexing` and `search`. `provider_exports_test.dart` asserts that 14 provider identities survive the barrel.
- `people_providers.dart` is **not** exported through the barrel; import it directly.
- No state file may import the barrel. CI detects only the relative form `import 'providers.dart'`; a `package:`
  import of the barrel from `lib/state` is not caught.
- Exceptions to "state lives in `lib/state`" (all also present on `main`):
  - `features/map/map_screen.dart`: `locationRepositoryProvider`, `locatedPhotosProvider`,
    `locationSummaryProvider`, `mapTileFactoryProvider`.
  - `features/timeline/timeline_screen.dart`: `memoryRepositoryProvider`, `memoriesProvider`,
    `memoryTimelineProvider`.
  - `features/search/conversation_sheet.dart`: `conversationHistoryProvider`.
  - `features/search/search_diagnostics_screen.dart`: `evaluationDatasetProvider`.
  - Direct DB use from widgets: `caption_screen.dart` writes `saved_captions` through `appDatabaseProvider`, and
    `people_screen.dart` acquires the `face-model-check` lease through `appDatabaseProvider`.
- Indexing and People coordinate:
  - Foreground indexing suspends People (`peopleControllerProvider` listens to `indexingControllerProvider`) and
    kicks it when the run ends, if People is enabled, unpaused and in the foreground. Background indexing is
    serialized only through the lease and returns a retryable `false` when the lease is taken.
  - A cross-isolate SQLite `ProcessingLease` serializes heavy work: foreground index, background index, People
    scan and the face-model check. It is a single row, `processing_leases` id 0, with a TTL of 5 min and a 10 s
    heartbeat.
  - **Search never takes the lease.**

### 4.3 Platform seams (conditional imports keep web compiling)

| Seam | Native | Stub |
|---|---|---|
| `state/index_bridge.dart` | runs the device pipeline | `unsupported` |
| `state/semantic_wiring.dart` | builds `SemanticSearchBackend` if a text model exists | `null` (keyword) |
| `core/platform_image.dart` | `FileImage` / `DeviceThumbnailImage` | placeholder |
| `data/local/connection/connection.dart` | `NativeDatabase.createInBackground` | throws `UnsupportedError` |
| `data/people/face_processor*.dart`, `face_model_check*.dart` | SFace worker isolate on any `dart:io` platform; the face model check also runs on desktop (Windows via `fromBuffer`); gallery face processing (`process`) is Android-only | unsupported |
| `indexing/adapters/background_indexing_bootstrap*.dart` | `Workmanager().initialize(...)` | no-op |
| `data/user_preferences_storage*.dart`, `evaluation/evaluation_storage*.dart` | files in app support | memory / none |

### 4.4 Where data lives (on device)

| Store | Location | Contents |
|---|---|---|
| Drift SQLite, schema **7** in code since 2026-10-22 (KI-16; the phone's installed build is still schema 6) | `<appDocuments>/pixelsearch.sqlite` | 14 Drift tables plus raw-SQL `processing_leases` (§7) |
| Preferences | `<appSupport>/user_preferences.json` (atomic `.pending` + rename) | onboarding flag, online consent and `base_url`, offline speech locales, **label corrections** keyed `photoId\|assetName` |
| Secure storage | `flutter_secure_storage`: key `backend_connection_v1` on the branch; key `backend_install_token` on `main` | Branch: `{origin, token}`; saving deletes the legacy key without migrating it, so the token must be entered again. `main`: a bare backend token with no origin binding. |
| Thumbnails | `<temp>/thumbnails/<id>.jpg` (256 px, q80) | OS-evictable; display falls back to a gallery thumbnail |
| MobileCLIP models | `<appSupport>/models/` | provisioned by hand |
| SFace model | copied from bundled asset to app support after a SHA-256 check | — |
| People crops | `<appSupport>/people_crops/` + `run_summary.json` | face crop previews |
| Evaluation | `<appSupport>/search_evaluation/{queries,latest_report}.json` | judgments and reports. The report includes filenames and query vectors; never auto-deleted. |

On Android, `<appDocuments>` is `/data/user/0/com.pixelsearch.pixelsearch/app_flutter` and `<appSupport>` is
`.../files`. `allowBackup=false`. `backup_rules.xml` and `data_extraction_rules.xml` (cloud backup and device
transfer) exclude the root, file, database, sharedpref and external domains; the `device_*` domains are not listed.

## 5. End-to-end workflows (traced in code)

### 5.1 First run and model provisioning

1. `StartupScreen` shows onboarding. Onboarding is skipped if `onboarding_complete` is set or the index already has
   photos.
   - "Index my photos" opens the folder picker. That triggers the photo permission request and starts indexing
     without awaiting it.
   - Onboarding is then marked complete **whatever the outcome**.
   - The onboarding copy claimed "Results in under two seconds", an unmeasured figure, until 2026-10-22, when the
     claim was removed on the branch (`462d7af`).
2. If no MobileCLIP image model exists, `runDeviceIndexing` returns `modelMissing` before any scan, so no rows are
   written. The only signal is one grey status line naming the expected path. It is held in memory and lost on
   restart. **The app gives no in-app guidance.** That line lists `mobileclip_image_fp16.onnx` before
   `mobileclip_image.onnx` (`ModelLocator.describeMissing`), so do not follow it literally: provision only the FP32
   files.
3. Without a text model, search falls back to keyword matching. Since the redesign (on the branch) the only
   indication is tooltip text; on `main` a visible keyword/semantic mode icon (`_ModeBadge`) showed it. Diagnostics
   refuse to run.
4. After models are added, nothing notices automatically. The user re-runs indexing. Because nothing was written,
   every selected asset is planned `added`.

**Manual provisioning (debug builds only; release builds are not debuggable, so `run-as` fails):**

Generate the exports with `cd model_kit && python prepare_model.py` (it uses a relative `out/`, so run it from
inside `model_kit/`). It writes both the FP32 files (`mobileclip_image.onnx`, `mobileclip_text.onnx`) and the FP16
files to `model_kit/out/`. Push only the FP32 files: FP16 is not accepted on Android (KI-2,
`ANDROID_SMOKE_TEST_2026-09-08.md`). (`model_kit/README.md` and `prepare_model.py` said to ship the FP16 files
until 2026-10-22, when that text was corrected.)

On Windows, run the block below in PowerShell or cmd. In Git Bash, prefix each command with `MSYS_NO_PATHCONV=1`
(or export it once first); otherwise MSYS rewrites every `/data/...` argument into a Windows path.

```sh
# from the repo root, with the FP32 exports in model_kit/out/
adb push model_kit/out/mobileclip_image.onnx /data/local/tmp/
adb push model_kit/out/mobileclip_text.onnx  /data/local/tmp/
adb shell chmod 644 /data/local/tmp/mobileclip_image.onnx /data/local/tmp/mobileclip_text.onnx
adb shell run-as com.pixelsearch.pixelsearch mkdir -p files/models
adb shell run-as com.pixelsearch.pixelsearch cp /data/local/tmp/mobileclip_image.onnx files/models/
adb shell run-as com.pixelsearch.pixelsearch cp /data/local/tmp/mobileclip_text.onnx  files/models/
adb shell rm /data/local/tmp/mobileclip_image.onnx /data/local/tmp/mobileclip_text.onnx
# check for leftover fp16 files (earlier handoff docs said to ship them) and remove them
adb shell run-as com.pixelsearch.pixelsearch ls files/models
adb shell run-as com.pixelsearch.pixelsearch rm -f files/models/mobileclip_image_fp16.onnx files/models/mobileclip_text_fp16.onnx
# compare the device hashes with the host hashes of the files you pushed (in PowerShell, use Get-FileHash on the host)
adb shell run-as com.pixelsearch.pixelsearch sha256sum files/models/mobileclip_image.onnx files/models/mobileclip_text.onnx
sha256sum model_kit/out/mobileclip_image.onnx model_kit/out/mobileclip_text.onnx
```

The device and host hashes must match. `pixelsearch_app/docs/ANDROID_SMOKE_TEST_2026-09-08.md` records the reference
hashes of the 2026-09-08 exports (image `8c5b72db…`, text `593f6eb8…`). A freshly regenerated export is not
guaranteed to be byte-identical, so a mismatch with those reference values does not by itself mean a bad copy.

> **Do not push the `*_fp16.onnx` files.** `ModelLocator` prefers fp16, and fp16 is unaccepted on Android. A
> leftover `mobileclip_text_fp16.onnx` on the device is still selected after the FP32 files are pushed, so run the
> check and cleanup lines above.
> - Image selection falls through to fp32 only if the fp16 session *fails to load*. A session that loads but fails
>   at inference makes every asset fail.
> - Text has no fallback at all: an unusable fp16 text model latches keyword mode.
> - Embedding rows do not record precision, so fp16 and fp32 vectors would mix silently.

### 5.2 Indexing (`lib/indexing/`, `lib/state/indexing_providers.dart`, `lib/state/index_bridge_io.dart`)

1. **Trigger.** `chooseFoldersAndIndex` (onboarding, Home or Privacy Centre) opens `FolderPickerScreen`. It saves a
   `FolderSelection` of MediaStore folder **IDs** (sorted JSON in `indexing_preferences_rows` id 0). Then
   `IndexingController.start()`:
   - suspends People
   - acquires the `foreground-index` lease (`onLost` cancels the run)
   - calls `runDeviceIndexing`
2. **Bridge.**
   - Refuses an empty selection, then requests image permission.
   - Lists model candidates (fp16, then fp32) and **selects by loading**: `buildDeviceIndexingService` loads the
     ORT session, and the next candidate is tried only if that throws.
   - Binds the cancel token and runs `IndexingService.run()`; disposes in a `finally`.
3. **`run()`** has four phases:
   - **Scan:** `PhotoManagerGallerySource.listAssets` pages MediaStore 500 at a time. For a subset selection with
     full access, it also scans whole-gallery metadata to learn which IDs exist. Limited access sets
     `canDeleteMissing=false`. A missing selected folder throws `StateError`.
   - **Plan:** `IndexPlanner.reconcile` marks each asset `added`, `changed` (mtime or byteSize differs; **the adapter
     hard-codes `byteSize: 0`, so change detection is mtime-only**), `staleVersion` (embedding version differs or
     no embedding), up-to-date, or deleted (only when `canDeleteMissing`).
   - **Delete:** `deleteAssets` cascades to memory members, captions, locations, embeddings and photos. The People
     cascade (2026-09-18) is on the branch only, not on `main`.
   - **Index:** per asset: `originBytes` → EXIF date only → **one** `img.decodeImage` (image 4.9.1 applies JPEG EXIF
     orientation) → 256-px q80 thumbnail → CLIP embedding → ML Kit labels and faces on the original bytes via a
     temp file.
     - Labels are kept only if `0.5 ≤ confidence ≤ 1`, with no fallback. The CHANGELOG's "every photo gets tags"
       fallback was removed in `5f6f074`.
     - Results are buffered and committed in **one Drift transaction per 32 items**, followed by a checkpoint and a
       progress event.
     - The loop yields `Duration.zero` between assets.
     - A per-asset failure is counted and never persisted, and the asset is **retried on every run** under its plan
       reason: `added` if it was never indexed, otherwise `changed` or `staleVersion`. In the latter cases the
       previous row and embedding stay in place and stay searchable. HEIC is not decodable by `image` 4.9.1
       (inferred).
     - A stage profile is logged every 20 assets.
4. **After the run**, the controller releases the lease, refreshes `photoLibraryProvider` and invalidates
   `indexWarmupProvider`. New photos become searchable only after the run ends (KI-6).
5. **Threading.** Decode, preprocessing, thumbnail encoding and the blocking ORT `session.run` execute on the **UI
   isolate** (TD-17). ML Kit runs natively and SQLite in a background isolate.
6. **Background.** `main.dart` awaits `initializeBackgroundIndexing()`, which registers `indexCallbackDispatcher`
   with WorkManager. **Nothing ever calls `WorkManagerScheduler.scheduleIndexing()`**, so no background job runs.
   The manifest has no foreground service. KI-10 (OEM screen-off freeze) is unresolved.
7. **Folder deselection** keeps already-indexed rows. Nothing applies a folder filter at read time: Home, search,
   map, timeline and People all show them. Folder scope controls scanning; it is **not** a visibility or privacy
   control (ADR-017).

Known defects (inferred from code, untested):

- A cancel tapped before `run()` starts is lost. The token replays it on `bind`, but `run()` then resets
  `_cancelRequested`.
- Any run-level error (scan, plan, delete, batch commit or checkpoint) is caught inside `run()`, logged, and
  surfaces only as "Indexing stopped unexpectedly after N photos". The cause is visible only in the log.
- The `onDispose` People cleanup (2026-09-18, on the branch) runs inside the bridge's `finally`. A throw there would replace a
  successful result.
- The background lease has no `onLost` handler.
- The checkpoint row (`index_state_rows`) is written but never read in production.

### 5.3 Semantic search and ranking

1. **Query parsing.**
   - `debouncedQueryProvider` mirrors `searchQueryProvider` with a 300 ms delay for non-empty queries
     (`query_providers.dart`).
   - `peopleQueryProvider` (`state/people_providers.dart`) watches it and calls `resolvePeopleQuery`
     (`domain/people/people_query.dart`; the assistant also calls it directly from `conversation_sheet.dart`), which
     strips registered names and aliases (whole-word, longest first) and one preceding relationship word.
   - A single year, "this year" or "last year" becomes a date filter. That parsing runs only when a name matched or
     a person filter is already set, and it overwrites preset dates.
   - An ambiguous alias returns an empty "choose person" response.
   - **Person-query grammar (Wave 3, 2026-10-22; ADR-019).** `resolvePeopleQuery` is still the only parser.
     - "me" and "myself" share one self key. A self word is not a subject after a request verb (show, find, get,
       give, …) unless it is coordinated or placed ("show me and X", "show me at the beach"), or after
       near/around/for/by/close to.
     - With People enabled and nobody marked "This is me", a subject "me" sets `selfMissing`.
     - Roles: required (AND, the default); any-of (names joined only by "or" or ","); excluded (after without,
       except, excluding, but not, not, no, neither, minus, apart from, other than, everyone but, …; "nor" continues
       an exclusion). Mixed and/or wording falls back to AND.
     - Possessive 's, edge punctuation and fillers are stripped only in person queries. A query that names nobody
       is returned byte-identical. Saved spellings are matched as well as lower-cased keys.
     - The result lists each `PersonMention` (query order, role, label, isSelf). `prunePeopleSelections` keeps name
       choices and dismissed chips while further words are typed.
     - Hidden people are not matched from typed text; only "me" still resolves to a hidden "This is me" person.
   - `selfMissing` and `needsChoice` short-circuit `searchResponseProvider`: no backend is called, so "me" never
     reaches CLIP and an ambiguous name is never guessed.
2. **Backend.**
   - `searchBackendProvider` waits for `indexWarmupProvider`, which loads all current-version embeddings into
     `BruteForceVectorIndex`.
   - It then builds `SemanticSearchBackend` only if a text model file exists (`resolveText` takes the first present
     file, with **no load fallback**). Otherwise it uses `KeywordSearchBackend`; web always uses keyword.
   - The ORT session loads lazily.
3. **Healthy semantic mode** (`data/search/semantic_search_backend.dart`, `search_ranking.dart`,
   `domain/search/hybrid_scorer.dart`):
   - With no name match and no person filter, the query reaches MobileCLIP unchanged. When a name matched or a
     person filter is set, `resolvePeopleQuery` removes the name and any qualifying relationship phrase, a single
     year/this-year/last-year phrase (turned into a date filter), a leading "show me photos of…" prefix and
     leading/trailing connectors, then collapses whitespace. Only that remainder is embedded: for example,
     `photos of <name> at the beach in 2023` reaches CLIP as `the beach`.
   - Filters (date `[from, until)`, album and place by exact match, people as eligible IDs) are applied **before**
     Top-K.
   - Exact dot-product scan, **topK = 60**, then the raw-cosine gate **≥ 0.15**.
   - Scoring: `final = 0.70·clamp(cos/0.35, 0, 1) + 0.25·(lex/maxLex) + 0.05·face`.
     - Lexical scaling is zero-anchored, *not* min-max as ADR-014 says.
     - The face term is `min(faceCount, 3)/3`, and only for face-intent words (people, person, selfie, group,
       family, wedding, …).
   - Scores ≤ 0 are dropped; ties go to the newer date, then id. Above cosine 0.35 the semantic part saturates, so
     strong matches tie and order by date.
   - **No lexical-only union.** ML Kit labels are excluded from lexical scoring (`Photo.metadataSearchBlob`), and the
     articles a/an/the are ignored.
4. **Keyword fallback** comes from two different rankers, which can order the same query differently:
   - With no model, or on web, `KeywordSearchBackend` ranks by raw keyword score and then date (mode `keyword`). It
     applies no hybrid scorer and no face term.
   - With an empty index or a tripped latch, `SemanticSearchBackend` ranks lexical-only candidates through
     `HybridScorer`, so the face-intent boost still applies and ties fall back to id (mode `keyword fallback`).
   - Both include labels, keep articles, match substrings and union every positive lexical hit.
   - Any load or embed exception latches the fallback for that backend instance. The backend is rebuilt after each
     indexing run, which resets the latch.
5. **People.**
   - A name-only query bypasses CLIP and returns that person's photos newest first.
   - A name plus a scene sends only the remaining text to CLIP, restricted to the eligible IDs.
   - Eligible IDs come from `matchPeoplePhotos` (Wave 3): (⋂ required) ∩ (⋃ any-of) − (⋃ excluded), over assigned,
     non-dismissed faces. Unknown ids and People off fail closed. They respect the photos the app can currently
     access, so person results can shrink silently when permission is reduced.
   - Membership comes from the cached People snapshot (`peoplePhotoIndexProvider`), so a person query adds no table
     loads. Exclusion covers assigned faces only (KI-14/KI-15).
   - Results carry a `PersonFilterSummary`. When a person search is empty, `explainEmptyPeopleSearch` says why:
     `selfMissing`, `peopleOff`, `noAssignedPhotos`, `notTogether`, `allExcluded`, `noneInFilters` or
     `noSceneMatch`. For `selfMissing` the screen asks "Which person is you?" and offers "Open People" and
     'Search without "me"'.
   - Search chips show "You", a name, "either X" or "not X", and a People filter chip picks people by hand. The
     viewer explanation says "Matched by assigned faces" and prints no ids.
6. **Semantic-mode results carry an explanation map** (raw and used cosine, components, weighted contributions,
   matched terms and metadata, gate, pool), shown in the viewer under "Why this matched". Keyword-backend results
   (no model, web, name-only People queries) carry only lexical evidence. Browse results carry none, and the viewer
   says so.
7. **Mode visibility.** The redesign (on the branch) shows semantic versus keyword mode **only in tooltip text**.
   `main` had a mode-specific icon. `isSemantic` stays true with an empty index even though the response mode says keyword.

Calibration status: the gate comes from six probes, and the band and weights are uncalibrated (KI-5/KI-13). On the
1,916-photo library the judged relevant "dog" photo has a lower cosine than irrelevant ones, so no gate can fix it.
The cause is classified as a MobileCLIP limitation [PARTIAL]. **Change weights, gate or lexical policy one at a
time, and only with judged held-out evidence.**

### 5.4 Offline People (`lib/data/people/`, `lib/data/people_repository.dart`, `lib/domain/people/`, `lib/features/people/`)

- **Opt-in.** `people_state.enabled` defaults to false and enabling it shows a consent dialog. Processing is Android
  only. Its work list is the indexed `photo_rows`, and it never enumerates the gallery. It does open each indexed
  photo's original file through photo_manager (`AssetEntity.fromId` → `originFile`) to detect faces, and under
  limited permission the accessibility check calls `AssetEntity.fromId` for every indexed photo.
- **Contract `sface-2021dec-mlkit-landmarks-v2`** in code since 2026-10-22 (ADR-023); the phone's installed build
  still runs `sface-2021dec-mlkit-landmarks-v1`. The two differ only in the minimum face size:
  - `PeopleImageDecoder.kt` decodes with a power-of-two downsample (longest side ≤ 2048), applies EXIF rotation, and
    writes a q95 JPEG.
  - ML Kit runs in accurate mode with landmarks and `minFaceSize` 0.02.
  - The five landmarks are put in image order and fitted to the SFace template with a least-squares similarity
    transform, then warped to 112×112.
  - The input is raw 0..255 RGB in CHW layout; the graph normalizes internally.
  - The bundled OpenCV Zoo SFace FP32 model (SHA-256 `0ba9fbfa…`) outputs `fc1`, 128-d. It is L2-normalized and must
    satisfy |Σx² − 1| ≤ 0.002.
  - Only faces with 5 landmarks and a box ≥ 64 px on both sides get a descriptor (FaceContract v2 since 2026-10-22,
    ADR-023; 100 px under v1). A re-scan under a new contract continues each matching earlier face by box overlap,
    keeping its id, name, assignment, "Not a face" and decisions; v1 faces stay visible until their photo is
    re-scanned, and reviews under v1 keep grouping off ("Face settings changed") until a new round passes.
- **Storage.**
  - Descriptors are 512-byte little-endian float32 blobs in `people_faces.vector`, never in `embedding_rows`.
  - The face id is derived from photo, revision, contract and index; a face continued across a contract upgrade
    keeps its earlier id (ADR-023). A changed photo revision drops its faces.
  - Commits fail closed if People is disabled or paused, or if the generation or revision changed.
    `insertOrIgnore` preserves user corrections.
- **Grouping gate.** No default threshold exists. Automatic grouping writes nothing unless `calibration()` passes:
  - At least 40 frozen pairs must exist and all must be judged (Same/Different/Unsure; none pending). Unsure counts
    toward the 40 but is ignored by the cutoff, and each subset needs at least one Same and one Different.
    - Pairs are photo-disjoint. The first review splits photos by `stableHash(photoId) % 3 == 0` (validation). In a
      fresh round (the 2026-09-18 recovery, on the branch), all earlier pairs become calibration and 20 validation pairs are sampled from
      never-reviewed photos. `calibration()` blocks any subset overlap.
    - Up to 40 calibration and 20 validation pairs are sampled from 3 nearest neighbours plus 1 farthest per face.
  - The cutoff is the calibration Same cosine with the most true joins and zero calibration false joins.
  - Validation must then show **zero false joins and at least one true join**.
  - Admission is complete-link with ambiguity rejection, same-photo exclusion and rejection memory.
  - **Deleting photos keeps review evidence (Wave 3, 2026-10-22).** `deleteAssets` keeps review pairs (face ids, a
    cosine and a judgment). A pair whose face is gone makes calibration fail closed ("A reviewed photo changed or is
    unavailable. Start a new review.") instead of re-scoring the remaining pairs, which might pass. "Disable and
    delete People data" still removes them.
  - **KI-16 (found and fixed 2026-10-22, ADR-024):** reviewed photos were identified only through current face ids,
    which include the photo revision, so an edited reviewed photo could be sampled into a new round. Schema v7
    stores the reviewed photo ids on review rows (filled from existing faces by the migration), and the
    reviewed-photo set unions them with the old face join.
- **User-requested grouping (Wave 3, 2026-10-22; ADR-020).** `groupNow()` runs the existing validated grouping
  (`groupFaces`, complete-link, the saved review cutoff) once at the user's explicit request, even while processing
  stays paused. It returns 0 unless People is enabled and the review gate passed. `applyGrouping()` (after a full
  processing pass, or after a passed review) still never runs while paused. UI: People ⋮ "Group similar faces",
  enabled only when the gate passed, behind a confirmation dialog; the review result loads with the screen. Only
  faces with descriptors take part (≥ 100 px under v1, the phone's build; ≥ 64 px under v2 after a re-scan, and only
  once a review round under v2 passes); wrong faces are fixed by moving or removing them.
- **Naming list (Wave 3, 2026-10-22; ADR-020).** `PeopleSnapshot.smallOrDuplicateFaces` (computed once per snapshot)
  holds faces under 40 px in the prepared image (`facePixels`, which halves the size as the Android decoder does
  until the long side fits 2048) and second detections that overlap a larger face in the same photo by IoU > 0.5.
  Only unassigned faces and automatic faces in unnamed groups are considered; nothing the user named is hidden, and
  grouping skips the duplicates. New Faces hides them behind "Show small faces (N)"; nothing is deleted, and they
  can still be named from the photo. `namingQueue()` and `toName()` drive the list ("N to name" counts each unnamed
  group once), and unnamed groups are listed largest first.
- **Device (Vivo):**
  - 2026-09-18: the first round failed (1 false join), and the user paused processing.
  - Backup B0, 2026-10-22 (aggregate): a fresh round of 60 calibration and 20 never-reviewed validation pairs
    **passed**. Calibration 46 Same / 14 Different; validation 16 Same / 4 Different, 0 false joins, 16 true joins;
    threshold ≈ 0.462. The app's wording is "Passed this reviewed sample; not a general accuracy guarantee", and the
    holdout has only 4 Different pairs.
  - Before grouping (backups B0 to B2): 0 automatic and 6 manual assignments, 5 named persons (1 marked "This is
    me", 0 hidden) and 7 faces marked Not a face.
  - Why the same person appeared many times (aggregate, from the backups): 2,342 detected faces in 430 photos; only
    336 are large enough (≥ 100 px) for an SFace descriptor, and the other 2,006 can never be grouped under
    contract v1 (the phone's build; v2 lowers the minimum to 64 px, ADR-023). 67 photos have 10 or more faces. Duplicates are a minor factor: 26 overlapping same-photo
    detection pairs and about 20 near-identical cross-photo pairs (the same image saved twice).
  - "Group similar faces", run once at the user's request (backup B3): 266 faces assigned `automatic` (3 of them to
    a named person, whose photos went from 1 to 4; the rest into 137 new unnamed groups, 142 persons in all). Only
    `people_faces` and `people_persons` changed; reviews, scans, decisions, photos and embeddings are identical, the
    threshold is unchanged, no face went to a person it was rejected for, and there are no orphans. A host
    simulation of the same code on a copy of backup B1 predicted exactly 266 / 137 / 3. The People header now reads
    142 groups, and New Faces shows 1,402 to name (was 2,329 face entries) with 798 behind "Show small faces".
  - "Same person?" build, installed in place twice more (backups B4 and B5 before the installs; tables identical
    from B3 to B5, so viewing writes nothing): the People tile reads "Same person? | 122 quick questions", that is 3
    verify questions (the 3 automatic faces in a named person) and 119 group pairs at or above the user's lowest
    "same" review score (≈ 0.398). A host simulation on a copy of backup B3 counted 9,347 possible group pairs, of
    which only 11 score ≥ 0.5. The first card is "Is this `<P0>`?" with "Added automatically". The assistant
    answered no question.
  - Review score ranges of the current round (backup B3): calibration Same 46 (0.398–0.996), Different 14
    (0.307–0.439); validation Same 16 (0.478–0.997), Different 4 (0.329–0.399). The Same and Different ranges
    overlap, so the 0.398 floor only limits which pairs are asked; it cannot tell people apart.
  - The user's answers and naming (B5 to B6): persons 142 → 127, manual 6 → 35, automatic 266 → 239, accept 6 → 35,
    reject 1 → 736, "me" photos 1 → 11; only the People faces, persons and decisions tables changed, and every
    must-be-zero check stayed 0. "photos of me with `<P3>`" now returns 2 results (the user named their own face in
    the shared photos).
  - The rounds build (backup B7, identical to B6) found no question left: of the group pairs, 79 were answered No or
    Not sure, 104 share a photo, 7,319 score below the floor and 1 joins two named people.
  - **Processing resumed (user's decision, 2026-10-22).** The pass ran from about 10:41 to 11:02 with the app open
    and the screen on: 1,431 photos at about 1.2 per second. Backup B8: 1,916 of 1,916 photos processed; faces 2,342
    → 2,642, descriptors 336 → 397. The validated `applyGrouping` then ran: automatic 239 → 324, groups 127 → 152,
    nothing added to a named person; manual assignments, decisions, reviews and the threshold unchanged; only the
    People faces, persons and scans tables changed. The People screen read "1916 of 1916 photos processed | 2642
    faces | 152 groups", "Same person? | 70 quick questions" and "1497 to name", and the main screen showed "Help
    improve face groups · 1 of 20". A host simulation on a copy of B8 counted the same 70 questions: all group
    pairs, 5 of them offering a named person, closest-face scores 0.399–0.983 (15 at 0.5 or more). None was answered
    by the assistant.
  - Three more builds with the later fixes were installed in place (the seventh to ninth installs, after backups B8,
    B9 and B10): B9 is identical to B8 in every table, and B10 differs from B9 only by one processing-lease row.
- **Naming.** The New Faces picker supports assign or new person, remove assignment, and dismiss ("Not a face").
  The name dialog offers "This is me" (adds the aliases `me`/`myself`). The person screen (`PersonScreen`) offers
  merge (the source name becomes an alias of the target), hide/unhide and choose cover. Manual decisions are
  authoritative.
- **Assisted naming (Wave 3, 2026-10-22; naming itself host-tested only, the screens rendered on the Vivo).**
  - New Faces is ordered newest photo first. Multi-select offers "Name selected faces" ("All N faces will be named as
    one person.") and "Not a face", both with Undo. The header shows "| Paused" while processing is paused.
  - "Faces marked Not a face" lists dismissed faces so they can be restored.
  - The name dialog shows who currently holds "This is me", which belongs to one person only. Aliases are
    de-duplicated case-insensitively. Merging into an unnamed group adopts the name. After saving, "Saved X." offers
    "Review similar".
  - `PersonScreen` adds "Search photos of X" (it works for hidden people too), "Delete person" and "Review similar
    faces".
  - Repository face validation loads one snapshot per action.
- **Similar-face suggestions (ADR-018).** `rankFaceSuggestions` orders unnamed faces with descriptors by their
  maximum cosine to the person's **manually** assigned faces (ties: mean of the top three, then face id). It
  suggests one face per photo and skips photos that already show the person and faces rejected for that person.
  There is no threshold and no score is shown.
  - `PersonSuggestionsScreen` ("Similar faces") has per-face selection, "Add to X" / "Not X", Undo and "Show more".
    It says "This is not recognition: nothing is added to X until you choose Add".
  - `suggestionsFor` is read-only; `confirmSuggestions`, `rejectSuggestions` and `undoSuggestionDecisions` write only
    what the user chose. "Not X" writes a reject decision, so that face is not suggested for X again.
  - Suggestions never assign a face without the user's confirmation of that face. Apart from the user-requested
    `groupNow` (above) and the user's own "Same person?" answers (below), no new code groups faces, resumes, calls
    `pause(false)` or kicks processing.
  - Coverage is limited (KI-14): on the phone (contract v1), 397 faces have descriptors after the full pass (backup
    B8; 336 before it). Contract v2 (64 px, ADR-023) adds faces from 64 to 99 px after a re-scan.
  - On the Vivo (2026-10-22, view only): for the person with one large manual face, "Review similar faces (58)", the
    explanation, the paused note and "1994 unnamed faces are too small to compare" rendered; people whose only faces
    are small see "Needs a clear, large face of X first." No suggestion was confirmed or rejected on the phone.
- **"Same person?" confirmations (Wave 3, 2026-10-22; ADR-021; user request, Google-style).** Each card shows two
  face crops (on the full screen capped at 160 px, each with "Open photo"; 72 px without it on the main-screen
  prompt) and the answers No / Not sure / Yes. Every answer is the
  user's decision; nothing is decided for the user.
  - `buildSamePersonQuestions` (`domain/people/same_person.dart`) asks two kinds of question, in this order:
    1. **Verify** ("Is this X?"): every face that automatic grouping put into a named person, shown next to a face
       the user confirmed for that person (the closest one with a descriptor, otherwise any confirmed face). A
       named person whose faces were all grouped automatically uses its cover face as the anchor, which is never
       asked about itself.
    2. **Merge** ("Is this X?" when the left group is named, "Same or different person?" when both are unnamed):
       pairs of groups, named or unnamed but never two named people, ordered by the cosine of their closest faces
       (ordering only, never shown). Pairs that share a photo are skipped, and the named (or larger) group is the
       left anchor. Pairs already answered (a reject or unsure decision) are never asked again. Pairs whose closest
       faces score below the **lowest** cosine among the review pairs the user judged "same" (`minSimilarity`,
       taken from the user's own review) are not asked; that floor selects questions and never decides an identity.
  - `PeopleRepository.samePersonQuestions({snapshot, limit})` is read-only and excludes hidden people; it builds the
    questions off the UI isolate (`compute`) when the pairwise work (faces times faces across groups) exceeds
    20,000. `answerSamePerson(question, answer)` writes only the user's answer:
    - Verify: Yes makes the face a manual assignment with an `accept` decision; No unassigns it with a `reject`
      decision, so it is never suggested for, or regrouped into, that person again.
    - Merge: Yes moves the right group into the left one (the named or larger group keeps its identity). Only the
      two faces the user compared become manual; other faces grouping placed stay `automatic`, so they can still be
      asked about. Earlier `reject` and `unsure` answers carry over, and a `reject` replaces an `unsure`. No records
      `reject` both ways for every face of the two groups.
    - Not sure stores the new decision value `unsure` (the face, or the right group's faces, against the left
      person) in the existing `people_decisions` table, with no schema change. It never overwrites an existing
      decision, grouping and suggestions ignore it, and a later explicit naming replaces it.
    - A stale question fails closed with "Try the next question" and writes nothing: a person in it no longer
      exists, or the automatic face, or either compared face, has left its person. Answering never resumes
      processing.
  - UI: `SamePersonScreen` ("Question k of N", the answers in a fixed bottom bar, a note that answers stay on the
    device and to answer Not sure when in doubt) opens from the People-screen tile "Same person? | N quick questions
    to make grouping more accurate"; `samePersonQuestionsProvider` (limit 1000) recomputes the list after every
    People edit.
  - **Rounds (ADR-022, user request, modelled on Google Photos' face-group prompts).** Up to 20 questions per app
    launch (`samePersonSessionSizeProvider`; in-memory answered and allowance counters, nothing stored). The Search
    home shows `SamePersonPrompt` ("Help improve face groups · k of N", answered in place, "Not now" until the next
    launch, "Open full screen"); the full screen ends a round with "Keep going (20 more)". Answers (and "Open full
    screen") are disabled while one saves (`samePersonSavingProvider`, shared by both) and until the next question
    loads (`samePersonBusy`); after a failed reload no question is shown. Every answer is stored, so no question
    repeats. At the user's choice only pairs at or above the floor are asked. On the full screen each card shows
    two 160 px crops with "Open photo"; the compact card on the main screen caps them at 72 px without "Open photo".
  - Only faces with descriptors can be asked about (≥ 100 px under v1, the phone's build; ≥ 64 px under v2 after a
    re-scan), so smaller faces still need manual naming (KI-14).
- **Privacy.**
  - The assistant refuses person queries before any HTTP call. Since Wave 3 its guard checks every saved name,
    hidden people included, and blocks any person filter, mention, or "or"/"without" person query. The payload never
    includes person ids (`toJson(includePeople: false)`). "Search text locally" strips voice punctuation.
  - Names typed in a different script from the saved one (for example Devanagari vs Latin) are not matched, so the
    guard cannot recognise them (pre-existing).
  - **Cloud speech transcription has no person guard**, so spoken names can leave the device after recording
    consent.
  - Disable-and-delete removes all People rows and crops. It keeps the CLIP index and the `photo_rows.facesJson`
    ML Kit boxes.
  - Descriptors and crops are not encrypted (accepted limitation).

### 5.5 Gallery, timeline, map, viewer

- **Routing.** `/` → `StartupScreen`. Then a `StatefulShellRoute.indexedStack` with Search, Timeline, Map and a
  fourth tab at `/home/settings`, labelled "Privacy" (screen title "Privacy Centre") since the redesign (on the
  branch) and "Settings" on `main`. The viewer, memory detail, story viewer and caption screen are imperative pushes with no
  deep links.
- **Home.** A metadata-only projection of the persisted library, newest first, grouped by local day and month.
  On `main`: exact row extents, month jumps and a draggable date thumb. The redesign (on the branch) also merges the
  search field into one scroll view as a pinned header and offsets month jumps by the pinned extent.
- **Thumbnails.** `DeviceThumbnailImage` tries the cached file, then a 512-px photo_manager thumbnail, then a
  transparent pixel. It is display-only.
- **Timeline.**
  - `MemoryRepository.reconcile` rewrites **every** `memory_members` row in one transaction on each library
    refresh, including a label edit.
  - Automatic events are local calendar days, replacing a 48-hour chain that once produced a 1,193-photo event.
    Titled or custom-cover events are never split or merged.
  - Stories hold up to 20 day-spread photos.
  - The timeline reads raw repository photos, so it does **not** show label corrections.
- **Map.**
  - A user-triggered EXIF scan (`LocationRepository`, which requests `ACCESS_MEDIA_LOCATION`) fills
    `photo_locations`, keyed to the photo's mtime revision. Missing GPS is never stored as 0,0.
  - Tiles load only with maps consent, while resumed, and with `TickerMode` on. Requests go only to
    `tile.openstreetmap.org`, with no redirects.
  - One oversized tile or a timeout closes the client for that view until Retry (bounds added 2026-09-18, on the
    branch).
  - Tiles are never written to disk: flutter_map's built-in tile cache is disabled, so no tile outlives a revoked
    maps consent (2026-10-22, `97404fb`, ADR-025).
  - Device result: 0 of 1,916 photos located.
- **Viewer.**
  - Always uses `AppTheme.dark()` (redesign, on the branch). On `main` the viewer has a black background only.
  - Details shows `photo_rows.lat/lng` (redesign, on the branch; on `main` Details shows no coordinates). They are **always null
    for device photos on Android 10+**: photo_manager never fills them and the EXIF extractor reads the date only.
    The map uses a different source, and the two are not reconciled.
  - Labels are corrected through user preferences.
  - Caption **generate** needs consent plus a per-photo preview. Caption **rewrite** sends the caption text with
    feature-level consent only.

### 5.6 Online enhancements and backend

- **`OnlinePolicy`.**
  - Starts offline-only and fails closed: `allows = loaded && !offline && featureEnabled`.
  - Granting a feature needs a confirm dialog. Revocation applies in memory before the write.
  - A generation counter cancels in-flight `EnhancementClient` requests, including on unrelated policy updates.
- **What leaves the device:**
  - **Captions:** a re-encoded, metadata-free JPEG (≤ 1280 px, q85) after a per-photo preview.
  - **Rewrite:** caption text plus a style.
  - **Assistant:** the message, current query, language, today's date and date/album/place filters. Never photos,
    vectors, filenames or person IDs.
  - **Transcription:** one AAC clip (≤ 30 s) after a per-recording dialog.
  - **Maps:** OSM tile GETs, which expose the IP address and tile coordinates.
  - **ML Kit usage metrics:** ML Kit sends metrics about its performance and use to Google (photos are not sent);
    indexing and People use ML Kit whatever the online settings. Since 2026-10-22 the Privacy Centre says so, as the
    ML Kit terms require (on the branch, `99433c5`, ADR-025).
- **`EnhancementClient`.** HTTPS only, no redirects, 4 MiB upload, 64 KiB response, 100 s timeout. Every 429 is
  shown as "Free quota reached". Binding the token to the exact HTTPS origin is the `BackendCredentials` change (on
  the branch, `ea639d5`); the base URL itself may still contain a path.
- **Backend (`enhancement_backend/app.py`).**
  - A stateless broker to `api.groq.com`.
  - Pinned models: `qwen/qwen3.6-27b` (JSON output, `max_completion_tokens` 512, reasoning effort none) and
    `whisper-large-v3-turbo`.
  - Authentication: SHA-256 of the per-install bearer token compared against `PIXELSEARCH_TOKEN_HASHES`. 10
    requests per 60 s per token, in-process.
  - Returns 503 unless `GROQ_API_KEY` is set and `GROQ_ZDR_CONFIRMED == "true"` (an operator attestation).
  - `/health` is unauthenticated.
  - FastAPI's default `/docs`, `/redoc` and `/openapi.json` are enabled and unauthenticated in code, both on `main`
    and on the branch: only POST requests are authenticated. Live exposure has not been checked.
  - `pytest` ships in the production requirements.
- **Deployment.** Render free plan via `render.yaml`. The Blueprint pins `GROQ_ZDR_CONFIRMED` to `"false"`, so a
  re-sync may break the live service. Live code was last verified on 2026-09-09 (`f38a72c`). The hardening is not
  deployed; on its own it does not change token validation. Token re-entry is forced by the new app build: the
  branch's `BackendCredentials` binds the token to the backend's HTTPS origin and ignores the legacy
  `backend_install_token`, so users must re-enter the token after installing that build, whether or not the backend
  is redeployed.
- **Offline speech.**
  - `MainActivity.kt` channel `pixelsearch/on_device_speech`, API ≥ 33. No cloud fallback.
  - It refuses if the language is not installed. Language download needs a dialog plus offline-only turned off.
  - Default language en-IN; Hindi and Hinglish use hi-IN. Accuracy has never been measured.

### 5.7 Evaluation and diagnostics

- **In app.** Privacy Centre (Settings on `main`) → Search diagnostics runs `inspect()`:
  - one embedding and an ungated full scan
  - replays production plus 14 experiments: legacy articles, ML Kit labels, lexical bypass, whole words, pools
    20/50/100/200, and gates off/0/0.1/0.2/0.25/0.3
  - **uses the same `rankSearchCandidates` as real search**
  - refuses in degraded or empty-index states, and ignores filters and people
  - The screen's third tab is the ML Kit-labels experiment, not whole-word as `SEARCH_EVALUATION.md` says.
- **Dart metrics** (`lib/evaluation/`): graded 2/1/0 judgments at K = 5/10/20. P@K and nDCG are null when the query
  has no judgments, or when an unjudged result is in the top K and the query is not marked `exhaustive`; for
  exhaustive queries, unjudged results count as 0. nDCG is also null when IDCG is 0. This differs from the Python
  `model_kit/eval/metrics.py`, which treats binary relevance with unjudged as negative.
- **Bundled dataset.** `assets/evaluation/scene_queries.json` has 24 queries and **no labels**.
- **Device integration test** (`integration_test/search_diagnostics_test.dart`): read-only DB, a digest of 4 of the
  14 tables, and a check that the replay equals the real top 200. It has never been accepted on a device. **Never
  run it bare on the phone (KI-12); use `tool/run_search_evaluation.ps1`.**
  - The script requires PowerShell 7 (`pwsh`), which is not installed on the audit machine (only Windows PowerShell
    5.1). Run it as `pwsh -File pixelsearch_app/tool/run_search_evaluation.ps1 -Device <serial>`; `-Device` is
    mandatory, and `-BackupOnly` takes only the backup. The `-Flutter` default is `C:\src\flutter\bin\flutter.bat`.
  - Force-stop PixelSearch first; the script refuses to run while the app is running.
  - It backs up app data, runs the test with `--no-uninstall`, then **rebuilds and reinstalls a debug APK**
    (`flutter build apk --debug`, `adb install -r`), replacing the installed build.

## 6. Model contract and versioning

- **Model.** MobileCLIP-S1 / datacompdr, 512-d, image 256. ONNX opset 17 from the legacy exporter.
  - Image: `pixel_values` float32 `[B,3,256,256]` → `image_embeds` `[B,512]`.
  - Text: `input_ids` int64 `[B,77]` → `text_embeds` `[B,512]`.
  - Both outputs are L2-normalized.
- **Image preprocessing** (`lib/ai/image_preprocess.dart`), a bit-faithful copy of the PIL/torchvision transform:
  - uint8 RGB
  - shorter side → 256, long side by truncation
  - antialiased separable triangle filter, rounding to uint8 after each pass
  - centre crop with a round-half-to-even offset
  - /255, no mean/std, CHW
  - Guarded by `test/preprocessing_golden_test.dart`: the sum must be within 0.05 of `100051.464714` and three
    sampled elements within 1e-5. This is a coarse regression fingerprint, captured from Dart output. Fidelity to
    PIL/torchvision rests on the earlier parity work (ADR-010: embedding cosine 1.000000 on 6 probes, before
    `a76d3b6`), not on this test.
- **Tokenizer** (`lib/ai/clip_tokenizer.dart`): a port of open_clip SimpleTokenizer, 19/19 id-exact. The test reads
  `../model_kit/out/bpe_simple_vocab_16e6.txt.gz` and `../model_kit/parity/reference_tokens.json`, so the app tests
  need the sibling `model_kit/`.
- **Text graph.** `Cast(int64→int32)` before `ArgMax` for ORT 1.15 (ADR-012); idempotent, inherited by fp16.
- **Encoder** (`lib/ai/onnx_encoder.dart`):
  - `OrtSession.fromFile`, intra-op threads = clamp(cores/2, 1, 4), **no execution provider**.
  - Batch 1; the 512-d output is re-normalized defensively (the contract text says not to; the step is harmless).
  - `OrtEnv` is initialized once per isolate and never released by CLIP.
  - The native env is process-global and ref-counted (inferred). The face worker's release is balanced.
  - **Leak:** each `searchBackendProvider` rebuild orphans the previous text session.
- **Versions** (`lib/core/ai_contract.dart`): `modelVersion '1.0'`, `embeddingVersion '1'`, `artifactVersion '3'`,
  `schemaVersion 7` (v7, 2026-10-22: reviewed photo ids on People review rows).
  - `AiContract.schemaVersion` is documentation only. The effective Drift version is the literal in
    `AppDatabase.schemaVersion` (`app_database.dart`), and the two must be bumped together.
  - Bump `embeddingVersion`, which forces a resumable full re-index, when the weights or image preprocessing change.
  - Artifact-only re-exports that are numerically identical, and tokenizer-only, schema or ANN changes, do not need
    a bump.
  - The fp32 → fp16 precision switch is an open exception. Until Android fp16 parity is shown (ADR-016), fp16 must
    not be deployed over a populated fp32 index, and a bump or re-index may be required if parity fails.
  - Embedding rows record no precision or artifact, so precision is enforced by process only.
- **FP16 v3.** Repaired on 2026-09-08 (ADR-016) using ORT's float16 converter with I/O kept float32, topological
  sort, checker and Cast validation. Both v3 graphs pass `onnx.checker`, and the fp16 image session creates on host
  CPU ORT (Python 1.28). The host cannot run fp16 inference, and no host session load of the fp16 text graph is
  recorded. FP16 has **never** been loaded, run or parity-checked under the app's ORT 1.15.1 on Android. The
  Android plugin ships ORT only for arm64-v8a and armeabi-v7a, with no x86_64.
- **Regeneration.**
  - `cd model_kit && python prepare_model.py`: export, verify, patch and convert.
  - `python repair_fp16_exports.py` (run inside `model_kit/`): rebuilds both fp16 graphs from the existing fp32
    exports, patches the fp32 text graph in place (idempotent ArgMax cast), and syncs `artifact_version` in both
    `preprocess_config.json` files. It downloads nothing and is not needed for the accepted fp32 CPU configuration.
  - Large exports are git-ignored, and only the SFace ONNX may be tracked.
  - **ModelKit is the source of truth.** Any Flutter/ModelKit mismatch is a critical bug.

## 7. Persistence and schema

| Version | Change |
|---|---|
| v1 → v2 | `embedding_rows.embedding_version` |
| v2 → v3 | M5 indexing metadata on `photo_rows` (mtime, byteSize, dimensions, `thumb_path`, `labels_json`, `faces_json`, `indexed_at_ms`) |
| v3 → v4 | `indexing_preferences_rows` (folder IDs) |
| v4 → v5 | `memory_events`, `memory_members` (one memory per photo), `saved_captions`, `photo_locations` |
| v5 → v6 | Six People tables, three raw indexes and the raw `processing_leases` table (no `IF NOT EXISTS`) |
| v6 → v7 | `people_reviews.left_photo_id` and `right_photo_id` (nullable), filled from existing faces (KI-16, 2026-10-22) |

- All steps are additive.
- Migration fixture tests exist for v3, v4, v5 → 6 and v6 → 7. The v3 and v5 fixtures are synthesized from the current
  schema; v4 uses hand-written DDL.
- There are no v1/v2 fixtures and no Drift schema-verification harness.
- Embedding BLOBs are little-endian float32, 2048 bytes, keyed `(photo_id, model_id)`.
- Only `IndexStore` writes `photo_rows`/`embedding_rows` in production. `PhotoRepository.savePhotos` and
  `photoIdsNeedingEmbedding` are test-only; `MIGRATIONS.md §B` is stale there.
- **Never uninstall or clear app data to upgrade.**

## 8. Decisions

The ADR log is [`pixelsearch_app/docs/ARCHITECTURE_DECISIONS.md`](../pixelsearch_app/docs/ARCHITECTURE_DECISIONS.md)
(newest first; ADR-018 to ADR-025 were added on 2026-10-22). Current status of each:

| ADR | Decision | Status now |
|---|---|---|
| 001 | Mobile-first, privacy-first, Android-first | Current |
| 002 | Riverpod + manual DI | Current (split by owner in `4a7c81f`) |
| 003 | MobileCLIP-S1, 512-d, 256 | Current |
| 004 | Ship fp16, not int8 | **Superseded in practice.** FP32 CPU is the only accepted configuration. |
| 005 | Provision models at runtime | Current; manual only (no M12); SFace is a bundled exception |
| 006 | Two separate repositories | **Superseded** by the one-repository layout (sibling folders). ModelKit still owns the contracts. |
| 007 | Drift with a conditional connection | Current |
| 008 | LE float32 BLOB embeddings | Current (its "memcpy" wording is inaccurate) |
| 009 | `VectorIndex` seam, brute force now | Current |
| 010 | Bit-faithful preprocessing | Current (TD-9 resolved) |
| 011 | Shared `OnnxEncoder` | Current |
| 012 | ArgMax int32 Cast for ORT 1.15 | Current |
| 013 | Hexagonal indexing, reconcile-based resume, batch transactions | Current |
| 014 | Async `SearchBackend` + hybrid scorer | **Partly superseded.** The lexical union is now fallback-only, labels are excluded, and scaling is zero-anchored, not min-max. |
| 015 | Conditional-import index bridge, DB-backed library | **Partly broken.** The early-cancel replay the ADR promises is defeated because `IndexingService.run()` clears the cancel flag on entry (§9 P2). The controller now lives in `indexing_providers.dart`. |
| 016 | fp16 repair, artifact v3 | Current; Android acceptance pending |
| 017 | Folder-scoped candidates with gallery-wide deletion reconciliation | Current. Folder scope and retention are device-verified (Vivo, 2026-09-08). Deletion reconciliation and the limited-access no-prune rule are host-tested only. |
| 018 | Similar-face suggestions are ranking-only and confirmed per face; deleting photos keeps review pairs (2026-10-22) | Current (branch `review-ready-2026-10-22`). Suggestions screen viewed on the Vivo 2026-10-22; confirm/reject host-tested only. |
| 019 | Person-query grammar ("me", "or", "without") and hidden-people semantics (2026-10-22) | Current (branch `review-ready-2026-10-22`). Accepted on the Vivo 2026-10-22 with typed queries; voice input not exercised. |
| 020 | User-requested validated grouping (`groupNow`, runs while paused but only after a passed gate) and a smaller naming list that hides small or duplicate faces without deleting them (2026-10-22) | Current (branch `review-ready-2026-10-22`). Run once on the Vivo at the user's request (266 automatic assignments, backup B3). |
| 021 | "Same person?" confirmations: verify automatic faces in named people and ask about group pairs, with Yes / No / Not sure; answers are the user's decisions; `unsure` is a new decision value (no schema change) that never overwrites and that grouping ignores; pairs below the user's lowest "same" review score are not asked (2026-10-22) | Current (branch `review-ready-2026-10-22`). Improves grouping accuracy only through the user's answers; only faces with descriptors are asked about (≥ 100 px under FaceContract v1, ≥ 64 px once a photo is re-scanned under v2). Shown on the Vivo 2026-10-22 (122 questions); the user answered on the phone (B5 to B6, checked through aggregate backup counts). |
| 022 | "Same person?" rounds: 20 per launch with in-memory counters, never repeated, a Search-home prompt (`SamePersonPrompt`) and a full screen; answers disabled while one saves and until the next question loads (2026-10-22) | Current (branch `review-ready-2026-10-22`). On the Vivo after the resumed pass: 70 questions and "Help improve face groups · 1 of 20" on the main screen; no answer given by the assistant, so answering through the rounds is host-tested only. |
| 023 | FaceContract v2: faces from 64 px; a re-scan continues matching v1 faces (id, name, decisions) by box overlap; v1 reviews cannot validate v2, so grouping waits for a new round (2026-10-22) | Current (branch). Rehearsed on a copy of backup B10; device install and re-scan pending. |
| 024 | Reviewed photo ids on review rows, schema v7 (KI-16, 2026-10-22) | Current (branch). Migration rehearsed on a copy of backup B10 (140 of 140 rows filled). |
| 025 | Publication guardrails: forward redaction, private-data scan, interim licence, in-app licences, no map tile disk cache (2026-10-22) | Current (branch). History not rewritten. |

Decisions in code with **no ADR yet** (write these):

- SFace People with the validation-gated complete-link grouping (schema v6)
- the schema v5 features
- semantic eligibility enforcement plus the ignore-articles policy
- removal of the label fallback
- calendar-day timeline events
- the backend broker design (Groq, per-install token hashes, ZDR attestation, no retries)
- release signing from operator env vars

## 9. Known issues register

Prioritized as of 2026-10-21; People items updated 2026-10-22 (after the device acceptance and grouping). "KI-n" and "TD-n" refer to
[`KNOWN_ISSUES.md`](../pixelsearch_app/docs/KNOWN_ISSUES.md) and
[`TECHNICAL_DEBT.md`](../pixelsearch_app/docs/TECHNICAL_DEBT.md), which are partly stale.

**P0: act before anything else**

1. **The public repository exposes personal data**: a device serial, personal photo filenames, the deployed backend
   URL, local user and backup paths, and real names in tests and docs (first names, a full name, and a team roster
   with surnames), in the pushed history. The working tree was redacted forward on 2026-10-22 (ADR-025); making
   the repository private or rewriting history is still open. See §11.
2. **CI is failing on `main`** (3 Flutter tests on the Linux runner). Cause found by simulation and fixed on the
   branch (KI-17, 2026-10-22); not yet confirmed on GitHub.
3. **The work since `4a7c81f` is committed only on a local branch** (`review-ready-2026-10-22`, 2026-10-22); until it
   is pushed and merged, the public repository shows none of it, and the backend hardening is not deployed.

**P1: correctness and safety**

4. **Device-test hazard (KI-12).** A bare device integration test uninstalls the app and destroyed a private index
   once.
5. **FP16 provisioning hazard.** The resolver prefers fp16 and there is no text fallback; precision is untracked
   (§5.1).
6. **Background indexing is never scheduled**, and the OEM screen-off freeze (KI-10) stops foreground runs.
7. **Indexing work runs on the UI isolate** (TD-17), which makes the phone feel hung during long runs.
8. **No in-app model provisioning or guidance (KI-8 / M12).** A fresh install cannot index anything: without the
   MobileCLIP image model, indexing stops with `modelMissing` and one transient status line naming the expected
   path, and nothing is written. With an image model but no usable text model, search silently falls back to
   keyword matching (tooltip only in the redesign).
9. **Search quality is uncalibrated** (KI-5/KI-13). Only 2 judged queries exist.
10. **People gate state (dated).** On 2026-09-18 the first round failed on the device (1 false join). Backup B0
    (2026-10-22) shows that a fresh 20-pair round passed (threshold ≈ 0.462), but the holdout has only 4 Different
    pairs. On 2026-10-22 the user ran "Group similar faces" once (266 automatic assignments, 137 new unnamed
    groups); those groups rest on that small holdout, and their accuracy has not been measured (the user can check
    them through the "Same person?" questions, ADR-021). The user then resumed processing, so `applyGrouping` now
    runs after each full pass (85 more automatic assignments after the first full pass, backup B8), on the same
    small holdout. The descriptor yield is low (397 of 2,642 detections with all photos processed).
11. **KI-16 (fixed 2026-10-22, schema v7, ADR-024).** An edited reviewed photo could be sampled into a new review
    round; review rows now store photo ids.

**P2: functional gaps and drift**

- Failed assets (for example HEIC) are re-processed on every run, with no failure record.
- Change detection is mtime-only (`byteSize: 0`).
- The early cancel is lost.
- Folder deselection does not hide content.
- Viewer GPS is always null on Android 10+, while the map uses EXIF. The two sources are not unified.
- The text ORT session leaks on each backend rebuild.
- Keyword fallback is visible only through a tooltip (redesign).
- The timeline rewrites all memberships on every library refresh.
- Label corrections are not applied in the timeline or diagnostics.
- A corrupt `user_preferences.json` gives an empty library and blocks all preference writes (inferred).
- No in-app "delete all local data". Thumbnails, evaluation reports and correction keys are never cleaned up.
- The assistant's "last year" is a rolling year; every 429 shows as a quota message.
- Cloud transcription has no person-name guard.
- **KI-14 (2026-10-22): person-search coverage.** Only assigned faces in processed photos count. On the phone
  (FaceContract v1) all 1,916 photos are processed since the resumed pass, and 397 of 2,642 detections have
  descriptors (backup B8; 336 of 2,342 at 485 photos before it), so suggestions, grouping and "Same person?"
  questions can reach at most 397 faces. FaceContract v2 (64 px, ADR-023, on the branch, not installed) adds faces
  from 64 to 99 px after a re-scan; the count is unmeasured. The rest can only be named by hand; the naming list hides faces under 40 px and same-photo duplicates behind "Show small faces" (ADR-020).
  While the user's own face in a photo is unnamed (for example a small face in a large group photo), "photos of me
  with X" leaves that photo out.
- **KI-15 (2026-10-22): person-query wording.** Exclusion covers assigned faces only. Names that are common words
  become filters until the chip is dismissed. Hinglish "me" meaning "in" is read as the owner (escape: 'Search
  without "me"' or dismiss the "You" chip). Bare I/we/us are not resolved. Mixed and/or wording means AND.
- Pre-existing People limits (unchanged 2026-10-22): names in a different script from the saved one are not
  matched; `editPerson` on a missing id silently succeeds; bulk manual naming allows two faces from one photo for
  one person (deliberate, for mirrors and photos of photos).
- Release signing switch: a release-signed build cannot update the debug install in place. Plan the migration;
  never uninstall.

**P3: hygiene**

- Stale docs (§10).
- No `.gitattributes` (CRLF churn).
- Theme mode is not persisted.
- Fixed on the branch 2026-10-22: the deliverable folders are git-ignored; the `applicationId` template TODO is
  replaced by a never-change warning (`c06d524`); the unmeasured onboarding speed claim is removed (`462d7af`).

## 10. Documentation status

**Current and reliable:**

- `README.md`, `HANDOFF.md`
- `pixelsearch_app/README.md` (its release-signing paragraph and FP32-only provisioning steps were updated on the
  branch, `c06d524`), `pixelsearch_app/docs/ARCHITECTURE.md` (except "Database schema 6": the code is at schema 7
  since 2026-10-22)
- `MIGRATIONS.md` (except §B; it has the v6 → v7 row)
- `model_kit/INTERFACE_CONTRACT.md` and `FACE_CONTRACT.md` (content current; the interface contract's header says
  v1.1 while the history reaches v1.3, and it has an FP32-only status note since 2026-10-22; the face contract is
  at v2 since 2026-10-22)
- `enhancement_backend/README.md` (its 2026-09-18 edit, committed on the branch in `b8c3310`, describes the
  undeployed hardening, not the live `f38a72c` service)
- `docs/SECURITY_REVIEW_2026-09-18.md`, `docs/architecture/README.md`, `DESIGN.md`, `PRODUCT.md` (untracked at the
  audit; committed on the branch on 2026-10-22, the first two after forward redaction)
- this handbook set

**Dated historical records** (accurate for their date; do not edit their measurements):

- `ANDROID_SMOKE_TEST_2026-09-08`, `FOLDER_INDEXING`, `SEARCH_QUALITY_DIAGNOSIS_2026-09-08`,
  `USABILITY_AND_SEARCH_PRECISION`
- `FIVE_FEATURE_IMPLEMENTATION_2026-09-09`, `ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09`,
  `INDEXED_GALLERY_2026-09-09`, `ONLINE_BACKEND_ACCEPTANCE_2026-09-09`, `SPEECH_SEARCH_FOLLOWUP_2026-09-09`
- `VOICE_MAP_TIMELINE_2026-09-10`, `OFFLINE_PEOPLE_2026-09-10`, `NEW_FACES_2026-09-10`, `NEW_FACES_DEVICE_2026-09-10`
- `PEOPLE_VALIDATION_2026-09-18`, `PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE`, `PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22`
  (untracked at the audit; committed on the branch on 2026-10-22)
- `docs/archive/*`

**Stale against code.** Every Markdown file below carries a dated status note at its top (the notes for
`RESEARCH_LOG.md` and `ARCHITECTURE_DECISIONS.md` were added last, during the 2026-10-21 review). `.env.example` is
a config template without a status note; its stale claim was corrected on 2026-10-22 (`c06d524`). Older docs not
listed here may still contain stale claims.

| Doc | Stale claim |
|---|---|
| `BENCHMARK_RESULTS.md` | fp16 "validated on-device"; device results PENDING |
| `RESEARCH_LOG.md` | fp16 is a validated on-device NNAPI/XNNPACK artifact (false: no execution provider is registered, and fp16 was never accepted on Android) |
| `ARCHITECTURE_DECISIONS.md` | ADR-006 "two separate repositories" (superseded by the one-repository layout); ADR-015's early-cancel replay (defeated); see §8 |
| `PROJECT_STATUS.md` | M9–M14 pending; schema v3/v4 |
| `ROADMAP.md` | Unchanged since `ce7bf55`; says "current M9" |
| `KNOWN_ISSUES.md` | KI-5/KI-13 lexical union; KI-8 filename; KI-11 untriaged |
| `TECHNICAL_DEBT.md` | TD-11 adapters "not runtime-tested" |
| `CHANGELOG.md` | Label fallback |
| `TEST_PLAN.md` | 11 tests; web build; FP16 NNAPI golden |
| `INDEXING_ARCHITECTURE.md` | Empty-gallery vs `StateError`; WorkManager claims; EXIF reads GPS |
| `AI_CORE_REVIEW.md` | `getPixel`; "dedicated isolate" |
| `ONLINE_ACCOUNT_SETUP.md` | "Backend uncommitted"; old start command |
| `ENGINEERING_AUDIT_AND_ROADMAP.md` | Lexical union |
| `SEARCH_EVALUATION.md` | Diagnostics tab; replay list |
| `FIVE_FEATURE_DEVICE_CHECKLIST.md` | Header ("not yet performed") |
| `.env.example` | "No cloud calls" (fixed on the branch 2026-10-22, `c06d524`: the app reads no variables; the backend holds its own secrets) |
| `model_kit/SPIKE_REPORT.md` | "Resize 256×256" |
| `model_kit/parity/README.md` | fp16 validated; old paths |

## 11. Security, privacy and publication exposure

This section is an index of exposures: it names files and categories and reproduces no values.

**Forward redaction done (2026-10-22, the owner's decision).** In the working tree every item below was replaced
with a placeholder: names in test fixtures (`Alice`, `Bob`, `Casey` and extensions that keep prefix cases), the
team roster in the archive handbook (`.md` and `.docx`), the device serial, local user and backup paths, private
photo filenames, the backend URL, APK and backup digests, backup names and the share links. Model digests stay
(contract evidence). Each dated report carries a dated redaction note; measurements are unchanged. Originals are
kept in the git-ignored `pixelsearch_app/local_evaluation/redaction-originals-20261022/`. History was **not**
rewritten: the pushed commits (`4a7c81f` and earlier) still contain the values, so making the repository private, or
a history rewrite, remains the owner's choice. Guardrails: the tracked `.gitignore` ignores the three deliverable
folders and `.privacy-denylist.txt`; `tool/check_repository.py` now scans tracked and addable files for generic
patterns (local user paths, camera and chat photo filenames, deployment URLs, share links, roll numbers, serial
phrasing) and, when the git-ignored denylist is present, for its whole-word terms (it never prints them). The list
below records what the pushed history contains.

- **The GitHub repository `origin` is public**, verified on 2026-10-21. `origin/main` = `4a7c81f` (also HEAD at the
  audit; HEAD is now the unpushed branch `review-ready-2026-10-22`).
- **Tracked, pushed files contain in history** (values deliberately not reproduced here):
  - a full device serial:
    - `pixelsearch_app/docs/ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09.md`
    - `pixelsearch_app/docs/INDEXED_GALLERY_2026-09-09.md`
    - plus a partial serial in `ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md`
  - personal gallery photo filenames:
    - the five-feature acceptance and indexed-gallery docs
    - `SPEECH_SEARCH_FOLLOWUP_2026-09-09.md`
    - `KNOWN_ISSUES.md` (from `ce7bf55`) names only a single descriptive desktop test-image filename; check its
      origin before treating it as personal.
  - the deployed backend URL (`ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md`)
  - local user-profile and backup paths (the repository path, and backup folders under the user's Downloads
    directory) in `ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09.md`, `FIVE_FEATURE_IMPLEMENTATION_2026-09-09.md` and
    `OFFLINE_PEOPLE_2026-09-10.md`
  - real names used as fixtures (mostly first names; `test/people_domain_test.dart` also has a full name with
    surname):
    - `test/people_domain_test.dart`, `people_widgets_test.dart`, `people_repository_test.dart`,
      `voice_search_widgets_test.dart`
    - a comment in `lib/domain/people/people_query.dart`
    - `NEW_FACES_2026-09-10.md`
  - the team roster with surnames in `docs/archive/initial-plan/PixelSearch_Mobile_Implementation_Handbook.md`,
    tracked since the first commit `14ed4c2` (and probably its `.docx`, a binary that was not opened)
  - Most of the rest arrived in commit `8c7293e`.
- **Files untracked at the audit with similar material** (2026-10-21 record; all were redacted forward before they
  were committed on the branch on 2026-10-22, and the repository check with the denylist passes on the working tree;
  the deliverable folders stay git-ignored and uncommitted):
  - `people_name_search_test.dart` and `PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md`, which breaks that doc's own
    no-names rule (the test maps a real first name to "me" and turns another into a two-part name)
  - Eraser share links with tokens, a hosted link to the rendered diagram and a pointer to a local `links.json` in
    `docs/architecture/README.md`
  - an absolute local path that shows the user-profile name in `docs/SECURITY_REVIEW_2026-09-18.md`
  - full SHA-256 digests (APK signer, delivered APK, a device backup), backup archive names and paths, and a local
    screenshot path in `pixelsearch_app/docs/PEOPLE_VALIDATION_2026-09-18.md`
  - one more use of an already-exposed real first name in a working-tree test added to `people_widgets_test.dart`
    (2026-10-18 wave)
  - student names in `reports/` and `PIXELSEARCH_COPYRIGHT_SOURCE/`
  - Found again by the 2026-10-22 verification pass, with redaction text proposed for each; none was changed then,
    because redaction is the owner's decision. Later that day the owner chose forward redaction (above). The
    2026-10-22 People-search docs and tests use slot labels and placeholder names only.
- **`tool/check_repository.py`** checks tracked paths, extensions and sizes, plus a few structural rules
  (export-only `providers.dart`, no barrel imports, bundled samples referenced by tests). At the audit it did not
  scan file content; since 2026-10-22 (`d4b4a59`) it scans tracked and addable text files for the generic patterns
  and denylist terms above. It still does not inspect images or other binaries (such as the archive `.docx`), and CI
  has no denylist.
- **Decided 2026-10-22:** forward redaction (done). **Still the owner's decision:** making the repository private
  and rewriting history; neither has been done.
- **No secrets were found.** Backend secrets are server-side only (`sync:false`). On the branch, release signing
  material comes only from four env vars (`c49f2d2`); on `main`, release builds are still signed with the debug key.
  The copyright secret scan's 2 hits are test fixtures.
- **Accepted limitations:** local data is not independently encrypted; deletion is logical, not forensic; Android
  backup is disabled.

## 12. Next steps (highest priority first)

> **Update (2026-10-22, later):** step 1's redaction was done forward on the branch (ADR-025); visibility and
> history rewriting remain the owner's decision. Step 2's cause was found by a Windows-host simulation and fixed on
> the branch (KI-17); it is confirmed only by a CI run, which happens on a pull request or a push to `main`. Step 3
> is done: the work is committed on the local branch `review-ready-2026-10-22`; redeploying the backend hardening
> and the token re-entry remain. Steps 1 to 3 below are kept as written on 2026-10-21/22.

1. **Privacy exposure.** With the user, decide on repository visibility, redaction and history rewriting.
2. **Fix CI.** Read run 7's log while signed in, or reproduce on Linux with Flutter 3.44.7 from a clean checkout of
   `4a7c81f` (not this working tree), as `.github/workflows/ci.yml` does: `cd pixelsearch_app && flutter pub get &&
   dart run build_runner build --delete-conflicting-outputs && flutter test test/`. A probable lead from 2026-10-22,
   not confirmed on Linux: the existing 320px widget tests pass only with the Windows Segoe font loaded as Roboto,
   and without it the `PersonScreen` column and the naming dialog overflow. The new Wave 3 tests pass without that
   font.
3. **Commit the working tree deliberately, in reviewed groups.** Fonts with `pubspec.yaml`; the signing doc with
   `build.gradle.kts`; untracked tests with their code. Then redeploy the backend hardening, verify the live
   service, and tell users to re-enter their token after installing the new app build (§5.6).
4. **Re-run Flutter-ORT parity** (`integration_test/image_parity_test.dart`, `text_parity_test.dart`,
   `golden_validation_test.dart` on Linux under xvfb) for the post-`a76d3b6` code. Add a PIL-generated
   preprocessing tensor fixture to ModelKit.
5. **Model safety before FP16.**
   - Make text model selection load-tested with fp32 fallback.
   - Record precision and artifact per embedding row, or keep fp16 off devices.
   - Then try an fp16-capable execution provider and accept fp16 against fp32 on the phone.
6. **M12 model provisioning,** at minimum in-app guidance for `modelMissing`. Then background or foreground-service
   indexing that survives screen-off (KI-10), and a worker isolate for decode and inference (TD-17).
7. **A judged retrieval benchmark** (20–50 scene queries with a held-out set) before any change to gate, weights or
   lexical policy. Label the 24 queries of the bundled template privately (in-app ratings on the device, or the
   git-ignored `local_evaluation/`). Never commit judgments to `assets/evaluation/scene_queries.json`: they would
   publish private gallery photo IDs.
8. **People (updated 2026-10-22, after the device acceptance, the user-requested grouping and "Same person?").**
   - **Naming the user's own faces** is the user's step. Where the user's face is unnamed (in the reported example,
     a small face in a group photo with a named friend, too small to compare), "photos of me with X" correctly
     leaves that photo out until the face is named. The user also checks the 137 automatic groups and the 3 faces
     added to a named person, and moves or removes wrong faces; the assistant never judges identities.
   - **Answering the "Same person?" questions** is also the user's step. The user answered the first 122 on
     2026-10-22 (none left on B7); after the resumed pass the phone offers 70 new group-pair questions, 20 per launch
     on the main screen. Answer Not sure when in doubt; the floor that selects the questions is not an identity
     threshold.
   - **Smaller faces (FaceContract v2, built 2026-10-22, ADR-023; owner chose 64 px).** Remaining: back up the
     phone, install the build in place (schema v7 migrates the database; rehearsed on a copy of backup B10), keep
     the app open for the re-scan, check from a new backup that names, decisions and "Not a face" carried over, then
     the user rates a new review round (identity decisions are the user's) so grouping can use faces from 64 px.
   - **Processing resumed (user's decision, 2026-10-22).** The first full pass is done (backup B8). `applyGrouping`
     runs after each full pass on a holdout with only 4 Different pairs, so a larger review round would make the
     cutoff more trustworthy. Never alter ratings.
   - Device checks still open: confirming and rejecting suggestions, answering through the main-screen rounds
     (shown on the phone, not answered by the assistant) and voice input. Naming and "Same person?" answers were done
     by the user on the phone (B5 to B6).
9. **Refresh the stale living docs** (§10) and write the missing ADRs (§8).

## 13. Unknowns and limits of this audit

- **Not run:** integration tests, the SFace-enabled suite, any Android build or install, adb or logcat. The current
  device state (installed APK, provisioned files, People paused) is known only from the 2026-09-18 records.
  (2026-10-22, after the audit: debug APKs were built on the host and installed in place over adb, and backups B0
  to B10 give the aggregate device state; see §5.4 and ledger §4.2.)
- **Unknown:**
  - the accuracy of the 266 automatic face assignments (never measured; the holdout behind the cutoff has only 4
    Different pairs)
  - suggestion confirm/reject and voice person queries on the phone (host-tested only); the user's naming and "Same
    person?" answers were checked only through aggregate backup counts (B5 to B6)
  - the accuracy of the 85 automatic assignments made after the resumed pass (B8)
  - whether the KI-17 fix makes CI pass on GitHub (the 3 failures were explained only by a Windows-host simulation
    on 2026-10-22; the job logs were never read and no Linux run was possible)
  - the face counts and grouping quality under FaceContract v2 on the phone (the v2 build is not installed)
  - which commit Render serves, and whether the service is live
  - whether Groq ZDR is still enabled and the preview Qwen model still available
  - whether the Vivo originals actually contain GPS
  - HEIC decode behaviour (inferred to fail)
  - whether the text session leak matters in practice (unmeasured)
  - whether `/docs` is reachable on the deployment
- **Not opened:**
  - `pixelsearch_app/local_evaluation/` beyond aggregate listings by verifier agents
  - binary deliverables (blackbook `.docx`/`.pdf`, posters, presentation)
  - platform scaffolds (`ios/`, `linux/`, `web/`; 57 tracked files)
  - `.impeccable/` (about 71 untracked text files of redesign tooling), except the few files `FILE_MAP.md` names
  - generated `app_database.g.dart`
  - third-party plugin sources, except targeted reads of onnxruntime, image and photo_manager in the pub cache

## 14. Audit method and coverage (2026-10-21)

- **Inventory:** 347 tracked or untracked text files (excluding generated Drift code, binaries, platform scaffolds,
  git-ignored private data, and the about 71 untracked `.impeccable/` text files of redesign tooling apart from the
  few that `FILE_MAP.md` names). Coverage figures below refer to this inventory.
- **Mapping:** eleven subsystem mappers read their assigned files in full. Each produced key claims, which two
  skeptics then verified: one against the code, one for currency against later code, diffs and docs.
- **Coverage:** a sweep covered the 21 files no mapper had opened. Total coverage was 347/347.
- **Cross-check:** a critic raised 14 cross-cutting questions, each answered with evidence: first run, provisioning,
  ORT version, parity currency, EXIF orientation, GPS, failed assets, folder retention, deletion, test health, CI and
  publication, among others.
- **Process notes:**
  - Some verifier agents went beyond strict file reading. They ran the backend tests in the existing venv, listed
    archive contents in `local_evaluation/` (aggregates only), and made read-only public GitHub API requests.
  - One agent wrote a temporary comparison file to the system temp directory, outside the repository.
  - No code, config or test file was changed by the audit.
- **Audit changes (2026-10-21, all uncommitted then; committed on the local branch in `ecccf18` on 2026-10-22, so
  the public `main` still has none of them):**
  - new, untracked: root `CLAUDE.md`, `docs/PROJECT_CONTEXT.md`, `docs/EVIDENCE_LEDGER.md`, `docs/FILE_MAP.md`
  - edits to `docs/README.md`, `pixelsearch_app/CLAUDE.md` and `model_kit/CLAUDE.md`
  - dated status notes at the top of the stale docs listed in §10, including the late additions `RESEARCH_LOG.md`
    and `ARCHITECTURE_DECISIONS.md`
  - They are separate from the 2026-09-18 and 2026-10-18 waves (§3.3).
