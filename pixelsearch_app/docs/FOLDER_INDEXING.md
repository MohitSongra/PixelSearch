# Folder-Scoped Indexing

Date: 2026-09-08. Production app: `pixelsearch_app`.

## Behavior

- Index and Re-index from onboarding, Search, and Settings open the same folder picker.
- Folders have checkboxes and photo counts. All folders is explicit and includes future folders.
- First use selects nothing. An empty selection cannot start indexing. Back cancels without saving.
- Folder IDs, not display names, are stored in SQLite and restored on the next visit/restart.
- As requested by the user, deselecting a folder keeps its already-indexed photos searchable.
- New/changed photos are processed only in the selection. Re-selecting an unchanged indexed photo
  skips it; changes made while deselected are processed when reselected.
- Original gallery files are never deleted by this feature.

## Architecture

The existing UI/controller -> bridge -> composition root -> IndexingService -> SQLite path remains.
`FolderPickerScreen` saves `FolderSelection` via `IndexingPreferencesRepository` before starting.
The background entry point reads the same persisted choice; no background task is newly scheduled.

`PhotoManagerGallerySource` resolves Android MediaStore buckets with `getAssetPathList`, pages
selected albums at 500 assets/page, deduplicates by asset ID, and returns a `GallerySnapshot`.
Selection limits candidate decoding, thumbnails, embeddings and ML Kit. With full access, a separate
paged metadata-only All-photos scan supplies existence IDs, so existing out-of-selection records
are not mistaken for deletions. This still has O(gallery size) ID memory and enumeration time;
unselected image bytes are not read. All-folders mode reuses its own candidate IDs for reconciliation.

Image-only permission requests match the actual media type. Limited access is identified in the
picker and disables missing-photo pruning. Denied/revoked access aborts scanning. Missing selected
folders abort rather than falling back to All. Duplicate Android folder names show relative paths.

Schema v3 -> v4 adds `indexing_preferences_rows` only. Photo rows and embedding bytes are not
rewritten. Model/artifact/embedding versions, preprocessing, ONNX providers and ranking are unchanged.

API reference: [photo_manager album and permission documentation](https://pub.dev/documentation/photo_manager/latest/).

## Host Verification

- `flutter analyze`: no issues.
- `flutter test`: 76 passed (18 new folder-selection tests).
- `flutter build apk --debug`: passed. Existing native-access and future Kotlin-plugin warnings remain.
- Adapter channel tests cover 1,101-photo paging, multi-folder deduplication, same-name/renamed
  folders, empty/missing choices, full/limited/denied access, image-only permission parameters,
  all-folders mode, and folder counts.
- Service/store tests cover deselected-row retention, actual deletion, newly selected candidates,
  changed photos on reselection, unchanged skips, 100% completion, and limited-access preservation.
- Preferences tests cover first-use defaults, restart persistence, and additive v3 migration with
  byte-identical embedding readback. Widget tests cover confirmation/cancel, saved choices,
  All-to-subset toggling, missing folders, and 320px layout at 1.6x text scale.

## Physical Android Verification

Vivo I2214/API 36, existing FP32 CPU models, debug APK built at 16:33:22 local time.
Installed with an in-place update; app data was not cleared. Android UI and SQLite were read
directly; database reads were in memory. No gallery photo was uploaded or deleted.

| Check | Measured/observed result |
|---|---|
| Schema upgrade on the phone | v3 -> v4; SQLite integrity `ok`; all 140 original embedding hashes unchanged |
| Picker | Onboarding Index opened it; no folders initially checked; confirmation disabled with zero selected |
| Duplicate Camera folders | 2 photos at `DCIM/DCIM/Camera/`, 4,453 at `DCIM/Camera/`; paths displayed separately |
| Permission correction | Image-only request removed the incorrect Limited photo access banner; READ_MEDIA_IMAGES was already granted |
| Selected scope | Small Camera folder (2) plus Canva (4): picker displayed 6 photos in 2 folders |
| First run, 16:36:44-16:36:50 | 6 discovered; 2 already up to date; 4 indexed; 0 failed; 0 deleted |
| First run duration | 31,699 ms including gallery-wide metadata reconciliation; not just AI inference |
| First run readback | 144 photos, embeddings, labels and thumbnails; the 4 new rows all belong to Canva |
| Cold restart | Both selected folder IDs restored and checked in the picker |
| Deselect Canva and rerun, 16:38:46 | 2 discovered; 2 up to date; 0 indexed; 0 failed; 0 deleted; UI: Already up to date |
| Second run duration | 34,437 ms, dominated by full-gallery existence metadata enumeration |
| Final database | 144 embeddings retained, all hashes identical to the first-run snapshot; integrity `ok` |
| Search after deselection | Query `Canva` displayed 59 results with Semantic badge; quality was not scored |
| Visual check | Real phone screenshot inspected: checkbox states, duplicate paths, counts and action fit without overlap |

Only the small Camera folder remains saved from the test. The picker is available on every Index
action for the user to choose their intended folders. Large-folder completion and limited-access
behavior were covered with host tests, not re-tested against a large physical-device sweep here.

## Remaining Limits

- This picker exposes MediaStore photo folders, not arbitrary filesystem directories or cloud-only albums.
- Empty or inaccessible albums may not be returned by Android; a saved missing folder requires review.
- Enumeration is not a transactional MediaStore snapshot. Gallery/permission changes during a scan
  may require a retry; detected empty pages abort before reconciliation.
- Newly indexed items still become searchable after completion/cancellation, not mid-run (existing KI-6).
- Full-library performance, screen-off/OEM behavior, Android FP16 parity and retrieval quality remain
  separate acceptance work. This feature does not claim to resolve them.
