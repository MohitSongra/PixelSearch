# ARCHITECTURE DECISIONS (ADR log)

> **Status note (2026-10-21 audit):** Some records below no longer match the code. ADR-006 (two separate repositories) is superseded: the app, `model_kit` and the backend now live as sibling folders in one repository, with the same ownership rule. ADR-015's early-cancel replay is defeated, because `IndexingService.run()` clears the cancel flag on entry. ADR-016 (fp16 v3) remains unaccepted on Android. Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The decisions below are kept unchanged as the historical record.

Format: each record is a decision, its context, and its consequences. Newest first.

## ADR-022 - "Same person?" rounds on the main screen (2026-10-22)
**Context:** the user asked for "Same person?" questions to come back every time the app opens, 20 at a time,
never repeating a question, as Google Photos does. Public sources on Google Photos (read 2026-10-22): its
help page (support.google.com/photos/answer/6128838) describes suggestions to merge two face groups, answered
Same / Different / Not sure, and says a merge cannot be undone. An Android Police article (2019-04-26,
androidpolice.com, "Google Photos has been asking users to help improve its facial recognition grouping")
describes a prompt to "improve some results" at the top of People & Pets, a full-screen view of matches
Photos is unsure about, and further prompts for other people after answering. Neither source gives a
question count or schedule; 20 per launch is the user's choice.
**Decision:** questions are asked in rounds. `samePersonSessionSizeProvider` (20) sets the round size, and
two in-memory providers count answers and the allowance for the current launch, so a new round starts with
each app launch. The Search home shows `SamePersonPrompt` while People is enabled and questions remain: one
question at a time, answered in place ("Help improve face groups · k of N"), "Not now" to hide it until the
next launch and "Open full screen". `SamePersonScreen` shows "Question k of N" and, at the end of a round,
"Keep going (20 more)". The question shown is always the first of the live list (provider limit 1000), which
is rebuilt after every answer. Every answer, Not sure included, is stored (ADR-021), so no question is asked
twice. The answer buttons (and "Open full screen") stay disabled while an answer is saving, through a flag
the prompt and the full screen share, and until the next question has loaded; if that reload fails, no
question is shown, because the old list may start with the pair just answered. The selection floor is
unchanged: at the user's choice (2026-10-22) only pairs at or above the lowest reviewed "same" score are
asked, with no lower tier when they run out.
**Consequences:** no schema, threshold, `FaceContract` or grouping-rule change, and nothing about rounds is
stored: a relaunch starts a new round, and "Not now" lasts until then. The supply of questions is limited by
faces with descriptors. On the test phone, after the user's answers, none were left: of the remaining group
pairs, 79 were already answered No or Not sure, 104 share a photo, 7,319 score below the floor and 1 joins
two named people. New questions need new faces, so on 2026-10-22 the user chose to resume People processing;
after each full pass the validated automatic grouping (`applyGrouping`) runs. On the phone that pass covered
all 1,916 photos (faces 2,342 to 2,642, descriptors 336 to 397), grouping assigned 85 more faces
automatically (groups 127 to 152, none added to a named person), and 70 questions were offered, all group
pairs; the main screen showed "Help improve face groups · 1 of 20".

## ADR-021 - "Same person?" confirmations (2026-10-22)
**Context:** after the user-requested grouping run (ADR-020), 266 faces on the test phone were assigned
automatically, 3 of them into a named person, and one person can still be split across unnamed groups. The
grouping cutoff is validated only on a 20-pair holdout with 4 different-person pairs, and same- and
different-person SFace scores overlap on that phone (current review round, calibration: same 0.398-0.996,
different 0.307-0.439). The user asked for Google-style "Is this the same person?" confirmations that compare
two faces and offer Yes / No / Not sure.
**Decision:** a pure builder, `buildSamePersonQuestions` (`lib/domain/people/same_person.dart`), asks two
kinds of question. (1) Every face that automatic grouping put into a named person ("Is this `<name>`?"), shown
beside a face the user confirmed for that person: the closest one with a descriptor, otherwise any confirmed
face. A named person whose faces were all grouped automatically has no confirmed face; its cover face (or its
first face) is the anchor instead and is never asked about itself. (2) Pairs of groups ("Is this `<name>`?"
when the left group is named, otherwise "Same or different person?"), named or unnamed but never two named
people, ordered by the cosine of their closest
faces (an ordering key only, never shown). Pairs that share a photo are skipped; the named (or larger) group is
the left anchor; pairs already answered No or Not sure are never asked again; and pairs whose closest faces
score below the lowest cosine among review pairs the user judged "same" (`minSimilarity`) are not asked. That
floor comes from the user's own review and selects questions; it never decides identity. Hidden people are not
asked about. `PeopleRepository.samePersonQuestions` is read-only and runs the builder off the UI isolate
when the pairwise work (faces times faces across groups) exceeds 20,000. `answerSamePerson` records only the
user's answer:
- For an automatic face, Yes makes it a manual assignment with an `accept` decision; No unassigns it and
  records `reject`, so it is never suggested or regrouped into that person; Not sure records `unsure`.
- For a group pair, Yes merges the right group into the left one, which keeps its identity. Only the two
  faces the user compared become manual (confirmed); other faces that grouping placed stay `automatic`, so
  they can still be asked about ("Is this X?") instead of turning into confirmations the user never made.
  Earlier `reject` and `unsure` answers carry over to the merged person, and a `reject` replaces an `unsure`.
  No records `reject` both ways for every face; Not sure records `unsure` for the right group's faces.
- `unsure` is a new decision value stored in the existing `people_decisions` table. Grouping and suggestions
  ignore it, it never overwrites an existing decision, and a later explicit naming replaces it.
- A stale question fails closed ("Try the next question") and writes nothing: when a person in it no longer
  exists, or when the automatic face, or either of the two compared faces, has left its person. Answers stay on
  the device, and no answer resumes processing or assigns anything automatically.
The UI is `SamePersonScreen` ("Same person?": two face crops capped at 160 px with "Open photo", No / Not sure
/ Yes in a fixed bottom bar, and a note to answer Not sure when in doubt), entered from a People screen tile;
the compact card on the main screen (ADR-022) caps the crops at 72 px and has no "Open photo".
ADR-022 adds rounds and the prompt on the main screen.
**Consequences:** grouping accuracy improves only through the user's answers. There is no threshold,
`FaceContract`, grouping-rule, calibration or schema change; `unsure` is a new value in an existing text
column, documented here. Questions only exist for faces with descriptors (at least 100 px), so small faces
still need manual naming (KI-14). A wrong Yes joins two people; the user fixes it by moving or removing faces,
as for ADR-020. On the phone after the grouping run the screen offered 122 questions (3 for the automatic faces
in a named person and 119 group pairs at or above the floor of about 0.398). That floor is below the highest
different-person calibration score (0.439), so some questions can show two different people, which is why
the user answers them.

## ADR-020 - User-requested validated grouping and a smaller naming list (2026-10-22)
**Context:** on the test phone the same person was listed many times in New faces. 2,006 of 2,342 detected
faces (86%) are below the 100 px SFace descriptor minimum and can never be compared; duplicate detections
are a minor factor. Automatic grouping had never run because the user keeps processing paused, although the
fresh review round passed (20 validation pairs, 4 of them different-person, 0 false joins). After seeing
this, the user chose automatic grouping and hiding tiny faces.
**Decision:** `PeopleRepository.groupNow()` runs the existing validated `groupFaces` (complete-link, the
saved review cutoff, never into a person already in that photo or one the user rejected for that face) once,
at an explicit user request (People ⋮ "Group similar faces", with a confirmation dialog), while processing
stays paused. It assigns nothing without a passed review gate. `applyGrouping()`, the automatic run after a
processing pass, still never runs while paused. New faces hides unassigned faces under 40 px in the prepared
image and a second detection overlapping a larger face in the same photo (IoU > 0.5) behind "Show small
faces (N)"; they are never deleted and can still be named from the photo. Each unnamed group counts once in
"N to name", and unnamed groups are listed largest first.
**Consequences:** no schema, `FaceContract`, grouping-rule or calibration change. Automatic assignments can
also join people the user named, and the cutoff is validated only on a 20-pair holdout with 4
different-person pairs, so wrong joins are possible; the user fixes them by moving or removing faces. On the
phone the run assigned 266 faces (137 new unnamed groups; 3 faces joined one named person). Small faces
still need manual naming. Lowering `minFacePixels` would need a new `FaceContract.id`, a re-scan with
processing resumed and a new review round to re-validate the cutoff; not done.

## ADR-019 - Person-query grammar and hidden-people semantics (2026-10-22)
**Context:** person search used one AND rule. "me" with no "This is me" person, voice punctuation,
"show me `<name>`" and "or"/"without" leaked words into the CLIP text or added the wrong person.
Hidden people were still matched by typed names.
**Decision:** `resolvePeopleQuery` stays the only parser. "me"/"myself" share one self key. A self word
is not a subject after a request verb (unless coordinated or placed) or after near/for/by. With People
enabled and no self person, the query reports `selfMissing` and no search runs. Names joined only by
"or" are alternatives; names after without/except/not are excluded; any mixed wording requires everyone
(the narrowest reading). Possessives, edge punctuation and fillers are stripped only in person queries;
a query that names nobody is returned byte-identical. Membership is one pure function
(`matchPeoplePhotos`) over assigned, non-dismissed faces, built once per People snapshot. Hidden people
are not resolved from typed text or offered in the People filter, but an explicit "Search photos of X"
still works, and the online privacy guard checks every saved name, hidden or not.
**Consequences:** no schema, ranking-constant or model change. Exclusion covers assigned faces only, so
an unassigned face of an excluded person can still appear. Names that are common words become filters
until the chip is dismissed. Hinglish "me" meaning "in" is a known false positive.

## ADR-018 - Similar-face suggestions are ranking-only and confirmed per face (2026-10-22)
**Context:** automatic grouping is only as trustworthy as a small reviewed holdout (the first round on
the test phone failed with one false join; a later 20-pair round passed), and People processing is
paused, so in practice every photo needs a manual name. Same- and different-person SFace scores overlap
on that phone.
**Decision:** for a named person, order unassigned, detailed faces by their maximum cosine to that
person's **manually** confirmed faces (ties: mean of the top three, then face id), one face per photo,
skipping photos that already show the person and faces the user rejected. There is no threshold, no
score shown and no select-all; nothing is assigned until the user confirms each face. "Not `<name>`"
writes the existing `people_decisions` reject row, so the face is never suggested for that person again.
Deleting photos keeps review pairs, so calibration fails closed ("A reviewed photo changed or is
unavailable") instead of re-scoring the remaining pairs.
**Consequences:** no schema change and no change to grouping, the gate or the sampler. Suggestions only
cover faces with descriptors (faces at least 100 px) in processed photos. A wrong confirmation attracts
look-alikes; per-face confirmation, Undo and "Remove assignment" are the mitigations. Retained review rows
hold face ids, a cosine and a judgment only, and "Disable and delete People data" still removes them.
**Update (2026-10-22, later the same day):** per-face confirmation governs similar-face suggestions. The
automatic grouping the user explicitly requests ("Group similar faces") assigns faces without per-face
confirmation; ADR-020 covers it. The Context line above ("in practice every photo needs a manual name")
predates that run, which assigned 266 faces automatically on the test phone; faces without descriptors still
need a manual name. "Same person?" questions (ADR-021) let the user confirm or undo automatic assignments.

## ADR-017 - Folder-scoped candidates with gallery-wide deletion reconciliation
**Context:** the user wants to choose folders for new indexing and explicitly retain already-indexed
photos when a folder is deselected. Treating a filtered gallery as the full gallery would delete those rows.
**Decision:** persist stable MediaStore folder IDs and explicit All mode in schema-v4 SQLite preferences.
Every foreground Index action confirms the scope; the existing background composition reads the same
preference. `GallerySnapshot` separates candidate metadata from existence IDs for `IndexPlanner`.
Only selected candidates reach decoding/CLIP/ML Kit. Full-access metadata scans identify true deletions;
limited access does not authorize pruning. Empty/unavailable selections never fall back to All.
**Consequences:** model/search contracts stay unchanged. Out-of-selection photos remain searchable but
are not refreshed until reselected. Subset runs still enumerate gallery-wide metadata for deletion checks,
with O(gallery size) ID memory. No WorkManager scheduling or automatic photo deletion is introduced.

## ADR-016 - Repair FP16 artifact conversion without changing the embedding contract
**Context:** the original fp16 image and text exports could not be loaded by ONNX Runtime: their declared
`Cast` output types were `float16` while the corresponding `Cast.to` attributes remained `float`. The source
was `onnxconverter_common.float16.convert_float_to_float16`, which changed value declarations without
normalizing those `Cast` attributes. The defect affected the physical ONNX graphs, not MobileCLIP weights,
tokenization, image preprocessing, or the public tensor contract.
**Decision:** regenerate fp16 artifacts from the preserved fp32 exports with ONNX Runtime's FP16 converter,
topologically sort the rewritten graph, normalize the existing internal ArgMax int32 cast idempotently, and
gate output with `onnx.checker` plus a `Cast` output-type validator. Record the repaired physical artifacts as
`artifact_version=3`; keep `embedding_version` unchanged until an Android fp16 session-load and numerical
parity gate succeeds. The desktop CPU harness deliberately selects fp32, because fp16 CPU execution is not
the Android target configuration.
**Consequences:** the repaired graphs are structurally valid and the image graph loads in host ONNX Runtime.
The model interface and indexed-vector compatibility have not been redefined. Android fp16 provider loading
and fp16-to-fp32 embedding parity remain required device acceptance tests before v3 replaces a populated
fp32 index. The reproducible repair path and its unit tests live in `model_kit/fp16_conversion.py`,
`repair_fp16_exports.py`, and `test_fp16_conversion.py`.

## ADR-015 — Indexing reaches the UI through a conditional-import bridge; the library is DB-backed
**Context:** M5 shipped a complete indexing engine that nothing called. The app still ran the M1 demo loader
(in-memory, capped at 80 photos, tags synthesized from EXIF), which shadowed the real pipeline and produced
both reported integration bugs. Wiring it up is not trivially "call `run()`": the composition root
(`buildDeviceIndexingService`) pulls in photo_manager, ML Kit, ONNX and `dart:io`, and `providers.dart` is
reachable from the web build.
**Decision:**
- Add a **conditional-import bridge**, `lib/state/index_bridge.dart` (+ `_io` / `_stub`), exactly mirroring
  `semantic_wiring.dart` (ADR-014): native assembles and runs the unmodified pipeline; web returns
  `IndexRunStatus.unsupported`. `providers.dart` never imports an indexing adapter, so the web build stays
  green. The bridge is *wiring only* — it contains no indexing logic, and `lib/indexing/**` was not touched.
- Cancellation crosses the boundary via a platform-free **`IndexCancelToken`**. The UI cannot hold an
  `IndexingService` (native-only type), and the service does not exist until the ONNX encoder has loaded —
  long enough for a user to press Cancel first — so the token records an early cancel and replays it on
  `bind()`.
- **Media permission is requested in the bridge**, before the scan. `PhotoManagerGallerySource` (correctly,
  as a port implementation) reports an empty gallery rather than an error when access was never granted, so
  an unprompted run would silently index zero photos. Permission is a platform concern of the composition
  layer, not of the port — this keeps `GallerySource` free of a permission API.
- **`PhotoLibrary` becomes a view of the store** (`PhotoRepository.loadPhotos()`), refreshed by
  `IndexingController` when a run ends; the indexer is the only writer. On completion the controller also
  invalidates `indexWarmupProvider`, so photos indexed this session become semantically searchable without a
  restart.
- `Photo` gains `thumbPath` and resolves it through a web-safe `fileImage()` boundary
  (`lib/core/platform_image*.dart`), keeping the domain model free of `dart:io`.
**Consequences:** one pipeline, one source of truth, and no cap anywhere on the path (`IndexingService`
indexes whatever `listAssets()` returns — pagination lives in the adapter). The cost is a fourth
conditional-import seam and a UI that must handle four non-running outcomes (unsupported, permission denied,
model missing, finished-with-phase). Runtime behaviour of photo_manager/ML Kit is still device-only
(TD-11); the wiring and persistence are covered by `test/indexing_integration_test.dart`.

## ADR-014 — Semantic search: async SearchBackend + hybrid re-ranking (M6)
**Context:** M6 makes search real — query text must be CLIP-embedded (ONNX) and scored against stored image
embeddings. Two frictions with the existing seam: (1) `SearchBackend.search` was **synchronous**, but text
embedding is a `Future`; (2) pure cosine ignores the rich signals the M5 indexer already stored (ML Kit
labels, faces) and the metadata users think in (tags, place, album).
**Decision:**
- Make `SearchBackend.search` **async** (`Future<List<Photo>>`). `KeywordSearchBackend` returns an
  already-complete future; `SemanticSearchBackend` awaits the encoder. The sync signature was a M2-era
  oversight — the seam was always meant to receive semantic search (ADR-009); this is a signature evolution,
  not a redesign (one existing implementor, updated trivially).
- Introduce a pure **`HybridScorer`** (domain policy, no ONNX/IO): `final = wSem·semantic ⊕ wLex·lexical ⊕
  wFace·face`. Semantic strength maps the cosine against a fixed reference band (absolute); lexical is
  min-max normalized across candidates (unbounded counts); face-intent boosts people/portrait queries by
  detected face count. Weights default 0.70 / 0.25 / 0.05, tunable and recorded (not fabricated).
- The `VectorIndex` stays the ANN-swap seam (ADR-009); `SemanticSearchBackend` **degrades to lexical** if the
  model can't load/embed, and web has no ONNX so it uses `KeywordSearchBackend` outright — search never fails.
- Enrich the domain `Photo` with read-only `labels`/`faceCount` (surfaced from the M5 DB columns) so the
  scorer is a pure function of `Photo` + raw signals, fully unit-testable.
**Consequences:** the whole M6 path is testable in-sandbox (14 unit tests with fakes) and was validated on a
**real Flutter ORT** at 6/6 retrieval. The min-cosine precision floor is a *measured*, recall-favoring
default (0.15, below the min observed correct-pair cosine 0.198, above the max distractor 0.146); principled
tuning is deferred to the M14 labeled eval. Async search means the UI renders an `AsyncValue` (spinner/badge)
— a deliberate, honest UX cost of running a real model. See `BENCHMARK_RESULTS.md §M6`.

## ADR-013 — Indexing engine: ports & adapters, reconcile-based resume, batch transactions (M5)
**Context:** the engine must scale to 50k photos, survive interruption/crash/reboot, index incrementally,
and integrate device-only plugins (photo_manager, ML Kit, WorkManager) — while staying testable.
**Decision:** hexagonal architecture. A pure core (`IndexingService` + `IndexPlanner` + `AssetProcessor` +
`IndexStore` + `ModelVersionManager`) depends only on ports (`GallerySource`, `MetadataExtractor`,
`ThumbnailGenerator`, `AssetEmbedder`, `ImageEnricher`, `BackgroundScheduler`). **Resume is structural**:
`run()` re-reconciles and skips up-to-date assets, so committed batches are the recovery unit — no bespoke
resume cursor to corrupt. Writes are **batched in one transaction** (never per-image). Embeddings persist
once, keyed by (photo, model) + tagged `embedding_version` for migrations.
**Consequences:** the entire orchestration + correctness logic is unit-tested in-sandbox with fakes (11
gates incl. cancel/resume/incremental/dedup/deleted/version/stress); device adapters are thin, swappable,
and the only on-device piece. The rest of PixelSearch depends only on the stable core + ports. See
`docs/INDEXING_ARCHITECTURE.md`.

## ADR-012 — Text ArgMax int32 cast for onnxruntime-1.15 compatibility (M4.3)
**Context:** CLIP's text encoder selects the EOT token via argmax over `input_ids` (int64). The Flutter
plugin bundles onnxruntime **1.15**, which has no int64 ArgMax CPU kernel — the real Flutter-ORT text
gate threw `Could not find an implementation for ArgMax(13)`. Python ORT (1.25) ran it, so a Python-only
check would have missed a bug that also **crashes on-device** (the same runtime ships there).
**Decision:** patch the exported text models (fp32 + fp16) to insert a `Cast(int64→int32)` before each
ArgMax. External I/O stays int64; argmax indices — and embeddings — are identical (ids ≪ 2³¹). Bump
`artifact_version` 1→2 (no `embedding_version` change, no re-index). Folded into `prepare_model.py` (§5b)
for reproducibility; standalone `patch_text_argmax.py` also provided.
**Consequences:** the shipped text model runs on the target runtime. Verified: patched model reproduces
the reference at cosine 1.0; the Flutter text gate passes at **cosine 1.000000**. The alternative
(int32 model input) was rejected — it would change the frozen contract dtype.

## ADR-011 — Shared `OnnxEncoder` base for the CLIP encoders (M4.3)
**Context:** the image and text embedders share the whole ORT session lifecycle — load once, reuse the
session, run one input tensor to an L2-normalized 512-d vector, release. Duplicating it invites drift.
**Decision:** extract an abstract `OnnxEncoder` (single responsibility) owning load/dispose/session-reuse
and the extraction + L2; `OnnxImageEmbedder` and `OnnxTextEmbedder` only build their own input tensor.
**Consequences:** one place for the ORT lifecycle; the image parity gate was re-verified after the
refactor (cosine 1.0, no regression). Each concrete embedder stays small and testable.

## ADR-010 — Bit-faithful image preprocessing to guarantee ONNX parity (M4)
**Context:** the M4 gate requires cosine > 0.999 between the Flutter and Python embeddings. The `image`
package's built-in resizes (linear/box) diverged (coffee bottomed at 0.9979).
**Decision:** implement preprocessing bit-faithful to open_clip's PIL/torchvision transform — a
separable **antialiased triangle-filter** resize with **uint8 intermediates**, `int(size*long/short)`
resize dims (truncation), and **round-half-to-even** center-crop offset.
**Consequences:** cosine = **1.000000** across all 6 probe images (max-abs-err ≤ 1.3e-4). The resampler
is pure and unit-tested, independent of ONNX. Per-pixel extraction via `image.getPixel` is not the
fastest path (TD-9); M4.5 profiling optimizes it with a direct byte buffer. This is why the app depends
on the exact model contract, not an approximation.

## ADR-009 — Search behind a `VectorIndex` seam (brute-force now, ANN later)
**Context:** exact brute-force cosine is fine to ~50k photos, but a larger library will want an ANN
backend (sqlite-vec / ObjectBox HNSW). We must be able to swap that in without touching upper layers.
**Decision:** define a `VectorIndex` interface (`upsert` / `remove` / `query topK`) with an in-memory
`BruteForceVectorIndex` implementation now (unit-tested). The M7 semantic-search service will depend
only on the interface, so a `SqliteVecVectorIndex` can replace it later with zero caller changes.
Separately, an app-level `SearchBackend` seam (keyword today → semantic at M7) keeps the search
provider and UI stable across that transition.
**Consequences:** the ANN swap the brief called out is fully insulated (interface + tests). The
keyword→semantic transition will introduce async at the provider once (planned, at M7); the
brute-force→sqlite-vec swap introduces nothing. No vector search is wired into the app yet — that is
M7, gated on the M4 numerical-validation pass.

## ADR-008 — Store embeddings as little-endian float32 BLOBs (M2)
**Context:** cosine search needs float32 in memory; SQLite has no vector type.
**Decision:** persist each 512-d vector as a 2048-byte little-endian float32 BLOB in `EmbeddingRows`.
**Consequences:** simple, lossless, fast to `memcpy` into a `Float32List`. Costs ~2 KB/photo
(~100 MB at 50k). fp16-blob halving is deferred (see `TECHNICAL_DEBT.md`). A brute-force cosine
scan is fine to ~50k; an ANN index (sqlite-vec / ObjectBox HNSW) is a later optimization, not MVP.

## ADR-007 — drift for local persistence, native-only via conditional connection (M2)
**Context:** need a typed, testable store; must not break the web build used for sandbox verification.
**Decision:** use `drift` (+ `sqlite3_flutter_libs`) with a conditional connection — native on
mobile/desktop, an `unsupported` stub on web — mirroring the existing device-gallery pattern.
**Consequences:** type-safe queries + migrations + in-memory tests on the host; web compiles but
has no DB backend for now (acceptable: Android-first, web is a verification/demo target). Adds a
build_runner codegen step (generated file committed).

## ADR-006 — Two separate repositories, ModelKit is source of truth
**Context:** model tooling (Python) and app (Flutter) have different lifecycles and languages.
**Decision:** keep **PixelSearch** (Flutter) and **PixelSearch ModelKit** (Python) separate; Flutter
consumes ModelKit artifacts and never redefines the contract.
**Consequences:** clean ownership; the contract lives in `INTERFACE_CONTRACT.md` (owned by ModelKit,
mirrored to Flutter). Any Flutter/ModelKit mismatch is treated as a critical bug.

## ADR-005 — Provision the model at runtime, don't bundle it in the APK
**Context:** fp16 encoders total ~171 MB.
**Decision:** ship the app without the models; provision them on first run; run in keyword-fallback until present.
**Consequences:** small install; the app is always usable; needs a model-manager UI (M12) and integrity checks.

## ADR-004 — Ship fp16, not int8
**Context:** measured — naive dynamic int8 dropped retrieval to 1/6 (unusable) on the conv-based image encoder;
fp16 is near-lossless.
**Decision:** ship fp16 (~171 MB). Smaller footprint later via MobileCLIP2-S0 or calibrated/QDQ int8.
**Consequences:** fp16 needs NNAPI/XNNPACK (not plain CPU fp32 kernels). See `BENCHMARK_RESULTS.md`.

## ADR-003 — MobileCLIP-S1 / datacompdr as the embedding model
**Context:** need strong image-text retrieval that fits a phone; verified in the spike.
**Decision:** MobileCLIP-S1, 512-d, 256×256 input. Export via legacy ONNX exporter, opset 17.
**Consequences:** frozen in `INTERFACE_CONTRACT.md`; parity verified (cos 1.000000, 6/6 retrieval).

## ADR-002 — Riverpod for state + manual DI
**Context:** need testable, override-able wiring without a heavy DI framework.
**Decision:** Riverpod providers as the composition root; inject repositories via provider overrides in tests.
**Consequences:** simple, idiomatic, no extra DI dependency.

## ADR-001 — Mobile-first pivot (from desktop/web), privacy-first preserved
**Context:** the original PixelSearch was desktop/web; the product thesis is on-device privacy.
**Decision:** pivot to a Flutter mobile app, Android-first, everything on-device by default.
**Consequences:** all subsequent architecture (on-device CLIP, local store, optional cloud) follows from this.
