# PixelSearch

Android-first semantic search for a personal photo gallery. Describe a remembered
scene, or name people you have registered, and search the local index.
Core indexing, image/text embeddings, ranking and People data stay on the device.
Online enhancements require separate consent.

## Repository layout

| Directory | Responsibility |
| --- | --- |
| `pixelsearch_app/` | Active Flutter application, Android integration and app tests |
| `model_kit/` | Model export/repair, preprocessing contracts and parity/evaluation tools |
| `enhancement_backend/` | Optional FastAPI caption, rewrite, assistant and speech service |
| `docs/` | Documentation index and clearly separated historical plans |
| `tool/` | Repository maintenance and publication checks |
| `.github/workflows/` | App, backend, ModelKit and repository CI |
| `render.yaml` | Optional backend deployment configuration |

The obsolete `app/` prototype is no longer an application entry point. Its source
remains in Git history. Local documents, posters, renderings and private diagnostics
belong in ignored `output/`, `tmp/` and `pixelsearch_app/local_evaluation/`.

## Start developing

Use Flutter 3.44.7 / Dart 3.12.2 to reproduce the current lock file and CI baseline.

```sh
cd pixelsearch_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

Android is the primary runtime. The iOS, Linux and web scaffolds remain for platform
boundaries and development/testing; their presence is not a feature-parity claim.
The large MobileCLIP encoders must be provisioned separately. A successful APK
build alone does not make semantic search ready. See the [app setup](pixelsearch_app/README.md).

## Implementation and verification

- Local MobileCLIP image/text embeddings and exact cosine retrieval, followed by
  hybrid reranking and filters; visible keyword fallback when semantic search is unavailable.
- Incremental gallery indexing and SQLite/Drift persistence, with cancellation and resume.
- Local SFace descriptors, New Faces naming, aliases, corrections and person-aware queries.
  Automatic grouping requires a reviewed local calibration/validation gate.
- Indexed gallery, daily timeline, stories, EXIF location records and consented map tiles.
- Offline speech integration and optional approved online speech, captions and assistant requests.

These are implemented paths, not claims of universal accuracy or a finished public
release. Real named-person retrieval, spoken-language quality, positive GPS pins
and full-gallery processing still require acceptance on the target phone.
Recorded Android model acceptance uses FP32 CPU; FP16 exports are not a completed
accelerated rollout. See [the documentation index](docs/README.md) for dated evidence.

## Optional backend

The app performs its own search. The backend is not a remote gallery or vector database.
It receives only explicitly approved requests. Credentials belong in server secrets
and local secure settings, never source control.

See [backend setup and tests](enhancement_backend/README.md). Pushing to the branch
configured by Render may trigger that service's normal deployment workflow.

## Before committing

```sh
python tool/check_repository.py
python model_kit/eval/test_metrics.py
```

Also run Flutter analysis/tests and the backend contract suite. Preserve the lock
files, generated Drift source, model contracts, fixture data and SFace license.
Do not add device databases, face crops, gallery exports, installation tokens,
private keys, APKs or large MobileCLIP exports.

[Architecture](pixelsearch_app/docs/ARCHITECTURE.md) |
[Documentation](docs/README.md) |
[Handoff](HANDOFF.md)
