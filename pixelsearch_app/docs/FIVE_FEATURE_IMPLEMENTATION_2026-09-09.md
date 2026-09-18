# PixelSearch: Five-feature implementation handoff

Date: 2026-09-09 (Asia/Calcutta)

> Historical pre-device handoff. The later [Android acceptance report](ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09.md)
> records the connected Vivo, data-preserving upgrades, new app logo, thumbnail
> recovery fix, 130 passing Flutter tests and completed local checks. Statements
> below about no connected device, no installation and the earlier APK hash apply
> only to this earlier checkpoint. Live online verification is still pending.

## Delivery status

**[IMPLEMENTED BUT UNVERIFIED] Physical-device acceptance and live online features.**
The five features are implemented in the existing Flutter application. Host tests,
layout checks and Android compilation pass. This is not a claim that the complete
milestone has passed on Vivo, that cloud services have been deployed, or that
semantic-search relevance has improved.

Repository: `C:\Users\mohit\Desktop\PixelSearch_handoff\PixelSearch`

Branch: `main`, based on commit `5f6f07418577475c90902d19f1981e01f524b725`.
Implementation changes are uncommitted and unpushed. Pre-existing `output/` and
`tmp/` contents were not removed.

## Data safety

**[VERIFIED] Existing laptop backup preserved and checked.**

Backup directory:
`C:\Users\mohit\Downloads\PixelSearch_Backups\before_five_features_20260909_183041`

- Preserved 57 files totaling 518,701,962 bytes from the existing local-evaluation archive.
- SHA-256 manifest: `sha256.csv` in that directory.
- Compared every source and destination with the manifest: 57 files, zero mismatches.
- The earlier app-private archive includes the SQLite database, image/text models
  and saved evaluation files. It is an earlier snapshot, not a fresh device backup.
- No phone installation, uninstall, data clearing, model transfer or device test
  installation was performed. ADB returned no connected devices during this work.
- A fresh, consistent device backup is still mandatory before an approved upgrade.

## Implemented features

### Shared foundations

- Additive SQLite schema v4 -> v5: memory events/membership, saved captions and
  revision-specific location enrichment. Existing tables and vectors are retained.
- `AiContract.schemaVersion` is 5. Model ID, artifact version, embedding version
  `1`, 512-dimensional geometry, tokenizer and inference contract are unchanged.
- Persistent default-off feature consents and master offline switch. Permission
  revocation invalidates pending enhancement requests and rejects late responses.
- HTTPS backend configuration, securely stored per-install access token, bounded
  uploads/responses, no redirect forwarding and no automatic enhancement retries.
- Android backup is disabled to avoid OS cloud backup of private index/token data.
  This does not replace the explicit local device-backup procedure.

### Memory Timeline

- Grouping moved into a domain service. The existing whole-hour gap rule is retained:
  a gap starts a new event when `gap.inHours > 48`.
- Durable event IDs, membership, editable title, selected cover, month selection
  and event-detail gallery are implemented.
- New photos join the nearest eligible event. Bridging additions do not merge
  established events. Empty events are removed and deleted covers are replaced
  deterministically. Edits and reconciliation share a serialized operation queue.
- Grouping uses metadata loaded from storage through provider/repository code,
  not image inference inside screen builds.

### Explainable Search

- `SearchBackend.searchDetailed(SearchRequest, corpus)` returns results and the
  evidence captured in that search. The existing list-returning API is a wrapper.
- Result details show raw cosine, gated cosine, normalized signals, actual weighted
  contributions, final score, matched metadata, active filters and retrieval mode.
- Stored ML Kit labels are distinguished from labels included in ranking policy.
  No heatmaps or probability claims are made.
- Existing weights, cosine gate, semantic normalization, unfiltered Top-K and
  ranking order are preserved. Explanation display does not run diagnostics again.
- Optional eligible-ID filtering occurs before vector Top-K selection. This is
  required for conversational filters and does not alter unfiltered selection.

### Map View

- The placeholder is replaced by `flutter_map`, clustered markers, viewport
  filtering and cluster-to-gallery navigation.
- A separately permissioned, resumable metadata pass reads original-photo EXIF
  GPS for indexed assets. It does not rescan the gallery for AI indexing or alter
  folder preferences and embeddings.
- GPS and provenance are stored separately from indexer-owned metadata. Completed
  revisions are skipped; unreadable/inaccessible assets remain retryable. Missing
  GPS never becomes an invented 0,0 location; explicit valid zero GPS is allowed.
- Tiles require map consent. Credit remains visible and links to OSM copyright.
  The resolved flutter_map 8.3.2 native provider includes persistent HTTP-aware
  caching, conditional requests and a seven-day fallback cache age. Application
  identification is set. No region downloads, geocoding or location inference.
- These choices follow the [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/).
  Actual Android tile traffic, cache reuse and GPS access are not yet validated.

### Captions

- One selected photo is orientation-corrected, resized to at most 1280 pixels per
  side, stripped of embedded metadata and previewed before explicit upload approval.
- Factual base description, concise/social/formal text-only rewriting, editing,
  copying, local saving and deletion are implemented.
- Saved records include revision, provider/model, base caption, edited caption,
  style, manual-edit flag and generation time. Reindexing does not overwrite them;
  a revision mismatch marks a generated caption stale when the screen loads.
- New captions never enter production retrieval metadata or ranking.
- The backend pins `qwen/qwen3.6-27b` with JSON output and non-thinking mode.
  Groq documents image/text support and preview status for this model; real account
  access and output quality remain unverified. [Model documentation](https://console.groq.com/docs/model/qwen/qwen3.6-27b)

### Voice and conversational search

- English/Hindi/Hinglish selection, microphone permission, editable transcript,
  cancellation, visible English-query preview and local query application.
- Native Android speech uses only the explicitly on-device recognizer and checks
  installed language support. The implementation requires API 33+ for that check;
  unavailable support is surfaced rather than silently using network recognition.
- English requests `en-IN`; Hindi and Hinglish currently request `hi-IN` locally.
  This is an implementation choice, not measured Hinglish support quality.
- Separately consented cloud recording/transcription uses `whisper-large-v3-turbo`,
  a 30-second recording bound, another approval before sending and temporary-file
  cleanup. Recording is cancelled when the app backgrounds or consent is revoked.
- The assistant returns a proposed English query and supported filters, not IDs,
  SQL or rankings. Date validation and album/place resolution occur locally.
  Ambiguity is surfaced for clarification. Language fidelity needs human evaluation;
  structural validation is not proof that a translation preserves meaning.
- Session-only previous search states provide undo and new-conversation actions.
  No gallery inventory, filenames, embeddings or photos are sent to the assistant.

## Optional backend

`enhancement_backend/` contains FastAPI routes for health/capabilities, caption,
rewrite, assistant and transcription; strict input/output models; per-install
token-hash authentication; bounded requests; quota handling; and provider calls.
`render.yaml` configures a free web service. Exact tested Python dependencies are
recorded in `requirements.lock`.

**[MISSING] Live configuration/deployment:** no Groq or Render credentials were
configured and no service was deployed. No private media was uploaded.
Provider keys belong only in server secrets. No paid upgrade was authorized or made.

Groq's account-level Zero Data Retention must be enabled before setting the backend's
`GROQ_ZDR_CONFIRMED` attestation. This flag cannot configure Groq on its own. Usage
metadata is distinct from retained request content. [Groq data controls](https://console.groq.com/docs/your-data)

Unavailable models fail explicitly; there is no silent model substitution. Render's
free service can sleep and cold-start, so it remains demo hosting, not an availability
promise. The app waits at most 100 seconds and requires an explicit retry.
[Render free-service limits](https://render.com/docs/free)

Cancelling a client request stops local pending work and new uploads; it cannot
recall bytes already delivered to a consented server or guarantee server-side
inference has stopped. Local search and saved results remain usable without the backend.

Setup: [Backend README](../../enhancement_backend/README.md).

## Actual verification results

| Check performed on this laptop | Result | Scope |
|---|---|---|
| Source/backup SHA-256 comparison | 57 files; 0 mismatches | Earlier laptop archive, not fresh device data |
| Flutter unit/widget suite | 125 passed | Includes existing indexing/search tests and new feature tests |
| Flutter analyzer | No issues found | Final source |
| Backend contract tests | 14 passed | Mocked provider responses; no AI-quality measurement |
| Debug Android APK | Built successfully | Compilation/packaging only; not installed |
| Small-screen/large-text rendering | Passed | 320x740 and 412x915; additional attribution test at 2x text |
| Connected Android devices | None returned by ADB | Physical acceptance not performed |

New checks cover additive migration with unchanged embedding bytes/version and
folder/checkpoint data; stable events and queued edits; deleted covers and late
imports; interrupted/denied GPS passes; saved captions outside search; default-off
consents and in-flight revocation; sanitized image payloads; response/filter
validation; filtered Top-K; and same-execution score contributions.

Host screenshots use bundled test fixtures, not the user's gallery or relevance
judgments. They validate layout, not model output, map accuracy or search quality.

Reproduction from `pixelsearch_app/`:

```powershell
C:\src\flutter\bin\flutter.bat test --no-pub --reporter expanded
C:\src\flutter\bin\flutter.bat analyze --no-pub
C:\src\flutter\bin\flutter.bat build apk --debug --no-pub
```

From `enhancement_backend/`: `.\.venv\Scripts\python.exe -m pytest -q`.

Saved Flutter logs: `build/five_feature_tests.log`, `build/five_feature_analyzer.log`,
`build/five_feature_apk_build.log`. Layout images: `build/feature_screenshots/`.

APK: `build/app/outputs/flutter-apk/app-debug.apk`

- Size: 260,438,882 bytes.
- SHA-256: `8B687D8E19D2B683E6E0F2C46D503B38507EB5F08C836BA7D5517C2DE2385CAA`.
- Built 2026-09-09, 21:15 local time. This APK was not installed.

## Changed code areas

Paths below are relative to the repository unless prefixed with `lib/` or `test/`,
which are relative to `pixelsearch_app/`.

| Area | Main files |
|---|---|
| Storage | `lib/data/local/app_database.dart`, generated `.g.dart`, `lib/core/ai_contract.dart` |
| Timeline | `lib/domain/timeline/memory_grouping.dart`, `lib/data/memory_repository.dart`, timeline screen |
| Search | domain search request/response/backend/index interfaces, both search backends, brute-force vector index, ranking evidence helper, providers |
| Viewer | photo viewer, original-photo widget, search explanation, caption screen, photo grid |
| Map | `lib/data/location_repository.dart`, map screen |
| Consent/client | `lib/data/enhancements/`, user preferences, online settings, providers |
| Voice | conversation sheet, assistant result parser, Android `MainActivity.kt` and manifest |
| Dependencies | `pixelsearch_app/pubspec.yaml` and lockfile |
| Tests | `test/five_feature_test.dart`, `test/five_feature_widgets_test.dart`, semantic backend tests |
| Backend | `enhancement_backend/app.py`, tests, requirements/lock, README; root `render.yaml` |
| Documentation | interface contract, migrations, this report, device checklist |

## Remaining risks and acceptance work

- **[IMPLEMENTED BUT UNVERIFIED]** Fresh v5 upgrade with the real 1,900-photo library,
  event persistence across actual restarts, gallery access and incremental indexing.
- **[IMPLEMENTED BUT UNVERIFIED]** GPS formats/permissions/limited-photo access,
  real marker counts and map cancellation/caching behavior on Vivo.
- **[IMPLEMENTED BUT UNVERIFIED]** Offline recognizer availability, ten utterances
  per language category, mixed-language transcription and multi-turn fidelity.
- **[IMPLEMENTED BUT UNVERIFIED]** Real caption facts, rewrite faithfulness, model
  availability, Render cold starts and free-tier quota behavior.
- Caption decoding reads one original before resizing; very large/unsupported
  formats and memory pressure need device validation. EXIF parsing errors remain
  retryable rather than fabricating GPS.
- Timeline retains the historical 48-whole-hour heuristic and performs a metadata
  reconciliation. Event merge/split and clustering-performance optimization are deferred.
- Caption staleness uses indexed modification time and refreshes on opening the
  caption screen; it is not a live observer of external edits while that screen is open.
- Android builds emit plugin/Kotlin migration and JDK native-access warnings, but
  succeed. Backend tests emit two upstream deprecation warnings.
- Windows desktop plugin linking needs Developer Mode; the Android build succeeded
  with resolved dependencies and `--no-pub`. Desktop/web were not acceptance targets.
- **[BUG, UNRESOLVED]** Semantic relevance remains a separate known product problem.
  No new accuracy, retrieval improvement or generalization claim is justified here.

## Next sequence

1. Reconnect Vivo. Preserve a fresh, readable device snapshot with the app quiescent;
   verify models, database, folder choices and judgments before any upgrade.
2. Obtain approval for an in-place update, check signing compatibility, and run the
   local-feature portion of the [device checklist](FIVE_FEATURE_DEVICE_CHECKLIST.md).
3. Configure Groq data controls and a Render free deployment using server secrets;
   provision a unique per-install token without exposing credentials in chat/Git.
4. Run consent/cancellation/quotas checks, approved caption examples and the 30
   multilingual trials. Record actual successes and failures separately from relevance.
5. Fix acceptance failures, then resume semantic evaluation from preserved judgments.
   Make retrieval changes only with measured before/after evidence.
6. Profile indexing/reconciliation separately; then address remaining synopsis/paper
   and supporting-product gaps. Do not mix those changes into this acceptance run.
