import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/local/processing_lease.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v5 to v6 is additive and preserves every previous table byte-for-byte',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      final old = AppDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await old.upsertPhotos([
        PhotoRowsCompanion.insert(
          id: 'retained',
          source: 1,
          dateMs: 42,
          mtimeMs: const Value(11),
          facesJson: const Value('[{}]'),
          labelsJson: const Value('["person"]'),
        ),
      ]);
      await old.upsertEmbedding(
        EmbeddingRowsCompanion.insert(
          photoId: 'retained',
          modelId: 'MobileCLIP-S1',
          dim: 512,
          vector: Uint8List.fromList(List.generate(2048, (i) => i % 256)),
        ),
      );
      await old.customStatement(
        "INSERT INTO index_state_rows VALUES (0, 'MobileCLIP-S1', 1916, 1916, 77, 1)",
      );
      await old.customStatement(
        "INSERT INTO indexing_preferences_rows VALUES (0, 0, '[\"camera\"]')",
      );
      await old.customStatement(
        "INSERT INTO memory_events VALUES ('event', 'User title', 'retained', 1)",
      );
      await old.customStatement(
        "INSERT INTO memory_members VALUES ('retained', 'event')",
      );
      await old.customStatement(
        "INSERT INTO saved_captions VALUES ('retained', 11, 'Base', 'Edited', 'model', 'groq', 'factual', 1, 2)",
      );
      await old.customStatement(
        "INSERT INTO photo_locations VALUES ('retained', 11, 19.0, 72.0, 'located', 'EXIF GPS')",
      );
      await old.close();
      // The eight pre-existing tables are unchanged in v6. Remove only additions
      // to exercise the real migration starting from an actual v5 layout.
      for (final name in [
        'people_persons',
        'people_faces',
        'people_scans',
        'people_decisions',
        'people_reviews',
        'people_state',
        'processing_leases',
      ]) {
        raw.execute('DROP TABLE $name');
      }
      raw.execute('PRAGMA user_version=5');
      const names = [
        'photo_rows',
        'embedding_rows',
        'index_state_rows',
        'indexing_preferences_rows',
        'memory_events',
        'memory_members',
        'saved_captions',
        'photo_locations',
      ];
      String dump(String table) => jsonEncode([
        for (final row in raw.select('SELECT * FROM $table ORDER BY 1'))
          {
            for (final entry in row.entries)
              entry.key: entry.value is Uint8List
                  ? base64Encode(entry.value as Uint8List)
                  : entry.value,
          },
      ]);
      final before = {for (final name in names) name: dump(name)};
      final upgraded = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(upgraded.close);
      expect(await upgraded.photoCount(), 1);
      expect(raw.select('PRAGMA user_version').single.values.single, 6);
      expect({for (final name in names) name: dump(name)}, before);
      expect(await upgraded.select(upgraded.peopleFaces).get(), isEmpty);
      expect(await upgraded.select(upgraded.peopleState).get(), isEmpty);
    },
  );

  test(
    'processing ownership is exclusive, released and crash-expiring',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final people = await ProcessingLease.acquire(db, 'people');
      expect(people, isNotNull);
      expect(await ProcessingLease.acquire(db, 'background'), isNull);
      await people!.release();
      final indexing = await ProcessingLease.acquire(db, 'indexing');
      expect(indexing, isNotNull);
      await db.customStatement('UPDATE processing_leases SET expires_ms=0');
      final recovered = await ProcessingLease.acquire(db, 'recovered');
      expect(recovered, isNotNull);
      await indexing!.release();
      expect(await ProcessingLease.acquire(db, 'other'), isNull);
      await recovered!.release();
    },
  );
}
