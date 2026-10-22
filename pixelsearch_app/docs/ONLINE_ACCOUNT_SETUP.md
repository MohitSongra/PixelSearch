# PixelSearch: free online account setup

> **Status note (2026-10-21 audit):** This file says the backend is local and uncommitted. In fact it was committed (`a4081f3`, `f38a72c`) and deployed on 2026-09-09. The working tree adds uncommitted backend hardening (admission/body-limit middleware in `app.py`; `--limit-concurrency 32 --timeout-keep-alive 5` in `render.yaml`), which is not deployed. Separately, it adds an app-side origin-bound token (`backend_credentials.dart`), which is uncommitted and needs a new APK. Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record.
>
> **Update 2026-10-22:** the backend hardening (`b8c3310`) and the origin-bound app token were committed and
> merged into `main` through pull request #1 on 2026-10-22. Render redeploys the hardening if its auto-deploy is
> on for `main` (the setting lives in Render); whether it redeployed was not checked from here. The backend keeps
> the same environment variables and token check, so existing tokens keep working. In the app the token is now
> bound to its HTTPS origin, so re-entering it on the phone is still the user's step if online features are used.

Checked against provider documentation on 2026-09-09. Account screens, quotas and
model availability can change. Stop if a step requires a paid plan or a card.

## What you need

- **Groq:** optional caption generation, rewriting, translation/conversational
  refinement and cloud transcription.
- **Render:** runs PixelSearch's small backend without keeping your laptop on.
- **GitHub:** connects the backend code to Render; your existing account is enough.

Local image indexing, MobileCLIP embeddings, search, Timeline and saved captions
stay on the phone. OpenStreetMap tiles need separate consent, not a Groq account.
Android offline speech uses Android's own language resources, not either account.

Device check on your Vivo: `en-US` is installed and has been selected for English;
`en-IN` and `hi-IN` are reported as downloadable. The app remembers explicit
language choices. No download was initiated. Successful speech transcription
still needs a spoken device test.

## 1. Create your Groq account

1. Open [Groq Console](https://console.groq.com/) and complete sign-up/sign-in.
2. Stay on the **Free** organization/plan. Do not select a paid upgrade.
3. Open **Settings > Data Controls**. As the organization administrator, enable
   **Zero Data Retention** for the inference services. Keep optional data sharing
   disabled. Verify the actual setting before proceeding.
4. Open **API Keys** and create a key named `PixelSearch backend`. You can postpone
   creating the key until Render is ready so it can go directly into a server secret.
5. Keep the key private. Never put it in chat, GitHub, Flutter source, the APK,
   a screenshot or the phone's backend-token field. If exposed, revoke it and make
   a new one.

Groq documents that all customers can enable ZDR. ZDR does not remove operational
usage metadata. Details: [data controls](https://console.groq.com/docs/your-data),
[API quickstart](https://console.groq.com/docs/quickstart).

## 2. Create your Render account

1. Open [Render Dashboard](https://dashboard.render.com/) and sign up. Using your
   GitHub sign-in is convenient.
2. Choose a free workspace option. Do not add payment details or buy compute.
3. When connecting GitHub for deployment, grant access only to the repository
   needed for PixelSearch, not all repositories unnecessarily.
4. Stop here until the backend code has been reviewed and published to GitHub.
   Currently `enhancement_backend/` and `render.yaml` are local, uncommitted files;
   Render cannot deploy those laptop-only changes from GitHub yet.

No code was committed, pushed or deployed as part of writing this guide. Publishing
the reviewed backend should be a deliberate next step, not an accidental all-files
commit: private backups and gallery screenshots must never be included.

[Render first deployment](https://render.com/docs/your-first-deploy),
[free-plan limits](https://render.com/docs/free).

## 3. Deploy after the backend is published

Create **New > Web Service** using the PixelSearch GitHub repository and the branch
that contains the reviewed backend. The checked-in `render.yaml` is an alternative
Blueprint configuration for the same service. Confirm these settings:

| Field | Value |
|---|---|
| Runtime | Python |
| Root directory | `enhancement_backend` |
| Build command | `pip install -r requirements.txt -c requirements.lock` |
| Start command | `uvicorn app:app --host 0.0.0.0 --port $PORT --no-access-log` |
| Health-check path | `/health` |
| Instance type | **Free** |
| Python version | `3.12.9` via `PYTHON_VERSION` |

No database, persistent disk, cron service, paid worker or keepalive is needed.
Free web services can sleep after inactivity and cold-start later; this is a
prototype deployment, not a production uptime promise.

Enter these under the Render service's **Environment** settings:

| Server variable | What belongs here |
|---|---|
| `GROQ_API_KEY` | The private key created in Groq |
| `PIXELSEARCH_TOKEN_HASHES` | SHA-256 hash of a newly generated, unique phone access token |
| `GROQ_ZDR_CONFIRMED` | `true` only after verifying Groq's ZDR setting |
| `PYTHON_VERSION` | `3.12.9` |

The ZDR variable is an attestation, not a way of turning Groq's setting on.
The phone token is **not** the Groq key: it authorizes one app installation to
use your backend. Generate it privately during provisioning; store only its hash
on the server and the original token in the app's secure storage. The backend
[README](../../enhancement_backend/README.md) contains the generation procedure.
Do not paste either secret into this conversation.

After deployment, the service receives an HTTPS `onrender.com` address. `/health`
shows configuration/capabilities, but does not prove the live provider models work.
Initial pinned models remain `qwen/qwen3.6-27b` and `whisper-large-v3-turbo`.
Qwen is a preview model; unavailable capabilities must fail explicitly, not silently
switch models. [Current Groq models](https://console.groq.com/docs/models).

## 4. Connect the phone

1. Open PixelSearch **Settings > Enhancement backend**.
2. Enter the Render **HTTPS base URL**, without `/health` at the end.
3. Enter the unique **phone access token**, not the Groq API key.
4. Turn off the master **Offline only** setting only when ready for online use.
5. Enable individual consents only for features you approve. Turning off Offline
   only by itself does not consent to every enhancement.
6. Start with one text-only rewrite/refinement, then an approved photo caption or
   audio recording. Photo uploads require a preview and another approval.
7. If free quota is exhausted or a service fails, keep local search usable and
   retry explicitly later. Do not enable billing to bypass the failure.

Render and Groq process approved uploads off-device. Stripping photo metadata does
not conceal visible faces, text or other identifying content. Never upload private
photos just to test account connectivity.

## Offline speech setup

Open **Search > Voice and conversation > Offline speech setup** (voice-settings
icon). The dialog reports the recognizer's installed, pending or downloadable
language state. English variants can be checked explicitly; a different variant
is never silently chosen. `en-IN` is Indian English; `en-US` is US English;
`hi-IN` is Hindi. Hinglish still needs real utterance testing.

If a language is downloadable, turn off Offline only, reopen setup and approve
that specific download. You do not need to enable cloud transcription or upload a
recording. Android controls the language download and may continue it after the
app closes. Once status is Ready, select **Use language** and turn Offline only
back on if desired. Then test a spoken phrase and review the editable transcript.

If the service reports no downloadable language, update/configure the phone's
speech provider manually through its own settings. App permission alone cannot
install a missing language or guarantee that the device offers it.
[Android language-support API](https://developer.android.com/reference/android/speech/RecognitionSupport).

## Get a genuine GPS test photo

1. Use an original camera photo whose Gallery details show a location. Otherwise,
   enable location tagging in your camera with your consent, then take a non-private
   test photo and check its Gallery details. A screenshot is not a substitute.
2. Ensure its folder is among your selected indexing folders. Index the new photo
   without changing or clearing the existing index.
3. Open Map and run **Read photo locations**. Only new/changed revisions need reading.
4. Enable map-tile consent when ready; verify the marker against the location in
   Gallery, then tap it to open the photo.

Use the original file, not a copy that has lost location metadata during sharing.
No coordinates will be guessed or attached to existing photos. The 1,916-photo
library checked earlier returned missing GPS; this is not proof that every photo
elsewhere on the phone lacks GPS.

## What to report back

Tell us whether Groq and Render sign-in are complete and whether ZDR is enabled.
Share only the non-secret service URL after deployment, never any key/token.
For device acceptance, report the offline language status, an actual transcript,
and whether a known-geotagged photo appears at the correct location.
