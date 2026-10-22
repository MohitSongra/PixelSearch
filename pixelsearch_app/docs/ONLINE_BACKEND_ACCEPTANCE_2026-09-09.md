# Online backend acceptance - 2026-09-09

> **Redaction note (2026-10-22):** personal identifiers (names, the device serial, local paths, private photo filenames, backup names and APK/backup digests) were replaced with placeholders. Measurements are unchanged.

## Scope and data safety

- Physical device: Vivo I2214, API 36, serial withheld.
- Existing app used without rebuilding, reinstalling, clearing data, or indexing.
- Settings displayed 1,916 indexed photos at the start of testing.
- No gallery images or microphone recordings uploaded during this session.
- No ranking, weights, model artifacts, embedding version, database schema, or folder selection changes.
- Backend URL: `<render-service-url>`
- Search Assistant was already consented on the phone. Offline only was off; online captions, transcription, and map tiles were off. These consent settings were not changed.

## Verified deployment and privacy

[VERIFIED] Render Free web service was Live on commit `a4081f3` before testing. The HTTPS health endpoint reported configured=true and the pinned Qwen/Whisper models. A health response alone does not prove model availability.

[VERIFIED] The user's Groq Data Controls page showed Global ZDR enabled and Inference APIs ZDR enabled. No privacy/account setting or credential was changed.

[VERIFIED] Groq organization limits listed Qwen at 30 requests/minute, 1,000 requests/day, 8,000 total tokens/minute and 200,000 tokens/day. Default Project had no custom limits. The later request error revealed an additional 1,000 output-token/minute limit.

## Before-fix observations

| Observation | Actual outcome |
| --- | --- |
| Actual submitted text ` together indoors` (leading space) | Proposed English query `people together indoors`, filters `{}` |
| Groq log for that request, 22:55:13 IST | HTTP 200; 208 input tokens; 38 output tokens; provider latency 0.154096 seconds |
| Full sentence `two people sitting together indoors`, 22:57:23 IST | HTTP 429; phone displayed the generic quota message |
| Local search with the full sentence | 26 results displayed; relevance was not judged |
| Follow-up `only last year` with current full sentence, 23:02:47 IST | HTTP 429; no proposed date filter |

The first intended full-sentence entry was interrupted by a phone-view/input change; only the actual shorter submitted text above is evidence. It is not a sentence-preservation test. Provider latency is not phone end-to-end latency.

## Exact failure and correction

[BUG] The deployed backend requested `max_completion_tokens=2048` for every caption, rewrite and search-assistant completion. Groq's detailed 23:02:47 error said the request's expected output was 1,444 tokens against an enforced 1,000 output-token/minute limit. This was an oversized request, not evidence that the user exhausted the daily quota. Waiting or repeatedly pressing retry cannot reliably repair this configuration.

[VERIFIED] With explicit user authorization, commit `f38a72c79eff7758398d1cec31c9221e99dbc122` was pushed to `main`. Only these backend files were committed:

- `enhancement_backend/app.py`: shared output cap of 512 tokens; reject non-completed responses; expose the cap in health for deployment verification.
- `enhancement_backend/test_app.py`: backend contract suite and regression coverage for the output cap and incomplete responses.

The pinned models, prompts, authentication, consent requirements and no-automatic-retry behavior remain unchanged. A smaller output cap is a request-budget correction, not a semantic-ranking change or an accuracy claim. Long responses may still hit the cap and will fail closed instead of returning partial content. Normal aggregate rate limits still apply.

## Automated verification

[VERIFIED] Backend suite: 19 tests passed, with two upstream deprecation warnings. Tests use controlled provider responses; they do not count as live model measurements. No Flutter source changes were made in this session, so a new APK was not required.

## Live acceptance after deployment

[VERIFIED] Automatic Render deployment completed sufficiently to serve the new code: the live HTTPS health response now includes `max_completion_tokens: 512`. Models and configuration remained unchanged. Three subsequent authenticated assistant requests completed on the physical phone without the oversized-output rejection.

| Test | Actual outcome | Assessment |
| --- | --- | --- |
| Retry `only last year` with current query `two people sitting together indoors` | Same English scene query; proposed dates 2025-09-09 inclusive to 2026-09-09 exclusive | Transport/budget fix verified; calendar-year interpretation failed |
| `only photos from calendar year 2025` with same current query | Same English scene query; dates 2025-01-01 inclusive to 2026-01-01 exclusive | Correct explicit date proposal |
| Apply calendar-2025 proposal | Search screen showed the expected filters and `No close matches` | UI/filter application verified; does not prove no photos exist in that period |
| Undo last refinement | Date filter removed; full scene query retained; 26 results returned | Undo smoke check passed |
| New conversation | Current query emptied, undo disabled, prior proposal cleared | Session reset smoke check passed |
| Hinglish selected; `do log ghar ke andar saath baithe hain` | `two people sitting together inside a house`, filters `{}` | Meaning preserved in this one typed example; not a speech-accuracy measurement |
| Unauthenticated POST to deployed `/assistant` | HTTP 401, per-install token required | Authentication still enforced |

[BUG] The relative-date prompt did not define calendar-year versus rolling-year semantics. Schema validation accepts both valid ranges, so it cannot catch that interpretation error. Do not claim the generic `last year` follow-up passed. The rolling-year proposal was not applied. A follow-up should explicitly define temporal semantics and regression-test them; this turn deliberately shipped only the authorized output-budget fix.

[VERIFIED] Final phone Settings still showed 1,916 photos and the same four online-consent switch states. No new backup/hash comparison was performed because there was no phone upgrade or index operation. No photo relevance ratings were changed.

Private screenshots saved under `pixelsearch_app/local_evaluation/`:

- `online_assistant_first_response.png`
- `online_calendar_2025_proposal.png`
- `online_hinglish_translation.png`

## Remaining acceptance

- Define and fix relative-date interpretation, then expand the typed language and multi-turn acceptance set. One successful example is not general accuracy evidence.
- Caption generation and rewriting require a user-selected, approved photo and captions consent.
- Cloud transcription requires separate consent and a user-approved recording. Ten spoken utterances per language category remain unmeasured.
- A known geotagged original photo is still needed for positive map-marker testing.
- Semantic retrieval quality remains unresolved; this backend fix does not change local MobileCLIP ranking.
- The installed app collapses all HTTP 429 responses to a generic quota message; the backend also replaces provider retry timing with a fixed 60 seconds. Better safe error classification/retry guidance is a separate follow-up, not part of this request-budget fix.

Official limit semantics: https://console.groq.com/docs/rate-limits
