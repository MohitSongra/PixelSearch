# Contributing to PixelSearch

PixelSearch is a final-year student project held to research-grade rules: measured results only, a frozen model
contract and no personal data in the repository. This page lists the rules that matter most when you change
something. The full rule set for maintainers is in the root [CLAUDE.md](CLAUDE.md), and the current state of the
project is in [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md).

## Before you start

- Use Flutter 3.44.7 / Dart 3.12.2 and keep `pubspec.lock`.
- Read [pixelsearch_app/docs/ARCHITECTURE.md](pixelsearch_app/docs/ARCHITECTURE.md) and the contract you are about
  to touch.
- Open an issue first for anything larger than a small fix.

## 1. Protect the phone's data (KI-12)

- **Never uninstall the app or clear its data** on a phone that holds a real index. The index, embeddings, People
  data and provisioned models live only in the app's private storage.
- **Never run a bare `flutter test integration_test/... -d <device>`.** Flutter uninstalls the app when the run
  ends. On 2026-09-08 this destroyed a 144-photo private index that could not be recovered.
- For device evaluation, use `pixelsearch_app/tool/run_search_evaluation.ps1` (Windows, PowerShell 7). It backs up
  first and passes `--no-uninstall`. The in-app search diagnostics are also safe.
- Upgrade an installed build only with `adb install -r`, the same signing key and a fresh backup. A release-signed
  build cannot replace a debug-signed install in place.
- Never copy a `*_fp16.onnx` file to a device. FP32 on CPU is the only accepted configuration.

## 2. The model contract is frozen

`model_kit/` is the source of truth. Any mismatch between ModelKit and the app is a critical bug.

- Do not change preprocessing, the tokenizer, the embedding size (512), the image size (256), normalization, ONNX
  input/output names or dtypes, or the opset without explicit approval, a version bump and re-verification of
  parity.
- Versions live in `pixelsearch_app/lib/core/ai_contract.dart`. Bump `embeddingVersion` (which forces a full
  re-index) **if and only if** the model weights or the image preprocessing change.
- Keep `model_kit/INTERFACE_CONTRACT.md` and `pixelsearch_app/docs/INTERFACE_CONTRACT.md` identical.
- Any change to the face pipeline needs a new `FaceContract.id` and an entry in `model_kit/FACE_CONTRACT.md`.

## 3. Code rules

- `pixelsearch_app/lib/state/providers.dart` contains **export lines only** (and `//` comments). No file in
  `lib/state/` may import it, in either the relative or the `package:` form. Import `people_providers.dart`
  directly.
- Indexing commits in batch transactions of 32, never one transaction per photo, and isolates per-photo failures.
- Heavy processing holds the SQLite processing lease. Search never takes it.
- Edit Drift table declarations and regenerate `app_database.g.dart`; never edit the generated file by hand.

## 4. Database migrations

Every schema change needs all of these in the same change:

1. An additive Drift migration step (never drop user data on upgrade).
2. The same bump to both `AppDatabase.schemaVersion` (`lib/data/local/app_database.dart`) and
   `AiContract.schemaVersion`.
3. A row in [pixelsearch_app/docs/MIGRATIONS.md](pixelsearch_app/docs/MIGRATIONS.md).
4. A migration test that upgrades a fixture of the previous version and checks that existing data is unchanged.

## 5. Search ranking

- The production constants are `topK` 60, gate 0.15, weights 0.70 / 0.25 / 0.05 and semantic band [0, 0.35]. They
  are policy constants, not calibrated values.
- Change the gate, the weights or the lexical policy **one at a time, and only with judged, held-out evidence**.
- Filters and person eligibility apply before Top-K. Search and the diagnostics screen must keep sharing
  `rankSearchCandidates`.

## 6. People rules

- There is **no default identity threshold**. Automatic grouping runs only after the user's photo-disjoint review
  round passes with zero false joins.
- Never change review ratings, and never delete review rows, to make validation pass.
- Suggestions only order faces; nothing is assigned until the user confirms that face. "Same person?" answers are
  the user's decisions. Code, tests and tools must never decide an identity for the user.
- Person names, faces and person filters never go online.

## 7. Online features

Online features default to offline-only and fail closed. Each needs its own consent, and photo or recording uploads
also need per-item approval. No redirects, no silent retries and no cloud fallback for on-device speech. Never put
provider keys or backend tokens in the app or the repository.

## 8. No personal data in the repository

The repository is public. Never commit:

- personal photos, face crops, face descriptors, gallery exports or device databases
- person names, GPS coordinates, device serials, local user paths or backup paths
- deployment URLs, share links, tokens, keys, `.env` files or keystores
- MobileCLIP ONNX exports, APKs or AABs (only the bundled SFace model is tracked)
- anything from `pixelsearch_app/local_evaluation/`

Use placeholders such as `<name>` or slot labels in tests and docs. Cite files and aggregate numbers instead of
private details. Before every commit, run:

```sh
python tool/check_repository.py
```

It checks the repository layout, the providers barrel and common shapes of private data. It cannot catch
everything, so review your diff as well.

## 9. Evidence and documentation

- Never fabricate a result. Record a measurement with its date, host or device, precision and sample size, and add
  it to [docs/EVIDENCE_LEDGER.md](docs/EVIDENCE_LEDGER.md).
- Dated reports (`*_2026-09-xx.md` and similar) are historical evidence. Do not rewrite their measurements; add a
  new dated report instead.
- Keep `docs/PROJECT_CONTEXT.md`, `docs/EVIDENCE_LEDGER.md`, `docs/FILE_MAP.md` and `docs/README.md` current, with
  dates, when the facts they describe change.

## 10. Checks before a pull request

```sh
cd pixelsearch_app
dart run build_runner build --delete-conflicting-outputs   # if you changed Drift tables
flutter analyze
flutter test test/
cd ..
python tool/check_repository.py
```

If you changed the backend, run its tests in the project virtual environment:
`cd enhancement_backend && .venv/Scripts/python -m pytest -q` (use `.venv/bin/python` outside Windows).

## 11. Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat(people): ...`, `fix(search): ...`,
  `docs: ...`, `test: ...`, `ci: ...`, `chore: ...`.
- **Stage explicit paths.** Never use `git add -A` or `git add .`: several local folders in a working copy are
  deliverables or private data and must not be committed.
- Keep code, its tests and its docs in the same commit, so every commit builds.
- Pushing to `main` can trigger a Render redeploy of the backend, if the operator's deployment follows `main`.
  Push only when you mean to.
