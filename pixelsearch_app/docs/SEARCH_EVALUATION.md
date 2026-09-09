# Search Evaluation

Date: 2026-09-08. No relevance labels are bundled or inferred.

## Device Workflow

1. Index your chosen folders. Wait for completion or cancel normally and wait for the committed batch.
2. Open Settings > Search diagnostics. Enter a complete scene query, or choose one from the list icon.
3. Tap the search icon to compare Raw cosine, Final, and Experiment. These use the same query embedding.
4. Inspect the thumbnails or open the existing viewer. Each result includes its filename, asset ID, cosine,
   original raw rank, and (where applicable) hybrid score. The information icon opens the component breakdown.
5. Set Relevant, Partially relevant, or Irrelevant only from your own visual judgment. Leave uncertain images
   Unjudged. Ratings are shared across the three tabs and saved privately on the device.
6. Use the evaluation-files menu to copy queries/judgments, import a JSON dataset from the clipboard, or copy
   the current report. Re-run after changing judgments. The playlist/play icon runs the whole dataset.

The Top 20/50/100/200 dropdown changes the number of displayed results, NOT the production candidate count.
Candidate-pool and gate replays are in the exported JSON. The Experiment tab tests whole-word lexical matching;
it is NOT enabled in ordinary search. No model, indexing preference, database schema or embedding version changes.

## Exact Input Format

The starter file is `assets/evaluation/scene_queries.json`: 24 unlabelled queries, four each for objects,
object/context, actions, composition, relationships, and natural descriptions. Replace or extend the query text
with scenes you actually have. A minimal valid dataset is:

```json
{
  "schema_version": 1,
  "dataset_id": "my-scene-evaluation-v1",
  "queries": [
    {
      "id": "scene-001",
      "query": "a dog running on a beach at sunset",
      "category": "composition",
      "exhaustive": false,
      "relevant": [],
      "partially_relevant": [],
      "irrelevant": []
    }
  ]
}
```

Put actual expected filenames or asset IDs inside `relevant`; put weaker matches in `partially_relevant` and
explicitly rejected results in `irrelevant`. Each array contains strings. IDs are preferred. A filename must
match exactly one indexed photo, including case and extension. Duplicate filenames require IDs. Missing,
ambiguous, or conflicting judgments fail validation rather than disappearing from the denominator.
An expected image outside the saved library must first be indexed through the existing folder picker.
Do not set `exhaustive: true` unless every other photo in that fixed corpus has been judged irrelevant.

The UI saves ratings by asset ID, so renaming an indexed file does not silently change its judgment.
IDs may change after moving/re-importing media; revalidate the dataset after gallery changes.

## Report and Metrics

Each query exports raw cosine ranking, unchanged production ranking, whole-word experiment, semantic pools
20/50/100/200, and gates disabled/0/0.1/0.2/0.25/0.3 alongside the production gate 0.15. These are experiments,
not recommended replacement thresholds. Each replay includes up to 200 ranked rows; expected ranks and metric
calculations use the complete result list. Thus a judged positive below exported rank 200 is still accounted for.

Important fields: `cosine` is the actual measured dot product; `cosine_used` is null if the candidate lost its
semantic contribution at the pool/gate stage. `weighted` contains the actual weighted contributions. The field
`lexical_term_scores` records the lexical matcher actually used by each ranking,
including whether ML Kit labels participated in that run.

The report records corpus/vector hashes, model/embedding version, query tokens and normalized query vectors,
missing embeddings, candidate counts, saturation counts and timing scope. The automated device test additionally
hashes the installed models and compares the complete persisted tables before/after using a read-only connection.
The database has no per-vector artifact hash; matching version strings alone cannot establish artifact provenance.

- Grade 2 = relevant, grade 1 = partial, grade 0 = irrelevant. Absence is unjudged, never implicitly zero.
- Precision@K uses fully relevant hits divided by K. It is null if any returned Top-K photo is unjudged unless
  the user explicitly supplies exhaustive judgments. Fewer than K returned photos do not shrink the denominator.
- Known-positive recall@K divides relevant hits by the number of supplied grade-2 positives. It is NOT full-corpus
  recall when judgments are incomplete. No positive labels means null.
- Judged-pool nDCG@K uses gains `2^grade - 1` and `log2(rank + 1)` discount. Its ideal order uses supplied judgments
  only, and it is withheld for unjudged returned results. It is not a claim of fully judged corpus quality.
- Candidate recall and expected-image ranks show whether known positives were lost before reranking.
- Top-1 disagreement and Top-5 overlap describe ranking changes, not improvements.

Rank-based evaluation and the need for explicit relevance assessment follow the
[ranked retrieval evaluation chapter](https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-ranked-retrieval-results-1.html)
and [relevance assessment discussion](https://nlp.stanford.edu/IR-book/html/htmledition/assessing-relevance-1.html).
The null-on-unjudged behavior and graded-pool protocol above are explicit choices of this harness.

## Repeatable Comparison

Freeze the corpus and judgments between compared runs. Keep the snapshot and dataset hashes with the report.
Judge the union of Top-20 raw, Final and Experiment results, plus any known expected images. Mix the order or
hide method names during judging where practical. Include scenes with no matching photo to assess false matches.
Start with about 20-50 queries, not a large invented benchmark. Keep calibration and holdout queries separate.

First inspect raw versus Final with all production parameters unchanged. Then test the whole-word experiment
alone. Only retain a default change if judged metrics and specific scene cases support it, including holdout
queries. Add the resulting relevant-in-Top-K regression cases. Do not tune weights, the gate and lexical matching
simultaneously. If raw rankings are poor, check production/reference tokens, tensors, embeddings and artifact
pairing before considering a model change. The center crop can omit scene context; changing it requires parity
and contract consideration, not an unversioned indexing modification.

Pool timings are candidate/scorer replay times after a shared full vector scan. They exclude embedding and trace
serialization and are not independent end-to-end benchmarks. The current brute-force implementation scans and
sorts every vector regardless of K. Measure warm repeated queries separately before changing performance policy.

## Files and Safety

Private device files are under `<app support>/search_evaluation/`:
`queries.json` and `latest_report.json`. The latter is replaced on each run. Copy a baseline report before
re-running with new judgments. These files can reveal filenames, labels and queries; they are not uploaded.
Clipboard export is explicit and may be visible to the operating system or the user's clipboard-sync service.
Host `local_evaluation/` is Git-ignored for private reports and backups.

**Do not run bare `flutter test integration_test/... -d ...` on this library. This installed Flutter version
defaults to uninstalling the application afterwards, deleting its private data.** See the incident in
`SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md`. Prefer the in-app evaluation button. For automated device checks,
finish/cancel indexing and force-stop the app yourself first, then run the backup-first wrapper from the app root:

```powershell
pwsh -File tool/run_search_evaluation.ps1 -Device '<device-id>'
```

The wrapper refuses a running app, archives all private app data and validates the archive before testing,
passes `--no-uninstall`, exports a successful report and rebuilds/reinstalls the normal app with `adb install -r`.
It never clears or uninstalls the app and never restores a backup over newer data automatically. `-BackupOnly`
creates just the archive. Wrapper syntax has been checked; its full device workflow remains unverified.

Host verification (does not target a phone):

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
