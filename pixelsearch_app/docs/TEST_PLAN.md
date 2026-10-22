# TEST PLAN

> **Status note (2026-10-21 audit):** This file is stale. The test count today is 372 passed + 1 skipped on the working tree. Web builds are not a CI target, and the "on-device fp16 golden on NNAPI/XNNPACK" item has never run. CI has failed on every push since 2026-09-09 (runs 4–7). At HEAD (`4a7c81f`, run 7, 2026-09-18) only the Flutter job failed: 324 passed, 3 failed, 1 skipped on the Linux runner. The causes of runs 4–6, and which 3 tests failed, are unknown (job logs not read). Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record. **Update 2026-10-22:** the branch `review-ready-2026-10-22` (where the former working tree is now committed) passes 535 + 1 skipped on the Windows host, the People search build passed device acceptance, and the three Linux-only CI failures are explained and fixed on the branch (KI-17; not yet run on GitHub); see the two sections added since: [Review-ready cleanup](#review-ready-cleanup-facecontract-v2-and-schema-v7-2026-10-22-later) and [People search (2026-10-22)](#people-search-2026-10-22).

Testing scales with the milestone. Principle: every milestone lands with the tests that prove it.

## Review-ready cleanup, FaceContract v2 and schema v7 (2026-10-22, later)

Windows host, 2026-10-22: `flutter analyze --no-pub` reports no issues and `flutter test --no-pub test/` gives
**535 passed, 1 skipped** (the real SFace worker test, which needs `--dart-define=SFACE_MODEL_TEST=true`); the same
after the formatting commits (`9bea6d4`). The KI-16 bug test is no longer skipped. New or changed tests:

- `test/people_contract_upgrade_test.dart` (4, new; ADR-023): a re-scan under v2 continues each matching face with
  its name, "Not a face" and decisions, drops unmatched unassigned observations and keeps unmatched named ones on
  record; earlier faces stay visible until their photo is re-scanned and only v2 scans count as processed; reviews
  under v1 keep grouping off with the "Face settings changed" reason; archived "same" answers keep the question
  floor. The carry-over and floor tests fail without their fixes.
- `test/people_migration_test.dart` (+1; ADR-024): v6 -> v7 adds the two photo-id columns, fills them from the faces
  that still exist (null when a face is gone) and leaves the photo, face and state tables unchanged.
- `test/people_validation_recovery_test.dart`: the KI-16 test now runs and passes (it fails without the fix); the
  review seed stores photo ids as the app does.
- `test/third_party_licenses_test.dart` (2, new): the licence page lists SFace, the CLIP vocabulary, Manrope, the
  Material Icons font and the native ONNX Runtime; the Privacy Centre shows the ML Kit metrics notice, and
  Settings > About opens the dialog with "All rights reserved" and "View licenses".
- `test/map_tile_client_test.dart` (+1): consented tiles use a disabled disk cache.
- `test/widget_test.dart`: onboarding makes no speed claim and states the online-feature exception;
  `test/startup_and_labels_test.dart` scrolls to the onboarding buttons, which the longer copy moves below the
  fold on short screens.
- `test/people_domain_test.dart`: the device-derived boundary cosines in the gate test are rounded to four decimals
  (same order, same outcome).
- `test/support/test_fonts.dart` (new) replaces the font loaders of five widget-test files, four of which loaded
  the Windows-only Segoe font as 'Roboto'; `test/modelkit_paths_test.dart` builds host-rooted paths (KI-17). Real
  names in fixtures were replaced with placeholders (ADR-025).

**Device, 2026-10-22** (Vivo I2214, API 36; aggregate): the schema-v7 / FaceContract-v2 debug build was installed in
place as the tenth install of the day. The v6 -> v7 migration filled both photo ids on 140 of 140 review rows (B12,
integrity ok), and all 1,916 photos were re-scanned under v2: 2,642 of 2,642 faces kept (0 new, 0 dropped) and faces
with a descriptor 397 -> 864. This is consistent with what the v7 migration test and the carry-over part of the
contract-upgrade tests check; the "Face settings changed" message stays host-tested (B12 has no threshold, but the
screen was not viewed on the phone). The "Same person?" answers given during the re-scan were the user's; the
assistant answered nothing. See `PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`, rows P25 to P27.

## People search (2026-10-22)

Windows host, 2026-10-22: `flutter analyze --no-pub` reports no issues and `flutter test --no-pub test/`
gives **526 passed, 2 skipped** after the rounds and all review fixes (523 + 2 before the second verification
pass's fixes, 512 + 2 on the first
"Same person?" build, 499 + 2 before it and 496 + 2 before the user-requested grouping change, all the same day;
372 + 1 on 2026-10-21). The skips are the real SFace worker test (needs
`--dart-define=SFACE_MODEL_TEST=true`) and the KI-16 bug test below.

- `test/people_query_parser_test.dart` (52, new): the `resolvePeopleQuery` grammar. Self words after request
  verbs, required / any-of / excluded roles, negation wording, mixed and/or falling back to AND, possessives
  and edge punctuation, saved spellings, and queries that name nobody returned byte-identical.
- `test/people_membership_test.dart` (21, new): `matchPeoplePhotos` (required ∩ any-of − excluded), failing closed.
- `test/people_suggestions_test.dart` (27, new): suggestion order with no cutoff; suggestions are read-only and
  assign nothing automatically; confirming fails closed without partial writes; rejected suggestions never return
  for that person; Undo restores the exact rows; paused stays paused and nothing becomes automatic after any
  other People action. Two review-fix tests: grouping skips duplicate detections, leaves no empty group and
  advances the generation; face size follows the decoder's power-of-two scaling (a 4160x3120 photo is prepared
  at 1040x780). Three tests cover the user-requested grouping and naming list (ADR-020):
  - "Group similar faces" while paused: `groupNow()` assigns nothing without a passed review; after the review
    passes, the automatic `applyGrouping()` still assigns nothing while paused, and `groupNow()` then groups two
    look-alike faces as `automatic` while People stays paused.
  - Tiny faces and duplicate detections leave the naming list; they are not deleted and can still be named.
  - An unnamed group counts once in the naming total.
- `test/people_same_person_test.dart` (24, new; ADR-021, ADR-022): the "Same person?" confirmations and rounds.
  - `buildSamePersonQuestions` (4): automatic faces in named people come first, beside the closest confirmed face
    (any confirmed face when none has a descriptor); group pairs are ordered closest first, never share a photo,
    never pair two named people, put the named (or larger) group on the left and skip pairs already answered;
    the limit is honoured; pairs less alike than the lowest reviewed "same" pair are not asked.
  - `answerSamePerson` (12): for an automatic face, Yes makes it manual with an accept decision, No unassigns it
    with a reject (it is no longer suggested for that person either) and Not sure changes nothing but records
    `unsure`; for two groups, Yes merges the unnamed group into the named person, No keeps them apart with
    rejects both ways and Not sure keeps both without asking again, while a later explicit naming still replaces
    `unsure`. Each answered question is not asked again. Answers keep processing paused and assign nothing
    automatically, and a stale question (its group deleted) fails closed. From the review fixes: a Yes confirms
    only the two faces shown (other automatic faces stay automatic and are asked about next); a Not sure survives
    a merge; a No outranks an earlier Not sure when groups merge; a named group with only automatic faces is
    checked against its cover.
  - Widget (1): the card shows both faces and the No / Not sure / Yes answers; Yes saves and the empty state
    follows.
  - Rounds (4, ADR-022): a round stops after its size, "Keep going" asks more and no question repeats; the home
    prompt answers in place and "Not now" hides it; the prompt disappears when the round is answered; and the
    prompt takes no answer until the next question has loaded (this test fails without the fix).
  - Second verification pass (3, each failing without its fix): a group pair whose compared face has moved fails
    closed and changes nothing; while an answer saves, neither the prompt nor the full screen takes another; if the
    next question fails to load, the answered pair is not shown again.
- `test/people_validation_recovery_test.dart` (+3): deleting a reviewed photo keeps automatic grouping off; a
  deleted reviewed photo blocks the fresh check until a new review; a **skipped BUG test** documents that a
  revised reviewed photo can be sampled into a new review (KI-16).
- `test/people_repository_test.dart` (updated): `deleteAssets` keeps the review row, so calibration fails closed.
- `test/people_widgets_test.dart` (+21): per-face confirmation and the "not recognition" copy, Undo binding,
  multi-select, the This-is-me holder (hidden self included), missing-self state, chips, empty states, hidden
  people, the People filter chip, no flow resuming processing, small-screen layouts, naming an automatic group
  confirms the face shown first, and a name-only search is labelled "Matched by assigned faces".
- `test/voice_search_widgets_test.dart` (+7): spoken punctuation removed before local search; the online guard
  blocks person filters, names (hidden people included), "or" and "without"; an allowed refinement sends no
  person keys.

**Device acceptance, 2026-10-22** (Vivo I2214, API 36; aggregate): driven over adb by the assistant at the user's
request through the accessibility tree, with no screenshots and no identity actions by the assistant (no naming,
confirming, rejecting or answering). The in-place install checks, backup comparisons, eight typed person queries,
the hidden-person flow, the user-approved "Group similar faces" run and restart persistence passed, with expected
values taken from backups. The "Same person?" screen was first only viewed (122 questions; tables unchanged from
B3 to B5). The user then named faces and answered the questions on the phone (B5 to B6, checked through backup
counts; "photos of me with" a named person then gave 2 results). The rounds build followed (no question left), the
user resumed People processing (all 1,916 photos processed, 70 new questions, the main-screen prompt shown), and
three builds with the later fixes were installed; nine in-place installs in all for this build series (a tenth, the
schema-v7 / FaceContract-v2 build, followed the same day; see the review-ready section above). Suggestion decisions,
answering through the rounds and voice input remain host-tested only. Results:
`PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`.

## Folder Selection (2026-09-08)

`photo_manager_gallery_test.dart`, `folder_indexing_test.dart`,
`indexing_preferences_test.dart`, and `folder_picker_test.dart` add 18 tests.
They cover multi-page scoped discovery, deduplication, image-only permissions,
limited/denied access, missing/empty selections, retained search rows, true deletions,
incremental reselection, saved choices, cancellation, schema migration, and compact layout.
Physical-device evidence is recorded in `FOLDER_INDEXING.md`.

## Layers
- **Unit** — pure logic and data. DB round-trip & migrations (M2), embedding-blob codec (M2),
  BPE tokenizer parity (M6), cosine ranking (M7), Photo⇆row mapper (M2).
- **Parity** — the Dart pipeline vs `reference_vectors.json`: for each query row, argmax == diagonal (6/6).
  This is the guardrail against silent ModelKit/Flutter drift (M6/M7).
- **Widget** — key screens render and respond (search, viewer, onboarding).
- **Integration** — index a small fixture set → query → assert ranked results (M5+M7).
- **Golden (optional)** — image preprocessing output vs a reference tensor, once M4 preprocessing is verified.

## Current coverage
- Baseline: analyzer clean; widget smoke test passes; `flutter build web` succeeds.

## M2 adds (this milestone)
- `test/database_test.dart`:
  - insert → read back a `PhotoRows` row (all fields survive).
  - upsert an `EmbeddingRows` vector; read back; assert the `Float32List` is **bit-identical** (blob codec is lossless).
  - `IndexStateRows` read/write single-row semantics.
  - runs against `NativeDatabase.memory()` on the host (no device needed).
- Gate: `flutter analyze` = 0 issues; `flutter test` green; `flutter build web` still compiles.

## Added with the architectural improvements (2026-08-06)
- `test/brute_force_vector_index_test.dart` — cosine ranking, topK, upsert/remove/clear.
- `test/benchmark_test.dart` — `TimingStats` math + harness warmup/iteration accounting.
- `test/database_test.dart` — added the `embedding_version` staleness case (schema v2).
- ModelKit `eval/test_metrics.py` — Precision@K / Recall@K / AP / mAP on synthetic inputs.
- **Totals:** Flutter **11** tests green; ModelKit metric tests green; analyzer 0 issues; web build OK.

## M4 parity tests (the numerical gate)
- **Image gate — DONE (real Flutter ORT):** `integration_test/image_parity_test.dart` runs the full
  production pipeline through onnxruntime on Linux desktop (`xvfb-run flutter test integration_test -d linux`)
  and asserts dims=512, cosine>0.999, max-abs-err<0.02, retrieval 6/6. **Result: cosine 1.000000 on all 6.**
- **Preprocessing unit tests** (in-sandbox `flutter test`): shape / [0,1] range / CHW / crop — ORT-independent.
- **Tokenizer parity — DONE:** Dart token ids == open_clip ids on 19 diverse cases (`test/clip_tokenizer_test.dart`).
- **Text gate — DONE (real Flutter ORT):** `integration_test/text_parity_test.dart` — query → tokenizer →
  Flutter ORT → L2 vs reference; **cosine 1.000000** on all 6 queries.
- **Golden suite — DONE (real Flutter ORT):** `integration_test/golden_validation_test.dart` — full
  image+text pipeline: 100% retrieval, cosine parity, normalization, stable Top-K ranking, repeatability;
  auto-writes `VALIDATION_REPORT.md`.
- **Regression guards — DONE:** `test/preprocessing_golden_test.dart` (pinned preprocessing fingerprint)
  + the 19-case tokenizer parity — silent preprocessing/tokenizer drift fails loudly.
- **Benchmark suite:** `integration_test/benchmark_test.dart` — model load, embed latency, throughput
  on real Flutter ORT (build host); auto-writes `BENCHMARK_REPORT.md` (BENCHMARK_RESULTS §8).
- **On-device fp16 golden** (device): the fp16 artifacts on NNAPI/XNNPACK (the CPU EP cannot execute fp16).

### Real-ORT fixture resolution
The host integration tests resolve the sibling `model_kit` directory by default. Set
`PIXELSEARCH_MODELKIT` to an alternate ModelKit root. They still require a supported Flutter runner:
Linux desktop or a connected Android device for this Android-first project; this checkout does not include a
Windows desktop target.

## M5 indexing tests (core — real drift DB + fakes, in-sandbox)
- `test/index_planner_test.dart` (7) — reconcile: added / changed / deleted / stale-version / no-embedding /
  idempotent-skip / mixed.
- `test/indexing_service_test.dart` (9) — full index + embed-once, incremental (no duplicate work), new-only,
  deleted (+embedding removed), changed re-embed, model-version migration, cancel→resume, per-asset failure
  isolation, 200-asset stress + checkpoint.
- `test/indexing_integration_test.dart` (3, added 2026-08-08) — **regression cover for the two integration
  bugs** the M1 demo loader caused (ADR-015): a 1500-asset gallery indexes 1500 (no cap anywhere; `fraction`
  reaches 1.0), ML Kit labels survive store → `Photo.labels`/`displayTags` while the demo's synthesized tags
  (`photo`/`portrait`/`landscape`/`travel`) are absent from `searchBlob`, and the generated thumbnail path
  reaches `Photo.thumbPath` for display.
- **On device (pending):** device adapters (photo_manager, ML Kit, WorkManager, EXIF, thumbnail),
  WorkManager reboot/backoff, permission prompt + "Selected Photos" (KI-7), and real latency/memory.

## M6 — semantic search (added 2026-08-07)
Unit (in-sandbox, no ONNX):
- `test/hybrid_scorer_test.dart` (8) — semantic-dominates-lexical, lexical boost on near-ties, min-max
  normalization, face-intent gating (boost only on people queries), zero-signal drop, empty input, `reason`
  attribution, fixed-band cosine mapping.
- `test/semantic_search_backend_test.dart` (6) — nearest-first retrieval, semantic hit with zero keyword
  overlap, empty-query browse (newest-first), `semanticMinCosine` gating, graceful keyword degradation on
  model-load failure (no embed calls after), empty-index → pure-lexical.

Integration (real Flutter ORT, `-d linux` via xvfb):
- `integration_test/semantic_search_test.dart` — embeds the 6 parity images, runs real text queries through
  the **entire** `SemanticSearchBackend` path: asserts **6/6** top-1 retrieval; measures diagonal/off-diagonal
  cosine, end-to-end query latency, and brute-force scan latency @1k/10k → `SEMANTIC_SEARCH_REPORT.md`.

## Tracked follow-ups
- A drift **schema-migration test** (v1→v2) using drift's schema-verification harness (not yet added).
- A widget test asserting the async search states (spinner → results, Semantic/Keyword badge).
- A widget test over `IndexingController` with an overridden `index_bridge` (Index → progress → Cancel →
  library refresh). Needs the bridge behind a provider so it can be overridden; today it is a top-level
  conditional-import function.

## Deferred (need a physical device — tracked in BENCHMARK_RESULTS as PENDING)
On-device latency, indexing throughput, memory, and end-to-end search quality on real libraries (M5/M6 runtime).
Hybrid-weight + threshold precision/recall on a labeled set (M14).
