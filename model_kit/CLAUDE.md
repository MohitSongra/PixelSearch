# PixelSearch AI Operating Guide (ModelKit)

> ModelKit is the **source of truth** for the model contract. This folder owns
> `INTERFACE_CONTRACT.md` and `FACE_CONTRACT.md`. The app mirrors the CLIP contract in
> `pixelsearch_app/docs/INTERFACE_CONTRACT.md`; keep the two copies identical. ModelKit was once a separate
> repository; it now lives in the same repository as the app. The full operating guide is
> `pixelsearch_app/CLAUDE.md`, and current state, safety rules and commands are in the root `CLAUDE.md` and
> `docs/PROJECT_CONTEXT.md` (audited 2026-10-21). The summary below is the ModelKit-relevant slice.

## Role & Principles
Principal Engineer / AI Engineer building PixelSearch to production + research-grade quality.
Offline First · Privacy First · Mobile First · Scalable · Maintainable · Research-Driven.
**Always think before coding.**

## What ModelKit owns
MobileCLIP export · ONNX artifacts · CLIP BPE tokenizer vocab · preprocessing constants ·
validation / parity vectors · benchmark artifacts. Flutter consumes these; it never redefines them.

## Never Change (without explicit approval + version bump + re-verification)
preprocessing · tokenizer · embedding size (512) · image size (256) · normalization ·
ONNX input/output names & dtypes · opset. Any drift between ModelKit and Flutter is a **critical bug**.

## Process
Understand → Analyze → Plan → Identify Risks → Implement → Review → Test → Document → Update Status.
**Never fabricate experimental results — only measured values.**

## Key files
`prepare_model.py` (regenerates everything, re-verifies), `INTERFACE_CONTRACT.md` (the frozen contract),
`preprocess_config.json` (constants), `reference_vectors.json` (parity target), `SPIKE_REPORT.md` (findings).
Also: `fp16_conversion.py` / `repair_fp16_exports.py` (fp16 v3 rebuild, ADR-016), `patch_text_argmax.py`
(ADR-012), `parity/` (reference embeddings, tokens and generated reports), `eval/` (Python metrics, the only
ModelKit CI job), `tool/sface_reference.py` (SFace fixtures).

## Facts verified 2026-10-21 (see `docs/EVIDENCE_LEDGER.md`)
- `out/*.onnx` are git-ignored. Local fp32 exports match the hashes provisioned on the test phone.
  fp16 v3 exists on the host but has **never** run on Android, and the app registers no execution provider.
- The pinned Python `onnxruntime==1.28.0` is not the app's runtime: the Flutter plugin bundles native ORT **1.15.1**.
  Host Python checks therefore do not prove device behaviour.
- `reference_vectors.json` `sim_matrix` is scaled by a matrix 1-norm (about 0.19 × cosine). Use argmax only;
  true cosines come from `parity/reference_embeddings.json`.
- `prepare_model.py` prints cosine only. The spike's max-diff figures and the int8 "1/6" result have no
  reproducing script in the repo.
