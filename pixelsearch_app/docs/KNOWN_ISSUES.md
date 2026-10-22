# KNOWN ISSUES

> **Status note (2026-10-21 audit):** Several entries are stale. KI-5 and KI-13 describe a lexical union with semantic candidates, but healthy semantic search now admits only the gated top-60. KI-8 says only `mobileclip_image.onnx` is checked, but the resolver tries fp16 first and then fp32. KI-11 (onboarding reappearing) is still listed as untriaged although onboarding completion is now persisted. The current prioritized register is `docs/PROJECT_CONTEXT.md` §9. Current state: [`docs/PROJECT_CONTEXT.md`](../../docs/PROJECT_CONTEXT.md); measured numbers: [`docs/EVIDENCE_LEDGER.md`](../../docs/EVIDENCE_LEDGER.md). The content below is kept unchanged as a historical record.

Ranked by severity. "Critical" = must be resolved before the dependent milestone is trusted.

## KI-14 (Open, coverage) - person search only covers assigned faces in processed photos (2026-10-22)
People search and similar-face suggestions use assigned faces (manual or automatic). On the test phone
People processing was paused by the user at 485 of 1,916 photos until 2026-10-22, when the user resumed it;
all 1,916 photos are now processed (backup B8: 2,642 detections, 397 with descriptors). Root cause of the same
person being listed many times: only 336 of 2,342 detections (at 485 photos) reach the 100 px SFace descriptor minimum
(`FaceContract.minFacePixels`); the other 2,006 have no descriptor, so face contract v1 (the phone's installed
build until the v2 install later on 2026-10-22) can never group or suggest them.
Duplicate detections are a minor factor (26 overlapping same-photo pairs, about 20
near-identical cross-photo pairs). The first review round failed (one false join); a backup taken on
2026-10-22 shows the later fresh round passed (validation 16 same / 4 different pairs, 0 false joins,
saved threshold about 0.462). That is a small holdout, not a general accuracy result.
On 2026-10-22 the user ran "Group similar faces" (ADR-020) with processing still paused. 266 faces were
assigned automatically (3 joined one named person; the rest formed 137 new unnamed groups, 142 groups in
total).
New faces went from 2,329 face entries to 1,402 to name, with 798 small or duplicate faces hidden behind
"Show small faces" (not deleted, still nameable). Under FaceContract v1 the suggestions screen then counted
1,994 unnamed faces as too small to compare; those needed manual naming. Grouping them needs a new
`FaceContract.id` with a lower minimum, a full re-scan and a new review round (built later on 2026-10-22 as
FaceContract v2; see the update below). The automatic grouping after a processing
pass (`applyGrouping`) never runs while paused; since the user resumed processing it runs after each full pass
(after the first one: 85 more automatic assignments, 127 to 152 groups, none added to a named person; New faces
then showed 1,497 to name; at 13:51 on 2026-10-22, after the v2 re-scan and the user's answers, the home
screen read 1,487 to name; a later viewing at about 14:50 the same day read 1,488 to name, and backup B14
shows that the viewing wrote nothing). Older docs that say the gate failed and the threshold is empty
describe the first round; since the v2 re-scan (backup B12, 2026-10-22; still empty at B13 and B14) the
threshold is empty again, because v1 review rounds cannot validate a v2 cutoff (see the update below).
The "Same person?" questions (ADR-021, 2026-10-22) also only cover faces with descriptors: the face asked
about is always at least the minimum size (only the confirmed face shown beside it may be smaller), so an
unnamed small face is never the subject of a question and still needs manual naming.
**Update 2026-10-22 (ADR-023):** at the owner's request `FaceContract` v2 lowers the minimum to 64 px. After the
re-scan, faces from 64 to 99 px get descriptors, so they can be suggested, asked about and, once a new review
round passes, grouped; faces under 64 px still need manual naming. Measured on the test phone (2026-10-22,
backups B11 to B12, after the v2 build was installed in place and every photo re-scanned): all 2,642 faces kept
their ids (0 new, 0 dropped); faces with a descriptor went from 397 to 864 (about 15 % to about 33 %), as 467
faces of 64 to 99 px gained one; 1,778 faces under 64 px still have none. The saved threshold was cleared
(about 0.462 under v1), so automatic grouping stays off until a review round under v2 passes; starting that
round and rating its pairs is the user's decision. See the evidence ledger.

## KI-15 (Low, by design) - person-query wording limits (2026-10-22)
"without X" excludes only photos where X's face is assigned. A saved name that is also a common word
(for example a flower or month) becomes a person filter until its chip is dismissed. In Hinglish, "me"
can mean "in" and is read as the device owner; dismiss the "You" chip, or use 'Search without "me"'
when nobody is marked This is me. Bare "I", "we" and "us" are not resolved, and mixed "and/or" wording
falls back to requiring everyone. Pre-existing and not by design: a name typed in a different script
from the saved one (for example Devanagari for a Latin-script name) is not matched, so the online guard
cannot recognise it either.

## KI-16 (Fixed 2026-10-22, schema v7) - an edited reviewed photo can be sampled into a new review
**Fixed (ADR-024):** review rows now store the reviewed photo ids (schema v7; the v6 -> v7 step fills them
from the faces that still exist), and the reviewed-photo set unions those ids with the old face join. The
former skipped bug test now runs and passes. On the test phone (2026-10-22) the migration filled both photo
ids on all 140 review rows (backup B12). Original description, kept as a record:
Pre-existing, found by the 2026-10-22 tests. `_reviewedPhotos` finds reviewed photos through their
current face ids, and face ids include the photo revision. After a reviewed photo is edited (a new
revision), that photo can be sampled again into a new review round (calibration or a fresh holdout),
which weakens the photo-disjoint guarantee of the validation gate. A proper fix stores the photo ids
with the review rows, which is a schema change and is not done. A skipped test in
`test/people_validation_recovery_test.dart` documents the bug. Mitigation: do not start a new review
after editing reviewed photos until this is fixed.

## KI-17 (Fixed 2026-10-22; confirmed on GitHub CI, pull request #1) - CI failed on Linux only
GitHub CI failed tests on the Linux runner that passed on Windows. Two causes, found by simulation on the
Windows host (2026-10-22) because the job logs need a GitHub sign-in: four widget-test files loaded the Windows
font `segoeui.ttf` as 'Roboto' only when it existed, so on Linux text used the wide FlutterTest font and
320 px layouts overflowed; and `modelkit_paths_test.dart` built Windows-only path literals. Both are fixed in
test code (`test/support/test_fonts.dart`, now used by five widget-test files, loads the bundled Manrope on
every host; the path test builds paths from the host root). A local Docker run of the fix (2026-10-22) failed
because Docker Desktop did not start. The first GitHub run of the fix (2026-10-22: Actions run 39760306942, pull
request #1, head `29b1862`, `ubuntu-24.04` runner) passed all four jobs, so the Flutter tests that failed there
before (3 of 328 at `4a7c81f`, the last of the four failing pushes to `main` before 2026-10-22) now pass. The CI
test count is not recorded (the job log needs a GitHub sign-in); the local Windows run at the same commit gave
535 passed, 1 skipped.

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
