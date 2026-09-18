# PixelSearch enhancement backend

This is an optional, stateless service. Indexing, embeddings, search rankings and
gallery storage remain on the phone. It does not serve as a replacement search engine.

## Deployment status

A deployment and live assistant checks were recorded on 9 September 2026 in
[the acceptance report](../pixelsearch_app/docs/ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md).
That historical check is not a guarantee of current service availability. Automated
tests use mocked provider responses; broad caption and speech quality still need
explicitly consented device acceptance.

## Free-tier setup

1. Create/use a Groq **Free** organization without upgrading billing. In Data Controls,
   enable Zero Data Retention and keep training/feedback sharing disabled.
2. Create a Groq API key and set `GROQ_API_KEY` as a **server secret** on Render. Never
   put it in Flutter, Git, a screenshot, or a chat message.
3. Generate a unique random access token for each app installation. Store only its
   SHA-256 hash in the comma-separated server secret `PIXELSEARCH_TOKEN_HASHES`.
   Supply the original token to that installation through Settings > Enhancement backend.
4. Deploy `render.yaml` as a Render Blueprint, explicitly choosing the **Free** web
   service. Keep billing disabled; if free service is unavailable, stop rather than
   choose a paid tier. Deployment needs the implemented backend files in the selected
   repository/ref. Verify the deployed revision after each release.
5. Set `GROQ_ZDR_CONFIRMED=true` **only after** checking Groq's account-level setting.
   The flag is an operator attestation, not a mechanism that enables ZDR at Groq.
6. Set the resulting HTTPS base URL and per-install token on the phone. Online
   permissions start off. Enable only the features you consent to use.

Example token creation, run privately on the administrator's computer:

```python
import hashlib
import secrets
token = secrets.token_urlsafe(32)
print('Phone token:', token)
print('Server hash:', hashlib.sha256(token.encode()).hexdigest())
```

Removing a token's hash revokes that installation. Replacing the provider key does
not require rebuilding the APK. The backend limits each token to ten requests per
minute; Groq also enforces its own free limits. There is no automatic retry, paid
fallback, model substitution, persistent upload store or gallery API.

## API

| Endpoint | Input | Output |
|---|---|---|
| `GET /health` | none | configuration and declared capabilities; explicitly not live model verification |
| `POST /caption` | one multipart `file`, at most 4 MiB | factual caption and model ID |
| `POST /rewrite` | `text`, style `concise`, `social`, or `formal` | rewritten text and model ID |
| `POST /assistant` | `message`, current `query`, `filters`, `today`, `language` | English query, validated filters, optional clarification |
| `POST /transcribe` | one multipart `file`, at most 4 MiB | transcript and model ID |

Every POST requires `Authorization: Bearer <installation-token>` and Content-Length.
No photo IDs, filenames, inventory or embeddings are accepted by the assistant.
Dates are calendar dates; `until` is exclusive. Album/place phrases are resolved
against local metadata by the app, not against an uploaded gallery catalog.

Models are pinned to `qwen/qwen3.6-27b` and `whisper-large-v3-turbo`. Qwen's Groq
deployment is preview software. An unavailable/deprecated model returns 503; changing
the model requires an explicit implementation and evaluation, not a hidden fallback.
The Qwen request uses its documented non-thinking mode and JSON-object output;
this avoids spending the short response budget on reasoning text. This setting
still needs a live contract check with the configured free account.

## Local verification

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -c requirements.lock
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8787 --no-access-log
```

Tests use injected provider responses and cannot establish caption, translation or
speech accuracy. Do not test by sending private media without per-request consent.
The app requires HTTPS; plain localhost HTTP is only for backend developer checks.

## Limits and privacy

- Render free hosting sleeps when idle, has quotas and no production availability
  guarantee. Cold starts can take about a minute. The client has a bounded timeout
  and asks for explicit retry. No keepalive traffic is used to evade free-tier limits.
- Requests are processed off-device by Render and Groq. Metadata stripping is not
  photo anonymization; visible personal information remains visible.
- The backend re-encodes image uploads, does not save images/audio, and disables
  access/payload logging. Provider usage metadata and hosting infrastructure logs
  are not equivalent to a promise of zero metadata retention.
- Groq ZDR and API access must be checked in the real account before live testing.
- Free quotas, model availability and service terms may change. Public rollout
  needs a separate hosting/security review; do not market this as an SLA-backed service.

References: [Groq data controls](https://console.groq.com/docs/your-data),
[model availability](https://console.groq.com/docs/models),
[Render free hosting](https://render.com/docs/free).
