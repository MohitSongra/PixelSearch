# PixelSearch — Session Guide (repository root)

Android-first Flutter app for **on-device semantic photo search**. MobileCLIP-S1 ONNX embeddings, exact cosine
retrieval with hybrid reranking, ML Kit labels and faces, and opt-in offline People (SFace). Optional consented
online features: captions, the assistant and cloud speech transcription go through a self-hosted FastAPI broker (to
Groq); consented map tiles are fetched directly from the public OpenStreetMap tile server by `MapTileClient` (GET
only, no redirects, size-capped), not through the broker. It is a final-year major project held to research-grade
standards.

**Last full audit: 2026-10-21; updated 2026-10-22 for the People-search wave (host-verified, then accepted on the
test phone the same day), its "Same person?" confirmations and rounds, and the user's resumed People processing;
later that day for the review-ready branch (schema v7 / KI-16, FaceContract v2, the KI-17 CI fix, the interim
licence), and once more that day when the schema-v7 / FaceContract-v2 build was installed on the test phone and every
photo was re-scanned under v2, then for the later backups B13 and B14 and a read-only check of the People and review
screens.** For the deep context read
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
| `reports/`, `PIXELSEARCH_COPYRIGHT_SOURCE/`, `.impeccable/` | Local deliverables, git-ignored since 2026-10-22 (tracked `.gitignore` and `.git/info/exclude`). Never commit them. Still stage by explicit path, never `git add -A`. A git-ignored `.privacy-denylist.txt` at the root (real names, the serial) feeds the private-data scan in `tool/check_repository.py`; never commit it. |
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
- The working tree was redacted forward on 2026-10-22 (ADR-025); the pushed history still holds the exposures
  listed in the handbook §11. Making the repository private or rewriting history is the owner's decision.
- Never commit MobileCLIP ONNX exports, device databases, APKs or AABs, keystores, `.env`, `local_evaluation/` or
  the git-ignored deliverable folders. Only the bundled SFace ONNX is tracked.
- Do not commit or push unless the user asks. Pushing `main` can trigger Render's deploy workflow.

**Model and contract (ModelKit is the source of truth; any mismatch is a critical bug)**

- Never change preprocessing, the tokenizer, embedding size (512), image size (256), normalization, ONNX names or
  dtypes, or the opset without explicit approval, a version bump and re-verification.
- `AiContract` (`lib/core/ai_contract.dart`): `modelVersion '1.0'`, `embeddingVersion '1'`, `artifactVersion '3'`,
  `schemaVersion 7` (v7 adds reviewed photo ids, KI-16, 2026-10-22).
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
  joins. Any change to the face pipeline needs a new `FaceContract.id`. Current: `sface-2021dec-mlkit-landmarks-v2`
  (minimum face 64 px, 2026-10-22, ADR-023); a re-scan continues matching v1 faces by box overlap, and grouping
  stays off until a review round under v2 passes.
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
    `applyGrouping` runs after each full pass, still only with a passed gate. The phone has run FaceContract v2
    since 2026-10-22, so it stays off there until a review round under v2 passes.
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
cd pixelsearch_app && flutter test --no-pub test/   # 535 passed + 1 skipped (2026-10-22, branch review-ready-2026-10-22): the SFace worker test; tokenizer tests read ../model_kit fixtures
cd pixelsearch_app && flutter test --dart-define=SFACE_MODEL_TEST=true   # adds the real SFace worker test (needs a native ORT library); not run in this audit
cd pixelsearch_app && flutter build apk --debug --no-pub   # built 2026-10-22 (versionCode 1, same signer as the phone's install) and installed with adb install -r; release builds need PIXELSEARCH_KEYSTORE_PATH, _KEYSTORE_PASSWORD, _KEY_ALIAS, _KEY_PASSWORD (operator-supplied values, never committed)

# Repository and ModelKit checks
python tool/check_repository.py                    # passed 2026-10-22 (run as python -I)
cd model_kit && python eval/test_metrics.py        # passed 2026-10-22

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

- **Git.** `main` = `origin/main` = `4a7c81f` (2026-09-18). Everything since is committed on the **branch
  `review-ready-2026-10-22`**, pushed to GitHub on 2026-10-22 as its own branch (no pull request yet; `main`
  untouched, because pushing `main` can deploy the backend on Render). `git log
  4a7c81f..review-ready-2026-10-22` lists the commits: privacy redaction of dated reports, backend-token binding,
  release signing, the combined redesign + People validation recovery + People search commit (these share
  `search_screen.dart` and `people_repository.dart`), the backend hardening, the security review, the audit
  handbook, the private-data scan, the CI test-portability fix and workflow hardening, KI-16 (schema v7), FaceContract
  v2, hygiene commits (dead code, FP32-only wording, map tiles never cached on disk, onboarding copy, in-app licences
  and explicit assets, the ML Kit metrics notice), the licence, README and docs commit, a formatting-only commit
  (`f1c7f9d`) with a CI `dart format` check (`9bea6d4`), then two docs commits, an LF line-ending commit
  (`0f20b8c`, from which the phone's v2 APK was built) and docs commits recording the phone's v2 install, re-scan
  and later checks (all commits dated 2026-10-22). Each code commit was built and
  tested in a clean worktree. Run `git status` for any uncommitted doc edits. The pushed history still holds the
  personal data that the working tree no longer has (ADR-025).

  The phone runs a debug build of the People-search work, installed in place with `adb install -r` (ten installs on
  2026-10-22; first-install time and signer unchanged). The tenth is the schema-v7 / FaceContract-v2 build, a debug
  APK built at 13:12 from the branch tip `0f20b8c` (versionCode 1, same signer; it has all five licence texts and no
  MobileCLIP or fp16 ONNX). The backups show that no earlier install, acceptance search or viewing of the questions
  changed a table (B0b, B1 and B2 identical; B3, B4 and B5 identical; B6 and B7 identical; B8 and B9 identical; B10
  differs only by a processing-lease row, and B10 to B11 only by that row's removal), and B13 and B14 are
  identical: launching the app, its processing check and viewing the People and review screens wrote nothing.
  Tables changed only through the user-requested grouping (B3); the user's own answers and naming (B5 to B6); the
  user's resumed processing pass with its automatic grouping (B7 to B8); from B11 to B12, the schema-v7 migration,
  the v2 re-scan and the user's own answers during it (People tables only); and from B12 to B13, the user's later
  answers (People decisions, faces, persons and the generation counter). The backend hardening is **not deployed**.
- **CI** failed on the last four pushes (Linux runner only). Cause (KI-17, found by simulation on the Windows host):
  widget tests loaded a Windows system font as 'Roboto' only when it existed, and one path test used Windows-only
  literals. Both are fixed on the branch (tests load the bundled Manrope; host-rooted paths) and the workflow is
  hardened, but the fix has **not yet run on GitHub**; a local Docker run failed because Docker Desktop did not start.
- **Device** (backups B0 to B14, 2026-10-22, aggregate).
  - Vivo I2214 (API 36) runs FP32 CPU with 1,916 indexed photos and 1,916 embeddings (schema 7 since the v2 install,
    integrity ok in B12; the migration and the re-scan left photos and embeddings unchanged).
  - People is enabled and, since the user resumed it on 2026-10-22, **not paused**. All 1,916 photos are now
    processed (backup B8): 2,642 faces, of which 397 were large enough for a v1 descriptor (485 photos, 2,342 faces
    and 336 descriptors before the resumed pass); after the v2 re-scan 864 have one (below). The first review round
    failed on 2026-09-18 (1 false join). A fresh 20-pair round (under v1) then **passed**: 0 false joins,
    threshold ≈ 0.462, with only 4 Different pairs in the holdout.
  - Device acceptance of the earlier 2026-10-22 People-search build (schema 6, FaceContract v1) **passed** (typed
    person searches, hidden person, suggestions view, persistence; `PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`).
    The assistant made no identity decision.
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
  - The schema-v7 / FaceContract-v2 build was installed after backup B11 (app force-stopped; no uninstall, no data
    clear). The 6 → 7 migration filled both photo ids in all 140 review rows and left them otherwise identical. With
    the app open (screen on, charging, processing not paused) every photo was re-scanned under v2: 1,916 of 1,916 by
    13:51, about 1,889 of them in under 32 minutes (about 1.0 photo per second). Backup B12 followed.
  - Carry-over (B11 → B12, by face id): all 2,642 earlier faces kept their ids and photos (0 new, 0 dropped); 864
    of 2,642 now have a descriptor (397 under v1; 467 faces of at least 64 and under 100 px gained one), and 1,778
    stay under 64 px with none. The 771 earlier decisions are unchanged; named persons stay at 5, with identical
    name, alias and hidden rows; no earlier unassigned face became assigned; the must-be-zero checks are all 0.
  - During the re-scan the user answered "Same person?" questions on the phone: accepts 35 → 62, rejects 736 → 751,
    manual 35 → 62, automatic 324 → 297, persons 152 → 142 (10 unnamed groups merged away, no named person
    removed), "me" photos 11 → 20, one named person 1 → 4 photos. The 33 earlier assigned faces that changed are all
    explained by these answers. The user kept answering after B12; backup B13 (14:43, app stopped, integrity ok)
    audits that. B12 → B13 changed only the People decisions, faces and persons (and the People generation counter,
    255 → 275, so at most 20 user actions): accepts 62 → 63, reject rows 751 → 1,022 (a "No" to two groups writes a
    reject row for every face of each group against the other, so rows are not answers), the 813 earlier decision
    rows unchanged; 3 faces changed, each with a new decision of the user's (1 automatic → manual, 2 automatic →
    unassigned); persons 142 → 141 (1 unnamed group merged away, the 5 named persons identical); "me" photos
    20 → 21; must-be-zero checks 0; threshold still null. The assistant answered nothing.
  - Under v2 the stored threshold is cleared (B12: null; ≈ 0.462 under v1) because all 140 review rows are v1 rows,
    so automatic grouping stays off until the user's review round under v2 passes. Seen on the phone at about 14:50
    (the assistant launched the app and read the screens through read-only accessibility dumps; it tapped only
    "People", the "Automatic assignment awaits validation" tile and Back, and answered and rated nothing): the home
    screen asked "Help improve face groups · 1 of 17" about a named person; People showed 2,642 faces, 141 groups,
    "Automatic assignment awaits validation", 17 "Same person?" questions and "New faces found | 1488 to name"; the
    review screen showed "80 of 80 reviewed" and "Face settings changed: smaller faces can now be compared. Start a
    new review to turn automatic grouping back on." ("New review" not tapped). Backup B14 (14:52) is identical to
    B13 in every table.
  - Suggestion confirm/reject and voice input were not exercised on the phone.
  - 0 photos with GPS were found; no positive map pin has been seen.
  - Only 2 judged search queries exist (P@5 0.20 and 0.40).
- **Not done:**
  - the user's new review round under v2 (the install and the re-scan are done, 2026-10-22), which turns automatic
    grouping back on for v2 if it passes; starting it and rating its pairs are the user's. v2 grouping quality is
    unmeasured.
  - the first GitHub CI run of the KI-17 fix. CI runs only on pushes to `main`/`master` and on pull requests, so it
    needs a pull request from the pushed branch or a push to `main` (the owner's decision)
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
- **Release signing.** A release-signed APK cannot update the debug-signed install in place.
- **Small faces.** Under FaceContract v1 only 397 of the phone's 2,642 detected faces (backup B8) reached the 100 px
  minimum. After the v2 (64 px) re-scan, 864 of 2,642 (about 33 %) have a descriptor (backup B12, 2026-10-22); the
  1,778 faces under 64 px still have none and are named by hand. Same-photo duplicate detections are a minor factor.
- **Contract upgrade.** After installing a build with a new `FaceContract.id`, People shows the earlier faces until
  each photo is re-scanned (only while the app is open); calibration says "Face settings changed" until the user
  starts a new review (New review archives the v1 round), and automatic grouping stays off until that round
  passes. A new round needs photos never reviewed before. Do not judge the review pairs for the user. Measured on
  the phone for v1 → v2 (2026-10-22, B11 → B12): the re-scan of 1,916 photos finished with the app open, every
  earlier face kept its id and photo, earlier assignments changed only through the user's own answers, and the
  threshold was cleared. The calibration message was also seen on the phone's review screen (2026-10-22).
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
