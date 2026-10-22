# People Validation Investigation - 2026-09-18

> **Redaction note (2026-10-22):** personal identifiers (names, the device serial, local paths, private photo filenames, backup names and APK/backup digests) were replaced with placeholders. Measurements are unchanged.

## Root Cause [VERIFIED]

The connected Vivo I2214 showed `60 of 60 reviewed` and the generic message
`Validation did not pass. Automatic assignment remains off.`
The ratings were complete and persisted. The conservative gate correctly refused
to enable automatic assignment, because the learned cutoff would join one pair
the user had marked Different people. This is not a model-loading exception.

Measured from the consistent private device backup:

| Measurement | Result |
| --- | --- |
| Indexed photos / semantic embeddings | 1,916 / 1,916 |
| People photos processed | 485 |
| Detected faces / ready descriptors | 2,342 / 336 |
| Small-face observations without descriptors | 2,006 |
| Calibration ratings | 31 Same, 9 Different |
| Validation ratings | 16 Same, 4 Different |
| Calibration-selected cosine cutoff | 0.4307765197209109 |
| Calibration same-person pairs accepted | 30 / 31 |
| Validation same-person pairs accepted | 15 / 16 |
| Validation incorrect joins | 1 / 4 Different pairs |
| Conflicting pair | 55, rated Different, cosine 0.5594195292466785 |
| Invalid stored descriptors | 0 |
| Maximum saved/recomputed pair cosine difference | 3.3306690738754696e-16 |
| Overlapping calibration/validation photo IDs | 0 |

Pair 57 is a missed Same-person pair, at cosine 0.40770883499056637.
That miss is reported separately; it is pair 55's proposed incorrect join that
closes this gate. These numbers describe this reviewed sample, not general
recognition accuracy. The assistant did not judge identities or modify ratings.

The existing on-device **Check face model** returned **Face model check passed**
on the Vivo. This verifies numerical reference behavior, not recognition quality.

## Fix

- Keep the zero-observed-false-join gate and existing threshold-selection rule.
- Retain the attempted cutoff separately from the deployable threshold. A failed
  candidate must never enable grouping.
- Report failed pair IDs, missed same-person pairs, counts, and a specific reason.
- Recompute review diagnostics for old saved reviews without rewriting judgments.
- Add Review results and a direct jump to the conflicting pair.
- Add **Check 20 new pairs**. After confirmation, archive the old round, carry
  its exact ratings into calibration, and freeze a new 20-pair test from photos
  not used in any retained review. Prior validation is now explicitly training
  evidence, never reused as an independent approval test.
- Keep grouping off until the new holdout has both judgment classes, nonzero
  same-person recall, and zero observed incorrect joins. Unsure is excluded.
- Refuse a new round when insufficient unseen detailed faces exist or accumulated
  ratings cannot calibrate any safe cutoff. Manual naming remains available.
- A full New review also excludes archived review photos, instead of presenting
  the same deterministic sample again.

No SFace or MobileCLIP artifacts, model contracts, semantic scores, database
schema, folder selection, or indexing behavior were changed.

## Files

- `lib/domain/people/face_grouping.dart`: diagnostic results and reusable sampling.
- `lib/data/people_repository.dart`: data-preserving fresh validation rounds.
- `lib/state/people_providers.dart`: current-review diagnostic provider.
- `lib/features/people/people_review_screen.dart`: results, pair navigation, recovery.
- `test/people_domain_test.dart`: device boundary regression and gate behavior.
- `test/people_validation_recovery_test.dart`: archive, carryover, independence,
  insufficient-data and inseparable-data tests.
- `test/people_widgets_test.dart`: old-review diagnostics, pair jump, cancellation.
- `tool/audit_people_review.py`: read-only local backup audit; no face images or
  asset IDs are included in its output.

## Verification

- [VERIFIED] Analyzer: no issues.
- [VERIFIED] 353 Flutter tests passed, including real SFace reference tests.
- [VERIFIED] Debug APK built; expected existing Java/Kotlin compatibility warnings
  remain unrelated to this change.
- [VERIFIED] Original evidence backup taken (private, git-ignored).
- [VERIFIED] Private anonymized numeric report kept locally (not published).
- [VERIFIED] Data-preserving update installed on Vivo I2214 using `adb install -r`;
  no uninstall or data clearing. Both APK signer SHA-256 values matched (value withheld).
- [VERIFIED] Delivered APK SHA-256 checked (value withheld).
- [VERIFIED] Immediate pre-upgrade backup taken (private, git-ignored; integrity OK, schema 6).
- [VERIFIED] Direct phone UI showed the actual 30/31 calibration, 15/16 validation,
  1/4 incorrect-join counts, cutoff 0.4308, and working Inspect pair 55 navigation.
- A private screenshot was kept locally (not published).

## Remaining Human Check

The user subsequently confirmed personally correcting a rating while device
checks were in progress. The table above preserves the original failure evidence,
not the final corrected round. The assistant stopped inputs when the review state
changed, asked who had corrected it, and did not invent or override judgments.
Any remaining conflict must be inspected using the user's knowledge; labels must
not be changed merely to pass validation. A fresh 20-pair check is available when
the corrected ratings still fail. Repeated rounds are development validation,
not a general benchmark. People processing was paused; preserve that choice.

## Final Corrected Snapshot [VERIFIED]

The user's corrections changed the remaining conflict to **pair 56**, rated
Different people with cosine **0.4391661156692819**, above the unchanged
calibration-selected cutoff **0.4307765197209109**. The corrected validation
subset contains **15 Same / 5 Different** ratings: 15 Same pairs matched, and
1 Different pair would incorrectly join. Automatic assignment correctly remains
off. Pair 55 is no longer the conflict. No fresh review was started by the assistant.

Final backup: private, git-ignored (digest withheld).
Final numeric report: private (not published).
Both SQLite integrity checks passed. Before/after row-count and content-hash
comparisons show only `people_reviews` and `people_state` changed, reflecting
the user's ratings and their recalculated diagnostic result. All other tables
are unchanged, including all 1,916 semantic embedding rows, photos, indexing
checkpoint/folders, memories, locations, captions, face descriptors and scans.
The model files, search-evaluation files and user preferences are byte-identical.
