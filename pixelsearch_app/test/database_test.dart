import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/models/photo.dart';

void main() {
  late AppDatabase db;
  late PhotoRepository repo;

  setUp(() {
    // In-memory native SQLite — no device, no files.
    db = AppDatabase(NativeDatabase.memory());
    repo = PhotoRepository(db);
  });
  tearDown(() async => db.close());

  test('photo metadata round-trips through the store', () async {
    final p = Photo(
      id: 'p1',
      assetName: 'assets/samples/beach_sunset.jpg',
      title: 'Sunset',
      caption: 'beach at dusk',
      tags: const ['beach', 'sunset', 'goa'],
      date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      lat: 15.29,
      lng: 74.12,
      place: 'Goa',
      album: 'Trips',
      source: PhotoSource.sample,
    );

    await repo.savePhotos([p]);
    expect(await repo.photoCount(), 1);

    final back = (await repo.loadPhotos()).single;
    expect(back.id, 'p1');
    expect(back.title, 'Sunset');
    expect(back.caption, 'beach at dusk');
    expect(back.tags, ['beach', 'sunset', 'goa']);
    expect(back.lat, closeTo(15.29, 1e-9));
    expect(back.lng, closeTo(74.12, 1e-9));
    expect(back.place, 'Goa');
    expect(back.album, 'Trips');
    expect(back.source, PhotoSource.sample);
    expect(back.date.millisecondsSinceEpoch, 1700000000000);
  });

  test('upsert replaces an existing photo rather than duplicating', () async {
    Photo mk(String title) => Photo(
          id: 'same',
          title: title,
          caption: '',
          tags: const [],
          date: DateTime.fromMillisecondsSinceEpoch(0),
          album: '',
          source: PhotoSource.device,
        );
    await repo.savePhotos([mk('first')]);
    await repo.savePhotos([mk('second')]);
    expect(await repo.photoCount(), 1);
    expect((await repo.loadPhotos()).single.title, 'second');
  });

  test('embedding BLOB is a lossless round-trip', () async {
    await repo.savePhotos([
      Photo(
        id: 'p1',
        title: '',
        caption: '',
        tags: const [],
        date: DateTime.fromMillisecondsSinceEpoch(0),
        album: '',
        source: PhotoSource.device,
      )
    ]);

    // Values chosen to exercise sign, fractions and exact powers of two.
    final v = Float32List.fromList(
        List<double>.generate(512, (i) => (i - 256) / 128.0));
    await repo.saveEmbedding('p1', v);

    final loaded = await repo.loadEmbeddings();
    expect(loaded.containsKey('p1'), isTrue);
    final back = loaded['p1']!;
    expect(back.length, 512);
    for (var i = 0; i < 512; i++) {
      expect(back[i], v[i], reason: 'element $i must be bit-identical');
    }
  });

  test('missing-embedding work queue drains as embeddings are added', () async {
    final photos = [
      for (var i = 0; i < 3; i++)
        Photo(
          id: 'p$i',
          title: '',
          caption: '',
          tags: const [],
          date: DateTime.fromMillisecondsSinceEpoch(i * 1000),
          album: '',
          source: PhotoSource.device,
        ),
    ];
    await repo.savePhotos(photos);
    expect((await repo.photoIdsNeedingEmbedding()).length, 3);

    await repo.saveEmbedding('p1', Float32List(512));
    final remaining = await repo.photoIdsNeedingEmbedding();
    expect(remaining.length, 2);
    expect(remaining.contains('p1'), isFalse);
  });

  test('a version bump makes existing embeddings stale', () async {
    await repo.savePhotos([
      Photo(
        id: 'p1',
        title: '',
        caption: '',
        tags: const [],
        date: DateTime.fromMillisecondsSinceEpoch(0),
        album: '',
        source: PhotoSource.device,
      )
    ]);
    await repo.saveEmbedding('p1', Float32List(512)); // stored at version '1'
    expect(await repo.photoIdsNeedingEmbedding(), isEmpty);
    // The same photo counts as stale under a newer embedding_version.
    expect(await repo.photoIdsNeedingEmbedding(version: '2'), ['p1']);
  });

  test('index state starts as a single default row and persists updates',
      () async {
    final initial = await db.indexState();
    expect(initial.id, 0);
    expect(initial.embeddedCount, 0);
    expect(initial.modelReady, isFalse);

    await db.putIndexState(const IndexStateRowsCompanion(
      modelId: Value('MobileCLIP-S1'),
      totalPhotos: Value(10),
      embeddedCount: Value(4),
      modelReady: Value(true),
    ));

    final updated = await db.indexState();
    expect(updated.id, 0);
    expect(updated.totalPhotos, 10);
    expect(updated.embeddedCount, 4);
    expect(updated.modelReady, isTrue);
  });
}
