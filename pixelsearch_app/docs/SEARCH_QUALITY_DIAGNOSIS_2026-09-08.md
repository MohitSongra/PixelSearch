# Semantic Search Diagnosis

Date: 2026-09-08, Asia/Calcutta. Scope: production retrieval, not indexing performance.

## Conclusion

[PARTIAL] We cannot yet decide whether raw MobileCLIP or hybrid reranking is the primary cause of poor scene
relevance. The user explicitly has no verified query-to-filename judgments. No accuracy, quality improvement,
or before/after relevance score is claimed. Production weights, model, gate and candidate count remain unchanged.
Whole-word lexical matching is a diagnostic experiment, not a promoted fix.

[VERIFIED] Source inspection and regression tests identify mechanisms that can change semantic order:
substring matches from ordinary sentence words; discarded cosine contributions after top-K/gating; a fixed
semantic ceiling that collapses stronger cosine scores to ties; and corpus-relative lexical scaling.
Their product-quality impact still requires the user's judgments. MobileCLIP has not been replaced.

## Production Execution Trace

Paths are relative to `pixelsearch_app/`; these describe inspected source, not just handbook claims.

| Stage | Actual implementation |
|---|---|
| Query/UI | `lib/features/search/search_screen.dart` writes `searchQueryProvider`; `lib/state/providers.dart` debounces nonempty input about 300 ms, invokes the backend and displays its order in `PhotoGrid` |
| Corpus | `PhotoRepository.loadPhotos()` reads all persisted photos, including previously indexed deselected folders. `indexWarmupProvider` loads current model/version vectors into `BruteForceVectorIndex` |
| Model selection | `lib/state/semantic_wiring_io.dart` resolves the text artifact through `ModelLocator`, loads bundled CLIP BPE and constructs a lazy `OnnxTextEmbedder` |
| Text preprocessing | The original complete sentence reaches `embed()`. `ClipTokenizer` applies HTML unescaping, whitespace cleanup, lowercase and CLIP BPE. No noun extraction, prompt template or query expansion |
| Token tensor | Int64 `[1,77]`, SOT 49406, EOT 49407, padding 0, truncation retaining EOT. Diagnostics export token IDs and truncation status |
| Text embedding | `OnnxEncoder.runEmbedding()` extracts 512 floats and applies defensive L2 normalization. CPU session; half-core thread count clamped to 1-4 |
| Image embedding | Existing `AssetProcessor` decodes the image; `preprocessForClip` shortest-side resize to 256, antialiased bilinear, center crop, CHW RGB `/255`, no ImageNet mean/std. Existing image model outputs 512 dimensions |
| Persistence | Little-endian float32 BLOBs filtered by model ID and embedding version. No schema, model or embedding-contract changes in this iteration |
| Similarity | `lib/data/search/brute_force_vector_index.dart` computes dot products assuming unit vectors, sorts every match, then returns top K. No approximate index or early noun filter |
| Candidates | `SemanticSearchBackend.search()` requests 60 neighbors. Shared `rankSearchCandidates()` applies raw cosine >=0.15, then unions the IDs with EVERY positive lexical hit in the saved corpus |
| Lexical | `lib/data/search_engine.dart`: each whitespace term scores exact tag 3, partial tag 2, exact ML Kit label 2, otherwise search-blob substring 1. Repeated terms accumulate; punctuation and stopwords remain |
| Metadata | `Photo.searchBlob` includes title/caption/tags/labels/place/album, not filename or date. ML Kit confidence is discarded at ranking; label strings contribute lexical scores |
| Faces | `HybridScorer` uses an explicit people-intent token set and saturating face count. It does not enforce "two people", spatial relationships or negation |
| Final/UI | Weighted score descending, then date descending and ID ascending. Scores <=0 dropped. No final result cap or additional date/label/relationship filter on this path |
| Failure | Normal search latches into keyword fallback after a model failure; an empty index produces lexical results. Diagnostics reject these states instead of reporting them as semantic evaluation |

The shared function avoids a second diagnostic implementation drifting from production. A regression test
compares it against the prior literal candidate/scoring algorithm. Experiment parameters never enter ordinary
search. Diagnostics explicitly await index warmup; normal provider lifecycle remains unchanged.

## Fusion and Threshold Audit

`c_used` is a cosine ONLY when it survives semantic top-K and the gate. A lexical-only candidate may have an
embedding and an actual measured cosine, but production gives it `c_used = null`.

```text
S = c_used is null ? 0 : clamp(c_used / 0.35, 0, 1)
L = max_lexical_raw == 0 ? 0 : lexical_raw / max_lexical_raw
F = wants_faces ? min(face_count, 3) / 3 : 0
score = 0.70*S + 0.25*L + 0.05*F
```

The lexical maximum is taken within the union candidates: zero-anchored max scaling, NOT observed min-max
normalization. Components are bounded [0,1], but they are not calibrated relevance probabilities. Within the
unsaturated band, weighted semantic contribution is `2*c_used`: the full lexical boost can offset 0.125 cosine,
and the full face boost 0.025. Above cosine 0.35, the semantic contribution is flat at 0.70.

| Parameter/filter | Evidence and risk | Experiment |
|---|---|---|
| Top K 60 | No scene-labelled tuning found; lexical union can exceed 60 results | Replay 20/50/100/200, measure known-positive candidate recall and expected ranks |
| Raw cosine >=0.15 | Historical six-probe minimum correct 0.198 / maximum distractor 0.146. Not scene calibration | Current gate vs disabled/0/0.1/0.2/0.25/0.3; do not choose a replacement without judged holdouts |
| Semantic band [0,0.35] | No labelled scene calibration found; ceiling removes distinctions | Count saturation and inspect relevant-image displacement before changing the mapping |
| Any positive lexical hit | Word fragments can admit unrelated candidates | Whole-word replay with identical embeddings, K, gate and weights |
| Weights 0.70/0.25/0.05 | Policy constants, not fitted scene probabilities | Leave unchanged until raw-vs-final judgments establish the failure mode |
| Face saturation 3 | Intent enrichment, not exact counting or relation reasoning | Include count, negation, group and relationship queries |
| Final score >0 | No-signal filter | Inspect missing positives at earlier candidate and gate stages |

[BUG] Word-fragment support is confirmed by a regression test: `a`, `on`, `in` score against `Camera`, `person`,
`sitting` even though those query words are absent. The experimental matcher removes these accidental matches
and retains exact tags/labels. [HYPOTHESIS] This harms real scene relevance; no default change is justified yet.
Another focused test exposes the existing semantic saturation/tie-break behavior without changing it.

## Implemented Evaluation

[VERIFIED on host] Settings > Search diagnostics exposes Raw cosine, Final and Experiment, filename/ID/ranks,
actual versus used cosine, normalized and weighted scores, thumbnails/viewer and private relevance ratings.
The starter dataset has 24 unlabelled queries across six scene categories. IDs or unique filenames are accepted;
missing, ambiguous or conflicting labels fail validation. Quality metrics stay null without judgments.
Ratings and reports live in private JSON, not SQLite. Corpus/vector hashes expose dataset changes. Only the first
200 rows per replay are materialized/exported; expected ranks and metrics use the full ranking.

[IMPLEMENTED BUT UNVERIFIED on the restored device library] Complete report export, actual-production replay
equality and read-only-store assertions still need a successful phone run after re-indexing. The device test
also hashes model files and compares all persisted tables before/after. See `SEARCH_EVALUATION.md` for exact JSON,
metric semantics, safety and calibration protocol; `SEARCH_DEVICE_FEEDBACK.md` contains the device checklist.

## Actual Observations This Iteration

| Check | Actual result | Scope |
|---|---|---|
| Analyzer | No issues | Host, latest source |
| Android debug APK | Build passed | Latest APK is in `build/app/outputs/flutter-apk/app-debug.apk`; this final rebuild was not installed while the user selects/re-indexes folders |
| Automated tests | 93 passed, including 17 new retrieval/evaluation/UI tests | Host; fixture ranking checks are not photo-retrieval accuracy |
| Preprocessing fingerprint | sum=100051.464714; a=0.623529; b=0.207843; c=0.956863 | Existing golden test passed unchanged |
| Phone text load | 1,752 ms | One cold load in the first device attempt; not a latency distribution |
| Phone first text inference | 83 ms, 512-d, logged norm=1.000000 | Same attempt, FP32 CPU |
| Phone diagnostic queries executed | 24/24 before the harness's report-field assertion failed | No accepted report or relevance comparison saved |
| Restored image model SHA-256 | 8c5b72db77d62bd5270e2a2d653b81429121aeffd862ab9d86b6ec01b7cf8e42 | Matches the previously provisioned FP32 artifact |
| Restored text model SHA-256 | 593f6eb87e7e244b0adb820ab36b407a69fd8c737a11717a27cba3ea981e1cb8 | Matches the previously provisioned FP32 artifact |

There are no measured relevance scores, disagreement aggregates, or accepted candidate-pool timing comparisons
to publish from this attempt. Six-image historical results are not general accuracy. Prior indexing and paper
measurements remain historical, unchanged evidence. A 144-vector corpus could not establish full 200-candidate
performance even if that original evaluation had completed.

## Device-Test Incident

[BUG, tooling operation] I invoked `flutter test ... -d <device-id>` without `--no-uninstall` (device serial omitted).
The installed Flutter version sets `uninstall` to `defaultsTo: true` in
`C:/src/flutter/packages/flutter_tools/lib/src/commands/test.dart`; the integration runner uninstalls at cleanup.
The first device attempt ran 24 queries on the existing private library, then failed because the new test read
the exported key `rows` instead of `ranking`. Cleanup removed the app and private data. The next attempt exposed
the missing database. The field-name mistake is corrected, but the original read-only-store assertion was never
reached. This is not a passing Android integration test.

The previous 144-photo database, embeddings, thumbnails and saved folder preferences were lost. No local backup
was found. Original gallery files were untouched. I informed the user, restored the normal app and both identical
FP32 model files, verified their device hashes and removed temporary transfers. The old embeddings were NOT
recovered and must not be described as preserved. The user chose to select folders on the phone for re-indexing;
no new scope was imposed. Restoring the app/models does not mean its prior private index was restored.

`tool/run_search_evaluation.ps1` requires a stopped app, creates and validates a private archive before testing,
passes `--no-uninstall`, and rebuilds/reinstalls the normal APK without clearing data. It retains the backup after
failures. Syntax is checked; the full wrapper remains device-unverified. Prefer the in-app evaluation button next.
Never repeat a bare device-test command or overwrite newer app data with a backup without explicit approval.

## Files Changed in This Retrieval Iteration

- `lib/data/search/semantic_search_backend.dart`: shared unchanged production policy plus strict full-cosine diagnostics.
- `lib/data/search/search_ranking.dart`: candidate/scoring function and non-default whole-word experiment.
- `lib/domain/search/search_diagnostics.dart`: platform-neutral trace interface and JSON representation.
- `lib/domain/search/hybrid_scorer.dart`: explanatory comments/formatting only; no weights or arithmetic changed.
- `lib/evaluation/`: query validation, unknown-aware graded evaluation, snapshot hashes, runner and JSON storage.
- `lib/features/search/search_diagnostics_screen.dart` and Settings entry: comparison, breakdown and relevance ratings.
- `assets/evaluation/scene_queries.json`: 24 unlabelled cases.
- `test/search_diagnostics_test.dart`, `test/retrieval_evaluation_test.dart`, `test/search_diagnostics_screen_test.dart`: 17 tests.
- `integration_test/search_diagnostics_test.dart`, `tool/run_search_evaluation.ps1`: read-only real-model test and backup-first runner.
- `pubspec.yaml`, `pubspec.lock`: crypto now direct; path-provider platform interface now a direct test dependency;
  resolved versions unchanged. Evaluation assets registered.
- Root `.gitignore`: private `local_evaluation/` reports and backups excluded. Retrieval docs, CHANGELOG,
  PROJECT_STATUS and KNOWN_ISSUES record findings, boundaries and the incident.

Existing indexing, folder, database/migration, model-contract and ModelKit modifications predate this iteration.
They were not redesigned. The dirty Git diff against HEAD includes earlier work; do not attribute it all to this task.

## Next Work and Remaining Risks

1. User selects folders and rebuilds the index. Record that new corpus, not the lost 144-photo snapshot.
2. Capture/retain an in-app baseline report. Make a private backup before any future automated device run and
   verify normal/diagnostic ranking equality with the corrected test when the user is not indexing.
3. User judges the Top-20 union for about 20-50 queries, adding expected filenames/IDs outside that pool.
4. Compare raw versus Final, locate candidate losses, then evaluate the whole-word change alone.
5. Promote only a judged improvement, add relevant-in-Top-K regressions, and verify holdout scene queries.
6. Only then investigate indexing performance, including full-gallery existence reconciliation.

[MISSING] Scene ground truth, accepted Android evaluation, large-corpus candidate timings and before/after quality.
[HYPOTHESIS] Asynchronous normal index warmup and backend/session lifecycle may affect first-query behavior;
no lifecycle change was made. The Semantic badge reads a non-notifying fallback latch and needs a separate check.
[PARTIAL] Rows store model/version, not per-row artifact hashes. A center crop can omit context. Clean-English
tokenizer parity does not prove general Unicode/ftfy equivalence. No new image/model parity acceptance is claimed
from text-only diagnostic execution. Investigate these if raw rankings are poor, before replacing MobileCLIP.
