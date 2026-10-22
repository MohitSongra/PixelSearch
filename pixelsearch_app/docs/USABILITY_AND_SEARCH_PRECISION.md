# Usability and Search Precision

> **Redaction note (2026-10-22):** personal identifiers (names, the device serial, local paths, private photo filenames, backup names and APK/backup digests) were replaced with placeholders. Measurements are unchanged.

Date: 2026-09-08. Scope: returning-user startup, excessive search results, and label correction.

## Outcome

[PARTIAL] Confirmed app defects are fixed. Raw semantic precision is **not** solved. In particular, the saved `a dog` search still has seven user-judged irrelevant photos above the existing cutoff. Returning fewer photos is not proof that the remaining photos are relevant.

## Confirmed Causes and Changes

1. [VERIFIED] The root route always built onboarding; neither action saved completion. Startup now reads durable state, migrates an existing indexed library, and waits before routing. Both accepting indexing and choosing Not now save completion. Read failures surface a retry screen instead of pretending the library is empty.
2. [VERIFIED] Semantic candidates were unioned with every positive metadata keyword match. Substring matching let the article `a` match `WhatsApp Images`, admitting all 1,916 photos despite the cosine gate. Healthy semantic search now requires membership in its gated top-60 pool. Keyword-only fallback explicitly retains its old behavior; diagnostics retain the old union as `lexical_bypass_experiment`. The prior ML Kit boost experiment remains available.
3. [VERIFIED] The label adapter retained up to three guesses below its 0.5 operating threshold when no label passed. It now permits an empty label list and rejects non-finite confidences. This is a confirmed weak-label policy defect, **not proof that every incorrect existing label came from the fallback**. Confidences were not persisted, and a confident classifier can still be wrong.

   The checked notebook result has stored labels `Paper` and `Monochrome`, with no `Dog` label. It appears in the dog search because of its raw embedding score, not because it was tagged dog.
4. [IMPLEMENTED] Photo details now has an Edit labels control. Corrections are saved separately from indexer-owned SQLite rows, take effect in the library, and survive a subsequent index refresh. Restore automatic labels is available. An empty correction is meaningful. Corrections do not retrain MobileCLIP or change semantic vectors.
5. [VERIFIED] Backend startup now awaits vector warmup. Search no longer displays the previous query's photos while a new query is loading. Search errors and a successful search with no matches have distinct states.

No model, preprocessing, tokenizer, embedding version, SQLite schema, hybrid weights, score normalization, cosine cutoff, folder-selection logic, or stored embedding was changed. The label adapter affects new indexing work; existing photos were not re-indexed.

## Measured Replay

Actual production Dart ranking code replayed saved Android cosine scores and SQLite metadata, changing only lexical-only candidate eligibility. This is a host replay, not a new Android inference benchmark. All 24 saved queries were replayed; surviving candidate order was unchanged in all 24.

| Query | Before results | After results | Relevance evidence |
|---|---:|---:|---|
| a dog | 1916 | 9 | 1 relevant, 1 partial, 7 irrelevant; relevant stays #5 |
| a car | 1916 | 24 | 6 relevant, 2 partial, 13 irrelevant, 3 unknown |
| a car on a road | 1916 | 2 | Unjudged |
| a dog on a beach | 1916 | 0 | Unjudged; absence in gallery is not established |
| a cat on a sofa | 1916 | 0 | Unjudged |
| a dog running on a beach at sunset | 1916 | 0 | Unjudged |
| people sitting together | 60 | 60 | Unjudged |

Twenty of the 24 old searches admitted the complete library. Only dog and car have saved user relevance judgments. Unknown results were not treated as irrelevant, and zero returned results do not establish that the gallery contains no relevant image.

The old 0.15 gate was chosen from a six-image sanity check, not a representative personal-library calibration set. It remains unchanged here to isolate the candidate bug. Increasing it cannot separate the known dog from higher-scoring false positives: the relevant dog's cosine is approximately 0.162492, below the irrelevant document's 0.168747 and the first irrelevant photo's 0.207322.

## Wording Experiment

[VERIFIED] Same frozen 1,916 image vectors, same FP32 CPU text artifact; only encoded text changed. No production query transformation was adopted.

| Encoded text | Known dog rank | Known car ranks in fixed ID order |
|---|---:|---|
| a dog / a car | 5 | 2, 5, 11, 14, 19, 21 |
| a photo of a dog / a photo of a car | 5 | 1, 2, 3, 5, 16, 13 |
| a picture of a dog / a picture of a car | 12 | 1, 2, 5, 6, 16, 19 |
| a photo of a dog. / a photo of a car. | 8 | 1, 2, 6, 12, 33, 28 |

Car gains do not justify assuming the same wording improves all queries. New images surfaced by an experiment remain unjudged. This does not establish general accuracy.

## Comparison With Existing Apps

- **Ente Photos:** MobileCLIP v1, on-device encoders, local stored vectors, cosine comparison, and a similarity threshold for displayed results. ONNX Runtime is already consistent with PixelSearch's approach. Ente also emphasizes matching preprocessing across platforms and managing battery/thermal load. Its cloud synchronization architecture is not a reason to add uploads to PixelSearch. [Ente engineering description](https://ente.com/ml/)
- **Immich:** CLIP semantic search plus explicit metadata/album/person filters. Its documented search uses server-side vector infrastructure, so its deployment and performance assumptions cannot be copied directly into a phone-only app. [Immich search documentation](https://docs.immich.app/features/searching/)
- **ML Kit:** Labels include confidence values and support a confidence threshold. They are classification outputs, not a guarantee of sentence-level visual relevance. PixelSearch must not manufacture labels merely to avoid an empty list. [Google's Android labeling guide](https://developers.google.com/ml-kit/vision/image-labeling/android)

Inference for PixelSearch: retain the existing on-device architecture, enforce result eligibility, keep uncertain labels optional, and calibrate abstention with real positive and negative examples. Another app's cutoff is not transferable evidence for this model/library.

## Spatial-View Probe

[VERIFIED] Five already-judged photos, unchanged FP32 encoder, and the exact production Dart decoder/preprocessor. Compared the current center view with four predeclared image quadrants. This is a five-photo host experiment, not a new gallery ranking.

| User judgment / photo role | Current-view cosine | Maximum over current view and four tiles |
|---|---:|---:|
| Relevant dog scene | 0.162492 | 0.183916 |
| Irrelevant raw #1 | 0.207322 | 0.207322 |
| Irrelevant raw #2 | 0.169425 | 0.169425 |
| Irrelevant notebook | 0.168746 | 0.168746 |
| Partially relevant raw #4 | 0.168085 | 0.174178 |

All five current-view embeddings matched their stored Android vectors with cosine at least 0.9999999999966. This strengthens the evidence against a storage or inference mismatch for these checked rows. It does not prove every production path or export is correct.

An initial PIL-decoded probe was not numerically interchangeable with Android: current-view vector cosine versus stored vectors ranged from approximately 0.989805 to 0.999859. Therefore the table above was rerun using production Dart tensors. These differences alone do not establish a faulty decoder, and PIL results were not silently substituted for production outputs.

The tiled probe used 25 encoder calls versus five for current views. No Android latency for tiles was measured. The known dog improves within this tiny group but still loses to an irrelevant image. Do not adopt this as a gallery-wide retrieval improvement or rebuild the index on this evidence.

## Verification and Artifacts

- [VERIFIED] `flutter analyze --no-pub`: no issues.
- [VERIFIED] `flutter test --no-pub --reporter expanded`: 107 tests passed, including existing folder/indexing regressions and new persistence, correction, and candidate tests.
- [VERIFIED] Separate private replay test: all 24 traces passed candidate eligibility and retained-order assertions.
- [VERIFIED] `flutter build apk --debug --no-pub`: APK built. Existing Java native-access and Kotlin-plugin migration warnings remain.
- [VERIFIED] User-approved `adb install -r`: succeeded after a checked private-data backup. No uninstall, data clear, or gallery re-index.
- [VERIFIED] Initial updated launch on Vivo I2214 opened search home with 1,916 photos. Normal `a dog` search displayed 9 results.
- [VERIFIED] After update, database, both model files, and saved judgments had identical SHA-256 hashes to the backup.
- [VERIFIED] One false `dog` label on the user's already-judged irrelevant first result was removed through the editor and stored as a local correction. Other labels were not endorsed or bulk rewritten.
- [VERIFIED] A subsequent force-stop/relaunch again opened search home with 1,916 photos; the saved label correction remained in private storage.
- [VERIFIED] Normal Android search for `a dog on a beach` displayed `No close matches`. This verifies empty-result handling, not actual absence of that scene in the gallery.
- [VERIFIED] Normal Android search for `a car on a road` displayed exactly two results. Their relevance to this compositional query remains unjudged; this verifies no result-count padding.
- Installed APK: 250,817,874 bytes; SHA-256 `<digest withheld>`.

Private artifacts (ignored by Git):

- `local_evaluation/pre_usability_update_20260908_234504/app_private_backup.tar` (454,938,112 bytes), plus integrity/count/hash manifest. Includes models, SQLite, judgments, preferences, and thumbnails. SQLite integrity: `ok`; 1,916 photos and embeddings.
- `local_evaluation/device_raw_semantic_snapshot_20260908_215144/usability_replay.json`
- `local_evaluation/device_raw_semantic_snapshot_20260908_215144/prompt_ablation.json`
- `local_evaluation/device_raw_semantic_snapshot_20260908_215144/spatial_crop_dart_probe.json`, with exact input tensors in `spatial_tensors/`.
- Reproducers: `local_evaluation/usability_replay_test.dart`, `local_evaluation/prompt_ablation.py`.
- Spatial reproducer: `dart run local_evaluation/export_spatial_tensors.dart`, then `python local_evaluation/spatial_crop_probe.py --decoder dart`.

## Remaining Work

[BUG] The model can rank unrelated images above relevant ones; candidate gating does not repair that ordering. No blanket precision claim is warranted. [HYPOTHESIS] Small subjects/whole-scene embeddings contribute in the known dog scene; previous inspection showed the dogs remain inside the crop but occupy little of the model input.

Highest-value next step: extend the existing relevance set with a small held-out set of complete-scene queries and explicitly absent queries. The current wording and crop probes do not support another production change. Evaluate any proposed semantic confirmation/abstention signal against both true matches and high-scoring false positives, before selecting an operating point. No single cosine cutoff can fix the demonstrated dog ordering while retaining that dog.

Before shipping any new cutoff or re-ranking policy, validate on held-out judged queries, including searches explicitly confirmed absent from the indexed folders. The current ratings are not exhaustive enough to certify absence. No need to review all 1,916 images.

Indexing performance work remains separate: profile decode/inference/enrichment and gallery-wide reconciliation only after retrieval quality is better understood. No quantization, extra model, gallery scan rewrite, or concurrency change was made in this pass.
