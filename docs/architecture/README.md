# PixelSearch: All-in-One Architecture

Source snapshot: **18 September 2026**, current working tree on base commit
`4a7c81f056188d20625432a27050dae02b871fe5`.

This architecture includes the security, redesign and People-validation changes
present at inspection time (2026-09-18). It documents source behavior, not a new claim
that every path has passed production or full-gallery acceptance. No application
source was changed to create it. No private gallery data, identities, tokens or
device measurements were included in the Eraser request.

## Deliverables

- `pixelsearch-all-in-one.eraser`: editable master diagram source; import it into Eraser to edit or render it.
- `../../output/architecture/`: generated request, response, image and verification records.
- Generated editor and image links are kept privately and are not published.

Verification: all 82 component nodes and 13 groups have unique identifiers;
every connector endpoint resolves. All 15 database tables and all five backend
routes in the inspected source are present. The final 2785-by-6762 PNG was
rendered by Eraser and visually inspected at full-canvas and close-up scales.
The free renderer watermark is retained. The diagram has not been saved into
an authenticated Eraser account on the user's behalf.

The master is a single zoomable engineering canvas. It is deliberately more
detailed than a presentation slide or A4 poster. Read the numbered boundaries,
then follow the lettered component groups. Solid arrows describe implemented
source paths; dotted links describe notes, logical associations or build/test
contracts, not additional data-transfer claims. Planned work is a separate panel.
Teal denotes phone runtime, green local persistence, gold optional online
processing and limitations, and gray offline engineering. Arrow labels name the
data or control relationship, not a mandatory execution order across every group.

## 1. Product and Ownership

PixelSearch is an Android-first Flutter/Dart application. Its core operation is
natural-language retrieval over a locally indexed personal photo gallery.
MobileCLIP scene embeddings, SFace identity embeddings and user-assigned names
are different data types and must not be conflated.

| Directory | Responsibility |
|---|---|
| `pixelsearch_app/lib/features/` | Screens, feature interaction and presentation |
| `pixelsearch_app/lib/widgets/`, `lib/core/` | Shared UI, theme, routing and model location |
| `pixelsearch_app/lib/state/` | Riverpod composition, lifecycle and reactive state |
| `pixelsearch_app/lib/domain/` | Search, People, gallery and memory policies |
| `pixelsearch_app/lib/data/` | Repositories, persistence, native adapters and online clients |
| `pixelsearch_app/lib/indexing/` | Planner, pipeline, ports and platform adapters |
| `pixelsearch_app/lib/ai/` | CLIP preprocessing, tokenizer and ONNX encoders |
| `pixelsearch_app/lib/evaluation/` | Local judgments, replay, reports and metrics |
| `pixelsearch_app/android/` | Android permissions, speech/image bridges and build configuration |
| `enhancement_backend/` | Optional FastAPI request broker, not a search service |
| `model_kit/` | Offline export, model contracts, fixtures and evaluation tooling |
| `.github/workflows/`, `tool/` | CI and repository publication boundaries |

Startup initializes Flutter and the Android WorkManager callback, then creates
the Riverpod scope and router. The indexed shell preserves Search, Timeline, Map
and Settings tab state. Onboarding handles initial setup; People, photo viewing,
captions, explanations and diagnostics are secondary experiences. Other platform
scaffolds do not establish feature parity; web has a keyword fallback, not the
Android native gallery and inference stack.

## 2. Gallery Indexing

1. `photo_manager` accesses Android MediaStore after image permission and folder
   selection. Partial-access visibility must not be mistaken for deleted assets.
2. The planner reconciles asset ID, modification time, byte size and embedding
   version, identifying new, changed, stale and deleted records.
3. A SQLite lease coordinates heavy indexing with People scanning.
4. The asset processor reads bytes, extracts EXIF, decodes once, writes a thumbnail,
   computes the scene embedding, and performs ML Kit labeling/face detection.
5. Photo metadata and embeddings are committed together in batches, default 32.
   Completed batches survive cancellation; corrupt assets are skipped and reported.
6. Deletion reconciliation removes related biometric observations, keeps review
   pairs so the calibration gate fails closed, and prunes crop files. Library and
   vector cache refresh after committed changes.

Heavy image decode/preprocessing and synchronous CLIP inference are still part of
the foreground app flow. Yielding between photos is not equivalent to moving the
whole pipeline to a worker. Drift's background database isolate and the SFace
worker are separate, implemented concurrency mechanisms. The WorkManager adapter
and bootstrap exist, but automatic production scheduling is not wired.

## 3. Scene Model and Search Contract

| Contract | Current implementation |
|---|---|
| Model | MobileCLIP-S1, `datacompdr`, ONNX runtime CPU |
| Image input | RGB, shortest-side resize to 256 with antialiasing, center crop 256, CHW, `/255`, float32 `[1,3,256,256]` |
| Text input | CLIP BPE, vocabulary 49,408; context 77; start 49,406 and end 49,407; int64 `[1,77]` |
| Shared representation | 512-dimensional L2-normalized scene vectors |
| Persistence | Versioned float32 little-endian blob, 2,048 bytes/vector |
| Index | In-memory exact brute-force cosine/dot scan; no FAISS, ANN server or cloud vector database |
| Model delivery | MobileCLIP files manually provisioned; vocabulary bundled; resolver prefers FP16 paths where usable, FP32 CPU is the accepted device baseline |

Typed text is debounced for 300 ms. Local name/alias resolution and structured
date, album and place filters produce eligible photo IDs. A multi-person query
requires every named person to be present. It does **not** exclude additional
people. A name-only query can return the identity-filtered set without CLIP;
combined people/scene queries apply the identity filter before semantic top-K.

The scene query is embedded, searched against eligible vectors, limited to 60
candidates and gated at raw cosine 0.15. Hybrid ranking uses configured weights
0.70 semantic, 0.25 lexical metadata and 0.05 face intent. Semantic strength is
clamped over cosine 0 to 0.35; lexical strength is candidate-normalized; deterministic
ties use recency and ID. These are implementation parameters, not accuracy claims.

Healthy semantic retrieval excludes ML Kit labels from candidate admission and
reranking, and does not admit lexical-only matches. Keyword fallback remains
explicit when the text model/index is unavailable. Empty queries browse the
library. Per-result evidence reports component scores, matching metadata and
People evidence. Older audit prose describing a lexical union is superseded by
the current `SemanticSearchBackend` policy.

## 4. People Recognition and Validation

People scanning is opt-in and operates on accessible, indexed photos. The Kotlin
decoder respects EXIF orientation and limits the prepared longest side to 2,048
pixels. ML Kit detects faces and five landmarks; it does not identify people.
Five-point alignment creates 112-by-112 RGB input for the separate SFace ONNX
model. A worker isolate runs FP32 CPU inference and validates its 128-dimensional
unit vector. The Apache-2.0 SFace artifact is bundled and hash checked.

New Faces lets the user provide names and aliases, including `me`, assign faces,
merge/hide identities and correct or dismiss suggestions. Low-quality/invalid
landmark cases do not silently become confident automatic identities. Manual
decisions are authoritative and naming remains usable without automatic grouping.

Automatic grouping requires a local calibration/held-out validation pass, not a
universal threshold from a blog. Reviews use Same/Different/Unsure judgments,
photo-disjoint subsets and both usable classes. The fixed threshold must satisfy
the implemented zero-false-join and nonzero-true-join checks in both stages.
Grouping is complete-link, excludes same-photo matches and does not automatically
merge established named groups.

The new recovery flow distinguishes attempted and deployable thresholds, exposes
failed pairs, archives old rounds, and can start 20 fresh unseen validation pairs.
Old judgments may inform calibration, but reused validation photos cannot count
as fresh approval evidence. Insufficient fresh evidence or inseparable calibration
does not enable automatic grouping. This is a validation gate, not a claim that
face recognition is infallible.

## 5. Other Local Experiences

- **Timeline:** calendar-day grouping, persistent memory membership, titles and
  cover choices; a local slideshow is implemented, a generated video reel is not.
- **Map:** permission-gated EXIF GPS and a revision-aware cache of location status;
  `flutter_map` displays local photo markers. Downloading basemap tiles is a
  separate online operation, not proof the entire Map feature is offline.
- **Voice:** Android API 33+ true on-device recognizer with installed language
  checks and model-setup support. English/Hindi/Hinglish transcripts are editable
  before use. Microphone permission and lifecycle cancellation are explicit; there
  is no silent fallback to network recognition.
- **Explainability:** local score evidence, original-photo viewing and label
  corrections. Label corrections are not a replacement for the CLIP embedding.
- **Diagnostics:** private query judgments, raw semantic replay, ranking/gate
  ablations, precision at K, known-positive recall and judged-pool nDCG. Partial
  judgments are marked and unsupported metrics withheld; no invented benchmark.

## 6. Complete Persistence Inventory

`pixelsearch.sqlite` is an app-private Drift native database, schema version 6,
created on a database background isolate. Fourteen Drift tables plus the raw SQL
lease table serve these roles:

| Table | Ownership / principal data |
|---|---|
| `photo_rows` | Gallery ID, descriptive metadata, dates/location, source revision, dimensions, thumbnail, labels and face metadata |
| `embedding_rows` | Composite photo/model key, embedding version, dimension and 512D scene blob |
| `index_state_rows` | Singleton model/index counts and last run |
| `indexing_preferences_rows` | All-folders flag and selected folder IDs |
| `memory_events` | Memory ID, title, cover and creation time |
| `memory_members` | Photo-to-memory membership |
| `saved_captions` | Photo revision, base/edited caption, style, model/provider and timestamps |
| `photo_locations` | Revision, coordinates, availability status and EXIF provenance |
| `people_persons` | User names/aliases, cover face and hidden state |
| `people_faces` | Photo/revision/contract, box/landmarks, 128D vector, quality, crop and assignment |
| `people_scans` | Photo revision/contract, scan status and completion |
| `people_decisions` | Face/person manual decisions |
| `people_reviews` | Face-pair judgments, similarity, contract and active/archived subset |
| `people_state` | Enable/pause state, generation, deployable threshold and calibration record |
| `processing_leases` | Heavy-work owner, expiry and heartbeat coordination |

Generated captions are saved separately from scene retrieval metadata. Saving or
rewriting a caption does not automatically regenerate the photo embedding.

Files contain thumbnails, People crops, model artifacts, vocabulary and local
diagnostic reports. Atomic `user_preferences.json` holds onboarding, consent,
speech settings and label corrections, not backend secrets. FlutterSecureStorage
holds the token and its exact backend origin. Temporary recorded audio is removed
when the flow completes or is canceled. Gallery originals remain in MediaStore.

Android backups/data extraction are disabled for private app data. This does not
mean the SQLite database is a separately encrypted vault or that file deletion is
forensic secure erasure.

## 7. Optional Online Data Flow

OnlinePolicy defaults offline-only with separate feature switches. Loading errors
fail closed; consent revocation changes a generation and cancels in-flight work.
The app uses HTTPS, an origin-bound token, bounded uploads/responses, deadlines,
and no redirect following or automatic request retries.

| Feature / endpoint | Data leaving the phone | What comes back |
|---|---|---|
| `POST /caption` | Only an approved selected image, resized to 1280 and metadata-stripped JPEG | Draft caption for review/edit/save |
| `POST /rewrite` | Caption text and requested style | Rewritten text |
| `POST /assistant` | Current message/query, structured filters, date and language | Typed scene query/filter proposal; user must apply it |
| `POST /transcribe` | One approved recording, maximum 30 seconds | Editable transcript |
| OSM tile GET | IP and requested map tile area | Basemap tile |

Named-person requests are kept out of the cloud assistant. The assistant does not
receive the complete photo library, face vectors, photo IDs, SQL access or the full
local conversation history. It proposes a local query; it does not search the
gallery remotely. OSM traffic is separate from the enhancement backend.

## 8. Optional Backend and Provider Boundary

FastAPI/Uvicorn on the configured Render service is a stateless broker with
`GET /health` and four POST endpoints. Health reports configured availability, not
a successful live provider transaction. Admission verifies SHA-256 bearer-token
hashes, limits requests per token (10/minute), limits active POSTs per worker (2),
caps the streaming body at 6 MiB and applies a 60-second request deadline.
Uploads are limited to 4 MiB; image decoding also has a pixel-safety bound and
re-encoding. Pydantic rejects unexpected fields. Responses use `no-store`;
access/payload logs and persistent gallery storage are not part of this broker.

Groq vision/text requests use the configured `qwen/qwen3.6-27b` model; speech uses
`whisper-large-v3-turbo`. The provider client applies a 45-second deadline and
64 KiB response bound with controlled failure responses. API keys and token hashes
are server-only. `GROQ_ZDR_CONFIRMED` is an operator assertion that needs actual
provider-account verification, not independent proof of retention behavior.

The security changes are present in this source snapshot. This task did not
redeploy the backend or verify its currently deployed configuration.

## 9. Engineering, Tests and Future Work

ModelKit exports MobileCLIP through PyTorch/open_clip to ONNX opset 17, validates
graphs and repaired FP16 artifacts, and supplies tokenizer/preprocessing/embedding
parity fixtures. Model/embedding compatibility governs re-index decisions.
MobileCLIP provisioning is manual; SFace and vocabulary have distinct bundle paths.

CI checks repository publication boundaries, Flutter analysis and unit/widget
tests, backend pytest contracts, and ModelKit metric tests. Real ONNX integration
tests need a supported host and artifacts; phone performance, large-gallery quality
and lifecycle acceptance require measured device runs. CI is not proof that those
acceptance checks are complete. This diagram task does not claim a fresh test run.

Remaining work is explicitly separate from implemented runtime: full indexing
worker isolation, background scheduling, automatic scene-model provisioning,
accelerated FP16 acceptance, deployment/release verification and full-library
acceptance. Relationship Graph, Emotion Search and generated video Highlight Reel
are roadmap items, not current capabilities. ANN should be justified by measured
scale rather than drawn as an already deployed component.

## Source Register

All paths below are relative to this repository. Source wins over old status prose.

| Source | Contribution |
|---|---|
| `README.md` | Repository ownership, baseline and platform scope |
| `pixelsearch_app/docs/ARCHITECTURE.md` | Layering and current runtime boundaries |
| `pixelsearch_app/lib/main.dart`, `lib/core/router.dart` | Bootstrap and navigation |
| `pixelsearch_app/lib/state/` | Riverpod ownership, search/indexing and consent lifecycles |
| `pixelsearch_app/lib/indexing/indexing_service.dart`, `asset_processor.dart`, `index_planner.dart` | Incremental planning, batch processing and persistence |
| `pixelsearch_app/lib/indexing/adapters/` | MediaStore, ML Kit, ONNX, WorkManager and wiring |
| `pixelsearch_app/lib/ai/onnx_encoder.dart`, `clip_tokenizer.dart`, `image_preprocess.dart` | Runtime CLIP tensors, preprocessing and sessions |
| `model_kit/INTERFACE_CONTRACT.md` | Scene embedding and model compatibility contract |
| `pixelsearch_app/lib/core/model_locator.dart` | Scene model resolution and provisioning limits |
| `pixelsearch_app/lib/data/search/semantic_search_backend.dart`, `search_ranking.dart`, `brute_force_vector_index.dart` | Candidate filtering, explicit fallback and exact retrieval |
| `pixelsearch_app/lib/domain/search/hybrid_scorer.dart`, `query_terms.dart` | Ranking and lexical policies |
| `pixelsearch_app/lib/domain/people/people_query.dart`, `face_grouping.dart` | Identity resolution and calibrated grouping |
| `pixelsearch_app/lib/data/people_repository.dart`, `lib/data/people/` | Recognition pipeline, persistence and review rounds |
| `pixelsearch_app/docs/PEOPLE_VALIDATION_2026-09-18.md` | New failed-pair and fresh-review behavior; no private examples exported |
| `model_kit/FACE_CONTRACT.md` | SFace shape, quality, licensing and validation contract |
| `pixelsearch_app/android/app/src/main/kotlin/com/pixelsearch/pixelsearch/PeopleImageDecoder.kt`, `MainActivity.kt` | Native image decoding and on-device speech bridge |
| `pixelsearch_app/lib/data/local/app_database.dart`, `people_tables.dart`, `processing_lease.dart`, `connection/connection_native.dart` | Exact table inventory, schema, leases and database isolate |
| `pixelsearch_app/lib/data/memory_repository.dart`, `location_repository.dart`, `offline_speech.dart` | Timeline, map metadata and speech |
| `pixelsearch_app/lib/features/viewer/`, `lib/features/search/`, `lib/features/map/`, `lib/features/timeline/` | Feature flows, output review and local experiences |
| `pixelsearch_app/lib/data/enhancements/` | Consent, credential binding, payload preparation and network limits |
| `pixelsearch_app/lib/data/user_preferences.dart`, `user_preferences_storage_io.dart` | Preference persistence and local corrections |
| `pixelsearch_app/lib/evaluation/retrieval_evaluation.dart`, `evaluation_runner.dart` | Honest local metrics and diagnostic replay |
| `enhancement_backend/app.py`, `render.yaml` | API routes, provider settings and security admission |
| `pixelsearch_app/android/app/src/main/AndroidManifest.xml`, `res/xml/` | Android permissions and backup exclusions |
| `.github/workflows/ci.yml` | Actual CI jobs and integration-test exclusions |
| `pixelsearch_app/docs/ENGINEERING_AUDIT_AND_ROADMAP.md` | Known limitations, read alongside newer source |
| `docs/SECURITY_REVIEW_2026-09-18.md` | Local security changes and deployment limitations |
| `https://github.com/eraserlabs/eraser-io` and installed `eraser-diagrams` skill | Eraser DSL and rendering/editor workflow only; no app claims |
