# Voice, map and timeline integration - 2026-09-10

> **Redaction note (2026-10-22):** personal identifiers (names, the device serial, local paths, private photo filenames, backup names and APK/backup digests) were replaced with placeholders. Measurements are unchanged.

## Scope

Vivo I2214, Android API 36, arm64. Preserve the existing indexed gallery, folder
selection, model contract, embeddings, relevance judgments, and online backend.
No uninstall, clear-data operation, destructive device test runner, model change,
or AI indexing run was used. Search Assistant and captions were reported as checked
by the user; they were not independently re-verified in this session.

## Root causes and changes

### Voice

[BUG] The main search microphone only opened the conversation sheet. It did not
start listening. The permission request also ran inside a busy operation whose
lifecycle handler cancelled on every loss of focus, including Android's own
microphone permission dialog. There was no listening-ready state, and shared
cancellation state could allow late responses to affect a newer operation.

[IMPLEMENTED] The microphone opens an explicitly listening sheet. Permission
focus loss is distinguished from actual backgrounding. Native readiness, stop,
recognition errors, and timeouts are surfaced. Each operation owns its cancellation,
recording file, recorder, and upload confirmation. Reset, disposal, revocation and
late completion cannot restore an obsolete transcript or search proposal.

Cloud transcription remains separately consented and requires approval of each
recording before upload. There is no automatic network fallback or language
download. English transcripts can be edited and searched locally. Hindi/Hinglish
translation remains explicit, visible, editable, and separate from speech capture.

[VERIFIED ON DEVICE] Offline setup reports en-US ready, with en-IN and en-US
installed. This is newer than the September 9 language-availability observation.
It establishes resource availability, not recognition accuracy.

[IMPLEMENTED BUT UNVERIFIED] A live spoken phrase and the authenticated phone-to-
Groq transcription round trip still require user participation. No microphone
recording or private audio upload was initiated during the checks recorded here.

### Map and GPS

[VERIFIED] Before testing, all four individual online switches were on, but the
master Offline only switch was also on. This correctly blocked online requests.
It was temporarily disabled for map testing, then restored. The individual
switches and backend configuration were left unchanged.

[BUG] The old map returned an empty message before constructing the tile view
whenever no located photos existed. Thus even enabling tiles could not show a map.
Missing GPS observations were also cached indefinitely for an unchanged revision,
without an explicit retry path. Per-rebuild default tile providers did not give
the view a stable, explicitly managed network-client lifetime.

[IMPLEMENTED] Consented tiles now render independently of photo pins. An empty
library of locations uses a neutral world camera, never invented coordinates.
The screen reports located, GPS-not-found and unchecked counts, offers a gallery
of unlocated photos, and supports an explicit retry of missing observations.
Scans report inaccessible and unreadable assets separately. Permission revocation,
revision changes, invalid coordinates and cancellation are guarded before writes.

Tile requests use one consent-aware HTTP client per map view, app identification,
bounded waits, no automatic retries, and the installed flutter_map disk cache.
The cache honors HTTP freshness with a seven-day fallback. No bulk downloads,
reverse geocoding, photo uploads or background-area downloads were added. Maps
do not require the Groq/Render backend. Tile errors offer explicit retry; hiding
the map or revoking consent disposes its client.

[VERIFIED ON VIVO] Actual OpenStreetMap world tiles and attribution rendered.
Restoring Offline only removed the map and displayed its disabled state.

[VERIFIED FRESH GPS PASS] All 1,916 indexed assets were checked again:

| Located | GPS not found | Inaccessible | Unreadable |
| ---: | ---: | ---: | ---: |
| 0 | 1,916 | 0 | 0 |

This is a result from the current original-file EXIF reader, not an assertion
that every image format or another copy of an original must lack location.
The reader found no coordinates to plot. No metadata was inferred from image
content, filenames, the phone's current location or a place-name guess. A known
geotagged indexed original is still needed for positive physical pin/cluster
acceptance; fixture tests cover marker and cluster behavior only.

### Timeline

[VERIFIED ROOT CAUSE ON VIVO] A legacy automatic event contained 1,193 photos
from 21 August through 8 December 2023. Comparing each new photo with the growing
event's end let a succession of gaps below 48 hours form a multi-month chain.
The previous screen additionally reused month-only titles for multiple events.

[IMPLEMENTED] The chronological view now has actual indexed year/month choices,
exact date subtitles, deterministic year stories, and an optional people story
based on existing face counts. Story selection is bounded to 20 photos with
calendar-day diversity, not random sampling. Playback is opt-in, can be paused,
and stops at the end. It does not identify people or infer relationships.

The grouping follow-up replaces untouched automatic gap chains with local
calendar-day events. Named or custom-cover memories are preserved as curated
collections. It keeps all photo memberships, deterministic IDs, user edits, and
the existing database schema; only automatic event partitioning intentionally
changes. Existing photos are not re-embedded or indexed again.

[VERIFIED ON VIVO, STORY UI] The current index supplies 2023, so the phone shows
Back in 2023 and People in 2023, not an invented 2024 collection. The people
story displayed a real group photo. Play advanced from photo 1 to photo 6; pause
stopped playback.

[VERIFIED ON VIVO, FINAL UPGRADE] The chronological view now displays 2 photos
on 8 December 2023, followed by 21 photos on 7 December 2023, instead of the
multi-month automatic collection. The final database contains 215 daily events
and all 1,916 memberships. A read-only audit using the device's +05:30 time zone
found zero multi-day events and zero unassigned indexed photos. This device
currently has no named events; preservation of titles and custom covers was
verified by automated tests, not by modifying the user's collections.

## Verification and preservation

- Final combined implementation, including the calendar grouping correction:
  275 Flutter tests passed; analyzer reported no issues.
- Backend: 27 contract tests passed, including multipart transcription shape,
  pinned model, malformed/empty transcript rejection, size bounds and auth.
  Controlled provider responses are not live transcription measurements.
- Native speech Kotlin compilation and the final debug APK build succeeded.
- Final APK: `build/app/outputs/flutter-apk/app-debug.apk`.
  SHA-256: `<digest withheld>`.
- Both updates were installed successfully with the data-preserving Android
  replacement option. The second update includes the calendar grouping fix.
- Signing certificate matches the existing Android debug installation.
- Pre-update backup: `<private backup>`.
  SHA-256: `<digest withheld>`.
- Pre-calendar-fix backup: `<private backup>`.
  SHA-256: `<digest withheld>`.
- These first two backups passed SQLite integrity checks, schema 5. All eight database
  table hashes matched between them, including 1,916 photos, 1,916 embeddings,
  27 memory events, 1,916 memory members and 1,916 location observations.
- Post-calendar-fix backup: `<private backup>`.
  SHA-256: `<digest withheld>`.
  SQLite integrity is `ok`, schema remains 5, and there are zero invalid covers.
  Photo, embedding, checkpoint, folder-preference, location and caption table
  hashes match the first backup. Only memory events and memberships intentionally
  changed. Both model files, evaluation queries, the latest relevance report,
  and secure/shared preference file hashes remain unchanged.
- The post-update archive captured the temporary online-testing setting
  (`offline: false`). The final live device was restored through Settings to
  `offline: true`, and its complete user-preferences file hash was then checked
  against the first backup: identical
  (`<digest withheld>`).
  Anyone restoring the post-update archive must also restore that original
  Offline only setting. All four individual feature choices remained enabled.
- Embeddings remain MobileCLIP-S1 FP32 CPU, version 1, 512 dimensions.

Private device screenshots under `local_evaluation/`: `map_tiles_20260910.png`,
`location_scan_complete_20260910.png`, `people_story_20260910.png`. These are not
publication assets. `timeline_daily_20260910.png` records the final daily view.
Host screenshots under `build/timeline_screenshots/` use
bundled fixture bitmaps and establish layout only.

## Files changed for this task

- Voice: `lib/features/search/conversation_sheet.dart`,
  `lib/features/search/search_screen.dart`, `lib/data/offline_speech.dart`,
  `android/app/src/main/kotlin/com/pixelsearch/pixelsearch/MainActivity.kt`.
- Maps: `lib/features/map/map_screen.dart`, `lib/data/location_repository.dart`,
  `lib/data/enhancements/map_tile_client.dart`.
- Timeline: `lib/features/timeline/timeline_screen.dart`,
  `lib/features/timeline/memory_story_viewer.dart`,
  `lib/features/timeline/timeline_photo_image.dart`,
  `lib/domain/timeline/memory_grouping.dart`,
  `lib/domain/timeline/memory_stories.dart`.
- Verification: voice, offline-speech, location, map-client, map-screen,
  timeline-grouping, timeline-story and timeline-widget tests; corresponding
  existing five-feature tests; `../enhancement_backend/test_app.py`; this report.

The worktree also contains earlier feature changes. This list is not a claim
that every currently modified or untracked repository file belongs to this task.

## Remaining device acceptance

1. Live voice: use the main search microphone and speak a known English phrase.
   Verify the listening state, editable transcript, and submission to local
   search. Repeat with cancellation, then Hindi/Hinglish using explicit
   translation. Resource availability is not enough to mark these checks passed.
2. Cloud transcription: disable Offline only, keep Online transcription enabled,
   select the cloud recording flow, record a known phrase, and explicitly approve
   Send. Record the actual returned text or error. Verify cancellation does not
   submit another request. No authenticated live audio round trip was made today.
3. Map pins: provide an indexed original whose Gallery details show actual GPS
   coordinates, grant photo-location access, and retry missing GPS observations.
   Compare the plotted location with those coordinates; do not guess a location
   for existing unlocated photos.

## Remaining boundaries

- Human voice quality, Hindi/Hinglish accuracy and live cloud transcription are
  not claimed from unit tests or language availability.
- No GPS found means no verified pins. Assigning guessed locations would be
  incorrect. Supported-format/original-file GPS evidence is needed for further
  diagnosis if the phone's Gallery shows coordinates that PixelSearch misses.
- Daily grouping does not identify semantic events within one day. Names and
  cover edits remain user-controlled. Older records have no explicit edit flag;
  the grouping preserves ambiguous missing-cover collections conservatively.
- Timeline dates are existing indexed local timestamps, not repaired original
  capture dates. Shared photos may have an import date different from a filename.
- No semantic search accuracy improvement is claimed. Ranking is unchanged.
- The full metadata pass was visibly lengthy and was not precisely timed as a
  benchmark; it is separate from AI indexing and remains a performance concern.

## References

Design reference: [Google Photos featured memories](https://support.google.com/photos/answer/9454489?hl=en).
Implementation does not claim Google Photos feature parity.
Platform contract: [Android SpeechRecognizer](https://developer.android.com/reference/android/speech/SpeechRecognizer).
Tile handling: [OpenStreetMap tile policy](https://operations.osmfoundation.org/policies/tiles/).
