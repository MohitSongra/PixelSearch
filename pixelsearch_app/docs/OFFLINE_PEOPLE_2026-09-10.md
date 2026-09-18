# Offline People: Implementation and Acceptance

Date: 2026-09-10. Repository: `C:/Users/mohit/Desktop/PixelSearch_handoff/PixelSearch`.

## Current Status

Later device follow-up: the New Faces build was installed on the Vivo I2214 with a data-preserving upgrade. Schema 6, unchanged existing data, Android numerical parity, real face previews and active processing were verified. No real identities were assigned and recognition accuracy remains unmeasured. See `NEW_FACES_DEVICE_2026-09-10.md`; the locked/disconnected-device notes below record the earlier checkpoint.

[VERIFIED] Local implementation, additive migration tests, reference alignment,
real desktop SFace inference, name filtering, corrections, privacy guards and
Flutter screen tests. Analyzer is clean. The full Flutter suite passes 316 tests
with the real-model test enabled; the existing backend suite passes 27 tests.

[IMPLEMENTED BUT UNVERIFIED] Physical Android processing, Android numerical
parity, real face crops, airplane-mode acceptance, memory/latency measurements,
and user-reviewed grouping quality. The debug APK builds successfully.

[PARTIAL] Automatic assignment is intentionally disabled until a local frozen
review passes its validation gate. No real face-pair judgments were invented or
entered. There is no recognition-accuracy measurement yet.

The Vivo I2214 was connected but locked at the device-verification checkpoint,
then disconnected from ADB before final delivery. The old app was running behind
the lock screen at the last successful observation. No People APK was installed,
no data was cleared, and no face processing was started on the device in this task.
Reconnecting and unlocking the phone is the next prerequisite; verify that indexing is idle before
taking a fresh backup or upgrading.

## Delivered Behavior

Build artifact: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `cd240505245f5e8c8a92f107e8c62808db054083d8ebbfdbefcde915072f8312`.
The debug signing certificate matches the existing app's verified signer.

- Search retains its four navigation tabs and gains a compact People entry.
- People is opt-in. Processing uses only indexed photo IDs, not album enumeration
  or additional gallery imports. Retained photos from deselected folders remain eligible.
- Accurate bundled ML Kit re-detects landmarks. Android performs bounded EXIF-aware
  decode; alignment and SFace inference use a reusable worker isolate/CPU session.
- Per-photo revisions/checkpoints make progress resumable. Missing/tiny faces stay
  manually assignable; no descriptor means no automatic identity assignment.
- A shared expiring SQLite lease serializes People with foreground/background
  indexing. The foreground controller checks the indexed database for new/revised
  rows every 30 seconds while enabled and active; this does not scan the gallery.
- Names/nicknames, photo counts, latest/name/count sorting, covers, hiding,
  merging, face moves/splits and removal of assignments are available locally.
- Person details reuse the dated gallery and original-photo viewer. Photo details
  expose individual face crops for corrections.
- Name-only search is chronological and works without the CLIP encoder. Names
  plus scenes resolve eligible IDs before Top-K; only the remaining scene reaches
  MobileCLIP. Multiple people mean AND, duplicate names require a face choice.
- Whole assigned names, nicknames, explicit years, this year and last year resolve
  locally. Existing date/album/place filters remain available.
- Person-aware assistant requests are blocked before HTTP. Names, crops,
  descriptors and person filters are never sent by the People implementation.
- Pause is distinct from confirmed disable-and-delete. Deletion invalidates late
  commits, removes face crops/descriptors/names/corrections/reviews and preserves
  original photos and semantic embeddings. Android automatic cloud/device-transfer
  backup excludes app-private storage.

## Grouping Gate

Review preparation freezes up to 40 calibration and 20 validation pairs, with
photo-disjoint membership chosen before judgments. Fewer than 40 pairs does not
create a review. Same/Different/Unsure remain user decisions; Unsure is excluded.
Both classes and nonzero recall are required. Calibration chooses highest observed
same-person recall with zero false joins, preferring the stricter threshold on ties.
The fixed threshold must then pass held-out validation with zero false joins and
nonzero recall. It is never retuned on validation data.

Automatic assignment is complete-link: every comparable member must pass. Only
one qualifying group permits a join; ambiguous cases stay unassigned. Established
groups are not automatically merged. Same-photo conflicts include manually assigned
faces without vectors. User rejections survive future processing.

Changing/losing a reviewed photo closes the gate. Previously saved assignments
are not silently deleted when a review is archived or fails; further automatic
assignments stop, and manual corrections remain available. A passed sample is not
a general accuracy guarantee.

## Storage and Model

Detection and recognition are separate: [ML Kit explicitly does not recognize
individuals](https://developers.google.com/ml-kit/vision/face-detection).
The bundled [OpenCV SFace model and Apache license](https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface)
supply numerical descriptors, while PixelSearch owns the local validation and
corrections. The naming/merge/correction workflow takes functional inspiration from
[Google Photos face groups](https://support.google.com/photos/answer/6128838?hl=en),
not its undisclosed recognition model or any accuracy claim.

Schema 6 adds `people_persons`, `people_faces`, `people_scans`, `people_decisions`,
`people_reviews`, `people_state`, three indexes and `processing_leases`.
No existing table rows are rewritten for this feature. Face descriptors are
128-dimensional float32 blobs, separate from the existing 512-dimensional CLIP
embeddings. They are numerical biometric descriptors, not irreversible hashes.

Bundled SFace: 38,696,353 bytes, unmodified FP32, Apache 2.0.
SHA-256: `0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79`.
This is the approved offline-first exception to the model-bundling rule. CLIP's
models, embedding version `1`, weights, gates and unfiltered ranking are unchanged.
See `model_kit/FACE_CONTRACT.md` for channel order, landmarks and graph normalization.

## Measured Local Results

| Check | Measured result |
|---|---|
| Full Flutter suite, including real SFace worker | 316 passed |
| Existing backend tests | 27 passed |
| Analyzer | No issues |
| v5 to v6 migration fixture | All eight old tables unchanged, including embedding bytes |
| OpenCV crop MAE, identity / scale | 0 / 0 |
| OpenCV crop MAE, rotation / border | 0.003082482993197279 / 0.00233843537414966 |
| Maximum channel error, transformed fixtures | 8 on the 0..255 scale |
| Worker/reference cosine, identity / scale | 0.9999999686938639 / 1.0 |
| Worker/reference cosine, rotation / border | 0.9999963760713015 / 0.9999978648745064 |
| Physical Android recognition quality | Not measured |

The numerical fixtures contain no people and test engine/preprocessing parity,
not recognition accuracy. The Windows plugin's UTF-8/UTF-16 filename mismatch is
handled by using the byte-loading API for desktop parity; Android remains file-backed.

## Files

- `model_kit/FACE_CONTRACT.md`, `model_kit/tool/sface_reference.py`: contract and reference generator.
- `lib/domain/people/`: alignment, descriptor contract, grouping/calibration, local name parsing.
- `lib/data/people/`, `lib/data/people_repository.dart`: native worker, processing, diagnostics and persistence.
- `lib/data/local/people_tables.dart`, `app_database.dart`, generated Drift code, `processing_lease.dart`: schema and ownership.
- `lib/state/people_providers.dart`, `lib/state/providers.dart`: existing Riverpod wiring and search filtering.
- `lib/features/people/`: People, person details, corrections and pair review screens.
- Search screen, conversation sheet, photo viewer and search explanation: local People entry/filter/evidence integration.
- Search request and both existing search backends: resolved eligible-ID constraint, unchanged unfiltered behavior.
- Android `PeopleImageDecoder.kt`, `MainActivity.kt`, manifest and backup XML: bounded decoding and private-storage exclusions.
- `assets/models/`: pinned SFace, Apache license and nonpersonal parity fixtures.
- `test/people_*`, `test/sface_reference_test.dart`, fixtures and focused existing-test extensions: regression coverage.

Unrelated work already present in this worktree was not reverted. No commit or push was performed.

## Data-Preserving Device Acceptance

1. Unlock the Vivo, open PixelSearch and confirm normal indexing is idle. Do not uninstall or clear data.
2. Close only PixelSearch after checking it is idle, then run the existing backup tool with `-BackupOnly`.
3. Audit the archive using `tool/audit_private_backup.py`. Preserve photo/embedding/folder/checkpoint/memory/caption/location tables, CLIP models, preferences and search judgments.
4. Verify the APK signer matches `5d6a02254b32e1c91b1ad84273009f7731fc10141022e0ccef0304546dfdb26e`, then use only a data-preserving `adb install -r` upgrade.
5. Launch and verify schema 6, original indexed count and all baseline data hashes before enabling People.
6. In airplane mode, open People, enable local processing and run options > Check face model. Save the `pixelsearch.PeopleModelCheck` log, which contains numerical fixture results only.
7. Observe actual face crops at the beginning and later in the scan. Pause, leave/reopen the app and continue; completed photos must not be inferred again. Capture memory and elapsed-time measurements.
8. Once enough detailed faces exist, prepare the local review. The user completes Same person / Different people / Unsure without guessing. No threshold is enabled unless the gate passes.
9. Test naming, duplicate-name choices, name-only, name+scene, names+years, two-person AND, merging, covers, face moves, hidden groups and correction persistence using user-confirmed identities.
10. Take another consistent backup and compare every old table hash plus CLIP model/preferences/judgment hashes to the fresh pre-upgrade audit. Export review rows privately for the acceptance report.

Do not run the standard destructive Android integration-test installer against
this library. Desktop tests use isolated databases only.

An earlier consistent baseline is retained at
`local_evaluation/app-data-20260910-121513-758.tar`, SHA-256
`b1eb185d4032599208df49adb88e703240793d9eed7bbf6449c91f4c72997148`.
Its audit is `local_evaluation/before_people_20260910.json`: schema 5, 1,916 indexed
photos/embeddings, 215 memories, 1,916 location rows. It is not a substitute for a
fresh snapshot now that the user has reopened the app.

## Remaining Limitations

- Android compatibility, EXIF behavior on real camera files, processing throughput,
  memory use and airplane-mode UI acceptance are pending the unlocked phone.
- No real identity-pair judgments or false-join/recall results exist yet.
- Tiny, occluded, profile or landmark-poor faces may need manual grouping; separate
  groups are preferred to unsupported identity claims.
- Changed indexed revisions require new observations. Edits not yet reflected in
  the existing photo index are only detected when normal indexing updates metadata.
- Pause is cooperative: an in-flight native photo operation finishes before the
  worker stops. No subsequent photo should start, and late deletion commits fail closed.
- Complete-link review/grouping is quadratic in the number of comparable faces;
  large-library runtime needs physical measurement before further optimization.
- Descriptors are in app-private storage, not encrypted against a compromised/rooted device.
  User-authorized laptop backups are also sensitive and remain git-ignored.
- Existing Gradle native-access/Kotlin-plugin and backend deprecation warnings remain.
- Human still-photo faces only. No pets, identity lookup, relationship/emotion/age
  inference or Google Photos-level accuracy claim. Semantic relevance remains a separate task.
