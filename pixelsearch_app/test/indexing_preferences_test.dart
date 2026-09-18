import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/core/ai_contract.dart';
import 'package:pixelsearch/data/indexing_preferences_repository.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/indexing/model/folder_selection.dart';
import 'package:pixelsearch/models/photo.dart';

void main() {
  test('new installations require an explicit folder choice', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, AiContract.schemaVersion);
    addTearDown(db.close);
    expect((await IndexingPreferencesRepository(db).load()).isEmpty, isTrue);
  });

  test(
    'folder IDs and all-folders mode persist across database reopen',
    () async {
      final dir = await Directory.systemTemp.createTemp('pixelsearch-folders-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await IndexingPreferencesRepository(
        db,
      ).save(FolderSelection(folderIds: {'42', '-7'}));
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      var saved = await IndexingPreferencesRepository(db).load();
      expect(saved.folderIds, {'42', '-7'});
      expect(saved.allFolders, isFalse);
      await IndexingPreferencesRepository(
        db,
      ).save(FolderSelection(allFolders: true));
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      saved = await IndexingPreferencesRepository(db).load();
      expect(saved.allFolders, isTrue);
      expect(saved.folderIds, isEmpty);
    },
  );

  test(
    'schema v3 upgrade preserves existing photos and embedding bytes',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'pixelsearch-migration-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      final repo = PhotoRepository(db);
      await repo.savePhotos([
        Photo(
          id: 'retained',
          title: '',
          caption: '',
          tags: [],
          date: DateTime(2026),
          album: 'Camera',
          source: PhotoSource.device,
        ),
      ]);
      final vector = Float32List(512)..[0] = 1;
      await repo.saveEmbedding('retained', vector);
      // Recreate the actual v3 layout, without later feature tables/indexes.
      for (final table in ['indexing_preferences_rows', 'memory_events', 'memory_members',
        'saved_captions', 'photo_locations', 'people_faces', 'people_persons', 'people_scans',
        'people_decisions', 'people_reviews', 'people_state', 'processing_leases']) {
        await db.customStatement('DROP TABLE $table');
      }
      await db.customStatement('PRAGMA user_version = 3');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      expect((await IndexingPreferencesRepository(db).load()).isEmpty, isTrue);
      expect(await db.photoCount(), 1);
      expect((await PhotoRepository(db).loadEmbeddings())['retained'], vector);
      await IndexingPreferencesRepository(
        db,
      ).save(FolderSelection(folderIds: {'camera'}));
      expect((await IndexingPreferencesRepository(db).load()).folderIds, {
        'camera',
      });
    },
  );
}
