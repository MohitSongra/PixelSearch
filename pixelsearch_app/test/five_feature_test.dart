import 'dart:async';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/data/memory_repository.dart';
import 'package:pixelsearch/data/location_repository.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/enhancements/enhancement_client.dart';
import 'package:pixelsearch/data/enhancements/caption_image.dart';
import 'package:pixelsearch/domain/search/assistant_result.dart';
import 'package:pixelsearch/domain/timeline/memory_grouping.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo(String id, int hour) => Photo(
  id: id,
  title: '',
  caption: '',
  tags: [],
  date: DateTime(2026).add(Duration(hours: hour)),
  album: 'Camera',
  source: PhotoSource.device,
);

void main() {
  test(
    'saved captions survive photo upserts and stay outside retrieval metadata',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PhotoRepository(db);
      await repo.savePhotos([photo('a', 0)]);
      await db
          .into(db.savedCaptions)
          .insert(
            SavedCaptionsCompanion.insert(
              photoId: 'a',
              revision: 0,
              baseCaption: 'Visible scene',
              editedCaption: 'My saved description',
              model: 'fixture',
              manuallyEdited: const Value(true),
              generatedMs: 42,
            ),
          );
      await repo.savePhotos([photo('a', 1)]);
      final saved = (await db.select(db.savedCaptions).get()).single;
      expect(saved.editedCaption, 'My saved description');
      expect(saved.manuallyEdited, isTrue);
      expect((await repo.loadPhotos()).single.caption, isEmpty);
      await db.deleteAssets(['a']);
      expect(await db.select(db.savedCaptions).get(), isEmpty);
    },
  );
  test(
    'location enrichment resumes, skips completed revisions and leaves embeddings intact',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final photos = PhotoRepository(db);
      await photos.savePhotos([photo('a', 0), photo('b', 1), photo('c', 2)]);
      await photos.saveEmbedding(
        'a',
        Float32List.fromList(List.filled(512, 0.5)),
      );
      final before = (await db.select(db.embeddingRows).get()).single.vector;
      var reads = 0;
      final locations = LocationRepository(
        db,
        requestAccess: () async {},
        stillAuthorized: () async => true,
        lookup: (_) async {
          reads++;
          return const LocationObservation(accessible: true, lat: 18, lng: 73);
        },
      );
      await locations.scan((done, _) {
        if (done == 1) locations.cancel();
      });
      expect((await locations.located()).length, 1);
      await locations.scan((_, _) {});
      expect(reads, 3);
      expect((await locations.located()).length, 3);
      await locations.scan((_, _) {});
      expect(reads, 3);
      expect((await db.select(db.embeddingRows).get()).single.vector, before);
      expect(await photos.photoCount(), 3);
    },
  );
  test(
    'inaccessible and denied locations do not get cached as missing GPS',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await PhotoRepository(db).savePhotos([photo('a', 0)]);
      final unavailable = LocationRepository(
        db,
        requestAccess: () async {},
        stillAuthorized: () async => true,
        lookup: (_) async => const LocationObservation(accessible: false),
      );
      await unavailable.scan((_, _) {});
      expect(await db.select(db.photoLocations).get(), isEmpty);
      final denied = LocationRepository(
        db,
        requestAccess: () async => throw StateError('denied'),
      );
      await expectLater(denied.scan((_, _) {}), throwsStateError);
      expect(denied.running, isFalse);
      expect(await db.select(db.photoLocations).get(), isEmpty);
    },
  );
  test(
    'timeline uses local calendar days and never merges established events',
    () {
      final a = photo('a', 0), b = photo('b', 100);
      final first = reconcileMemories([a, b], []);
      expect(first.length, 2);
      final edited = [
        for (final e in first)
          MemoryGroup(
            id: e.id,
            photos: e.photos,
            title: 'Keep ${e.id}',
            coverId: e.coverId,
          ),
      ];
      final second = reconcileMemories([
        a,
        photo('bridge', 48),
        photo('bridge2', 70),
        b,
      ], edited);
      // The former 48-hour rule chained unrelated days into multi-month events.
      // The two bridge photos occupy Jan 3; the curated Jan 1/5 events stay whole.
      expect(second.length, 3);
      for (final original in edited) {
        final retained = second.singleWhere((e) => e.id == original.id);
        expect(retained.title, original.title);
        expect(retained.coverId, original.coverId);
        expect(retained.photos, original.photos);
      }
      expect(second.expand((e) => e.photos).map((p) => p.id).toSet().length, 4);
      expect(reconcileMemories([photo('a', 0), photo('b', 23)], []).length, 1);
      expect(reconcileMemories([photo('a', 23), photo('b', 24)], []).length, 2);
      expect(reconcileMemories([photo('a', 0), photo('b', 48)], []).length, 2);
    },
  );

  test(
    'memory edits survive reconciliation, deleted covers get replaced',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MemoryRepository(db);
      final first = (await repo.reconcile([
        photo('a', 0),
        photo('b', 1),
      ])).single;
      await repo.edit(first.id, title: 'Family day', coverId: 'b');
      final next = (await repo.reconcile([
        photo('a', 0),
        photo('b', 1),
        photo('c', 2),
      ])).single;
      expect(next.title, 'Family day');
      expect(next.cover.id, 'b');
      expect(next.id, first.id);
      final deleted = (await repo.reconcile([
        photo('a', 0),
        photo('c', 2),
      ])).single;
      expect(deleted.cover.id, 'a');
      expect(deleted.title, 'Family day');
      expect(await repo.reconcile([]), isEmpty);
      expect(await db.select(db.memoryEvents).get(), isEmpty);
    },
  );

  test(
    'queued memory edits and reconciliation preserve invocation order',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MemoryRepository(db);
      final photos = [photo('a', 0), photo('b', 1)];
      final original = (await repo.reconcile(photos)).single;
      final firstEdit = repo.edit(original.id, title: 'First title');
      final firstRead = repo.reconcile(photos);
      final secondEdit = repo.edit(
        original.id,
        title: 'Final title',
        coverId: 'b',
      );
      final secondRead = repo.reconcile(photos);
      await firstEdit;
      expect((await firstRead).single.title, 'First title');
      await secondEdit;
      final result = (await secondRead).single;
      expect(result.title, 'Final title');
      expect(result.cover.id, 'b');
    },
  );

  test('v4 to v5 migration preserves existing data and all embedding bytes', () async {
    final raw = sqlite.sqlite3.openInMemory();
    raw.execute(
      '''CREATE TABLE photo_rows (id TEXT NOT NULL PRIMARY KEY, source INTEGER NOT NULL,
      asset_name TEXT, title TEXT NOT NULL DEFAULT '', caption TEXT NOT NULL DEFAULT '',
      tags_json TEXT NOT NULL DEFAULT '[]', date_ms INTEGER NOT NULL, lat REAL, lng REAL, place TEXT,
      album TEXT NOT NULL DEFAULT '', created_at_ms INTEGER NOT NULL DEFAULT 0,
      mtime_ms INTEGER NOT NULL DEFAULT 0, byte_size INTEGER NOT NULL DEFAULT 0,
      width INTEGER NOT NULL DEFAULT 0, height INTEGER NOT NULL DEFAULT 0, thumb_path TEXT,
      labels_json TEXT NOT NULL DEFAULT '[]', faces_json TEXT NOT NULL DEFAULT '[]', indexed_at_ms INTEGER NOT NULL DEFAULT 0)''',
    );
    raw.execute(
      '''CREATE TABLE embedding_rows (photo_id TEXT NOT NULL, model_id TEXT NOT NULL,
      embedding_version TEXT NOT NULL DEFAULT '1', dim INTEGER NOT NULL, vector BLOB NOT NULL,
      created_at_ms INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(photo_id,model_id))''',
    );
    raw.execute(
      '''CREATE TABLE index_state_rows (id INTEGER NOT NULL PRIMARY KEY DEFAULT 0,
      model_id TEXT NOT NULL DEFAULT '', total_photos INTEGER NOT NULL DEFAULT 0,
      embedded_count INTEGER NOT NULL DEFAULT 0, last_run_ms INTEGER NOT NULL DEFAULT 0, model_ready INTEGER NOT NULL DEFAULT 0)''',
    );
    raw.execute(
      '''CREATE TABLE indexing_preferences_rows (id INTEGER NOT NULL PRIMARY KEY DEFAULT 0,
      all_folders INTEGER NOT NULL DEFAULT 0, folder_ids_json TEXT NOT NULL DEFAULT '[]')''',
    );
    final bytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));
    raw.execute(
      "INSERT INTO photo_rows(id,source,date_ms,labels_json,faces_json,mtime_ms) VALUES ('a',1,42,'[\"dog\"]','[{}]',123)",
    );
    raw.execute(
      "INSERT INTO embedding_rows(photo_id,model_id,dim,vector) VALUES ('a','MobileCLIP-S1',512,?)",
      [bytes],
    );
    raw.execute(
      "INSERT INTO indexing_preferences_rows VALUES (0,0,'[\"folder-id\"]')",
    );
    raw.execute(
      "INSERT INTO index_state_rows VALUES (0,'MobileCLIP-S1',1916,1916,123,1)",
    );
    raw.execute('PRAGMA user_version=4');
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);
    expect((await db.allPhotos()).single.mtimeMs, 123);
    expect((await db.select(db.embeddingRows).get()).single.vector, bytes);
    expect(
      (await db.select(db.embeddingRows).get()).single.embeddingVersion,
      '1',
    );
    expect(
      (await db.select(db.indexingPreferencesRows).get()).single.folderIdsJson,
      '["folder-id"]',
    );
    expect((await db.indexState()).embeddedCount, 1916);
    expect(await db.select(db.memoryEvents).get(), isEmpty);
    expect(await db.select(db.savedCaptions).get(), isEmpty);
    expect(await db.select(db.photoLocations).get(), isEmpty);
    expect((await PhotoRepository(db).photoIdsNeedingEmbedding()), isEmpty);
  });

  test(
    'consent defaults offline, persists, and superseded enables cannot undo revocation',
    () async {
      String? saved;
      final prefs = UserPreferences(
        read: () async => saved,
        write: (s) async {
          await Future<void>.delayed(Duration.zero);
          saved = s;
        },
      );
      final policy = OnlinePolicy(prefs);
      await policy.load();
      expect(policy.allows(OnlineFeature.captions), isFalse);
      await policy.update(feature: OnlineFeature.captions, allow: true);
      final enabling = policy.update(offline: false);
      final revoke = policy.update(offline: true);
      expect(policy.allows(OnlineFeature.captions), isFalse);
      await enabling;
      expect(policy.allows(OnlineFeature.captions), isFalse);
      await revoke;
      final restored = OnlinePolicy(
        UserPreferences(read: () async => saved, write: (_) async {}),
      );
      await restored.load();
      expect(restored.offline, isTrue);
      expect(restored.enabled.contains(OnlineFeature.captions), isTrue);
    },
  );

  test(
    'zero HTTP calls without consent; rewrites contain no image bytes',
    () async {
      final policy = OnlinePolicy(
        UserPreferences(read: () async => null, write: (_) async {}),
      );
      await policy.load();
      var calls = 0;
      final client = EnhancementClient(
        policy,
        token: () async => 'test-token',
        client: () => MockClient((request) async {
          calls++;
          expect(request.body, '{"text":"A tree","style":"concise"}');
          expect(request.headers['authorization'], 'Bearer test-token');
          return http.Response('{"text":"Tree","model":"fixture"}', 200);
        }),
      );
      await expectLater(
        client.request(OnlineFeature.captions, 'rewrite'),
        throwsStateError,
      );
      expect(calls, 0);
      await policy.update(
        baseUrl: 'https://example.test',
        offline: false,
        feature: OnlineFeature.captions,
        allow: true,
      );
      final result = await client.request(
        OnlineFeature.captions,
        'rewrite',
        json: {'text': 'A tree', 'style': 'concise'},
      );
      expect(result['text'], 'Tree');
      expect(calls, 1);
    },
  );

  test('revocation rejects an in-flight response without retrying', () async {
    final policy = OnlinePolicy(
      UserPreferences(read: () async => null, write: (_) async {}),
    );
    await policy.load();
    await policy.update(
      baseUrl: 'https://example.test',
      offline: false,
      feature: OnlineFeature.assistant,
      allow: true,
    );
    final started = Completer<void>(), finish = Completer<void>();
    var calls = 0;
    final client = EnhancementClient(
      policy,
      token: () async => 'test',
      client: () => MockClient((r) async {
        calls++;
        started.complete();
        await finish.future;
        return http.Response('{}', 200);
      }),
    );
    final pending = client.request(OnlineFeature.assistant, 'assistant');
    final rejected = expectLater(pending, throwsStateError);
    await started.future;
    await policy.update(offline: true);
    finish.complete();
    await rejected;
    expect(calls, 1);
  });

  test(
    'assistant rejects invented filters and invalid dates, resolves real albums',
    () {
      Map<String, dynamic> response(Map<String, Object?> filters) => {
        'query': 'people on a beach',
        'filters': filters,
      };
      expect(
        parseAssistantResult(response({'album': 'camera'}), [
          photo('a', 0),
        ]).filters.album,
        'Camera',
      );
      expect(
        () => parseAssistantResult(response({'album': 'Invented'}), [
          photo('a', 0),
        ]),
        throwsStateError,
      );
      expect(
        () => parseAssistantResult(response({'from': '2026-02-31'}), []),
        throwsFormatException,
      );
      expect(
        () => parseAssistantResult(response({'sql': 'DROP TABLE photos'}), []),
        throwsFormatException,
      );
    },
  );

  test(
    'caption upload has bounded resolution and strips image metadata',
    () async {
      final source = img.Image(width: 2000, height: 1000);
      source.exif.imageIfd['ImageDescription'] = 'private description';
      final encoded = Uint8List.fromList(img.encodeJpg(source));
      final clean = prepareCaptionImage(encoded);
      final result = img.decodeJpg(clean)!;
      expect(result.width, 1280);
      expect(result.height, 640);
      final tags = await readExifFromBytes(clean);
      expect(tags.values.any((v) => v.printable.contains('private')), isFalse);
      expect(clean.length, lessThan(4 * 1024 * 1024));
    },
  );

  test('GPS absent is unknown; explicit zero coordinates remain valid', () {
    expect(gpsFromTags({}), isNull);
    IfdTag ref(String s) =>
        IfdTag(tag: 0, tagType: 'ASCII', printable: s, values: const IfdNone());
    IfdTag coord() => IfdTag(
      tag: 0,
      tagType: 'Ratio',
      printable: '0',
      values: IfdRatios([Ratio(0, 1), Ratio(0, 1), Ratio(0, 1)]),
    );
    expect(
      gpsFromTags({
        'GPS GPSLatitude': coord(),
        'GPS GPSLongitude': coord(),
        'GPS GPSLatitudeRef': ref('N'),
        'GPS GPSLongitudeRef': ref('E'),
      }),
      (lat: 0.0, lng: 0.0),
    );
  });
  test(
    'GPS degrees/minutes/seconds preserve hemisphere and reject invalid ranges',
    () {
      IfdTag direction(String s) => IfdTag(
        tag: 0,
        tagType: 'ASCII',
        printable: s,
        values: const IfdNone(),
      );
      IfdTag coord(int degrees, int minutes, int seconds) => IfdTag(
        tag: 0,
        tagType: 'Ratio',
        printable: '',
        values: IfdRatios([
          Ratio(degrees, 1),
          Ratio(minutes, 1),
          Ratio(seconds, 1),
        ]),
      );
      final tags = {
        'GPS GPSLatitude': coord(31, 30, 0),
        'GPS GPSLongitude': coord(70, 15, 0),
        'GPS GPSLatitudeRef': direction('S'),
        'GPS GPSLongitudeRef': direction('W'),
      };
      expect(gpsFromTags(tags), (lat: -31.5, lng: -70.25));
      tags['GPS GPSLatitude'] = coord(91, 0, 0);
      expect(gpsFromTags(tags), isNull);
      tags['GPS GPSLatitude'] = coord(31, 60, 0);
      expect(gpsFromTags(tags), isNull);
    },
  );
}
