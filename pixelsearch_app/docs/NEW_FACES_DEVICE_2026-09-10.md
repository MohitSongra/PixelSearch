# New Faces: Connected-Device Installation

Date: 2026-09-10. Device: Vivo I2214, Android.

## Installation and Preservation

- Installed the New Faces debug APK with `adb install -r`. The app was not uninstalled and no app data was cleared.
- Verified the installed and replacement APKs have the same signing certificate: `5d6a02254b32e1c91b1ad84273009f7731fc10141022e0ccef0304546dfdb26e`.
- Installed APK SHA-256: `573986eb5d5a64976e5bff2947ba863053e1da62fb8a2a880f0c131510bc2880`.
- Confirmed indexing was idle before closing the app for a consistent pre-upgrade backup. Retained the old APK locally as well.
- After launching the update, took a second consistent backup before enabling People. Both SQLite integrity checks returned `ok`.
- The database migrated from schema 5 to schema 6. All eight existing tables retained identical row counts and content hashes: photos, embeddings, index state, folder preferences, memories, memory members, locations and saved captions.
- Preserved 1,916 indexed photos, 1,916 embeddings, 215 memories and 1,916 location records.
- Both CLIP model files, saved search judgments, evaluation report and user preferences retained identical file hashes.

Private backups remain under the git-ignored `local_evaluation/` directory:

| Snapshot | File | SHA-256 |
| --- | --- | --- |
| Before upgrade | `app-data-20260910-141219-092.tar` | `50b223ffa9c01f8dff281ba2add06f6cfa4923d5b8340abe20993401cba7ff67` |
| After migration, before People processing | `app-data-20260910-141433-868.tar` | `99f9027a8582b7d11d8333e79d6f8cbefc8005aa5a0f61abf06c6390f46652b7` |

## On-Device Checks

- User explicitly approved starting offline face processing; enabled People through its consent dialog.
- Processing advanced through real indexed photos. The New faces found notice, New faces view, actual face previews and Add a name controls appeared.
- Opened the assignment sheet and new-person form on the phone. Verified the name/nickname fields, This is me checkbox, Cancel and Save were present with the keyboard open. Canceled without entering or saving an identity.
- The built-in Android CPU face-model check passed all four numerical reference fixtures:

| Fixture | Reference cosine |
| --- | ---: |
| Identity | 0.999999965354575 |
| Scale | 1.0 |
| Rotation | 0.9999963805502139 |
| Border | 0.9999978583319918 |

The model check reported 2,186 ms total for this numerical test, not per-gallery-photo processing latency. These fixtures verify numerical parity, not recognition accuracy.

- Processing resumed after the model check. The last recorded checkpoint showed 300/1,916 photos committed, 1,091 face detections and zero named groups; the live scanner was at 310/1,916. Counts continue changing while the scan runs.
- Left the app on New faces with Pause people processing visible, indicating an active scan.
- A private screenshot of the earlier 120-photo checkpoint is retained as `local_evaluation/new-faces-device-20260910.png`.

## Remaining Scope

- Face detections are not unique people. Blurred faces, repeated appearances and faces in printed/illustrated content can appear; the user must confirm names and dismiss incorrect detections.
- No names, same/different judgments, or real identity assignments were invented. Automatic grouping remains gated by the existing user-reviewed validation.
- Name-search logic has automated regression coverage; real named-person search acceptance awaits user-confirmed labels on this phone.
- Full-library processing had not finished at handoff. Keep PixelSearch open to continue; the existing controller pauses work when the app is backgrounded.
- Airplane-mode acceptance, recognition accuracy, full-library timing and peak memory were not measured in this installation task.
