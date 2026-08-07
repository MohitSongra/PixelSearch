# PixelSearch AI Operating Guide (ModelKit)

> ModelKit is the **source of truth** for the model contract. This repo owns
> `INTERFACE_CONTRACT.md`; the Flutter repo mirrors it. See the full operating
> guide in the PixelSearch (Flutter) repo — the summary below is the ModelKit-relevant slice.

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
