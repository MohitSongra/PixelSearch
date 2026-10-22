# PixelSearch Security Review and Repairs

Date: 18 September 2026. Baseline: `4a7c81f056188d20625432a27050dae02b871fe5`.

## Summary

This was a source review with local adversarial tests and targeted repairs, not a
certification or an exhaustive penetration test. The review covered the optional
FastAPI backend, Flutter online clients and consent state, token storage, Android
signing/backup configuration, People persistence and cleanup, native speech/image
entry points, indexed storage, and dependency/publication boundaries.

The concurrent redesign was preserved. Its author cleared the small credential
change in `online_settings.dart`; no layout, theme, font, navigation, or redesign
test edits belong to this security pass. Verification used a separate copy of the
baseline plus the security changes and the current online settings file.

No live provider requests, private-media uploads, phone installations, cloud
deployments, Git commits, or Git pushes were performed in this security pass.

## Findings Fixed

### [P1] Bind installation credentials to their server

Previously, changing the backend URL and leaving the token field blank reused
the global `backend_install_token`. The next approved request sent that secret
to the newly configured host. This required changing settings; no unsolicited
remote takeover or actual credential theft was observed.

The app now stores the token and canonical HTTPS origin together in secure
storage. A different host or port receives no request until its token is entered.
URLs with embedded credentials, query strings, or fragments are rejected again
at the transport boundary. Redirects remain disabled. Legacy tokens are not
automatically assigned to an unverified current URL.

Code: `pixelsearch_app/lib/data/enhancements/backend_credentials.dart`,
`enhancement_client.dart`, and `features/settings/online_settings.dart`.
Tests: `test/backend_credentials_test.dart` covers host/port changes, canonical
port 443, legacy re-entry, malformed storage, unsafe URLs, and zero HTTP calls to
a changed origin with the saved token.

### [P1] Admit uploads before parsing and bound received work

Authentication was a FastAPI endpoint dependency, which runs after request-body
parsing. An unauthenticated multipart upload could therefore consume parser and
temporary-file resources before rejection. The old size check inspected only
Content-Length. A synthetic ASGI request with length 1 and a body over 6 MiB
reached validation instead of being rejected at the byte limit. Network-level
handling of conflicting HTTP framing also depends on the server/proxy; this
test demonstrates the missing application boundary, not a verified proxy exploit.

ASGI admission now authenticates before reading a body, applies the existing
10-per-minute token quota on the event loop, permits only two active POSTs per
worker, and rejects excess requests immediately. Starlette's installed body-limit
middleware counts actual bytes across chunks, up to 6 MiB including multipart
overhead. A 60-second deadline bounds asynchronous request work. The deployment
command also limits Uvicorn connections/concurrency to 32 and keep-alive to 5 seconds.
Controlled errors carry `Cache-Control: no-store`; validation no longer echoes
the submitted text or invalid body.

Code: `enhancement_backend/app.py`, `requirements.txt`, `render.yaml`.
Tests: `test_security.py` proves no body reads or multipart parsing before 401,
actual-byte and multi-chunk limits, rejection without queuing, deadline handling,
capacity release after cancellation, and non-echoing errors. The initial
reproduction run had 12 failures across admission/error-handling checks; those
checks pass after repair.

### [P2] Remove debug signing from release builds

The release build type explicitly selected the debug signing configuration.
Release now uses a separate, externally supplied signing configuration. An
explicit prerequisite stops release packaging when credentials are missing,
including when Android omits its own validation task for an incomplete signing
configuration. Debug builds retain their existing signing behavior.

Code: `pixelsearch_app/android/app/build.gradle.kts`.
Verification: both the dedicated credential task and `:app:preReleaseBuild`
reject missing variables with a clear message. No signing key was generated.
See [release setup](../pixelsearch_app/docs/ANDROID_RELEASE_SIGNING.md).
Android documents why debug certificates are unsuitable for store releases in
[its signing guide](https://developer.android.com/studio/publish/app-signing).

### [P2] Remove biometric observations when indexed photos are deleted

`deleteAssets` removed photo/embedding rows but retained People observations and
scan records. Face vectors and cropped previews could remain until the next
People scan, including indefinitely while scanning was paused.

Deletion now also removes face/scan rows, dangling decisions/review pairs and
cover references, and invalidates calibration based on removed observations.
Names and unrelated faces are preserved. The production indexing disposal hook
reconciles People and prunes orphaned face crops regardless of whether People is
enabled or paused, while retaining the existing resource-disposal guarantees.

Code: `pixelsearch_app/lib/data/local/app_database.dart` and
`lib/indexing/adapters/indexing_wiring.dart`.
Tests: `test/people_repository_test.dart` checks paused-state deletion, preserving
unrelated faces/names, clearing stale calibration, and deleting orphaned crop
files without initializing a face model.

This is logical removal, not forensic secure erasure of SQLite pages, flash, OS
caches, or backups outside the app's control. Crop cleanup is best effort and
retryable on later indexing/scanning; an interrupted process cannot guarantee
immediate physical file removal.

### [P2] Handle malformed provider envelopes without server errors

Completion choices such as `null`/lists and non-object transcription replies
caused uncaught attribute errors. These cases now return controlled 502 responses
without exposing provider bodies, retrying, or accepting malformed content.

Code: `enhancement_backend/app.py` (`completion`, `transcribe`).
Tests: parameterized malformed-envelope tests in `test_security.py`, plus the
existing output-schema and incomplete-completion tests in `test_app.py`.

### [P2] Bound provider responses and total request time

The backend previously buffered the entire provider response, and its HTTP
timeout was not a total deadline for a response that kept slowly producing data.
Responses are now streamed with a 64 KiB decoded-body cap and a 45-second total
provider deadline. Invalid JSON/envelopes are rejected explicitly. Valid provider
responses still produce the existing API outputs.

Code: `enhancement_backend/app.py` (`groq`).
Tests: synthetic oversized, stalled, and successful streams in `test_security.py`.
The provider is a fixed HTTPS host; this is resilience against malformed upstream
responses, not evidence of an attacker-controlled provider or an observed attack.

### [P2] Bound map-tile downloads

Map downloads had an inactivity timeout but no total body-size/duration limit.
A steadily arriving oversized response could continue accumulating data.
The client now limits a tile to 2 MiB and the complete request to 20 seconds,
closes on a limit failure, and preserves consent cancellation and no-retry behavior.

Code: `pixelsearch_app/lib/data/enhancements/map_tile_client.dart`.
Tests: `test/map_tile_client_test.dart`, including a misleading Content-Length
and a slow continuous stream. The fixed OpenStreetMap HTTPS allowlist remains.

## Verification

| Check | Result |
| --- | --- |
| Flutter full suite, `--dart-define=SFACE_MODEL_TEST=true` | 337 passed; no skipped tests in the final run |
| Backend `pytest -q` | 51 passed; two upstream deprecation warnings |
| Flutter analyzer | No issues found |
| Android debug APK | Built successfully; not installed |
| Release credential prerequisite | Expected rejection without the four signing variables |
| Actual `:app:preReleaseBuild` prerequisite | Expected rejection through the same credential guard |
| Backend `pip check` | No broken requirements |
| Repository publication check | Passed |
| `git diff --check` | Passed; line-ending normalization notices only |

The Flutter verification ran in a separate local copy of the repository (path not
recorded).
Its final security run included the real bundled SFace model against the existing
synthetic OpenCV reference fixtures. This is a model-contract regression check,
not a face-recognition accuracy study on real people. The active redesign is
still changing independently, so this is not a certification of its future edits.

Dependency checks performed on 18 September 2026:

- `pip-audit` 2.10.1 checked all 24 packages in the backend lock file: no known
  advisories reported and no skipped packages in its JSON result.
- OSV's batch API checked 160 hosted Dart package name/version pairs from the
  resolved baseline: no advisories returned. Only public dependency metadata was
  transmitted, not application code, credentials, photos, or user data.
- A tracked-source scan found no matches for common Groq/OpenAI/GitHub/AWS key
  formats or PEM private-key headers. This was not an exhaustive secret detector
  and did not scan all Git history.
- `tool/check_repository.py` passed publication-boundary checks.

Advisory checks cannot establish the absence of unknown vulnerabilities. They did
not fully inventory bundled native code, Android Maven transitives, the OS, or the
remote hosting stack. The [OSV API documentation](https://google.github.io/osv.dev/api/)
describes the package/version lookup used here.

## Operational Follow-Through and Limits

1. Re-enter the per-install backend token in Settings once after updating the app.
   Tokens stay in platform secure storage, not preferences or source code.
2. Configure a private release keystore before creating a production release.
   Do not uninstall a debug installation to change certificates without first
   planning for the local data that uninstalling would remove.
3. These fixes are local source changes. Rebuild/install through the usual
   approved device workflow and redeploy the backend to activate them in use.
4. Server counters are per worker. Multiple workers/replicas need shared rate
   limiting. Upstream proxy upload/connection limits must also be configured;
   application middleware cannot protect a proxy that buffers first.
5. This review did not verify the live provider account's zero-retention setting,
   the deployed server revision, TLS/proxy configuration, or a live attack surface.
   Provider retention still depends on real account configuration.
6. Local SQLite metadata, vectors and thumbnails remain app-private data, not an
   independently encrypted vault. Revoking gallery permission is not a secure
   deletion operation for already indexed copies. Rooted-device/physical forensic
   resistance and a complete retained-data deletion policy require separate work.
7. Native decoder fuzzing, large-scale load testing, broad device/OS coverage,
   and a signed release installation were not performed. Face-recognition accuracy
   and semantic model quality are not proven by these security tests.
8. Existing Gradle/Kotlin migration warnings and two upstream Python test-client
   deprecation warnings were observed. Dependency migrations were not mixed into
   the concurrent redesign/security patches.
