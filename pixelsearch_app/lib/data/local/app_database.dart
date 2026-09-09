import 'package:drift/drift.dart';

import 'connection/connection.dart';

part 'app_database.g.dart';

/// Photo metadata. Thumbnails are deliberately NOT stored here (they are
/// re-decoded on demand); this table is the durable index the AI core
/// (indexer + search) reads from and writes to.
class PhotoRows extends Table {
  TextColumn get id => text()();
  IntColumn get source => integer()(); // PhotoSource.index
  TextColumn get assetName => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get caption => text().withDefault(const Constant(''))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get dateMs => integer()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get place => text().nullable()();
  TextColumn get album => text().withDefault(const Constant(''))();
  IntColumn get createdAtMs => integer().withDefault(const Constant(0))();
  // M5 indexing metadata. (mtimeMs, byteSize) is the change-detection fingerprint;
  // labels/faces feed M6 hybrid ranking; thumbPath points at a cached file (not a blob).
  IntColumn get mtimeMs => integer().withDefault(const Constant(0))();
  IntColumn get byteSize => integer().withDefault(const Constant(0))();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();
  TextColumn get thumbPath => text().nullable()();
  TextColumn get labelsJson => text().withDefault(const Constant('[]'))();
  TextColumn get facesJson => text().withDefault(const Constant('[]'))();
  IntColumn get indexedAtMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One embedding per (photo, model). [vector] is a little-endian float32 BLOB
/// (512 × 4 = 2048 bytes) per INTERFACE_CONTRACT.md. Keyed by [modelId] so a
/// future model can coexist with the current one during a migration.
class EmbeddingRows extends Table {
  TextColumn get photoId => text()();
  TextColumn get modelId => text()();
  TextColumn get embeddingVersion => text().withDefault(const Constant('1'))();
  IntColumn get dim => integer()();
  BlobColumn get vector => blob()();
  IntColumn get createdAtMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {photoId, modelId};
}

/// Single-row indexing progress / coverage (id is always 0). Drives the M5
/// indexer and the settings/model-manager UI (M12).
class IndexStateRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get modelId => text().withDefault(const Constant(''))();
  IntColumn get totalPhotos => integer().withDefault(const Constant(0))();
  IntColumn get embeddedCount => integer().withDefault(const Constant(0))();
  IntColumn get lastRunMs => integer().withDefault(const Constant(0))();
  BoolColumn get modelReady => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-selected MediaStore folder IDs, independent of indexing checkpoints.
class IndexingPreferencesRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get allFolders => boolean().withDefault(const Constant(false))();
  TextColumn get folderIdsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [PhotoRows, EmbeddingRows, IndexStateRows, IndexingPreferencesRows],
)
class AppDatabase extends _$AppDatabase {
  /// The app passes nothing (uses the platform connection); tests inject an
  /// in-memory executor via `AppDatabase(NativeDatabase.memory())`.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v1 → v2: tag each embedding with the embedding_version that produced it.
      if (from < 2) {
        await m.addColumn(embeddingRows, embeddingRows.embeddingVersion);
      }
      // v2 → v3: M5 indexing metadata columns on photo_rows.
      if (from < 3) {
        await m.addColumn(photoRows, photoRows.mtimeMs);
        await m.addColumn(photoRows, photoRows.byteSize);
        await m.addColumn(photoRows, photoRows.width);
        await m.addColumn(photoRows, photoRows.height);
        await m.addColumn(photoRows, photoRows.thumbPath);
        await m.addColumn(photoRows, photoRows.labelsJson);
        await m.addColumn(photoRows, photoRows.facesJson);
        await m.addColumn(photoRows, photoRows.indexedAtMs);
      }
      if (from < 4) {
        await m.createTable(indexingPreferencesRows);
      }
    },
  );

  // --- Photos --------------------------------------------------------------
  Future<void> upsertPhotos(List<PhotoRowsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(photoRows, rows));

  Future<List<PhotoRow>> allPhotos() =>
      (select(photoRows)..orderBy([(t) => OrderingTerm.desc(t.dateMs)])).get();

  Future<int> photoCount() async {
    final c = countAll();
    final row = await (selectOnly(photoRows)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  // --- Embeddings ----------------------------------------------------------
  Future<void> upsertEmbedding(EmbeddingRowsCompanion row) =>
      into(embeddingRows).insertOnConflictUpdate(row);

  Future<List<EmbeddingRow>> embeddingsFor(
    String modelId,
    String embeddingVersion,
  ) =>
      (select(embeddingRows)..where(
            (t) =>
                t.modelId.equals(modelId) &
                t.embeddingVersion.equals(embeddingVersion),
          ))
          .get();

  Future<int> embeddingCount(String modelId, String embeddingVersion) async {
    final c = countAll();
    final row =
        await (selectOnly(embeddingRows)
              ..addColumns([c])
              ..where(
                embeddingRows.modelId.equals(modelId) &
                    embeddingRows.embeddingVersion.equals(embeddingVersion),
              ))
            .getSingle();
    return row.read(c) ?? 0;
  }

  /// Photo ids that lack a **current-version** embedding for [modelId] — the M5
  /// indexer's work queue. A NOT EXISTS anti-join keyed on model + version, so a
  /// version bump makes every photo stale (see MIGRATIONS.md §B). Cheap at scale.
  Future<List<String>> photoIdsNeedingEmbedding(
    String modelId,
    String embeddingVersion,
  ) async {
    final rows = await customSelect(
      'SELECT p.id AS id FROM photo_rows p '
      'WHERE NOT EXISTS (SELECT 1 FROM embedding_rows e '
      'WHERE e.photo_id = p.id AND e.model_id = ?1 AND e.embedding_version = ?2)',
      variables: [
        Variable<String>(modelId),
        Variable<String>(embeddingVersion),
      ],
      readsFrom: {photoRows, embeddingRows},
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  // --- M5 indexing gateway --------------------------------------------------

  /// Reconciliation projection: every stored asset with its change-fingerprint
  /// and the embedding_version it currently holds for [modelId] (null if none).
  Future<
    List<({String id, int mtimeMs, int byteSize, String? embeddingVersion})>
  >
  indexRecords(String modelId) async {
    final rows = await customSelect(
      'SELECT p.id AS id, p.mtime_ms AS mtime_ms, p.byte_size AS byte_size, '
      'e.embedding_version AS ev FROM photo_rows p '
      'LEFT JOIN embedding_rows e ON e.photo_id = p.id AND e.model_id = ?1',
      variables: [Variable<String>(modelId)],
      readsFrom: {photoRows, embeddingRows},
    ).get();
    return [
      for (final r in rows)
        (
          id: r.read<String>('id'),
          mtimeMs: r.read<int>('mtime_ms'),
          byteSize: r.read<int>('byte_size'),
          embeddingVersion: r.read<String?>('ev'),
        ),
    ];
  }

  /// Batch upsert embeddings in one statement (never one write per image).
  Future<void> upsertEmbeddings(List<EmbeddingRowsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(embeddingRows, rows));

  /// Remove assets and their embeddings atomically (deleted-photo handling).
  Future<void> deleteAssets(List<String> ids) async {
    if (ids.isEmpty) return;
    await transaction(() async {
      await (delete(embeddingRows)..where((t) => t.photoId.isIn(ids))).go();
      await (delete(photoRows)..where((t) => t.id.isIn(ids))).go();
    });
  }

  // --- Index state (singleton row, id = 0) ---------------------------------
  Future<IndexStateRow> indexState() async {
    final existing = await (select(
      indexStateRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (existing != null) return existing;
    await into(
      indexStateRows,
    ).insert(const IndexStateRowsCompanion(id: Value(0)));
    return (select(indexStateRows)..where((t) => t.id.equals(0))).getSingle();
  }

  Future<void> putIndexState(IndexStateRowsCompanion row) => into(
    indexStateRows,
  ).insertOnConflictUpdate(row.copyWith(id: const Value(0)));
}
