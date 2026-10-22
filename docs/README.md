# Documentation Index

This index lists the repository's documents (apart from platform-scaffold and asset READMEs) and says what each one
is for.

- **Living documents** are kept current and carry dates when facts change: the root README, the project context,
  the evidence ledger, the file map, the contracts and this index.
- **Dated reports** are historical evidence. They are accurate for their date and are never rewritten; newer work
  gets a new dated report. Reports that once held personal identifiers carry a redaction note dated 2026-10-22;
  their measurements are unchanged.
- **Implementation is not device acceptance.** Check the current source and tests first, then the dated records for
  what was actually observed on a phone.

## For reviewers

A 15-minute reading path:

1. [Repository README](../README.md): what PixelSearch is, its status, the privacy model and the key measured
   results. About 4 minutes.
2. [Project context](PROJECT_CONTEXT.md): read §1 (what it is), §2 (status matrix) and §5.3 (how search works,
   traced in code). §9 is the prioritized known-issue register and §12 the next steps. About 5 minutes. It
   predates the schema v7 (KI-16) and FaceContract v2 commits of 2026-10-22, so where it says schema 6, a 100 px
   face minimum or KI-16 open, the evidence ledger and ADR-023 to ADR-025 are newer.
3. [Evidence ledger](EVIDENCE_LEDGER.md): every measured number with its date, device or host, precision and
   caveats, and the list of things never measured (§10). About 3 minutes.
4. [App architecture](../pixelsearch_app/docs/ARCHITECTURE.md): layers, state ownership, and the indexing and
   search flows. About 2 minutes.
5. The two contracts: [MobileCLIP interface contract](../model_kit/INTERFACE_CONTRACT.md) and
   [People/SFace face contract](../model_kit/FACE_CONTRACT.md). About 1 minute to skim.

Going deeper:

- [File map](FILE_MAP.md): one line per source, test, tool and doc file. Generated 2026-10-21; its git-state column
  describes the working tree of that day.
- [Architecture decision records](../pixelsearch_app/docs/ARCHITECTURE_DECISIONS.md): ADR-001 to ADR-025, newest
  first. The note at the top lists the records that no longer match the code;
  [project context §8](PROJECT_CONTEXT.md#8-decisions) gives the status of ADR-001 to ADR-022.
- [Architecture overview](architecture/README.md): a detailed source snapshot of 2026-09-18 with the editable
  diagram source `pixelsearch-all-in-one.eraser`.
- [Security review, 2026-09-18](SECURITY_REVIEW_2026-09-18.md): seven findings and their fixes.
- [Known issues](../pixelsearch_app/docs/KNOWN_ISSUES.md): KI-1 to KI-17 (see the note under Engineering history).
- [Product brief](../PRODUCT.md) and [design system](../DESIGN.md) for the 2026-09-18 redesign.

## Contracts

| Document | What it fixes |
|---|---|
| [MobileCLIP interface contract](../model_kit/INTERFACE_CONTRACT.md) | Model, preprocessing, tokenizer, ONNX names, dtypes and opset, and the version rules. ModelKit owns it. |
| [App mirror of the interface contract](../pixelsearch_app/docs/INTERFACE_CONTRACT.md) | Must stay identical to the ModelKit copy. |
| [People/SFace face contract](../model_kit/FACE_CONTRACT.md) | Face detection, alignment, the SFace descriptor and the grouping gate. Current id `sface-2021dec-mlkit-landmarks-v2` (2026-10-22, faces compared from 64 px; ADR-023). |
| [Database migrations](../pixelsearch_app/docs/MIGRATIONS.md) | The four version numbers, schema steps v1 to v7, and the re-index runbook (its §B is partly stale). |
| [`ai_contract.dart`](../pixelsearch_app/lib/core/ai_contract.dart) | The app's single Dart mirror of the contract versions and model geometry. |

## Setup and operations

- [Flutter app setup](../pixelsearch_app/README.md): toolchain, build, tests, models and fixtures.
- [Model provisioning for debug builds](PROJECT_CONTEXT.md#51-first-run-and-model-provisioning): copy the FP32
  files only; never provision `*_fp16.onnx` to a device.
- [ModelKit](../model_kit/README.md): MobileCLIP export and FP16 repair. Also the
  [retrieval metrics](../model_kit/eval/README.md) and the [parity gate](../model_kit/parity/README.md) (the latter
  carries a stale-claims note).
- [Backend setup and API](../enhancement_backend/README.md): the optional FastAPI broker, its endpoints, limits and
  local tests.
- [Online account setup](../pixelsearch_app/docs/ONLINE_ACCOUNT_SETUP.md): free-tier provider and hosting setup,
  checked 2026-09-09. Its status note lists what has changed since.
- [Android release signing](../pixelsearch_app/docs/ANDROID_RELEASE_SIGNING.md): operator-supplied keystore through
  four environment variables. No release-signed build has been made yet.
- [Benchmark harness](../pixelsearch_app/benchmark/README.md): the in-app timing harness.
- [Contributing](../CONTRIBUTING.md) and [security policy](../SECURITY.md).
- [Licence](../LICENSE) (all rights reserved, published for academic evaluation),
  [third-party notices](../THIRD_PARTY_NOTICES.md) and [citation metadata](../CITATION.cff).

## Evidence records

Dated reports, oldest first. All device work used the Vivo I2214 test phone (Android API 36) with MobileCLIP FP32
on CPU unless the report says otherwise. Numbers from these reports are collected, with caveats, in the
[evidence ledger](EVIDENCE_LEDGER.md).

| Date | Record | Scope |
|---|---|---|
| 2026-09-08 | [ANDROID_SMOKE_TEST_2026-09-08.md](../pixelsearch_app/docs/ANDROID_SMOKE_TEST_2026-09-08.md) | First FP32 model provisioning and smoke test on the phone: model hashes, load and inference times, first indexing runs, memory. |
| 2026-09-08 | [FOLDER_INDEXING.md](../pixelsearch_app/docs/FOLDER_INDEXING.md) | Folder-scoped indexing: behaviour, architecture and the device check. |
| 2026-09-08 | [SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md](../pixelsearch_app/docs/SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md) | Semantic search diagnosis and the diagnostics harness; records the KI-12 uninstall incident. |
| 2026-09-08 | [USABILITY_AND_SEARCH_PRECISION.md](../pixelsearch_app/docs/USABILITY_AND_SEARCH_PRECISION.md) | Startup fix, the lexical-bypass fix and label corrections; host replays on frozen phone vectors. |
| 2026-09-09 | [FIVE_FEATURE_IMPLEMENTATION_2026-09-09.md](../pixelsearch_app/docs/FIVE_FEATURE_IMPLEMENTATION_2026-09-09.md) | Implementation handoff for the timeline, explanations, map, captions and voice/assistant, before device checks. |
| 2026-09-09 | [ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09.md](../pixelsearch_app/docs/ANDROID_FIVE_FEATURE_ACCEPTANCE_2026-09-09.md) | Local acceptance of those five features on the phone, with data-preserving upgrades. |
| 2026-09-09 | [INDEXED_GALLERY_2026-09-09.md](../pixelsearch_app/docs/INDEXED_GALLERY_2026-09-09.md) | Indexed gallery and library-specific suggestions; 1,916 indexed photos. |
| 2026-09-09 | [ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md](../pixelsearch_app/docs/ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md) | Backend deployment and live assistant checks. |
| 2026-09-09 | [SPEECH_SEARCH_FOLLOWUP_2026-09-09.md](../pixelsearch_app/docs/SPEECH_SEARCH_FOLLOWUP_2026-09-09.md) | Offline speech setup and article scoring; holds the only judged retrieval metrics (2 queries). |
| 2026-09-10 | [OFFLINE_PEOPLE_2026-09-10.md](../pixelsearch_app/docs/OFFLINE_PEOPLE_2026-09-10.md) | Offline People (SFace) implementation and its host results. |
| 2026-09-10 | [NEW_FACES_2026-09-10.md](../pixelsearch_app/docs/NEW_FACES_2026-09-10.md) | New Faces naming and named-person search. |
| 2026-09-10 | [NEW_FACES_DEVICE_2026-09-10.md](../pixelsearch_app/docs/NEW_FACES_DEVICE_2026-09-10.md) | In-place install, the schema 6 migration and the Android SFace numerical check. |
| 2026-09-10 | [VOICE_MAP_TIMELINE_2026-09-10.md](../pixelsearch_app/docs/VOICE_MAP_TIMELINE_2026-09-10.md) | Voice search, the map's EXIF GPS pass (0 of 1,916 photos located) and calendar-day timeline events. |
| 2026-09-18 | [SECURITY_REVIEW_2026-09-18.md](SECURITY_REVIEW_2026-09-18.md) | Source security review: seven findings, their fixes and the accepted limits. |
| 2026-09-18 | [PEOPLE_VALIDATION_2026-09-18.md](../pixelsearch_app/docs/PEOPLE_VALIDATION_2026-09-18.md) | The first People review round on the phone; the gate failed (1 false join). A later round passed (ledger §6). |
| 2026-10-18 | [PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md](../pixelsearch_app/docs/PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md) | Name-search checklist, host results and a device baseline of counts; cases for the 2026-10-22 build were added and partly run that day. |
| 2026-10-22 | [PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md](../pixelsearch_app/docs/PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md) | People search build: host results, in-place installs and device acceptance; aggregate numbers only. |

Host model reports, generated by the parity and benchmark tests (the files carry no date; the ledger dates them):

| Date | Record | Scope |
|---|---|---|
| 2026-08-06 | [VALIDATION_REPORT.md](../model_kit/parity/VALIDATION_REPORT.md) | Golden validation on a real Flutter ONNX Runtime, host, FP32: 6/6 retrieval. |
| 2026-08-06 | [BENCHMARK_REPORT.md](../model_kit/parity/BENCHMARK_REPORT.md) | Host encoder load and embedding latency, FP32. Not device numbers. |
| 2026-08-07 | [SEMANTIC_SEARCH_REPORT.md](../model_kit/parity/SEMANTIC_SEARCH_REPORT.md) | Retrieval on the six parity probes (the basis of the 0.15 gate) and host query latency. |

## Engineering history

These documents record how the project got here. Each carries a dated status note at the top that names its stale
claims, and the older content below the note is kept unchanged as a record. The ADR log, the changelog, the known
issues and the test plan also take new dated entries. The full list of stale claims is in
[project context §10](PROJECT_CONTEXT.md#10-documentation-status).

| Document | What it records | Main stale point |
|---|---|---|
| [PROJECT_STATUS.md](../pixelsearch_app/docs/PROJECT_STATUS.md) | Milestone status up to 2026-09-09 | Lists M9 to M14 as pending; describes schema v3/v4. |
| [ROADMAP.md](../pixelsearch_app/docs/ROADMAP.md) | The original milestone plan | Unchanged since 2026-08-07; names M9 as current. |
| [CHANGELOG.md](../pixelsearch_app/docs/CHANGELOG.md) | Changes to 2026-09-08, plus two 2026-10-22 entries (People search; the review-ready cleanup with FaceContract v2 and schema v7) | Describes a label fallback that was removed; the changes from 2026-09-09 to 2026-10-18 are not recorded. |
| [RESEARCH_LOG.md](../pixelsearch_app/docs/RESEARCH_LOG.md) | Investigations and findings by date | Calls FP16 a validated on-device artifact, which is false. |
| [BENCHMARK_RESULTS.md](../pixelsearch_app/docs/BENCHMARK_RESULTS.md) | Host benchmarks | Claims FP16 was validated on a device (false); device sections still say PENDING. |
| [ARCHITECTURE_DECISIONS.md](../pixelsearch_app/docs/ARCHITECTURE_DECISIONS.md) | ADR-001 to ADR-025 | ADR-006 (two repositories) is superseded; ADR-015's early-cancel replay is defeated. ADR-018 to ADR-025 were added on 2026-10-22; the newest are ADR-023 (FaceContract v2), ADR-024 (schema v7) and ADR-025 (publication guardrails). |
| [KNOWN_ISSUES.md](../pixelsearch_app/docs/KNOWN_ISSUES.md) | Known issues KI-1 to KI-17 | KI-5, KI-8, KI-11 and KI-13 are stale. KI-16 is marked fixed (schema v7, 2026-10-22); KI-17 (Linux-only CI failures) is fixed on the branch but not yet confirmed on a Linux runner. |
| [TECHNICAL_DEBT.md](../pixelsearch_app/docs/TECHNICAL_DEBT.md) | Deliberate shortcuts TD-1 onwards | TD-11 says the device adapters were never run; TD-17 to TD-19 remain open. |
| [TEST_PLAN.md](../pixelsearch_app/docs/TEST_PLAN.md) | Tests added per milestone | Older sections are stale; the two 2026-10-22 sections at the top (the review-ready cleanup and People search) are current. |
| [INDEXING_ARCHITECTURE.md](../pixelsearch_app/docs/INDEXING_ARCHITECTURE.md) | M5 indexing engine design | WorkManager, empty-gallery and EXIF GPS claims. |
| [AI_CORE_REVIEW.md](../pixelsearch_app/docs/AI_CORE_REVIEW.md) | M4.6 review of `lib/ai/` | Pixel reads and the "dedicated isolate" claim. |
| [ENGINEERING_AUDIT_AND_ROADMAP.md](../pixelsearch_app/docs/ENGINEERING_AUDIT_AND_ROADMAP.md) | The 2026-09-08 engineering audit | Describes a lexical union that healthy semantic search no longer uses. |
| [SPIKE_REPORT.md](../model_kit/SPIKE_REPORT.md) | The 2026-07-24 MobileCLIP spike | Its resize description was superseded by the contract; FP16 was never accepted on Android. |

## Procedures

- [Device test checklist](../pixelsearch_app/docs/DEVICE_TEST_CHECKLIST.md): how to turn phone observations into
  reproducible evidence.
- [Five-feature device checklist](../pixelsearch_app/docs/FIVE_FEATURE_DEVICE_CHECKLIST.md): the checks behind the
  2026-09-09 acceptance (its status note explains which remain open).
- [People name-search acceptance](../pixelsearch_app/docs/PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md): the manual
  People checklist, also listed under Evidence records.
- [Scene search feedback](../pixelsearch_app/docs/SEARCH_DEVICE_FEEDBACK.md): what to record for each judged query.
- [Search evaluation](../pixelsearch_app/docs/SEARCH_EVALUATION.md): the in-app diagnostics workflow and judgment
  format (dated 2026-09-08; carries a stale-claims note).
- [Device evaluation script](../pixelsearch_app/tool/run_search_evaluation.ps1): needs PowerShell 7. It backs up
  the app's data, runs the device test with `--no-uninstall`, then reinstalls a debug build in place. Never run a
  bare `flutter test integration_test/... -d <device>` instead (KI-12).
- Schema changes follow the recipe in [Database migrations](../pixelsearch_app/docs/MIGRATIONS.md) and
  [Contributing](../CONTRIBUTING.md#4-database-migrations).

## Maintainer and AI-agent guides

- [Repository session guide](../CLAUDE.md): the non-negotiable rules, commands, current state and known traps.
  Its current-state section is dated; where it differs from the evidence ledger or the code, the ledger and the
  code win.
- [App operating guide](../pixelsearch_app/CLAUDE.md): the engineering contract for work in `pixelsearch_app/`.
- [ModelKit guide](../model_kit/CLAUDE.md): what ModelKit owns and must never change without a version bump.
- [Handoff pointer](../HANDOFF.md): a short map of entry points.
- [Contributing](../CONTRIBUTING.md): the same rules, condensed for human contributors.

## Archive

- [Initial implementation handbook](archive/initial-plan/PixelSearch_Mobile_Implementation_Handbook.md): the
  original plan, with its Word version and figures in `archive/initial-plan/`. It describes intentions, not current
  capabilities.
- [M6 handoff](archive/HANDOFF_M6.md): a frozen inventory from the M6 milestone. Its paths and status describe that
  snapshot, not the present repository.

College deliverables (reports, posters, presentations and renderings) are not part of this repository.
