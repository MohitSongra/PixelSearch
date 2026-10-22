# PixelSearch: speech setup, article scoring and online onboarding

> **Redaction note (2026-10-22):** personal identifiers (names, the device serial, local paths, private photo filenames, backup names and APK/backup digests) were replaced with placeholders. Measurements are unchanged.

Date: 2026-09-09, Asia/Calcutta. Follow-up to the five-feature Android acceptance.

## Applied changes

### Offline speech

**[VERIFIED ROOT CAUSE]** The old implementation always requested `en-IN` for
English and `hi-IN` for Hindi/Hinglish. Vivo's native support query reports
`en-US` installed, while `en-IN` and `hi-IN` need downloading. Microphone
permission was already granted; permission alone did not solve this mismatch.

- Added native `support` and explicitly confirmed `download` operations using
  Android's on-device recognizer. No general/cloud recognizer fallback.
- New Offline speech setup dialog reports installed/pending/downloadable states;
  language variants can be checked and selected explicitly, not silently substituted.
- Saved `en-US` as the English choice in existing user preferences. Other
  preferences and online consent settings are retained.
- Downloads require explicit per-download approval and Offline only must be off.
  No cloud-transcription consent, photo or audio upload is needed for this action.
- Offline revocation cancels pending app work and ignores late completion. Android
  controls an already-started model download, so the confirmation explains that it
  may continue after the app closes. No promise of cancelling OS-managed bytes.
- Friendly errors replace raw PlatformException wrappers.

**[VERIFIED ON VIVO]** `en-US` displays Ready; `en-IN` and `hi-IN` display Download
available. Download controls are disabled while Offline only is on. Selected
English `en-US` through Use language. No downloads, recording or cloud requests
were initiated during these checks.
After the final backup/restart, reopened setup and confirmed it starts at `en-US`
and still reports Ready. Left the conversation sheet open with no recording active.

**[IMPLEMENTED BUT UNVERIFIED]** Successful speech/transcript quality, live language
download, and ten utterances per language category remain acceptance work. Hinglish
currently uses the Hindi offline recognizer; mixed-language fidelity is not assumed.
API 33 is required for the support check; API 34+ offers download completion
callbacks. Older supported paths report a request, not false completion.

### Article scoring

**[VERIFIED ROOT CAUSE]** Query terms were whitespace tokens and metadata matching
used substrings. The article `a` matched `WhatsApp Images`, creating lexical raw
score 1 even with no `dog` metadata. Max-lex normalization turned this into 1.0,
then the existing 0.25 weight added a misleading 0.25 contribution.

Added an explicit `ignoreArticles` ranking policy for semantic-hybrid retrieval.
It omits only `a`, `an`, `the` from the lexical signal. The complete sentence still
goes to MobileCLIP. Content words, relationships, negation and quantities remain.
No weights, cosine gate, Top-K, embeddings, tokenizer, model or indexing changed.
Keyword-only fallback remains unchanged. The `legacy_articles_experiment` preserves
the immediate previous behavior for comparisons. Existing older label-inclusive
historical experiments remain available.

**[VERIFIED MEASUREMENT]** Replayed all 24 saved Android query cosine traces using
current backup metadata and saved judgments. First asserted every stored embedding
byte/version/dimension matches the trace-era database. The replay uses the shared
production ranking function and existing evaluation metrics, not a new search
implementation. All 24 retained identical final ID ordering and candidate sets.

| Saved rated query | Saved judgments | P@5 before | P@5 after | Judged-pool nDCG@5 before/after |
|---|---:|---:|---:|---:|
| a dog | 20 | 0.20 | 0.20 | 0.43824449597567855 |
| a car | 21 | 0.40 | 0.40 | 0.3451913422468693 |

Other 22 queries have no saved judgments; no precision/nDCG claim is made for them.
These are non-exhaustive judged pools, not general accuracy. One retained dog
irrelevance judgment has historically ambiguous human/assistant provenance; this
replay uses existing saved ratings unchanged and makes no new relevance judgments.
Older notes saying only `a dog` has ratings are historical; the current saved file
also includes the 21 car judgments.

**[VERIFIED ON VIVO]** `a dog` still returns nine results. For the first result,
`<private photo A>`, the explanation now shows raw cosine 0.2073, normalized
semantic 0.5923, metadata 0.0000, weighted lexical 0.0000, and final score 0.4146
(previously 0.6646). Matching terms no longer contains `a`. Raw cosine is unchanged.

**[PARTIAL]** This removes incorrect scoring evidence; it does not improve the
measured ranking on this corpus, where the article boost was shared. It must not
be advertised as an accuracy improvement. Raw MobileCLIP relevance remains a
separate unresolved product issue. Other substring matches/normalization and the
uncalibrated gate remain subjects for evidence-based experiments, not blind changes.

Replay tool: `tool/replay_article_policy.dart` (opt-in host Flutter test).
Private inputs/output: `local_evaluation/article_policy_20260909/` including
`replay.json`. It reads the frozen baseline and existing relevance dataset;
nothing is written back to the phone's evaluation files.

### GPS and map

**[VERIFIED SOURCE AUDIT]** photo_manager 3.11.0 checks the granted location
permission and honors original-file requests; its scoped URI path supports
`MediaStore.setRequireOriginal`. No evidence was found that a permission-option
flag is secretly disabling the granted permission in this path.

The earlier 1,916 `missing` GPS observations remain unchanged. Added parser
regressions for nonzero degrees/minutes/seconds, southern/western signs, and
out-of-range coordinates. These are test fixtures, not measured real photo
locations. No coordinates or test photos were inserted into the phone library.

**[MISSING]** Positive physical map acceptance still requires an original accessible
photo whose Gallery details show GPS, plus explicit consent for map tiles. The
account guide describes how to supply one. No location is guessed or inferred.

### Accounts

The [account setup guide](ONLINE_ACCOUNT_SETUP.md) covers Groq signup/ZDR, Render
free signup, the GitHub publication prerequisite, exact deployment commands, server
secrets, per-install token separation, phone consent, and verification limitations.
No credentials were collected or created. No deployment, paid upgrade, commit or
push occurred. Cloud features remain default-off and not configured.

## Verification

- 142 Flutter unit/widget tests passed, including existing indexing/folder tests.
- Analyzer: no issues found.
- 14 backend contract tests passed; two upstream deprecation warnings.
- Final Android debug build succeeded in 26.5 seconds, then installed in place.
- Final APK: `build/app/outputs/flutter-apk/app-debug.apk`, 260,457,114 bytes.
- SHA-256: `<digest withheld>`.
- Signing compatibility checked; no uninstall, clear-data command or destructive
  test runner. Two incremental in-place builds were installed during this follow-up.
- Logs: `build/followup_tests.log`, `build/followup_analyzer.log`,
  `build/followup_apk.log`. UI observations used fresh Android snapshots, not a
  claim of Android Studio UI control.

Before each update, a fresh backup was taken with the app quiescent and audited:

| Backup | SHA-256 |
|---|---|
| `<private backup>` | `<digest withheld>` |
| `<private backup>` | `<digest withheld>` |

Both backups pass SQLite integrity; all database tables matched between them.
Existing 1,916 image embeddings, version 1 and dimension 512, remained present.
**[VERIFIED FINAL AUDIT]** Post-test archive:
`<private backup>`, SHA-256
`<digest withheld>`.
SQLite integrity is `ok`. Every table hash matches the pre-update snapshot;
both model files and both saved evaluation files also match exactly. All 1,916
photo/vector rows and 27 memories remain present. Structured comparison of the
preferences confirms the only addition is `offline_speech_locales.English=en-US`;
all pre-existing fields, including privacy choices and label corrections, match.
Audit output: `local_evaluation/after_speech_article_update.json`.

## Modified areas in this follow-up

- Android `MainActivity.kt`: on-device support/download bridge.
- `lib/data/offline_speech.dart`, `lib/features/search/offline_speech_setup.dart`:
  structured support states, consent-gated download and setup UI.
- `lib/features/search/conversation_sheet.dart`, `lib/data/user_preferences.dart`:
  chosen locale persistence and readable errors.
- `lib/data/search/search_ranking.dart`, `semantic_search_backend.dart`: articles
  policy, matched-evidence consistency and historical comparison.
- `test/offline_speech_test.dart`, `article_policy_test.dart`,
  `semantic_search_backend_test.dart`, `search_diagnostics_test.dart`,
  `five_feature_test.dart`: focused regression/fixture coverage.
- `tool/replay_article_policy.dart`, this report and account setup guide.

## Next user-assisted checks

1. Speak a short English query with the saved en-US option and report the exact
   editable transcript. Availability is verified, transcription quality is not.
2. Approve hi-IN/en-IN language downloads only when desired; recheck Ready before
   recording. Do not expect Hindi/Hinglish translation from MobileCLIP itself.
3. Create the two free accounts and enable Groq ZDR, without sharing secrets here.
4. Publish only reviewed backend files when explicitly authorized, deploy free,
   then validate text-only requests before approved private media uploads.
5. Supply a known-geotagged original for positive map testing and continue saved
   compositional-query relevance judgments before deeper retrieval changes.
