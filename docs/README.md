# Documentation Index

## Start here (living handbook, audited 2026-10-21, updated 2026-10-22)

- [Repository session guide](../CLAUDE.md): rules, commands, current state and traps.
- [Project context](PROJECT_CONTEXT.md): status matrix, traced workflows, decisions, known-issue register, next
  steps, unknowns and the status of every other doc.
- [Evidence ledger](EVIDENCE_LEDGER.md): every measured number, with date, device, precision and caveats;
  CI history; test counts.
- [File map](FILE_MAP.md): one line per source, test, tool and doc file.

These four handbook files were untracked at the 2026-10-21 audit; commit them together with this README and the
status notes that link to them.

Some older status docs in `pixelsearch_app/docs/` are stale against the code. The docs listed in
[PROJECT_CONTEXT §10](PROJECT_CONTEXT.md#10-documentation-status) carry a dated status note at their top, as do
`RESEARCH_LOG.md` and `ARCHITECTURE_DECISIONS.md`. Other older docs may still contain stale claims.

## Current entry points

- [App architecture](../pixelsearch_app/docs/ARCHITECTURE.md)
- [Flutter setup](../pixelsearch_app/README.md)
- [Backend setup and API](../enhancement_backend/README.md)
- [ModelKit](../model_kit/README.md)
- [MobileCLIP contract](../model_kit/INTERFACE_CONTRACT.md)
- [People/SFace contract](../model_kit/FACE_CONTRACT.md)
- [Database migrations](../pixelsearch_app/docs/MIGRATIONS.md)
- [Search evaluation](../pixelsearch_app/docs/SEARCH_EVALUATION.md)
- [Engineering audit and roadmap](../pixelsearch_app/docs/ENGINEERING_AUDIT_AND_ROADMAP.md)

## Implementation and acceptance records

Implementation is not the same as end-to-end device acceptance. Consult current
source and tests first, then dated reports for what was actually observed.

- [People implementation](../pixelsearch_app/docs/OFFLINE_PEOPLE_2026-09-10.md)
- [New Faces implementation](../pixelsearch_app/docs/NEW_FACES_2026-09-10.md)
- [New Faces device checks](../pixelsearch_app/docs/NEW_FACES_DEVICE_2026-09-10.md)
- [Voice, map and timeline checks](../pixelsearch_app/docs/VOICE_MAP_TIMELINE_2026-09-10.md)
- [Online backend acceptance](../pixelsearch_app/docs/ONLINE_BACKEND_ACCEPTANCE_2026-09-09.md)
- [Device checklist](../pixelsearch_app/docs/FIVE_FEATURE_DEVICE_CHECKLIST.md)

Newer records. **These files are untracked (not yet committed):**

- [Security review 2026-09-18](SECURITY_REVIEW_2026-09-18.md): seven findings. All fixes are uncommitted and the
  backend fixes are not deployed.
- [Architecture overview with diagrams](architecture/README.md). It contains third-party diagram share links; do not
  publish those links.
- [People validation 2026-09-18](../pixelsearch_app/docs/PEOPLE_VALIDATION_2026-09-18.md): the automatic-grouping
  gate failed on the device that day. A fresh 20-pair round passed later (backup of 2026-10-22).
- [People name-search acceptance](../pixelsearch_app/docs/PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md) (2026-10-18;
  unit-test results plus a device baseline of counts; the six manual acceptance steps were not recorded; cases 7–16
  for the 2026-10-22 build were partly run on the device on 2026-10-22; contains personal names, so review before
  publishing).
- [People search device acceptance 2026-10-22](../pixelsearch_app/docs/PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md):
  host results, in-place install and device acceptance on 2026-10-22, plus the user-requested grouping, the
  "Same person?" check, the user's own answers, the rounds build and the user's resumed People processing on the
  phone. Aggregate numbers only.
- [Android release signing](../pixelsearch_app/docs/ANDROID_RELEASE_SIGNING.md) (pairs with the uncommitted
  `build.gradle.kts` change).
- [Design system](../DESIGN.md) and [product brief](../PRODUCT.md) (2026-09-18 redesign).

Older milestone/status documents in the app docs retain useful engineering
history, but their test counts, deployment status and future-work lists can be
superseded by these later records. They are not release guarantees.

## Historical material

- `archive/initial-plan/`: original planning handbook and its figures.
- `archive/HANDOFF_M6.md`: frozen M6-era inventory. Paths and status describe that
  historical snapshot, not the present repository.

College deliverables and temporary renderings are local-only in ignored
`output/` and `tmp/`. They are intentionally absent from the source distribution.
