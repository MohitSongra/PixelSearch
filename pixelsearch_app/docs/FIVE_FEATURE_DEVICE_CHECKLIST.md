# Five-feature Android acceptance checklist

Status: **not yet performed on the physical phone**. Test on Vivo I2214 / API 36.
Host tests and APK compilation do not establish speech or caption accuracy.

## Preserve the existing installation

1. Reconnect USB debugging and record the installed app version, indexed count,
   selected folders and saved diagnostic judgments.
2. Finish/cancel indexing. With the user's approval, close the app process before
   taking a consistent snapshot. The existing `tool/run_search_evaluation.ps1`
   supports `-BackupOnly`; use that flag and do not run its device-test branch.
3. Verify the archive contains the database, any WAL files, models, preferences,
   and search-evaluation files. Verify hashes and readable database contents.
4. Check package ID and signing certificate compatibility. Install only an approved
   in-place update. Never uninstall, clear app data, or accept a destructive fallback.
5. Verify indexed count, embedding version `1`, folder choices and judgments survive.

## Local features

- Timeline: open events, filter by month, rename one event and choose a cover.
  Restart the app and run incremental indexing; verify both edits survive.
- Timeline: test a deleted cover and late-imported photo. Existing events must not
  silently merge; the original gallery is never edited by event controls.
- Explainability: open a normal search result, then Why this matched. Compare its
  cosine/components with diagnostics using the same unfiltered query and index.
  Components must sum to the displayed final score. No confidence percentage is implied.
- Search filters: refine a date restriction, undo it and start a new conversation.
  A supported filter must constrain the candidate pool before Top-K selection.
- Map: grant photo-location access separately. Test at least one known geotagged
  original camera photo and one photo without GPS. WhatsApp photos may lack GPS.
- Cancel the location pass, resume, then repeat. Completed, unchanged revisions
  must be skipped. Indexed embeddings and folder preferences must not change.
- Deny GPS access / restrict gallery access. Unknown or unavailable photos must
  not become pins at 0,0. Test clusters and zoom near the antimeridian if available.
- Toggle offline mode while a map is loading. Stop new tile requests; local photo
  browsing remains available. No offline tile download or geocoding is implemented.

## Online captions and conversation

Configure the backend using `enhancement_backend/README.md`. Keep free plans only.
Verify Groq's account-level Zero Data Retention setting before private uploads.

- With every online permission off, exercise all online actions: no requests.
- Allow captions, preview one selected photo, decline upload: no request.
- Approve one photo. Inspect the factual description against the actual image.
  Rewrite, edit, save, restart, copy and delete. Rewrites must transmit text only.
- Edit/re-index the original photo: old generated captions must be marked stale,
  and manual captions must not be overwritten by indexing.
- Revoke a feature or turn on offline mode during an in-flight request. It must
  cancel locally, reject late responses and never automatically retry.
- Test offline, expired token, exhausted quota and unavailable model. Local search
  must still work; no fabricated caption or search refinement may be shown.

## Voice: ten trials per language

For each sentence below, test English, a natural Hindi equivalent, and the Hinglish
equivalent you would actually speak. Use your own translations; do not treat an
AI-generated expected transcript as a measured observation.

1. A dog on a beach.
2. Two people sitting indoors.
3. A person beside a red car.
4. Friends having dinner at night.
5. A child playing in a garden.
6. A bicycle on a road.
7. Sunset over mountains.
8. Flowers in a vase.
9. Only photos from last year. (follow-up)
10. Now show the beach ones. (follow-up)

Test microphone denial, missing offline language packs, cancellation, silence,
backgrounding and the 30-second recording limit. Cloud audio requires a separate
approval; there must be no silent network fallback from on-device recognition.

Record each trial locally:

```text
Language / spoken sentence:
On-device or approved cloud transcription:
Observed transcript:
Observed English query and filters:
Meaning preserved: Yes / Partly / No / Unknown
Expected filename(s), only if personally verified:
Actual Top 5 / relevant rank:
Caption factual errors, if applicable:
Latency / failure / notes:
```

Do not conflate transcription quality, query translation and MobileCLIP relevance.
Report them separately. Existing semantic-search judgments remain the retrieval baseline.
