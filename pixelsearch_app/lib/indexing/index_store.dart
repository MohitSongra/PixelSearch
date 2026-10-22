import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../core/ai_contract.dart';
import '../data/local/app_database.dart';
import '../data/photo_repository.dart' show encodeVector;
import '../models/photo.dart' show PhotoSource;
import 'model/index_record.dart';
import 'model/indexed_item.dart';

/// The indexing engine's database gateway (DatabaseWriter + reader + checkpoints).
///
/// All writes are **batched inside a single transaction** (never one txn per
/// image), which is both fast and the unit of crash recovery: a batch either
/// fully commits or not at all, so an interrupted run simply re-processes the
/// items that never committed. Reconciliation reads a light projection.
class IndexStore {
  IndexStore(
    this._db, {
    this.modelId = AiContract.modelId,
    this.embeddingVersion = AiContract.embeddingVersion,
  });

  final AppDatabase _db;
  final String modelId;
  final String embeddingVersion;

  /// Projection for reconciliation: id + change-fingerprint + stored version.
  Future<List<IndexRecord>> indexedRecords() async {
    final rows = await _db.indexRecords(modelId);
    return [
      for (final r in rows)
        IndexRecord(
          id: r.id,
          mtimeMs: r.mtimeMs,
          byteSize: r.byteSize,
          embeddingVersion: r.embeddingVersion,
        ),
    ];
  }

  /// Persist a batch of processed items (photo rows + embeddings) atomically.
  Future<void> commitBatch(
    List<IndexedItem> items, {
    required int nowMs,
  }) async {
    if (items.isEmpty) return;
    final photos = <PhotoRowsCompanion>[];
    final embeds = <EmbeddingRowsCompanion>[];
    for (final it in items) {
      photos.add(_photoCompanion(it, nowMs));
      embeds.add(
        EmbeddingRowsCompanion.insert(
          photoId: it.asset.id,
          modelId: modelId,
          embeddingVersion: Value(embeddingVersion),
          dim: it.embedding.length,
          vector: encodeVector(it.embedding),
          createdAtMs: Value(nowMs),
        ),
      );
    }
    await _db.transaction(() async {
      await _db.upsertPhotos(photos);
      await _db.upsertEmbeddings(embeds);
    });
  }

  Future<void> deleteAssets(List<String> ids) => _db.deleteAssets(ids);

  // --- checkpoints (crash-recovery / resume, via the singleton IndexStateRows) ---
  Future<void> saveCheckpoint({
    required int total,
    required int embedded,
    int nowMs = 0,
  }) => _db.putIndexState(
    IndexStateRowsCompanion(
      modelId: Value(modelId),
      totalPhotos: Value(total),
      embeddedCount: Value(embedded),
      lastRunMs: Value(nowMs),
      modelReady: const Value(true),
    ),
  );

  Future<({int total, int embedded})> loadCheckpoint() async {
    final s = await _db.indexState();
    return (total: s.totalPhotos, embedded: s.embeddedCount);
  }

  PhotoRowsCompanion _photoCompanion(IndexedItem it, int nowMs) {
    final a = it.asset;
    final m = it.meta;
    return PhotoRowsCompanion.insert(
      id: a.id,
      source: PhotoSource.device.index,
      assetName: Value(a.assetName),
      dateMs: m.dateTakenMs ?? a.dateTakenMs ?? nowMs,
      lat: Value(m.lat ?? a.lat),
      lng: Value(m.lng ?? a.lng),
      album: Value(a.album),
      mtimeMs: Value(a.mtimeMs),
      byteSize: Value(a.byteSize),
      width: Value(m.width != 0 ? m.width : a.width),
      height: Value(m.height != 0 ? m.height : a.height),
      thumbPath: Value(it.thumbPath),
      labelsJson: Value(jsonEncode(it.labels)),
      facesJson: Value(jsonEncode([for (final f in it.faces) f.toJson()])),
      indexedAtMs: Value(nowMs),
      createdAtMs: Value(nowMs),
    );
  }
}
