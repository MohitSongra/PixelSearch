# KNOWN ISSUES

Ranked by severity. "Critical" = must be resolved before the dependent milestone is trusted.

## KI-1 (RESOLVED 2026-08-06) — preprocessing constants verified against open_clip
The M4 preflight (`PixelSearch_ModelKit/preflight/`) introspected the real
`open_clip.create_model_and_transforms('MobileCLIP-S1','datacompdr')` transform:
`Resize(shortest→256, bilinear, antialias) → CenterCrop(256) → toTensor([0,1]) → Normalize(0,1)`, RGB/CHW.
A probe on RGB(128,64,200) returned exactly (128,64,200)/255 — pure [0,1] scaling, no mean/std.
**Every frozen contract value matched.** The contract (v1.1) now states the resize/crop semantics and
`antialias=true` explicitly (a clarification; no frozen value changed, reference vectors still valid).
Residual (low) risk: Dart bilinear+antialias must match torchvision closely — bounded and checked by
the §6 preprocessing-parity test in Phase 3.

## KI-2 (Info, by design) — fp16 models don't run on plain CPU
fp16 encoders require an fp16-capable EP (NNAPI/XNNPACK). On a CPU-only fp32 runtime they won't
execute; that's why spike parity was validated at fp32. Not a bug; a device/EP requirement to honor in M4.

## KI-3 (Low, by design) — web build has no database backend
The M2 drift connection is native-only; on web the DB resolves to an `unsupported` stub. Web still
**compiles** (our sandbox verification path) but cannot persist. Acceptable while Android-first;
revisit with drift-wasm if web becomes a real target (TD-4).

## KI-4 (Low, informational) — reference sim-matrix magnitudes are small
Diagonal similarities in `reference_vectors.json` are ~0.05 due to the self-test's L1 normalization.
Retrieval is still correct (6/6 by argmax). Parity assertions must use **argmax/diagonal**, not absolute magnitude.

## KI-5 (Low, by design) — M6 semantic min-cosine is a small-sample heuristic
`SemanticSearchBackend.semanticMinCosine` defaults to 0.15, chosen from the 6-image parity set (min correct
0.198, max distractor 0.146). It favors recall and is **not** a validated operating point. On a real, diverse
library it may admit weak matches or (less likely) drop borderline ones. Principled precision/recall tuning
is M14 eval work. Mitigation today: it only gates the *semantic* candidate set; lexical hits are unaffected,
and ranking (argmax) is unchanged.

## KI-6 (Low, by design) — index warm-up is rebuilt per run, not incrementally during one
`indexWarmupProvider` loads embeddings from the DB into the in-memory `VectorIndex` in one pass.
`IndexingController` invalidates it when a run finishes, so photos indexed this session **are** searchable
without a restart. What is still missing is *in-flight* visibility: a search issued while indexing is running
won't see batches committed after the last warm-up. Wiring an incremental index-update hook off the indexer's
progress stream is a small follow-up (tracked in TECHNICAL_DEBT TD-13).

## KI-7 (Info, by design) — Android 13/14 "Selected Photos" legitimately caps what can be indexed
`PhotoManager.requestPermissionExtend()` can return **limited** access (`PermissionState.limited`) when the
user picks "Select photos" instead of "Allow all". Indexing then covers only the selected assets — that is
the OS honouring the user's choice, not a scan bug. The indexed count will be lower than the gallery count,
and re-running after granting full access picks up the rest incrementally. Distinguishing "limited" in the UI
(so the count is explained rather than surprising) is a small M12 improvement.

## KI-10 (High, device) — the OEM freezes the app when the screen turns off
**Observed 2026-08-08 on Realme RMX3092 / Android 12 (ColorOS).** Mid-index, with the screen off:

```
OplusHansManager: freeze uid: 10267 com.pixelsearch.pixelsearch pids: [...] scene: LcdOff
```

Indexing stops dead and does not resume until the app is foregrounded again. Nothing is lost —
reconciliation resumes from the last committed batch — but a full sweep currently requires the screen to
stay on for its whole duration, which for ~2900 photos is tens of minutes. Verified workaround while
testing: `adb shell svc power stayon true`.

Real fix: run indexing as background work rather than a foreground task. `WorkManagerScheduler` and the
`indexCallbackDispatcher` entrypoint already exist (M5, ADR-013) but `main.dart` never calls
`Workmanager().initialize(indexCallbackDispatcher)`, so the background path is unreachable. Aggressive
OEM power management (ColorOS/MIUI/EMUI) additionally needs a foreground service with a notification for
long sweeps, plus a battery-optimisation exemption prompt.

## KI-9 (High, blocking fp16 production) — the fp16 image export does not load
**Measured 2026-08-08** on a freshly regenerated `out/` (`onnxconverter_common 1.16.0`,
`onnxruntime 1.28.0`, `onnx 1.22.0`). `mobileclip_image_fp16.onnx` fails at *session creation*:

```
Type Error: Type (tensor(float16)) of output arg
(/visual/trunk/stages.3/blocks/blocks.0/token_mixer/Cast_output_0)
of node (.../token_mixer/Cast) does not match expected type (tensor(float)).
```

`float16.convert_float_to_float16(..., keep_io_types=True)` rewrote the tensor to fp16 but left the
node's declared/value_info type at float — an invalid graph, so it is rejected before any inference.
This is a **conversion defect, not a weights or preprocessing problem**: the fp32 export from the same
run reproduces the frozen reference at **cosine 1.000000, max|err| 3.46e-07, ‖v‖ = 1.00000** on all six
parity probes.

Mitigation in the app: the model resolver tries candidates in preference order and falls through on a
**load failure**, not merely on absence, so a device with both artifacts installed runs on fp32 and says
so in the log and in the UI ("… via mobileclip_image.onnx (fp32, 86.6 MB)"). Cost of the fallback is
size and speed (87 MB vs 44 MB, fp32 kernels), not accuracy.

Pay down in ModelKit: pin/patch the fp16 converter (e.g. re-run shape inference after conversion, or
convert with `onnxruntime.transformers.float16`), then re-verify against `parity/reference_embeddings.json`
before restoring fp16 as the shipped image artifact. The fp16 **text** encoder has not been re-verified
yet — the ADR-012 ArgMax patch was still running when this was recorded.

## KI-8 (Medium, by design) — indexing needs the CLIP image model provisioned first
Per ADR-005 the fp16 encoders are not bundled. `runDeviceIndexing` checks for
`<app support>/models/mobileclip_image.onnx` and, when it is missing, returns `IndexRunStatus.modelMissing`
with the expected path — the UI reports it instead of crashing, and nothing is indexed. Until the M12 model
manager ships, the file must be placed there manually. Search degrades gracefully in the same situation
(keyword fallback, ADR-014); indexing cannot, because embeddings *are* the output.
