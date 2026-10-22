# PixelSearch — Session Guide (repository root)

Android-first Flutter app for **on-device semantic photo search**. MobileCLIP-S1 ONNX embeddings, exact cosine
retrieval with hybrid reranking, ML Kit labels and faces, and opt-in offline People (SFace). Optional consented
online features: captions, the assistant and cloud speech transcription go through a self-hosted FastAPI broker (to
Groq); consented map tiles are fetched directly from the public OpenStreetMap tile server by `MapTileClient` (GET
only, no redirects, size-capped), not through the broker. It is a final-year major project held to research-grade
standards.

**Last full audit: 2026-10-21; updated 2026-10-22 for the People-search wave (host-verified, then accepted on the
test phone the same day), its "Same person?" confirmations and rounds, and the user's resumed People processing.**
For the deep context read
[`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).
Measured numbers are in [`docs/EVIDENCE_LEDGER.md`](docs/EVIDENCE_LEDGER.md) and the per-file map is in
[`docs/FILE_MAP.md`](docs/FILE_MAP.md). App-level engineering rules are in
[`pixelsearch_app/CLAUDE.md`](pixelsearch_app/CLAUDE.md); contract rules are in
[`model_kit/CLAUDE.md`](model_kit/CLAUDE.md).

## Repository map

| Path | Role |
|---|---|
| `pixelsearch_app/` | The Flutter app. `lib/{ai,benchmark,core,data,domain,evaluation,features,indexing,models,state,widgets}` plus `lib/main.dart` and `lib/app.dart`, `test/`, `integration_test/`, `android/` |
| `model_kit/` | Python: MobileCLIP export, fp16 repair, ArgMax patch, parity references, metrics, SFace fixtures. **Source of truth for the contracts.** |
| `enhancement_backend/` | Optional FastAPI broker to Groq. `render.yaml` deploys it on the Render free plan. |
| `tool/check_repository.py` | Publication-boundary check (CI) |
| `docs/` | Index, handbook (`PROJECT_CONTEXT`, `EVIDENCE_LEDGER`, `FILE_MAP`), security review, archive |
| `pixelsearch_app/docs/` | Architecture, ADRs, contracts mirror, migrations, dated acceptance reports, status docs (several stale; see the handbook §10) |
| `reports/`, `PIXELSEARCH_COPYRIGHT_SOURCE/`, `.impeccable/`, root `DESIGN.md` and `PRODUCT.md` | Untracked and **not git-ignored**. Never `git add -A`. The three folders are local deliverables, not for commit; whether `DESIGN.md`/`PRODUCT.md` are committed is the owner's decision. Untracked files that *are* meant to be committed: this `CLAUDE.md`, `docs/PROJECT_CONTEXT.md`, `docs/EVIDENCE_LEDGER.md`, `docs/FILE_MAP.md`, and the wave-1 to wave-3 untracked source, tests and docs (handbook §3.3). Stage by explicit path. |
| `pixelsearch_app/local_evaluation/`, `pixelsearch_app/docs/RAW_SEMANTIC_DIAGNOSIS.md` | Git-ignored private device data. Never publish, never quote. |

## Non-negotiable rules

**Device and data safety**

- **Never uninstall the app, clear its data, or run bare `flutter test integration_test/... -d <device>`.**
  Flutter's post-test uninstall destroyed a private index on 2026-09-08 (KI-12).
- For device evaluation use `pixelsearch_app/tool/run_search_evaluation.ps1`, which backs up first and passes
  `--no-uninstall`, or the in-app diagnostics.
- Upgrade the app only with a quiescent backup, a matching signer and `adb install -r`. Device actions need the
  user's approval.
- People processing on the device was paused by the user until 2026-10-22, when **the user chose to resume it**
  (to find more faces and "Same person?" questions). Do not pause or resume it without the user's decision.
- Do not change People review ratings to make validation pass. The assistant must never judge identities.

**Privacy and publication — the GitHub repository is PUBLIC**

- Never add personal photo filenames, person names, face data, GPS, device serials, deployment URLs, share links,
  backup paths or secrets to tracked files or docs. Cite files and aggregate numbers instead.
- Existing exposures are listed in the handbook §11; redacting them is a user decision.
- Never commit MobileCLIP ONNX exports, device databases, APKs or AABs, keystores, `.env`, `local_evaluation/` or
  the untracked deliverable folders. Only the bundled SFace ONNX is tracked.
- Do not commit or push unless the user asks. Pushing `main` can trigger Render's deploy workflow.

**Model and contract (ModelKit is the source of truth; any mismatch is a critical bug)**

- Never change preprocessing, the tokenizer, embedding size (512), image size (256), normalization, ONNX names or
  dtypes, or the opset without explicit approval, a version bump and re-verification.
- `AiContract` (`lib/core/ai_contract.dart`): `modelVersion '1.0'`, `embeddingVersion '1'`, `artifactVersion '3'`,
  `schemaVersion 6`.
  - Bump `embeddingVersion` (which forces a full re-index) **if and only if** the weights or image preprocessing
    change.
- Keep `model_kit/INTERFACE_CONTRACT.md` and `pixelsearch_app/docs/INTERFACE_CONTRACT.md` identical.
- **Do not provision `*_fp16.onnx` to a device.** FP16 is unaccepted on Android, and no execution provider is
  registered.
  - The resolver prefers fp16.
  - Text selection has no fallback.
  - Embedding rows do not record precision.
  - FP32 CPU is the only accepted configuration.
- Never fabricate results. Record only measured values with date, device, precision and scope.

**Code invariants**

- `lib/state/providers.dart` holds **export lines only** (plus `//` comments), and no state file may import it.
  CI checks the first rule, but catches the second only in the relative `import 'providers.dart'` form; a
  `package:` import of the barrel from `lib/state` is not caught. `people_providers.dart` is imported directly, not
  through the barrel.
- Schema changes need: an additive Drift step; bumps to both `AppDatabase.schemaVersion` and
  `AiContract.schemaVersion`; a `MIGRATIONS.md` row; and a migration test. Edit Drift tables and regenerate
  `app_database.g.dart`; never hand-edit it.
- Indexing commits in batch transactions (32 per batch, never one transaction per image). Per-asset failures are
  isolated.
- Heavy processing holds the SQLite `ProcessingLease`; **search never does**.
- Search ranking:
  - Production constants: `topK 60`, gate `0.15`, weights `0.70/0.25/0.05`, semantic band `[0, 0.35]`.
  - Healthy semantic mode has **no lexical-only union** and **no ML Kit labels** in lexical scoring; it ignores the
    articles a/an/the. Keyword fallback keeps the old behaviour.
  - Search and diagnostics share `rankSearchCandidates`.
  - Change the gate, weights or lexical policy one at a time, and only with judged held-out evidence.
- Filters and person eligibility apply **before** Top-K. Person names, faces and person filters never go online.
- Online features default to offline-only and fail closed. They need per-feature consent; photo and recording
  uploads also need per-item approval. No redirects, no silent retries, no cloud fallback for on-device speech.
- Labels: ML Kit confidence ≥ 0.5 or no labels. There is no fallback; it was removed on purpose in `5f6f074`.
- People: no default identity threshold. Automatic grouping only after a photo-disjoint validation with zero false
  joins. Any change to the face pipeline needs a new `FaceContract.id`.
- People search (2026-10-22; ADR-018 to ADR-022):
  - Similar-face suggestions only order faces (no threshold, no score shown). Nothing is assigned until the user
    confirms that face.
  - "Same person?" answers (`answerSamePerson`) are the user's decisions; the assistant never answers them. Yes
    keeps an automatic face as a manual one, or merges the right group into the named (or larger) left group,
    confirming only the two faces compared (other automatic faces stay automatic); No unassigns the face, or
    rejects the pair both ways. "Not sure" stores the decision value `unsure` in the existing `people_decisions`
    table (no schema change): it never overwrites an existing decision, grouping and suggestions ignore it, a
    carried-over reject replaces it, and a later explicit naming replaces it. Answered pairs are not asked again.
  - Questions come in rounds of 20 per app launch (in-memory counters, nothing stored), on the Search home
    (`SamePersonPrompt`) and the full screen.
  - Group pairs whose closest faces score below the lowest cosine of a review pair the user judged "same" are not
    asked. That floor only selects questions; it never decides an identity. Two named people are never paired.
  - `groupNow` ("Group similar faces") runs only when the user asks, after a confirmation dialog, and returns 0
    unless the review gate passed. It is the only grouping that runs while paused; `applyGrouping` (after a full
    processing pass) never runs while processing is paused. Now that the user has resumed processing,
    `applyGrouping` runs after each full pass on the phone, still only with a passed gate.
  - Unassigned small or duplicate faces (under 40 px in the prepared image, or overlapping a larger face in the same
    photo by IoU > 0.5) are hidden from the naming list behind "Show small faces", never deleted.
  - `deleteAssets` keeps review pairs, so calibration fails closed after a reviewed photo goes away. Never delete
    review rows to make the gate pass.
  - Hidden people are not matched from typed names; only "me" still resolves to a hidden "This is me" person.
  - The assistant's online guard checks every saved name, hidden people included. Person ids never enter a payload.
  - A `selfMissing` or `needsChoice` query never reaches a search backend: no search runs, "me" never reaches CLIP
    and an ambiguous name is never guessed.

## Commands (verified 2026-10-21 unless noted)

All commands start from the repository root.

```sh
# App (Flutter 3.44.7 / Dart 3.12.2; keep pubspec.lock)
cd pixelsearch_app && flutter pub get && dart run build_runner build --delete-conflicting-outputs   # what CI runs; not run 2026-10-21 (no dependency resolution in the audit)
cd pixelsearch_app && flutter analyze --no-pub      # --no-pub skips dependency resolution; no issues 2026-10-22
cd pixelsearch_app && flutter test --no-pub test/   # 526 passed + 2 skipped on the working tree (2026-10-22): the SFace worker test and the KI-16 bug test; tokenizer tests read ../model_kit fixtures
cd pixelsearch_app && flutter test --dart-define=SFACE_MODEL_TEST=true   # adds the real SFace worker test (needs a native ORT library); not run in this audit
cd pixelsearch_app && flutter build apk --debug --no-pub   # built 2026-10-22 (versionCode 1, same signer as the phone's install) and installed with adb install -r; release builds need PIXELSEARCH_KEYSTORE_PATH, _KEYSTORE_PASSWORD, _KEY_ALIAS, _KEY_PASSWORD (uncommitted signing config)

# Repository and ModelKit checks
python tool/check_repository.py                    # passed 2026-10-22 (run as python -I)
cd model_kit && python eval/test_metrics.py

# Backend: use the project venv (the system Python 3.14 has starlette 1.3.1, below the required 1.6)
cd enhancement_backend && .venv/Scripts/python -m pytest -q   # 51 passed

# Model regeneration (not run 2026-10-21)
cd model_kit && python prepare_model.py            # regenerates the fp32 and fp16 exports in model_kit/out (heavy; downloads weights)
cd model_kit && python repair_fp16_exports.py      # fp16 only: rebuilds the *_fp16.onnx from the existing fp32 exports, patches the fp32 text graph in place and syncs artifact_version in both preprocess_config.json files; not needed for the accepted fp32 CPU configuration

# Host real-ORT parity (Linux desktop + ModelKit exports in model_kit/out; not in CI; not run 2026-10-21)
cd pixelsearch_app && xvfb-run -a flutter test integration_test/image_parity_test.dart -d linux
```

MobileCLIP must be copied into the app by hand: `<app support>/models/`, which is
`/data/user/0/com.pixelsearch.pixelsearch/files/models` on Android. Debug builds only; the fp32 files only. Recipe:
handbook §5.1.

## Current state (2026-10-22)

- **Git.** `main` = `origin/main` = `4a7c81f` (2026-09-18), with a **large uncommitted tree**: about 40 modified
  tracked files from three waves (code, config, tests and the backend README), plus the audit's documentation
  edits, and about 30 untracked entries. Run `git status` for the live state. The waves contain:
  - 2026-09-18: the backend security hardening, origin-bound backend token, map-tile bounds, release-signing
    config, People deletion cascade and validation recovery, and the UI redesign (teal, Manrope, Privacy Centre).
  - 2026-10-18: a person-search empty state.
  - 2026-10-22, People search: the person-query grammar ("me", "or", "without"), similar-face suggestions,
    multi-select naming, delete person, the "Not a face" restore screen, the user-requested "Group similar faces"
    action, a smaller naming list, the "Same person?" confirmations and their rounds on the main screen. It adds
    7 untracked lib files and 4 untracked test files; `people_query.dart` is tracked and modified.

  A debug build of this working tree (all three waves) is installed on the test phone, in place with
  `adb install -r` (nine installs on 2026-10-22; first-install time and signer unchanged). The backups show that
  no install, acceptance search or viewing of the questions changed a table (B0b, B1 and B2 identical; B3, B4 and
  B5 identical; B6 and B7 identical; B8 and B9 identical; B10 differs only by a processing-lease row). Tables
  changed only through the user-requested grouping (B3), the user's own answers and naming (B5 to B6) and the
  user's resumed processing pass with its automatic grouping (B7 to B8). The backend hardening is **not deployed**.
- **CI is failing** on the last four pushes, including HEAD: 3 of 328 Flutter tests fail on the Linux runner, while
  the same HEAD passes locally. The cause is not identified. A probable lead from 2026-10-22, not confirmed on
  Linux: the 320px widget tests pass on Windows only because the Segoe font is loaded as Roboto.
- **Device** (backups B0 to B10, 2026-10-22, aggregate).
  - Vivo I2214 (API 36) runs FP32 CPU with 1,916 indexed photos and 1,916 embeddings (schema 6, integrity ok).
  - People is enabled and, since the user resumed it on 2026-10-22, **not paused**. All 1,916 photos are now
    processed (backup B8): 2,642 faces, of which 397 are large enough for a descriptor (485 photos, 2,342 faces and
    336 descriptors before). The first review round failed on 2026-09-18 (1 false join). A fresh 20-pair round then
    **passed**: 0 false joins, threshold ≈ 0.462, with only 4 Different pairs in the holdout.
  - Device acceptance of the 2026-10-22 build **passed** (typed person searches, hidden person, suggestions view,
    persistence; `PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`). The assistant made no identity decision.
  - At the user's request "Group similar faces" ran once (backup B3): 266 automatic assignments, 137 new unnamed
    groups (142 persons in all), 3 of the faces added to a named person; reviews, scans and decisions unchanged;
    processing still paused then. A host simulation on a copy of backup B1 predicted exactly these numbers.
  - "Same person?" after that grouping: 122 questions (3 about automatic faces in a named person, 119 group pairs at
    or above the user's lowest "same" review score, ≈ 0.398). The user then named faces and answered questions on the
    phone (B5 to B6): persons 142 → 127, manual 6 → 35, automatic 266 → 239, rejects 1 → 736, "me" photos 1 → 11;
    "photos of me with `<P3>`" now returns 2 results. On B7 no question was left (79 group pairs answered No or Not
    sure, 104 share a photo, 7,319 below the floor, 1 joins two named people).
  - The user resumed processing (2026-10-22, about 10:41 to 11:02, app open, screen on): 1,431 photos at about 1.2 per
    second; the validated `applyGrouping` then ran (B8): automatic 239 → 324, groups 127 → 152, nothing added to a
    named person, manual assignments, decisions, reviews and threshold unchanged. The phone then offered 70
    questions (all group pairs; 5 offer a named person) and showed the main-screen prompt "Help improve face groups
    · 1 of 20". None was answered by the assistant.
  - Suggestion confirm/reject and voice input were not exercised on the phone.
  - 0 photos with GPS were found; no positive map pin has been seen.
  - Only 2 judged search queries exist (P@5 0.20 and 0.40).
- **Not done:**
  - grouping faces under 100 px (needs a new `FaceContract.id` with a lower minimum, a full re-scan of all photos
    and a new review round; proposed, not started)
  - the KI-16 fix (review rows need photo ids, which is a schema change)
  - M12 model manager. Provisioning is manual. The only in-app signal is a transient status line after an
    indexing attempt; it names the expected path and lists the fp16 file first, so do not follow it literally:
    provision only the fp32 files.
  - background indexing (WorkManager is initialized but **never scheduled**; OEM screen-off freeze KI-10)
  - worker-isolate indexing (decode and ORT run on the UI isolate)
  - FP16 / NNAPI
  - a judged retrieval benchmark
  - a release-signed build

## Known traps

- **Folder deselection** keeps indexed rows, which stay visible and searchable everywhere. Folder scope controls
  scanning only.
- **Failed assets** (for example HEIC) are re-planned and re-processed on every run.
- **Change detection** is mtime-only (`byteSize` is hard-coded to 0).
- **Viewer Details GPS** comes from `photo_rows.lat/lng`, which are always null on Android 10+. The map uses the
  separate EXIF `photo_locations`.
- **Search mode** (semantic or keyword fallback) is shown only by tooltip in the redesign. `isSemantic` stays true
  with an empty index.
- **`searchBackendProvider` rebuilds** after every indexing run and orphans the previous text ORT session (leak).
- **Commit coupling.**
  - Committing `pubspec.yaml` needs the untracked `assets/fonts/`.
  - `build.gradle.kts` needs the untracked `docs/ANDROID_RELEASE_SIGNING.md`.
  - Committing `enhancement_client.dart` or `online_settings.dart` without the untracked
    `lib/data/enhancements/backend_credentials.dart` (and its test) breaks compilation.
  - The 2026-10-22 wave's tracked files import its 7 untracked lib files (for example `search_providers.dart`
    imports `people_membership.dart`, and `people_screen.dart` imports `same_person_screen.dart`). Commit them
    together.
  - A release-signed APK cannot update the debug-signed install in place.
- **Small faces.** Only 397 of the phone's 2,642 detected faces (all photos processed, backup B8) reach the 100 px
  SFace minimum; the rest have no descriptor, so grouping, suggestions and "Same person?" questions can never reach
  them under the current `FaceContract`, and they are named by hand (of the first 485 processed photos, 67 have 10
  or more faces). Same-photo duplicate detections are a minor factor.
- **Reviewed photos (KI-16).** Reviewed photos are found through face ids, which include the photo revision. After a
  reviewed photo is edited it can be sampled into a new review round, so do not start a new review after editing
  reviewed photos until KI-16 is fixed.
- **Parity currency.** Host Flutter-ORT parity has not been re-run since `a76d3b6` (2026-08-08). The preprocessing
  fingerprint is Dart-captured, not PIL-derived.

## Documentation discipline

- Dated reports (`*_2026-09-xx.md`) are historical evidence. Do not rewrite their measurements; add new dated
  reports instead.
- Living docs: keep `docs/PROJECT_CONTEXT.md`, `docs/EVIDENCE_LEDGER.md`, `docs/FILE_MAP.md` and `docs/README.md`
  current when facts change, with dates.
- Several older status docs are stale and carry a dated note at the top (handbook §10). Refresh them, or write the
  missing ADRs (handbook §8), as part of the work that changes them.
- Label every number host or device, fp32 or fp16, with its date and its sample size.
