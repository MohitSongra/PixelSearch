# PixelSearch: Android local feature acceptance

Date: 2026-09-09, approximately 21:22-22:00 Asia/Calcutta.

> Later follow-up: [speech setup and article scoring](SPEECH_SEARCH_FOLLOWUP_2026-09-09.md).
> It identifies installed en-US, adds explicit offline-language setup, removes
> article-only semantic-hybrid boosts, and records the later APK/data audit.
> The scores and unavailable-language observations below are the earlier baseline.

## Status

**[PARTIAL] Five-feature milestone:** local device checks completed as listed
below; live cloud features, successful speech transcription and positive GPS-map
rendering are not yet accepted. Semantic relevance is not improved by this work.

- Repository: `C:\Users\mohit\Desktop\PixelSearch_handoff\PixelSearch`.
- App: `pixelsearch_app/`; branch `main`, based on
  `5f6f07418577475c90902d19f1981e01f524b725`; work remains uncommitted/unpushed.
- Device: Vivo I2214, API 36, arm64, ADB serial `10BD1X0DL40005U`.
- User deferred Groq/Render setup and requested local testing first.
- Device UI was operated through ADB with fresh UI snapshots/screenshots. Android
  Studio was not running when the Windows application inventory was checked.
- The user enabled microphone and photo-location permissions. Both were confirmed
  granted afterward, alongside full image access. No online consent was enabled.

## Data safety and installed build

**[VERIFIED] Two in-place updates; no uninstall, data clearing, destructive test
installation or model reprovisioning.** Signing certificates were checked for
compatibility before the first update. Backups were taken with the app quiescent.
Only the backup-only branch of the existing device evaluation script was used.

All archive paths below are within `pixelsearch_app/local_evaluation/`:

| Snapshot | Archive | SHA-256 |
|---|---|---|
| Before schema-v5/logo upgrade | `app-data-20260909-212249-679.tar` | `2D6FC7B67B84D53BACEDB2A12EF49691978EDF37235BC315C151F71E2FF17649` |
| Before thumbnail-fix upgrade | `app-data-20260909-213808-649.tar` | `37525751D93D36A1F15BC9235D84C425BF7410E215C69433345792BC9A310F0E` |
| Final, after test cleanup | `app-data-20260909-215455-906.tar` | `16066788A59685AAFA2665E3C30EE707DAEF5D1A9F8CC1F163B95F44EFA7FD7A` |

The first archive, its manifest and the previously installed APK are also preserved
outside the repository at:
`C:\Users\mohit\Downloads\PixelSearch_Backups\phone_before_five_features_20260909_212249`.

Installed APK: `build/app/outputs/flutter-apk/app-debug.apk`.

- Size: 260,444,090 bytes.
- SHA-256: `F5CC3906C631F37BDE7DFA2BC5141EB3D978DBDA59D0EF5FDD8070553BE2F576`.
- Package/version unchanged: `com.pixelsearch.pixelsearch`, `0.1.0+1`.
- Device first-install timestamp remained `2026-09-08 17:25:50`.
- Last update: `2026-09-09 21:39:47`.

The read-only `tool/audit_private_backup.py` opens a temporary copy of SQLite
including WAL/SHM when present, checks integrity, and hashes canonical table rows.
It never writes the phone database. Final versus baseline comparison established:

| Durable item | Result |
|---|---|
| Photo rows, including labels/faces/metadata | 1,916; exact canonical table hash unchanged |
| Embedding rows including all vector bytes | 1,916; exact canonical table hash unchanged |
| Index checkpoint/state | Exact canonical table hash unchanged |
| Folder preferences | Exact canonical table hash unchanged |
| Image/text ONNX artifacts | Both SHA-256 hashes unchanged |
| Saved queries and diagnostic report | Both SHA-256 hashes unchanged |
| User preferences | SHA-256 unchanged |
| SQLite integrity | `ok` before and after |
| Schema | Additive v4 -> v5 |
| Embedding contract | MobileCLIP-S1, version `1`, dimension 512 for all 1,916 rows |

Folder choices remain `-1739773001` and `-1829889111`; all-folders is false.
The SQLite file hash necessarily changed because new feature tables were populated;
the four original tables did not change.

Audit outputs:
`before_five_features_device_20260909.json`,
`after_v5_first_upgrade_20260909.json`,
`final_five_features_device_20260909.json` in `local_evaluation/`.
These archives and screenshots contain private gallery data; do not publish them.

## Device results

### Memory Timeline

**[VERIFIED]** 27 persisted memories with 1,916 memberships. Event details and
original-photo viewing work. Renamed the 16-photo August 4-18 event to
`Timeline test`, then verified the title after an in-place update and restart.
Changed its cover, restarted the app, and visually confirmed the selected cover
persisted. Restored the automatic title and original cover through the UI.
Final database: zero custom titles and zero covers outside their event membership.

**[HISTORICAL DESIGN, RETAINED]** The existing `gap.inHours > 48` rule produces a
large 1,193-photo August 21-December 8 event through chained nearby dates. This is
not a new inference/grouping algorithm. Merge/split remains deferred.

**[IMPLEMENTED BUT UNVERIFIED ON THIS DEVICE]** Late imports, deleted-cover
replacement and month navigation have host test/source coverage but were not all
repeated on the physical gallery during this session.

### Explainable Search

**[VERIFIED]** Opened an actual result for `a dog`, then `Why this matched`.
It displayed the evidence captured by the search, not a new diagnostics run.
Result filename: `IMG-20230821-WA0165.jpg`. The search returned nine results.

| Displayed component | Observed value |
|---|---:|
| Raw cosine | 0.2073 |
| Cosine after gate | 0.2073 |
| Normalized semantic signal | 0.5923 |
| Normalized metadata signal | 1.0000 |
| Face signal | 0.0000 |
| Weighted semantic contribution | 0.4146 |
| Weighted lexical contribution | 0.2500 |
| Weighted face contribution | 0.0000 |
| Final score | 0.6646 |
| Raw cosine gate | 0.15 |
| Candidate limit | 60 |

The displayed contributions sum to the displayed final score. Matching term:
`a`; album: `WhatsApp Images`. The screen explicitly said stored ML Kit labels
were not used in this ranking and that scores are not probabilities.

**[VERIFIED OBSERVATION, NOT A QUALITY RESULT]** The article `a` can yield a
saturated metadata contribution in the current ranking path. This is evidence
for the next lexical-matching experiment, not proof that removing it improves
retrieval. No weights, gates, candidate counts, model or judgments changed here.
`beach at sunset` returned no close matches; no accuracy conclusion follows
without reviewed relevance labels for that query.

### Map and location enrichment

**[VERIFIED]** With user-granted photo-location permission, the metadata scan
checked all 1,916 indexed assets. Cancellation stopped at 784/1,916; after resume,
progress was observed at 828/1,916 rather than restarting from zero. It completed
at 1,916/1,916. Final database has 1,916 location rows, all status `missing`, zero
non-null coordinate pairs. The UI says no photos with verified GPS locations.

This establishes missing-GPS handling and resumable metadata processing, not that
the device's entire gallery lacks GPS. No image inference or embedding updates
were required, and original photo metadata remained byte-for-byte equivalent at
the canonical table level. Map consent remained off; no tile test was attempted.

**[IMPLEMENTED BUT UNVERIFIED]** Positive GPS parsing on this device, real marker
placement/counts, cluster navigation, tile fetching/caching and attribution during
live tile use need known-geotagged accessible photos plus explicit map consent.

### Captions

**[VERIFIED]** Saved the manual text `Local caption test` for
`IMG-20230804-WA0000.jpg` while offline. Reopened it after an update/restart and
confirmed persistence. Deleted it through the UI; final `saved_captions` count is
zero. The generated-caption action was blocked while online caption consent was
off. No image was approved for upload.

**[IMPLEMENTED BUT UNVERIFIED]** Live generation, factual correctness, rewrite
faithfulness and account/model availability require the deferred backend setup.
Caption text remains excluded from production search ranking.

### Voice and conversation

**[VERIFIED]** English/Hindi/Hinglish controls are reachable with microphone
permission granted. Each local listening attempt returned
`Requested language is not installed` through the native support check. English
requests `en-IN`; Hindi and Hinglish request `hi-IN`. This does not establish that
all possible offline language variants are absent. No transcript was produced.

**[VERIFIED]** Trying cloud recording while its consent was off returned
`Enable online transcription in Settings first.` No silent cloud fallback occurred.
The current error UI exposes a raw `PlatformException`; user-facing error wording
should be improved in a follow-up. No online feature was enabled for testing.

**[IMPLEMENTED BUT UNVERIFIED]** Successful local speech, ten utterances per
language category, mixed-language quality, multi-turn refinement, and live
translation require supported local language resources or the separately
consented backend. Do not report transcription accuracy from this session.

## Device bug fixed: evicted thumbnails

**Root cause [VERIFIED]:** Existing indexed rows refer to disposable Android cache
files. Several referenced thumbnails were already missing from the pre-upgrade
archive. The old display path returned `FileImage` without recovery, so Timeline
and grid tiles showed `PathNotFoundException` despite accessible originals.

**Fix:** Native device photos now use `DeviceThumbnailImage`. It first reads the
cached thumbnail asynchronously; if missing/corrupt, it requests a bounded 512x512
thumbnail from `photo_manager` for the asset ID. Unavailable/deleted assets use a
neutral transparent fallback. Flutter's bounded image cache shares loads. No
synchronous disk checks in widget builds, reindexing, model work, SQLite changes
or durable thumbnail writes were introduced.

**[VERIFIED]** Timeline and grid photos rendered correctly after the second
in-place update. Five new tests cover valid/missing/corrupt caches, absent paths,
and inaccessible gallery assets. Later gallery permission changes can require
image-cache refresh/reopening; that lifecycle is not fully device-tested here.

## New logo

**[VERIFIED]** Installed Android icon now uses a photo frame, landscape and
magnifying glass: teal/white with an amber detail on charcoal. Its small-size
rendering was visually checked in Android App Info.

- Source bitmap and provenance: `assets/branding/pixelsearch_icon.png`, `README.md`.
- Generation configuration: `flutter_launcher_icons.yaml`.
- Standard density icons and adaptive Android foreground/background resources.
- iOS/web icons were not changed or tested.

## Verification and changed files

| Check | Actual result |
|---|---|
| Flutter unit/widget suite | 130 passed |
| Flutter analyzer | No issues found |
| Backend contract suite | 14 passed; two upstream deprecation warnings |
| Debug APK build | Success, 23.7 seconds for the final build |
| In-place final update | Success, app starts with 1,916 indexed photos |
| Baseline/final data comparison | Original four tables and five critical non-DB files unchanged |

Logs: `build/device_fix_tests.log`, `build/device_fix_analyzer.log`,
`build/device_fix_apk.log`. Backend tests were rerun with mocked provider responses,
not a live Groq account. No destructive Flutter integration runner was used.

Files added/changed specifically in this continuation:

- `lib/core/platform_image.dart`, `platform_image_io.dart`, `platform_image_stub.dart`.
- `lib/models/photo.dart`, `test/device_thumbnail_test.dart`.
- `assets/branding/`, `flutter_launcher_icons.yaml`, `pubspec.yaml`, `pubspec.lock`.
- Android launcher resources, adaptive icon XML and `values/colors.xml`.
- Generated Linux plugin registration after dependency resolution; Linux untested.
- `tool/audit_private_backup.py` and this report; status note in the earlier handoff.

The larger five-feature implementation is documented in
[the earlier implementation handoff](FIVE_FEATURE_IMPLEMENTATION_2026-09-09.md).
No new indexing, model-contract or ranking-policy changes were made during this
device continuation. Existing folder indexing/cancellation/resume tests pass, but
no new physical AI reindex run was started; its checkpoints were preserved exactly.

## Next work

1. Diagnose which offline recognition languages the Vivo service actually exposes;
   provide a clear unavailable-language message and a user-controlled setup path.
   Do not silently download resources or switch to network recognition.
2. Test with one known-geotagged accessible photo, then consented map tiles and
   cluster navigation. Do not invent coordinates for the current test set.
3. When accounts are ready, configure Groq data controls and Render free hosting
   with server-only secrets and a unique per-install access token.
4. Complete approved caption examples and the 30 multilingual speech trials;
   verify cancellation, offline transitions, cold starts and quota handling.
5. Resume semantic-quality work from preserved judgments, beginning with a measured
   lexical stopword/saturation comparison and raw-cosine versus final ranking.

Private screenshots are kept only in `local_evaluation/`, including
`timeline_recovered.png`, `timeline_cover_after_restart.png`, and
`installed_logo_app_info.png`. Original gallery files were not changed.
