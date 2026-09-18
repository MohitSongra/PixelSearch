# Indexed gallery and library-specific suggestions

## Delivery status

[VERIFIED] Implementation, analyzer, all 154 Flutter tests, and debug APK build passed on 2026-09-09.

[VERIFIED] Following the user's instruction to proceed, the matching-signer APK was installed in place on the Vivo I2214 (API 36, arm64) on 2026-09-09. Real-device checks passed for the indexed gallery, date navigation, photo viewer, search/clear restoration, library-derived suggestions, and preserved folder choices. No uninstall, data clearing, or indexing run was performed.

The earlier build-only handoff deferred installation while the phone was in use. This section supersedes that delivery status. During final checks the user switched to another app; further UI input stopped immediately. Subsequent preservation checks were read-only app-private file hashes and did not interrupt that app.

## User-facing changes

- An empty search with no active filters now opens the entire indexed library as a newest-first gallery, grouped by local calendar day. The source is the existing persisted `photoLibraryProvider`, not a new gallery scan, sample collection, or semantic Top-K result.
- The month header follows the visible date. Tapping it opens a month picker populated only with dates present in the index. A draggable right-hand date scrubber jumps across the full collection.
- Square thumbnails are virtualized in rows, with only a small offscreen cache. Each photo opens the existing full-screen viewer at its position in the chronological collection. Returning from the viewer or clearing a search restores the gallery scroll position.
- The existing folder-selection action is retained. Its repeat-run label is now **Continue indexing** on the home page and in Settings. First-run action remains **Index photos** / **Index my photos**.
- **Try searching** uses the indexed photos' labels, including saved user label corrections. Labels are normalized, counted once per photo, sorted by frequency with deterministic ties, and limited to eight suggestions. Empty/unhelpful generic labels are omitted.
- No labels means no suggestions. There is no fallback to "beach at sunset" or other fixed examples. Individual labels are never combined into invented relationships or scene captions.
- Suggestions update when the existing library provider refreshes after indexing or label editing. Tapping one submits that exact label through the unchanged production search path. The tooltip identifies the stored-label source and warns that automatic labels may be incorrect.

Reference: the dense Photos-view browsing pattern, not a Google branding or code copy. [Google Photos: Organise your Photos view](https://support.google.com/photos/answer/14169846?hl=en-uk).

## Files changed in this turn

- `lib/domain/gallery/indexed_gallery.dart`: metadata grouping and exact virtual-row/date offsets.
- `lib/domain/search/library_suggestions.dart`: local label-derived suggestions.
- `lib/features/search/indexed_gallery_view.dart`: lazy photo rows, day headers, month navigation, date scrubber, viewer integration.
- `lib/features/search/search_screen.dart`: gallery home, compact index controls, dynamic suggestions, accessible header layout.
- `lib/features/settings/settings_screen.dart`: Continue indexing wording and singular photo count.
- `lib/state/providers.dart`: two derived providers over the existing indexed library.
- `lib/data/sample_data.dart`: removed obsolete fixed suggestions.
- `test/indexed_gallery_test.dart` and `test/indexed_gallery_widgets_test.dart`: 12 new tests.

Pre-existing uncommitted five-feature changes were preserved. No commit or push was made for this gallery task.

## Verification

| Check | Actual result |
| --- | --- |
| Full Flutter test suite | 154 passed |
| Analyzer | No issues |
| Debug APK | Built successfully |
| Signature verification | Passed; same known debug signing certificate |
| Pure layout coverage fixture | All 1,916 fixture IDs occur exactly once with 3, 5, and 8 columns |
| Widget laziness fixture | Fewer than 50 photo tile widgets built initially for a 1,916-photo fixture |
| Date navigation | Month jump and end-of-rail drag reach the oldest fixture photo |
| Viewer / search return | Correct viewer index; gallery position restored |
| Dynamic suggestions | Replace/correct library labels and previous suggestions disappear |
| Responsive UI | 320px at 200% text, 412px, and 1100px without layout exceptions |

Tests initially exposed an accessibility-value annotation issue and an estimated-scroll-length issue that could stop short of the oldest row. Both were fixed and the tests passed afterward. The scrubber uses known row extents rather than Flutter's provisional scroll estimate.

Logs: `build/gallery_full_tests.log`, `build/gallery_analyzer.log`, `build/gallery_apk.log`.

Layout screenshots: `build/gallery_screenshots/`. These use existing bundled fixture bitmaps, not the user's device photos; they are layout checks only, not evidence of semantic relevance or actual device rendering.

APK: `build/app/outputs/flutter-apk/app-debug.apk`

- Size: 260,474,177 bytes.
- SHA-256: `0029031B44F795E15D6D61B2B4618260DFDD5DA4E914CAF91D6993FD3AF2281F`.
- Signing certificate SHA-256: `5d6a02254b32e1c91b1ad84273009f7731fc10141022e0ccef0304546dfdb26e`.

Build warnings about future Java native-access restrictions and plugin Kotlin Gradle migration remain; they did not prevent this build.

## Unchanged contracts and limitations

- No database/schema changes, embedding regeneration, model/version changes, ranking changes, new online requests, or indexing-pipeline changes.
- Dates use the existing indexed timestamp in local time. Incorrect or missing original capture metadata is not repaired; imported images may therefore appear under an import/creation date.
- Automatic labels can be wrong, and a supported label suggestion does not guarantee that unchanged semantic ranking will retrieve the best photos. Retrieval accuracy remains a separate unresolved task.
- Lazy construction is covered by tests and real thumbnails were inspected on the Vivo. Sustained scrolling frame times, bounded long-run memory behavior, and permission-revocation behavior still need dedicated physical testing. The brief memory observations below do not establish a performance improvement or a memory leak.

## Physical acceptance on 2026-09-09

| Check | Observed result |
| --- | --- |
| Home gallery | 1,916 indexed photos; real square thumbnails rendered with day headers and counts |
| Newest indexed date | 8 December 2023, two photos; followed by 7 December, 21 photos |
| Month picker | Actual month counts displayed; selecting September 2023 (265 photos) opened 30 September |
| Date scrubber | Dragging to the oldest end exposed the final photo on 10 February 2023; dragging back restored December |
| Original viewer | Opened `IMG-20230210-WA0079.jpeg`; displayed original photo, date, album, and stored label |
| Return from viewer | Retained the same February scroll position |
| Suggestion execution | Paper submitted `paper` to existing semantic search and displayed 60 results; no ranking-quality claim was made |
| Clear search | Returned to the gallery at the same February position |
| Folder selection | Continue indexing opened the existing picker; Camera and WhatsApp Images remained checked, All folders remained unchecked; exited without saving changes or starting indexing |
| Settings | Continue indexing wording and 1,916 indexed count present; backend URL and consent flags unchanged |

All eight actual suggestions were observed by horizontally scrolling the strip: Paper (780 labelled photos), Poster (463), Screenshot (293), Pattern (250), Leisure (245), Smile (244), Jeans (222), Jacket (212). These are stored automatic-label counts, not human-verified scene counts or promised search-result counts.

The folder picker reports 16,720 available photos across its two selected folders (Camera 4,453; WhatsApp Images 12,267). This is not the indexed count: the main gallery correctly represents the existing 1,916-photo index. No new indexing was requested during acceptance.

Local private screenshots: `local_evaluation/gallery_device_home.png`, `gallery_device_oldest.png`, and `gallery_device_viewer.png`. These contain personal photos and are not intended for publication.

Two `dumpsys meminfo` observations, in KB:

| Point | Total PSS | Total RSS | Total swap PSS |
| --- | ---: | ---: | ---: |
| Initial gallery | 381,068 | 449,468 | 18,200 |
| After date jumps, viewer, semantic search, folder picker and settings | 841,515 | 633,832 | 285,152 |

These are debug-build samples from different application states, including semantic inference and thumbnail caching. They are not a controlled gallery-only comparison. No sustained plateau, frame-time measurement, or release-build memory test was performed.

## Data preservation

The app was idle before upgrade. Only PixelSearch was force-stopped for the consistent pre-update archive, then installed using `adb install -r` with the verified matching signer.

- Backup: `local_evaluation/app-data-20260909-234315-863.tar`.
- Archive SHA-256: `96830FAE80769320551FB19769E8E327D90BE16EC65D7A04EE1B02508F13F2ED`.
- Audit: `local_evaluation/before_gallery_update.json`; SQLite integrity `ok`, schema 5.
- Preserved database counts: 1,916 photos; 1,916 embeddings; 27 memory events; 1,916 event members; 1,916 location records; zero saved captions; one checkpoint row and one folder-preference row.
- Embeddings remain MobileCLIP-S1, version 1, dimension 512. Saved folder IDs remain `-1739773001` and `-1829889111`, with all-folders disabled.

After the UI checks, read-only SHA-256 comparisons matched the backup exactly for the SQLite database, both model files, evaluation queries, latest evaluation report, user preferences, and all four archived shared-preference files, including both secure-storage files. There were no SQLite WAL/SHM files in the backup or at the post-check, so the unchanged main database comparison covers the persisted database rather than omitting a pending WAL. No credentials or private file contents were logged.

Evidence: `local_evaluation/gallery_post_update_file_checks.json` and `local_evaluation/gallery_post_update_private_checks.json`.

A second quiescent full archive was not taken because the user resumed using another app. The verified pre-update archive is retained; the post-check was a read-only preservation comparison, not a new atomic backup. PixelSearch was left installed normally, with no indexing running and no changes to the user's foreground app.

## Procedure for future protected upgrades

1. Confirm PixelSearch is idle. Force-stop only PixelSearch for a consistent offline snapshot.
2. Run `tool/run_search_evaluation.ps1 -Device 10BD1X0DL40005U -BackupOnly`. Never use the destructive integration-test installation path.
3. Audit the archive with the existing `tool/audit_private_backup.py`. Preserve models, all database tables, folder preferences, secure backend settings and relevance judgments.
4. Install only with a data-preserving `adb install -r`, using the verified matching signature. Never uninstall or clear data.
5. Check the real 1,916-photo home gallery, newest/oldest dates, month picker, date scrubber, original-photo viewer, and scroll restoration after searching.
6. Check suggestions against actual stored labels; inspect Continue indexing opening the same folder picker without starting an unintended run.
7. Take a final quiescent snapshot and compare critical database/model/judgment hashes. Record actual UI and memory observations, not assumed success.
