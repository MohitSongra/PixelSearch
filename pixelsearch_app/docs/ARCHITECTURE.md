# ARCHITECTURE

## Shape
A **fat on-device client** with an **optional, privacy-gated cloud** (off by default).
Everything required for search runs locally; the network is never on the critical path.

## Layers (clean architecture, feature-first)
```
Presentation   lib/features/*        screens + widgets, Riverpod-driven, no business logic
State          lib/state/*          Riverpod providers (StateNotifier / Provider)
Domain         lib/models/*         Photo (platform-free), value types
Data           lib/data/*          repositories, device gallery, search, local DB (M2)
Core           lib/core/*          theme, router, DI wiring
```
Cross-platform safety is enforced with **conditional imports** (`dart.library.io`):
the same public API resolves to a native implementation on mobile/desktop and a stub on web.
This is how the device gallery works today and how the M2 database connection works.

## On-device data flow (target, once the AI core lands)
```mermaid
flowchart LR
  subgraph Device
    G[Gallery / MediaStore] --> IDX[Indexer (isolate, batched)]
    IDX -->|image tensor 1x3x256x256| IMG[ONNX image encoder fp16]
    IMG -->|512-d L2-normalized| DB[(drift / SQLite\nphotos + embeddings)]
    Q[Query text] --> TOK[CLIP BPE tokenizer] --> TXT[ONNX text encoder fp16]
    TXT -->|512-d| S[Cosine search]
    DB --> S
    S --> UI[Ranked results]
  end
  DB -. optional, privacy-gated .-> CLOUD[FastAPI backend]
```

## Where each milestone plugs in
- **M2 (now):** the `(photos + embeddings)` store — the spine everything else reads/writes.
- **M4/M6:** the two ONNX encoders + tokenizer, implementing `INTERFACE_CONTRACT.md`.
- **M5:** the indexer isolate that fills `EmbeddingRows` in the background, resumably.
- **M6 (done):** real semantic cosine search (`SemanticSearchBackend` + `HybridScorer`) replacing `search_engine.dart`'s mock, with keyword fallback when the model isn't provisioned.

## Model provisioning
The fp16 encoders total ~171 MB and are **not** bundled in the APK. They are provisioned to
the device on first run (download or dev-push) and loaded **once** per session (`INTERFACE_CONTRACT.md` §7).
Until they are present, the app runs in keyword-fallback mode — the product is always usable.

## Persistence design (M2)
- `PhotoRows` — one row per photo (id, source, assetName, title, caption, tagsCsv, dateMs, lat, lng, place, album, createdAtMs). Thumbnails are **not** stored; re-decoded from the asset on demand.
- `EmbeddingRows` — `(photoId, modelId)` composite key; `dim`; `vector` BLOB (little-endian float32, 512×4 = 2048 bytes); `createdAtMs`. Keyed by `modelId` so a future model can coexist during migration.
- `IndexStateRows` — single-row progress/coverage record for the M5 indexer and the settings UI.

## Search layer (swap-stable)
Two seams keep search backends replaceable without disturbing the layers above them:

```
UI ── searchResultsProvider (AsyncValue) ── SearchBackend ─── (SemanticSearchBackend │ KeywordSearchBackend)
                                                  │ semantic = TextEmbedder → VectorIndex → HybridScorer
                                                  └── VectorIndex ── (BruteForceVectorIndex now │ SqliteVec/HNSW later)
```

- `SearchBackend` (`domain/search/`, **async** since M6 — ADR-014) — app-level strategy. On device the
  `SemanticSearchBackend` runs real CLIP; on web (or if the model isn't provisioned) `KeywordSearchBackend`
  is the fallback, and the semantic backend itself degrades to lexical on any model failure. The UI only ever
  watches `searchResultsProvider` (now an `AsyncValue`).
- `HybridScorer` (`domain/search/`, pure) — fuses CLIP cosine ⊕ lexical (tags/ML Kit labels/…) ⊕ face-intent
  into the final ranking (ADR-014). Fully unit-tested with no ONNX/IO.
- `VectorIndex` (`domain/search/`) — the ANN-swappable primitive. `BruteForceVectorIndex` does an exact
  cosine scan now; `SqliteVecVectorIndex`/ObjectBox can replace it behind the same interface with no
  caller change. Vectors are L2-normalized, so similarity is a dot product (contract §5). See ADR-009.

**M6 status:** real semantic search is wired end-to-end and verified on a real ONNX Runtime (6/6 retrieval).
On-device provisioning of the fp16 text model + live DB index warm-up is the remaining runtime step (shared
with the M5 indexer).
