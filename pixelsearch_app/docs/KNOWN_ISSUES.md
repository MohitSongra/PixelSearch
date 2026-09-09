# KNOWN ISSUES

Ranked by severity. "Critical" = must be resolved before the dependent milestone is trusted.

## KI-12 (Critical testing safety) - device-test cleanup removed private app data
On 2026-09-08, a new semantic diagnostics integration test was run without `--no-uninstall`.
The installed Flutter version defaults to uninstalling the app at test cleanup. This removed the
144-photo private index, embeddings, thumbnails, saved folder scope and provisioned models. Original
gallery photos were untouched. The normal app and byte-identical FP32 models have been restored,
but the old index was not recovered; the user chose to select folders for rebuilding it.
Use the in-app diagnostics or the backup-first `tool/run_search_evaluation.ps1`, never a bare device-test
command on an existing library. See `SEARCH_QUALITY_DIAGNOSIS_2026-09-08.md` for the incident and limits.

## KI-13 (Open quality investigation) - scene retrieval needs judged evaluation
Production uses top-60 cosine >=0.15, a lexical union, cosine saturation at 0.35 and weights 0.70/0.25/0.05.
Short words match inside unrelated metadata words. The new diagnostic experiment and tests expose that
mechanism; its real scene-quality impact is unmeasured. No verified relevance labels were supplied, so
the model-versus-reranker question remains open. See `SEARCH_EVALUATION.md` for the 24-query template.

## KI-1 (RESOLVED 2026-08-06) — preprocessing constants verified against open_clip
The M4 preflight (`PixelSearch_ModelKit/preflight/`) introspected the real
`open_clip.create_model_and_transforms('MobileCLIP-S1','datacompdr')` transform:
`Resize(shortest→256, bilinear, antialias) → CenterCrop(256) → toTensor([0,1]) → Normalize(0,1)`, RGB/CHW.
A probe on RGB(128,64,200) returned exactly (128,64,200)/255 — pure [0,1] scaling, no mean/std.
**Every frozen contract value matched.** The contract (v1.1) now states the resize/crop semantics and
`antialias=true` explicitly (a clarification; no frozen value changed, reference vectors still valid).
Residual (low) risk: Dart bilinear+antialias must match torchvision closely — bounded and checked by
the §6 preprocessing-parity test in Phase 3.

## KI-2 (Open) - current sessions use CPU; FP16 execution is not accepted
`OnnxEncoder.load()` configures thread counts but registers no NNAPI or XNNPACK provider.
Android does not automatically enable those providers merely because an FP16 file is present.
The 2026-09-08 Vivo smoke test ran both FP32 encoders successfully on this current path.
FP16 requires validation with a compatible runtime/provider, including graph coverage and numerical
parity. See [the device report](ANDROID_SMOKE_TEST_2026-09-08.md); do not assume all CPU runtimes or
all accelerator configurations have the same FP16 capabilities.

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

**Partial source-level mitigation (2026-09-08):** `main.dart` now registers `indexCallbackDispatcher` through
an Android-only bootstrap, and `runBackgroundIndex()` now uses the same fp16-then-fp32 load-and-fallback
selection as foreground indexing. This makes the callback available once a task is scheduled, but no current
UI or policy schedules a job; the observed screen-off failure is therefore **not resolved**. Validate task
scheduling, retry, app restart, reboot, and screen-off behavior on hardware before claiming a background
solution. Aggressive OEM power management (ColorOS/MIUI/EMUI) may additionally require a foreground service
with a notification and a battery-optimization exemption prompt for long sweeps.

## KI-9 (High, device acceptance) — repaired fp16 artifacts still need Android validation
**Original defect, measured 2026-08-08:** the fp16 image export produced by
`onnxconverter_common 1.16.0` failed at *session creation*:

```
Type Error: Type (tensor(float16)) of output arg
(/visual/trunk/stages.3/blocks/blocks.0/token_mixer/Cast_output_0)
of node (.../token_mixer/Cast) does not match expected type (tensor(float)).
```

**Source repair, verified 2026-09-08:** ModelKit now uses ONNX Runtime's fp16 converter, topologically
sorts the graph, runs `onnx.checker`, and rejects any Cast whose declared output type differs from its
`to` attribute. The repaired v3 image and text graphs pass the checker; the image graph now creates a
CPU Runtime session; and two ModelKit regression tests cover conversion/session loading and idempotent
ArgMax patching. The fp32 export remains the verified reference at **cosine 1.000000,
max|err| 3.46e-07, ‖v‖ = 1.00000** on all six parity probes.

The desktop custom-image tester now intentionally selects the verified fp32 CPU models and was exercised
over 12 local photos: the query `a red sports car` returned `red_sports_car.jpg`. This is not an fp16
device result. The app resolver still falls through to fp32 if a preferred candidate fails to load.

**Remaining blocker:** the current app registers no accelerated provider, and Android FP16 execution
has not been accepted. The Vivo test on 2026-09-08 used FP32 successfully. Validate an explicitly configured
compatible provider, verify image and text FP16 session loading and inference, compare output to the FP32
reference, and run a fresh/incremental index before
allowing v3 to replace a populated fp32 index. `artifact_version` is now `3`; `embedding_version` remains
`1` pending that numerical acceptance.

## KI-8 (Medium, by design) — indexing needs the CLIP image model provisioned first
Per ADR-005 the fp16 encoders are not bundled. `runDeviceIndexing` checks for
`<app support>/models/mobileclip_image.onnx` and, when it is missing, returns `IndexRunStatus.modelMissing`
with the expected path — the UI reports it instead of crashing, and nothing is indexed. Until the M12 model
manager ships, the file must be placed there manually. Search degrades gracefully in the same situation
(keyword fallback, ADR-014); indexing cannot, because embeddings *are* the output.

**Device update 2026-09-08:** both FP32 reference files were manually installed on the Vivo I2214 with
matching host/device SHA-256 checksums. Both encoders executed, 140 photos were saved across two intentionally
cancelled runs, cold restart/resume skipped the first 103 saved photos, and a semantic query returned results.
The missing-model blocker is resolved for this
installation; first-run provisioning for other installations is still missing (M12).

## KI-11 (Observed, untriaged) - onboarding reappears after cold app restart
During the 2026-09-08 Vivo test, the onboarding screen reappeared after force-stop and launch,
despite 103 saved photos. Selecting Index my photos correctly resumed incrementally and preserved
the index. The source cause and intended onboarding persistence behavior were not investigated;
this is a UI-state concern, not evidence of database loss.
