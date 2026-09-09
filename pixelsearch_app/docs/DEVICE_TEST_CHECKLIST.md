# PixelSearch Device Test Checklist

Use this checklist with a real Android device. It turns device observations into
reproducible engineering evidence. Do not report only “search is bad”; capture
the query, expected scene, top results, and any relevant logs.

## Folder Selection

- Open Index from onboarding, Search and Settings; confirm the same picker appears.
- Select two small folders; verify the displayed count against each folder's gallery count.
- Confirm only new/changed selected photos are indexed and the run completes.
- Restart; verify saved checkbox choices and indexed photos survive.
- Deselect one folder and run again; its existing photos must remain searchable.
- Verify duplicate folder names can be distinguished by path.
- Under Selected Photos access, verify only permitted assets are candidates and no unlisted
  indexed rows are pruned. Denial or a missing selected folder must never fall back to All.
- Repeat with a folder larger than one 500-asset page; record completion and memory.

See `FOLDER_INDEXING.md` for the completed small-folder run and host regression coverage.

## Run Header

```text
Device / Android version:
PixelSearch build / Git commit:
Model used (from app/log, fp16 or fp32):
Permission selected: Allow all photos / Selected photos / Denied
Photos visible in the phone gallery:
Starting indexed-photo count:
Battery level / charging state:
Network state (not required, recorded only):
```

## 1. Gallery Coverage and First Index

Before starting, make sure photo permission is **Allow all photos**, not
Selected photos. Record the app's final count and these log lines if available:

```text
scan: N gallery assets discovered
plan: N to index, N to delete, N already up to date
run done: sent=N embedded=N failed=N deleted=N
```

| Check | Record |
|---|---|
| Phone-gallery image count | |
| Assets discovered by PixelSearch | |
| Planned for first index | |
| Indexed-photo count at completion | |
| Failed / skipped count | |
| Start time / finish time / elapsed | |
| Progress reached 100% | Yes / No |
| Count mismatch explained by Selected Photos, non-image media, or errors | |

Result: `PASS / FAIL / PARTIAL`

Notes:

## 2. Responsiveness and Resource Use

During a 10- to 20-minute indexing run, use the phone normally.

| Observation | Result |
|---|---|
| Can scroll the PixelSearch grid while indexing | Yes / No / sluggish |
| Can open Settings and press Cancel promptly | Yes / No; delay: |
| Can switch apps and return without a crash | Yes / No |
| Phone feels hot | none / mild / high |
| Battery drop during run | |
| Memory warning, crash, or Android “not responding” dialog | |
| Progress updates visibly move | smooth / bursty / frozen |
| App remains usable after 100 indexed photos | Yes / No |
| App remains usable after 500 indexed photos | Yes / No / n/a |
| App remains usable after 1,000 indexed photos | Yes / No / n/a |

Capture any stage-profile line, for example:

```text
profile over N assets: loadBytes ... decode ... thumbnail ... embed ... mlkit ...
```

Result: `PASS / FAIL / PARTIAL`

Notes:

## 3. Lifecycle, Cancellation, and Incremental Indexing

1. Start indexing, wait until several photos are complete, then press Cancel.
2. Re-open the app and resume indexing.
3. Add one known image and delete one known indexed image in the system gallery.
4. Re-index once more.

| Check | Expected | Actual |
|---|---|---|
| Cancel preserves completed work | Completed photos remain indexed | |
| Resume avoids reprocessing completed photos | Only remaining photos planned | |
| Added image appears after re-index | One new photo indexed | |
| Deleted image is removed | Removed from grid and vector index | |
| Screen-off behavior | Run resumes or explains pause | |
| App restart behavior | No corrupted index or crash | |
| Selected Photos permission | Count is limited but clearly explainable | |

Result: `PASS / FAIL / PARTIAL`

Notes:

## 4. ML Kit Metadata Sanity Check

Choose known images: a flower/plant, dog/pet, car/vehicle, food, a person, and
a landscape. Open each result after indexing.

| Image | Expected useful labels | Labels displayed | Useful? | Notes |
|---|---|---|---|---|
| Flower / plant | flower, plant, nature | | Yes / No | |
| Dog / pet | dog, pet, animal | | Yes / No | |
| Car / vehicle | car, vehicle, transportation | | Yes / No | |
| Food | food or dish-specific term | | Yes / No | |
| Person | person / face-related metadata | | Yes / No | |
| Landscape | scene-specific labels | | Yes / No | |

## 5. Semantic Search Evaluation

Use photos you personally know exist. For each query, assess whether the result
matches the **whole scene**, not just one word. Record the top five or ten
results by short description or photo ID.

```text
Query:
Known target photo(s):
Expected full scene:
Top results:
1.
2.
3.
4.
5.
Correct image found: Yes / No
Highest relevant rank:
Relevant / irrelevant observations:
Mode badge: Semantic / Keyword
Notes:
```

Run at least one query from each group below, substituting descriptions that
match your own gallery.

| Group | Example query | What to judge |
|---|---|---|
| Single object | `a dog` | Object retrieval |
| Single scene | `a sunset over mountains` | Scene retrieval |
| Object + action | `a dog running` | Action should change ranking |
| Object + location | `a dog on a beach` | Location should matter |
| Object + color | `a red car` | Color should matter |
| Object + time | `a restaurant at night` | Time/lighting should matter |
| Person + scene | `two people sitting at a restaurant at night` | Whole scene, not faces alone |
| Relationship | `my friend standing beside a red car` | Multi-object relationship |
| Complex scene | `a dog running on a beach during sunset` | Dog + action + beach + sunset together |
| Ambiguous contrast | `a dog indoors` versus `a dog on a beach` | Query change should alter ranking |
| Negative/weak query | `a blue object` or a query with no known target | Avoid confidently irrelevant results |

For every failure, report whether top results look like:

```text
Mostly semantic near-misses / mostly keyword-label matches / unrelated images /
empty result / keyword fallback / wrong model / unknown
```

## 6. Required Evidence for the Next Engineering Iteration

Send back:

1. This completed checklist.
2. A screenshot or copied indexing logs for one full run.
3. Ten to twenty completed semantic-query records, including at least three
   complex-scene failures or successes.
4. The device model, Android version, selected photo permission, and which model
   artifact the app logged as loaded.

That evidence will be converted into regression tests, profiling targets, and
measured retrieval experiments. It will not be treated as a claim until it is
recorded here.
