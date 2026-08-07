# ROADMAP

Milestone-by-milestone path to a production-quality MVP. We do not skip milestones and
do not redesign completed work (per `CLAUDE.md`).

## Sequence
```
M0 scaffold ─ M1 gallery ─ M3 UI shell ─ [mock search]        ✅ shipped for review
        │
        └─ ModelKit spike (export+verify MobileCLIP)           ✅ de-risked
                │
   M2 persistence (drift: photos + embeddings)                 ✅ done
        │
   M4 Dart CLIP (ONNX image+text + BPE tokenizer)              ✅ done (real-ORT parity)
        │
   M5 background indexing (isolate, batched, resumable)        ✅ core done; device runtime pending
        │
   M6 real semantic search (CLIP cosine + hybrid, kw fallback) ✅ done (real-ORT 6/6)
        │
 ► M9 filters ─ M10 timeline-from-DB ─ M11 real map            ◄── current
        │
   M12 model manager + privacy ─ M13 optional cloud ─ M14 faces + eval
```
> **Renumber note:** on-device semantic search shipped as **M6** (earlier drafts
> of this roadmap numbered it "M7"; M4 and M6 were the Dart-CLIP + search pair).

## Current milestone — M9: filters over the store
**Goal:** date / place / album / people facets that refine both M6 search results and the browse view,
sourced from the DB + the M5 indexing metadata (labels/faces/EXIF), behind the existing search seam.

M0–M6 are complete — see `PROJECT_STATUS.md` for the authoritative per-milestone ledger and evidence.
The search stack that M9 builds on: `SearchBackend` (async, ADR-014) → `SemanticSearchBackend`
(`OnnxTextEmbedder` + `VectorIndex` + `HybridScorer`), with `KeywordSearchBackend` as the fallback.

**M9 plan (sketch)**
1. A `SearchFilters` value object (date range, place, album, hasFaces) threaded through the results provider.
2. Apply filters as a post-rank predicate first (cheap); push down into DB queries when the corpus is DB-backed.
3. Filter chips in the search UI; empty-query browse also respects filters.
4. Tests: filter predicate units + a widget test; no change to the model contract.

**Definition of done (every milestone):** analyzer clean · unit tests green · `flutter build web`+linux pass · docs updated.

## Guiding constraints (all milestones)
10k–50k photos on mid-range Android · never block the UI · load ONNX once · isolates for heavy work ·
ModelKit is the source of truth for anything model-shaped.
