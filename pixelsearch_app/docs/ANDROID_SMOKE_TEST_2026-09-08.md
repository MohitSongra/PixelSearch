# Android Model Provisioning and Smoke Test

Date: 2026-09-08, times in Asia/Calcutta. Device: Vivo I2214, API 36, arm64.
App: com.pixelsearch.pixelsearch, version 0.1.0 (1), debug APK built at 15:36:01
and installed at 15:36:13. These results come from the installed app, ADB logs,
an in-memory read of its SQLite database, and Android Studio device mirroring.

## Model Provisioning

Copied the existing FP32 reference artifacts from the repository's model_kit/out
to /data/user/0/com.pixelsearch.pixelsearch/files/models. Device and host SHA-256
values matched for both files:

| File | Bytes | SHA-256 |
|---|---:|---|
| mobileclip_image.onnx | 86,553,519 | 8c5b72db77d62bd5270e2a2d653b81429121aeffd862ab9d86b6ec01b7cf8e42 |
| mobileclip_text.onnx | 254,084,070 | 593f6eb87e7e244b0adb820ab36b407a69fd8c737a11717a27cba3ea981e1cb8 |

Important correction to earlier instructions: OnnxEncoder.load() sets thread
counts but does not register NNAPI or XNNPACK. This installed build therefore
uses CPU execution. FP32 is the verified configuration in this test. Merely
putting repaired FP16 v3 files on the phone would not enable acceleration.
FP16 graph validation, provider support, inference, and numerical parity are
separate acceptance requirements. No preprocessing or embedding version changed.

## Measured Results

| Check | Observed result | Scope |
|---|---|---|
| Photo permission | READ_MEDIA_IMAGES granted | Read only; no permission changed |
| System MediaStore image rows | 19,260 | External image collection, _id projection |
| App gallery discovery | 19,260 | Exactly matches MediaStore count |
| Initial reconciliation | 19,260 to index; 0 deleted; 0 up to date | Empty initial index |
| Image model session load | 939 ms | FP32, 4 intra-op threads |
| First image inference | 251 ms; 512 dimensions; norm 1.000000 | Inference log, excludes preprocessing |
| First saved batch | 32 photos and 32 embeddings | Direct SQLite read; integrity_check = ok |
| First-batch vector validity | All 512 dimensions / 2,048 bytes, embedding_version 1 | Norm range 0.9999999731 to 1.0000000295 |
| First-batch enrichment | 32 labelled photos; 16 with faces | Direct SQLite read |
| Cancelled run | 103 embedded; 0 failed; 0 deleted | 209,514 ms including enumeration and finalization |
| First-run library readback | 103 photos, 103 with labels, 103 with thumbnails | Production controller's database readback log |
| Text model session load | 1,822 ms | FP32, 4 intra-op threads |
| First text inference | 82 ms; 512 dimensions; norm 1.000000 | Inference log, not end-to-end query latency |
| Sentence query | Results displayed with Semantic badge | Query: a group of people sitting together indoors |
| Cold restart | App launched successfully; saved models and index survived | ADB force-stop and fresh activity launch, not a phone reboot |
| Resume reconciliation | 19,260 discovered; 19,157 to index; 103 already up to date; 0 deleted | Existing photos skipped after restart |
| Second cancelled run | 37 newly embedded; 0 failed; 0 deleted | 54,431 ms including enumeration and finalization |
| Final saved library | 140 photos, 140 embeddings, 140 labelled, 140 with thumbnails, 50 with faces | Direct SQLite read; integrity_check = ok |
| Final vector validity | All 140 vectors finite, 512 dimensions / 2,048 bytes | Norm range 0.9999999705 to 1.0000000299 |
| Restarted image session | Load 1,024 ms; first inference 366 ms | 512 dimensions; norm 1.000000 |
| Restarted text session | Load 1,634 ms; first inference 76 ms | 512 dimensions; norm 1.000000 |
| Search after resume | 118 results with Semantic badge for the same sentence | Persisted 140-photo library; relevance not scored |
| Viewer label display | sitting, jacket, crowd, interaction, event, jeans, selfie, cool, fun | Opened a result in the actual Android photo viewer |

Actual first-batch labels included Jacket, Hat, Paper, Crowd, Tableware, Sitting,
Room, Smile, and Event. This verifies native ML Kit output reaches persistent
storage. It does not require particular fixed labels for every image.

After USB reconnection, the app was still alive. A deliberate cold restart then
verified incremental resume: it skipped the 103 saved photos and added 37 more
before a second intentional cancellation. The final library contains 140 photos;
19,120 remain unindexed if the gallery does not change. Search was checked again
against that saved library and a result opened successfully with its labels.

Cancellation was intentional after a sample exceeded the former 80-photo cap.
The saved library was refreshed and became searchable without restarting the app.
The top visible query results contained people. Exact scene relevance, precision,
recall, and sentence-composition accuracy were not scored against a labelled set.

## Observed Performance

The production profile accumulates averages across completed assets; image sizes
vary. This is a debug build with Android Studio mirroring active.

| Stage | First 40 assets (ms/photo) | First 100 assets (ms/photo) |
|---|---:|---:|
| Load bytes | 82 | 72 |
| EXIF | 2 | 1 |
| Decode | 948 | 635 |
| Thumbnail | 31 | 29 |
| Preprocess + image inference | 619 | 553 |
| ML Kit labels + faces | 683 | 523 |
| Total reported per asset | 2,366 | 1,813 |

The different averages reflect different images and cannot establish a speedup.
Two indexing-time dumpsys samples reported total PSS of 1,081,280 KB and
1,071,962 KB. These are spot readings, not a peak-memory measurement or proof
that memory remains stable across the full library. Decode, inference, and ML Kit
remain substantial costs. No change to responsiveness is claimed from this test.

## Remaining Checks

- Full completion and 100% progress across all 19,260 photos were not tested.
- Cancellation, cold app restart, and skipping unchanged saved photos passed.
- Phone reboot, newly added/deleted photos, screen-off work, and sustained
  responsiveness still need the device checklist.
- Android FP16 load/inference/parity and acceleration are unverified.
- Historical Python/Flutter parity results were not rerun or replaced by this
  smoke test; normalized outputs alone do not establish numerical parity.
- USB briefly disconnected after the first semantic query. The phone reconnected
  and testing continued successfully. Android Studio's old Flutter terminal lost
  its debug attachment; that stale message does not indicate the current app
  crashed. The new process was started through ADB.
- Onboarding appeared again after cold restart despite the saved index. This is
  an observed UX issue; its source cause was not investigated in this test.
- Temporary model transfer copies were removed from /data/local/tmp after
  reconnecting. The verified files remain in the private models directory.

Application code and ranking policy were unchanged during this provisioning test.
