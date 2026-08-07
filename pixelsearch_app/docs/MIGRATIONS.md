# MIGRATIONS

How PixelSearch evolves data and artifacts safely. Authoritative policy lives in
`INTERFACE_CONTRACT.md` §9; this file is the operational runbook.

## The four versions (recap)
| Version | Lives in | Bump triggers |
|---|---|---|
| `model_version` | contract / `AiContract` | model weights or architecture change |
| `embedding_version` | contract / `AiContract` / `EmbeddingRows.embeddingVersion` | model **or** image-preprocessing change |
| `artifact_version` | contract / `AiContract` / `preprocess_config.json` | any re-export of the physical files |
| `schema_version` | `AppDatabase.schemaVersion` | any DB table/column change |

## A. Database schema migrations (drift)
Keyed on `AppDatabase.schemaVersion` via a `MigrationStrategy`.

| From → To | Change | Migration step |
|---|---|---|
| 1 → 2 | add `EmbeddingRows.embeddingVersion` (default `'1'`) | `m.addColumn(embeddingRows, embeddingRows.embeddingVersion)` |

Rules: migrations are **additive and reversible-in-spirit** (never drop data on upgrade without a backup
path); every new `schema_version` gets a row here and a drift migration test (tracked in `TEST_PLAN.md`).

## B. Embedding regeneration (the re-index runbook)
Stored embeddings are keyed `(photo_id, model_id)` and tagged with `embedding_version`.

1. On launch, the indexer (M5) computes the **stale/missing** set: photos with no embedding row at the
   **current** `model_id` + `embedding_version` (`AppDatabase.photoIdsNeedingEmbedding`).
2. It re-embeds only that set, batched, in an isolate, resumably.
3. When `embedding_version` bumps, **every** photo becomes stale ⇒ a full, resumable re-index.
4. Re-embedding overwrites the prior vector in place; the row's `embedding_version` advances to current.

**Regenerate iff `embedding_version` changed.** Never re-index for a tokenizer-only change (query path
only), an identical re-export (`artifact_version` only), a schema migration, or an ANN-backend swap.

## C. Artifact re-provisioning
The model manager (M12) compares the device's `artifact_version` against the contract. On mismatch it
re-downloads the ONNX/vocab files and updates the stored `artifact_version`. This forces a re-index
**only if** `embedding_version` also moved.

Applied history: **v1 → v2** (2026-08-06) — text model patched with `Cast(int64→int32)` before ArgMax
for onnxruntime-1.15 compatibility. Embeddings identical; **no re-index** (ADR-012).

## D. Checklist when changing anything model-shaped
1. Update `INTERFACE_CONTRACT.md` (ModelKit) + bump the right version(s); mirror to Flutter.
2. Update `AiContract` constants to match.
3. If preprocessing/model changed: bump `embedding_version`, regenerate `reference_vectors.json`, re-run parity (§6).
4. If schema changed: bump `schema_version`, add a migration + row in §A + a migration test.
5. Update `CHANGELOG.md` and `RESEARCH_LOG.md`.
