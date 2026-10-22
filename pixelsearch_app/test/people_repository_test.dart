import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people/face_processor_api.dart';
import 'package:pixelsearch/data/people/people_service.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';

Future<void> seedPhoto(
  AppDatabase db,
  String id, {
  int revision = 1,
  String faces = '[]',
}) => db.upsertPhotos([
  PhotoRowsCompanion.insert(
    id: id,
    source: 1,
    dateMs: int.tryParse(id) ?? 1,
    mtimeMs: Value(revision),
    width: const Value(500),
    height: const Value(500),
    facesJson: Value(faces),
  ),
]);

PeopleFacesCompanion observation(
  String photo,
  String id, {
  int revision = 1,
  String? crop,
  Float32List? vector,
}) => PeopleFacesCompanion.insert(
  id: id,
  photoId: photo,
  revision: '$revision:0:500:500',
  contract: FaceContract.id,
  x: .1,
  y: .1,
  w: .4,
  h: .4,
  quality: 'ready',
  cropPath: Value(crop),
  vector: Value(encodeFaceVector(vector ?? (Float32List(128)..[0] = 1))),
);

Future<void> addFaces(
  PeopleRepository repo,
  String photo,
  List<String> faces,
) async {
  await seedPhoto(repo.db, photo);
  expect(
    await repo.commitPhoto(
      photoId: photo,
      revision: '1:0:500:500',
      generation: (await repo.state()).generation,
      faces: [for (final f in faces) observation(photo, f)],
    ),
    isTrue,
  );
}

class FakeProcessor implements FaceProcessor {
  int loads = 0, calls = 0, disposed = 0;
  final started = Completer<void>();
  Completer<void>? gate;
  @override
  Future<void> load() async {
    loads++;
  }

  @override
  Future<List<ProcessedFace>> process(String path) async {
    calls++;
    if (!started.isCompleted) started.complete();
    await gate?.future;
    return [
      ProcessedFace(
        x: .1,
        y: .1,
        w: .4,
        h: .4,
        landmarks: [],
        quality: 'ready',
        preview: Uint8List.fromList([1, 2, 3]),
        vector: Float32List(128)..[0] = 1,
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    disposed++;
  }
}

void main() {
  late AppDatabase db;
  late PeopleRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PeopleRepository(db);
  });
  tearDown(() => db.close());

  test(
    'deleting an asset removes face data even while People is paused',
    () async {
      await repo.enable();
      await addFaces(repo, 'removed', ['a']);
      await addFaces(repo, 'kept', ['b']);
      final person = await repo.createPerson([
        'a',
        'b',
      ], name: 'Synthetic Person');
      await repo.editPerson(person, coverFaceId: 'a');
      await db
          .into(db.peopleReviews)
          .insert(
            PeopleReviewsCompanion.insert(
              id: 'review',
              leftFaceId: 'a',
              rightFaceId: 'b',
              subset: 'calibration',
              cosine: .9,
              contract: FaceContract.id,
            ),
          );
      await db
          .update(db.peopleState)
          .write(
            const PeopleStateCompanion(
              threshold: Value(.9),
              calibrationJson: Value('{"threshold":0.9}'),
            ),
          );
      await repo.pause(true);
      await db.deleteAssets(['removed']);
      expect((await db.select(db.peopleFaces).get()).map((f) => f.id), ['b']);
      expect((await db.select(db.peopleScans).get()).map((s) => s.photoId), [
        'kept',
      ]);
      expect(
        (await db.select(db.peopleDecisions).get()).every(
          (d) => d.faceId == 'b',
        ),
        isTrue,
      );
      // The review row is kept so calibration fails closed instead of
      // re-scoring the remaining pairs.
      expect((await db.select(db.peopleReviews).get()).map((r) => r.id), [
        'review',
      ]);
      final calibration = await repo.calibration();
      expect(calibration.passed, isFalse);
      expect(calibration.reason, contains('unavailable'));
      final saved = (await db.select(db.peoplePersons).get()).single;
      expect(saved.name, 'Synthetic Person');
      expect(saved.coverFaceId, isNull);
      expect((await repo.state()).paused, isTrue);
      expect((await repo.state()).threshold, isNull);
      expect((await repo.state()).calibrationJson, '{}');
    },
  );

  test(
    'post-index pruning removes deleted face crops without loading a model',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'pixelsearch-retention-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final removed = File('${directory.path}/removed.jpg');
      final kept = File('${directory.path}/kept.jpg');
      await removed.writeAsBytes([1]);
      await kept.writeAsBytes([2]);
      await repo.enable();
      for (final id in ['removed', 'kept']) {
        await seedPhoto(db, id);
        await repo.commitPhoto(
          photoId: id,
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [observation(id, id, crop: '${directory.path}/$id.jpg')],
        );
      }
      await repo.pause(true);
      await db.deleteAssets(['removed']);
      await repo.reconcile();
      await PeopleService(
        repo,
        processor: () => throw StateError('Cleanup must not load a face model'),
        cropDirectory: () async => directory,
      ).pruneCrops();
      expect(await removed.exists(), isFalse);
      expect(await kept.exists(), isTrue);
    },
  );

  test(
    'new and revised indexed photos are detected without enumerating the gallery',
    () async {
      await seedPhoto(db, '1');
      expect(await repo.hasPendingPhotos(), isFalse);
      await repo.enable();
      expect(await repo.hasPendingPhotos(), isTrue);
      await addFaces(repo, '1', ['a']);
      expect(await repo.hasPendingPhotos(), isFalse);
      await seedPhoto(db, '1', revision: 2);
      expect(await repo.hasPendingPhotos(), isTrue);
      await repo.pause(true);
      expect(await repo.hasPendingPhotos(), isFalse);
    },
  );

  test(
    'too few detailed faces never create an undersized frozen review',
    () async {
      await repo.enable();
      await addFaces(repo, 'one', ['face1']);
      await addFaces(repo, 'two', ['face2']);
      await expectLater(repo.prepareReview(), throwsStateError);
      expect((await repo.load()).reviews, isEmpty);
    },
  );

  test(
    'opt-in default, restart, names, aliases and distinct photo counts',
    () async {
      expect((await repo.state()).enabled, isFalse);
      await repo.enable();
      await addFaces(repo, '1', ['a', 'b']);
      await addFaces(repo, '2', ['c']);
      final id = await repo.createPerson(
        ['a', 'b', 'c'],
        name: 'Alice',
        aliases: ['Mo'],
      );
      final restored = await PeopleRepository(db).load();
      expect(restored.people.single.record.id, id);
      expect(restored.people.single.label, 'Alice');
      expect(restored.people.single.aliases, ['Mo']);
      expect(restored.people.single.photoCount, 2);
      expect(restored.state.threshold, isNull);
    },
  );

  test(
    'moving, removing, hiding and merging persist manual corrections',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a']);
      await addFaces(repo, '2', ['b']);
      final a = await repo.createPerson(['a'], name: 'One');
      final b = await repo.createPerson(['b'], name: 'Two');
      await repo.assign(['a'], b);
      expect(
        (await db.select(db.peopleDecisions).get()).any(
          (d) => d.faceId == 'a' && d.personId == a && d.decision == 'reject',
        ),
        isTrue,
      );
      await repo.editPerson(b, coverFaceId: 'a', hidden: true);
      await repo.assign(['a'], null);
      final restored = (await repo.load()).people.singleWhere(
        (p) => p.record.id == b,
      );
      expect(restored.cover!.id, 'b');
      expect(restored.record.hidden, isTrue);
      await repo.assign(['a'], a);
      await repo.merge(a, b);
      expect((await repo.load()).people.single.aliases, contains('One'));
      expect(await repo.photoIdsFor({b}), {'1', '2'});
      expect(await repo.photoIdsFor({a}), isEmpty);
    },
  );

  test(
    'multiple selected people require all, unknown person fails closed',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a', 'b']);
      await addFaces(repo, '2', ['c']);
      final first = await repo.createPerson(['a', 'c']);
      final second = await repo.createPerson(['b']);
      expect(await repo.photoIdsFor({first, second}), {'1'});
      expect(await repo.photoIdsFor({first, 'missing'}), isEmpty);
    },
  );

  test(
    'new faces include unnamed groups but not named, hidden or dismissed faces',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a', 'b', 'c', 'd', 'e']);
      final unnamed = await repo.createPerson(['a', 'b']);
      final hidden = await repo.createPerson(['d']);
      await repo.editPerson(hidden, hidden: true);
      await repo.assign(['e'], null, dismiss: true);
      var snapshot = await repo.load();
      expect(snapshot.facesToName, 3);
      expect(snapshot.unnamedPeople.single.record.id, unnamed);
      expect(snapshot.unassigned.single.id, 'c');
      await repo.editPerson(unnamed, name: 'Bob');
      snapshot = await PeopleRepository(db).load();
      expect(snapshot.facesToName, 1);
      expect(snapshot.unnamedPeople, isEmpty);
      await repo.assign(['c'], unnamed);
      expect((await repo.load()).facesToName, 0);
      await repo.disableAndDelete();
      expect((await repo.load()).facesToName, 0);
    },
  );

  test(
    'revision changes never transfer identities; deleted covers fall back deterministically',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a']);
      await addFaces(repo, '2', ['b']);
      final id = await repo.createPerson(['a', 'b'], name: 'Saved name');
      await seedPhoto(db, '1', revision: 2);
      await repo.reconcile();
      var person = (await repo.load()).people.single;
      expect(person.cover!.id, 'b');
      expect(person.record.id, id);
      expect(await db.select(db.peopleFaces).get(), hasLength(1));
      await repo.commitPhoto(
        photoId: '1',
        revision: '2:0:500:500',
        generation: (await repo.state()).generation,
        faces: [observation('1', 'new-a', revision: 2)],
      );
      expect((await repo.load()).unassigned.single.id, 'new-a');
      await (db.delete(db.photoRows)..where((p) => p.id.equals('2'))).go();
      await repo.reconcile();
      person = (await repo.load()).people.single;
      expect(person.faces, isEmpty);
      expect(person.label, 'Saved name');
    },
  );

  test(
    'permission-limited snapshot and name search cannot expose inaccessible faces',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a']);
      await addFaces(repo, '2', ['b']);
      final id = await repo.createPerson(['a', 'b']);
      var allowed = <String>{'1'};
      final limited = PeopleRepository(
        db,
        accessiblePhotoIds: () async => allowed,
      );
      expect((await limited.load()).faces.map((f) => f.id), ['a']);
      expect(await limited.photoIdsFor({id}), {'1'});
      allowed = {};
      expect(await limited.photoIdsFor({id}), isEmpty);
      expect((await limited.load()).faces, isEmpty);
    },
  );

  test(
    'pause or delete invalidates late commits, photos and semantic bytes survive',
    () async {
      await repo.enable();
      await addFaces(repo, '1', ['a']);
      final bytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      await db.upsertEmbedding(
        EmbeddingRowsCompanion.insert(
          photoId: '1',
          modelId: 'MobileCLIP-S1',
          dim: 512,
          vector: bytes,
        ),
      );
      final generation = (await repo.state()).generation;
      await repo.pause(true);
      expect(
        await repo.commitPhoto(
          photoId: '1',
          revision: '1:0:500:500',
          generation: generation,
          faces: [],
        ),
        isFalse,
      );
      await repo.disableAndDelete();
      expect(
        await repo.commitPhoto(
          photoId: '1',
          revision: '1:0:500:500',
          generation: generation,
          faces: [observation('1', 'late')],
        ),
        isFalse,
      );
      expect(await db.photoCount(), 1);
      expect((await db.select(db.embeddingRows).get()).single.vector, bytes);
      expect(
        (await db.select(db.embeddingRows).get()).single.embeddingVersion,
        '1',
      );
      expect(await db.select(db.peopleFaces).get(), isEmpty);
      expect(await db.select(db.peopleReviews).get(), isEmpty);
    },
  );

  test(
    'review freezes, judgments persist, missing reviewed photos close gate',
    () async {
      await repo.enable();
      for (var i = 0; i < 40; i++) {
        await addFaces(repo, '$i', ['f$i']);
      }
      expect(await repo.prepareReview(), 60);
      final before = (await repo.load()).reviews;
      await repo.judge(before.first.id, 'unsure');
      expect(await repo.prepareReview(), 60);
      expect(
        (await repo.load()).reviews.map((p) => p.id),
        before.map((p) => p.id),
      );
      expect((await repo.calibration()).passed, isFalse);
      final id = before.first.leftFaceId.substring(1);
      await (db.delete(db.photoRows)..where((p) => p.id.equals(id))).go();
      expect((await repo.calibration()).reason, contains('unavailable'));
      await repo.archiveReview();
      expect((await repo.load()).reviews, isEmpty);
      expect(await db.select(db.peopleReviews).get(), hasLength(60));
    },
  );

  group('bounded service', () {
    late Directory crops;
    setUp(() async {
      crops = await Directory.systemTemp.createTemp('pixelsearch_people_test_');
    });
    tearDown(() async {
      await crops.delete(recursive: true);
    });

    test(
      'only indexed photos processed, zero-count metadata not excluded, incremental skip',
      () async {
        await repo.enable();
        await seedPhoto(db, '1');
        await seedPhoto(db, '2', faces: '[{}]');
        final processors = <FakeProcessor>[];
        final lookedUp = <String>[];
        final service = PeopleService(
          repo,
          processor: () {
            final p = FakeProcessor();
            processors.add(p);
            return p;
          },
          lookup: (id) async {
            lookedUp.add(id);
            return 'indexed:$id';
          },
          authorized: () async => true,
          cropDirectory: () async => crops,
        );
        final result = await service.run((_) {});
        expect(result.phase, 'done');
        expect(result.checked, 2);
        expect(result.faces, 2);
        expect(lookedUp, ['2', '1']);
        expect(processors.single.calls, 2);
        expect((await repo.load()).unassigned, hasLength(2));
        expect((await repo.load()).people, isEmpty);
        await service.run((_) {});
        expect(processors.last.calls, 0);
        expect(processors.last.loads, 0);
        expect(
          await crops.list().where((f) => f.path.endsWith('.jpg')).length,
          2,
        );
      },
    );

    test(
      'cancellation mid-inference checkpoints nothing; resume succeeds',
      () async {
        await repo.enable();
        await seedPhoto(db, '1');
        final processor = FakeProcessor()..gate = Completer<void>();
        final service = PeopleService(
          repo,
          processor: () => processor,
          lookup: (_) async => 'path',
          authorized: () async => true,
          cropDirectory: () async => crops,
        );
        final run = service.run((_) {});
        await processor.started.future;
        service.cancel();
        processor.gate!.complete();
        expect((await run).phase, 'paused');
        expect((await repo.load()).processed, 0);
        expect(
          await crops.list().where((f) => f.path.endsWith('.jpg')).length,
          0,
        );
        expect((await service.run((_) {})).phase, 'done');
        expect((await repo.load()).processed, 1);
      },
    );

    test(
      'disable while inference is active cannot recreate any People data or orphan crop',
      () async {
        await repo.enable();
        await seedPhoto(db, '1');
        await File('${crops.path}/orphan.jpg').writeAsBytes([1]);
        final processor = FakeProcessor()..gate = Completer<void>();
        final service = PeopleService(
          repo,
          processor: () => processor,
          lookup: (_) async => 'path',
          authorized: () async => true,
          cropDirectory: () async => crops,
        );
        final run = service.run((_) {});
        await processor.started.future;
        service.cancel();
        final paths = await repo.disableAndDelete();
        processor.gate!.complete();
        await run;
        await service.deleteCrops(paths);
        expect(await db.select(db.peopleFaces).get(), isEmpty);
        expect(await db.select(db.peopleScans).get(), isEmpty);
        expect(await crops.list().length, 0);
        expect(await db.photoCount(), 1);
      },
    );

    test(
      'inaccessible photo is reported and denied access starts no model',
      () async {
        await repo.enable();
        await seedPhoto(db, '1');
        final processor = FakeProcessor();
        var allowed = false;
        final service = PeopleService(
          repo,
          processor: () => processor,
          lookup: (_) async => null,
          authorized: () async => allowed,
          cropDirectory: () async => crops,
        );
        expect((await service.run((_) {})).phase, 'paused');
        expect(processor.loads, 0);
        allowed = true;
        final result = await service.run((_) {});
        expect(result.inaccessible, 1);
        expect(processor.calls, 0);
        expect((await repo.load()).inaccessible, 1);
      },
    );
  });
}
