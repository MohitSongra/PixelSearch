import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/keyword_search_backend.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';
import 'package:pixelsearch/domain/people/people_query.dart';
import 'package:pixelsearch/domain/search/search_response.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/ai/text_embedder.dart';

class _FakeTextEmbedder implements TextEmbedder {
  _FakeTextEmbedder(this._vectors);
  final Map<String, Float32List> _vectors;
  bool _loaded = false;
  int embedCalls = 0;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async {
    _loaded = true;
  }

  @override
  Future<Float32List> embed(String text) async {
    embedCalls++;
    final key = text.trim().toLowerCase();
    if (_vectors.containsKey(key)) return _vectors[key]!;
    return Float32List(FaceContract.dimensions);
  }

  @override
  Future<void> dispose() async {
    _loaded = false;
  }
}

Photo _mockPhoto(String id, {List<String> labels = const [], DateTime? date}) =>
    Photo(
      id: id,
      title: id,
      caption: '',
      tags: const [],
      labels: labels,
      date: date ?? DateTime(2026, 1, 1),
      album: 'Camera',
      source: PhotoSource.sample,
    );

Future<void> seedPhoto(
  AppDatabase db,
  String id, {
  int revision = 1,
  String faces = '[]',
}) => db.upsertPhotos([
  PhotoRowsCompanion.insert(
    id: id,
    source: 1,
    dateMs: int.tryParse(id) ?? 1000,
    mtimeMs: Value(revision),
    width: const Value(500),
    height: const Value(500),
    facesJson: Value(faces),
  ),
]);

PeopleFacesCompanion mockFace(
  String photoId,
  String faceId, {
  int revision = 1,
  Float32List? vector,
}) {
  final v = vector ?? (Float32List(128)..[0] = 1.0);
  return PeopleFacesCompanion.insert(
    id: faceId,
    photoId: photoId,
    revision: '$revision:0:500:500',
    contract: FaceContract.id,
    x: 0.1,
    y: 0.1,
    w: 0.4,
    h: 0.4,
    quality: 'ready',
    vector: Value(encodeFaceVector(v)),
  );
}

void main() {
  group('People Name Search: Aliases and Ambiguous Resolution', () {
    const people = [
      NamedPerson('p_alice', 'Alice', aliases: ['me', 'myself', 'Ally']),
      NamedPerson('p_bob', 'Bob', aliases: ['Bobby', 'friend Bob']),
      NamedPerson('p_casey1', 'Casey', aliases: ['Caseyann']),
      NamedPerson('p_casey2', 'Casey', aliases: ['Caseyton']),
    ];

    test('resolves primary name and multiple aliases case-insensitively', () {
      final q1 = resolvePeopleQuery('Alice', people);
      expect(q1.filters.personIds, {'p_alice'});
      expect(q1.matched, {'alice': 'p_alice'});
      expect(q1.needsChoice, isFalse);

      final q2 = resolvePeopleQuery('photos of me', people);
      expect(q2.filters.personIds, {'p_alice'});
      expect(q2.matched, {'me': 'p_alice'});

      final q3 = resolvePeopleQuery('Ally in the garden', people);
      expect(q3.filters.personIds, {'p_alice'});
      expect(q3.query, 'the garden');

      final q4 = resolvePeopleQuery('Bobby at sunset', people);
      expect(q4.filters.personIds, {'p_bob'});
      expect(q4.query, 'sunset');
    });

    test('ambiguous names require explicit user choice and never guess', () {
      final qAmbiguous = resolvePeopleQuery('Casey', people);
      expect(qAmbiguous.needsChoice, isTrue);
      expect(qAmbiguous.filters.personIds, isEmpty);
      expect(qAmbiguous.ambiguous['casey']?.map((p) => p.id), [
        'p_casey1',
        'p_casey2',
      ]);

      // With choice supplied, resolves unambiguously
      final qChosen = resolvePeopleQuery(
        'Casey',
        people,
        choices: {'casey': 'p_casey2'},
      );
      expect(qChosen.needsChoice, isFalse);
      expect(qChosen.filters.personIds, {'p_casey2'});
      expect(qChosen.matched, {'casey': 'p_casey2'});

      // With unknown choice, remains ambiguous
      final qInvalidChoice = resolvePeopleQuery(
        'Casey',
        people,
        choices: {'casey': 'invalid_id'},
      );
      expect(qInvalidChoice.needsChoice, isTrue);
      expect(qInvalidChoice.filters.personIds, isEmpty);
    });

    test(
      'mixed query: one ambiguous and one unique requires choice without dropping unique',
      () {
        final qMixed = resolvePeopleQuery('me with Casey at the park', people);
        expect(qMixed.needsChoice, isTrue);
        // 'me' is identified, but Casey requires choice
        expect(qMixed.matched, {'me': 'p_alice'});
        expect(qMixed.ambiguous['casey']?.length, 2);
        expect(qMixed.filters.personIds, {'p_alice'});
        expect(qMixed.query, 'Casey at the park');

        // Now resolve the choice
        final qResolved = resolvePeopleQuery(
          'me with Casey at the park',
          people,
          choices: {'casey': 'p_casey1'},
        );
        expect(qResolved.needsChoice, isFalse);
        expect(qResolved.filters.personIds, {'p_alice', 'p_casey1'});
        expect(qResolved.query, 'the park');
      },
    );
  });

  group(
    'People Name Search: Multi-Person Intersection and Unassigned Exclusion',
    () {
      late AppDatabase db;
      late PeopleRepository repo;

      setUp(() async {
        db = AppDatabase(NativeDatabase.memory());
        repo = PeopleRepository(db);
        await repo.enable();

        // Photos:
        // photo_1: Alice only
        // photo_2: Bob only
        // photo_3: Alice and Bob
        // photo_4: Alice, Bob, and Casey
        // photo_5: Similar face detected but unconfirmed (unassigned)
        await seedPhoto(db, 'photo_1');
        await seedPhoto(db, 'photo_2');
        await seedPhoto(db, 'photo_3');
        await seedPhoto(db, 'photo_4');
        await seedPhoto(db, 'photo_5');

        await repo.commitPhoto(
          photoId: 'photo_1',
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [mockFace('photo_1', 'face_1')],
        );
        await repo.commitPhoto(
          photoId: 'photo_2',
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [mockFace('photo_2', 'face_2')],
        );
        await repo.commitPhoto(
          photoId: 'photo_3',
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [
            mockFace('photo_3', 'face_3_m'),
            mockFace('photo_3', 'face_3_r'),
          ],
        );
        await repo.commitPhoto(
          photoId: 'photo_4',
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [
            mockFace('photo_4', 'face_4_m'),
            mockFace('photo_4', 'face_4_r'),
            mockFace('photo_4', 'face_4_s'),
          ],
        );
        // photo_5 has a detected face that is NOT assigned to anyone
        await repo.commitPhoto(
          photoId: 'photo_5',
          revision: '1:0:500:500',
          generation: (await repo.state()).generation,
          faces: [mockFace('photo_5', 'face_5_unassigned')],
        );

        // Create persons and manual assignments:
        await repo.createPerson(
          ['face_1', 'face_3_m', 'face_4_m'],
          name: 'Alice',
          aliases: ['me'],
        );
        await repo.createPerson([
          'face_2',
          'face_3_r',
          'face_4_r',
        ], name: 'Bob');
        await repo.createPerson(['face_4_s'], name: 'Casey');
      });

      tearDown(() => db.close());

      test(
        'single person query returns only photos assigned to that person',
        () async {
          final snapshot = await repo.load();
          final alice = snapshot.people.firstWhere(
            (p) => p.record.name == 'Alice',
          );
          final bob = snapshot.people.firstWhere((p) => p.record.name == 'Bob');
          final casey = snapshot.people.firstWhere(
            (p) => p.record.name == 'Casey',
          );

          final alicePhotos = await repo.photoIdsFor({alice.record.id});
          expect(alicePhotos, {'photo_1', 'photo_3', 'photo_4'});
          expect(alicePhotos.contains('photo_2'), isFalse);
          expect(
            alicePhotos.contains('photo_5'),
            isFalse,
            reason: 'Unassigned face photo must never appear',
          );

          final bobPhotos = await repo.photoIdsFor({bob.record.id});
          expect(bobPhotos, {'photo_2', 'photo_3', 'photo_4'});
          expect(bobPhotos.contains('photo_1'), isFalse);
          expect(bobPhotos.contains('photo_5'), isFalse);

          final caseyPhotos = await repo.photoIdsFor({casey.record.id});
          expect(caseyPhotos, {'photo_4'});
        },
      );

      test(
        'multi-person intersection strictly returns photos containing ALL requested people',
        () async {
          final snapshot = await repo.load();
          final alice = snapshot.people.firstWhere(
            (p) => p.record.name == 'Alice',
          );
          final bob = snapshot.people.firstWhere((p) => p.record.name == 'Bob');
          final casey = snapshot.people.firstWhere(
            (p) => p.record.name == 'Casey',
          );

          // "me with Bob" -> intersection of Alice and Bob
          final sharedAliceBob = await repo.photoIdsFor({
            alice.record.id,
            bob.record.id,
          });
          expect(sharedAliceBob, {'photo_3', 'photo_4'});
          expect(sharedAliceBob.contains('photo_1'), isFalse);
          expect(sharedAliceBob.contains('photo_2'), isFalse);
          expect(sharedAliceBob.contains('photo_5'), isFalse);

          // "me with Bob and Casey" -> intersection of all three
          final sharedAllThree = await repo.photoIdsFor({
            alice.record.id,
            bob.record.id,
            casey.record.id,
          });
          expect(sharedAllThree, {'photo_4'});
        },
      );

      test(
        'unassigned or similarly looking unconfirmed face NEVER appears in search results',
        () async {
          final snapshot = await repo.load();
          // Ensure face_5_unassigned is in unassigned list
          expect(
            snapshot.unassigned.any((f) => f.id == 'face_5_unassigned'),
            isTrue,
          );

          final alice = snapshot.people.firstWhere(
            (p) => p.record.name == 'Alice',
          );
          final bob = snapshot.people.firstWhere((p) => p.record.name == 'Bob');

          final allAssignedPhotos = (await repo.photoIdsFor({
            alice.record.id,
          })).union(await repo.photoIdsFor({bob.record.id}));
          expect(allAssignedPhotos.contains('photo_5'), isFalse);
        },
      );

      test(
        'disjoint person query returns empty photo set (honest empty state)',
        () async {
          final snapshot = await repo.load();
          final alice = snapshot.people.firstWhere(
            (p) => p.record.name == 'Alice',
          );
          // Create empty person with no confirmed photos
          final ghost = await repo.createPerson([
            'face_5_unassigned',
          ], name: 'Ghost');
          // Remove assignment so Ghost has 0 photos
          await repo.assign(['face_5_unassigned'], null);

          final ghostPhotos = await repo.photoIdsFor({ghost});
          expect(ghostPhotos, isEmpty);

          final disjoint = await repo.photoIdsFor({alice.record.id, ghost});
          expect(disjoint, isEmpty);
        },
      );
    },
  );

  group('People Name Search: Corrections, Dismissals, and Persistence', () {
    late AppDatabase db;
    late PeopleRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
      await repo.enable();

      await seedPhoto(db, 'p1');
      await seedPhoto(db, 'p2');
      await repo.commitPhoto(
        photoId: 'p1',
        revision: '1:0:500:500',
        generation: (await repo.state()).generation,
        faces: [mockFace('p1', 'f1')],
      );
      await repo.commitPhoto(
        photoId: 'p2',
        revision: '1:0:500:500',
        generation: (await repo.state()).generation,
        faces: [mockFace('p2', 'f2')],
      );
    });

    tearDown(() => db.close());

    test(
      'rename person and edit aliases immediately updates search matching',
      () async {
        final id = await repo.createPerson(
          ['f1'],
          name: 'Bob',
          aliases: ['Bobby'],
        );
        var snapshot = await repo.load();
        var person = snapshot.people.firstWhere((p) => p.record.id == id);
        expect(person.label, 'Bob');
        expect(person.aliases, ['Bobby']);

        var query = resolvePeopleQuery('Bob', [
          NamedPerson(
            person.record.id,
            person.record.name,
            aliases: person.aliases,
          ),
        ]);
        expect(query.filters.personIds, {id});

        // Rename to Bob Stone and add alias Bobson
        await repo.editPerson(
          id,
          name: 'Bob Stone',
          aliases: ['Bobson', 'Bobby'],
        );
        snapshot = await repo.load();
        person = snapshot.people.firstWhere((p) => p.record.id == id);
        expect(person.label, 'Bob Stone');
        expect(person.aliases, contains('Bobson'));

        final updatedNamedPerson = NamedPerson(
          person.record.id,
          person.record.name,
          aliases: person.aliases,
        );

        // Old primary name 'Bob' without alias match won't match if it's not in aliases
        // but 'Bobson' now matches
        final qNewAlias = resolvePeopleQuery('Bobson', [updatedNamedPerson]);
        expect(qNewAlias.filters.personIds, {id});

        final qFullName = resolvePeopleQuery('Bob Stone', [updatedNamedPerson]);
        expect(qFullName.filters.personIds, {id});
      },
    );

    test(
      'remove-assignment immediately excludes photo from person query',
      () async {
        final id = await repo.createPerson(['f1', 'f2'], name: 'Alice');
        var photos = await repo.photoIdsFor({id});
        expect(photos, {'p1', 'p2'});

        // Remove f2
        await repo.assign(['f2'], null);
        photos = await repo.photoIdsFor({id});
        expect(photos, {'p1'});
        expect(photos.contains('p2'), isFalse);
      },
    );

    test(
      'dismiss face marks face dismissed and excludes from unassigned list and queries',
      () async {
        final snapshotBefore = await repo.load();
        expect(snapshotBefore.unassigned.length, 2);

        // Dismiss f2 as not a real face
        await repo.assign(['f2'], null, dismiss: true);

        final snapshotAfter = await repo.load();
        expect(snapshotAfter.unassigned.length, 1);
        expect(snapshotAfter.unassigned.any((f) => f.id == 'f2'), isFalse);

        final f2Record = (await db.select(db.peopleFaces).get()).firstWhere(
          (f) => f.id == 'f2',
        );
        expect(f2Record.dismissed, isTrue);
        expect(f2Record.personId, isNull);
      },
    );

    test(
      'all corrections and assignments persist across fresh repository instance (app restart)',
      () async {
        final personId = await repo.createPerson(
          ['f1'],
          name: 'Alice',
          aliases: ['me', 'myself'],
        );
        await repo.assign(['f2'], null, dismiss: true);

        // Simulate app restart by creating a new repository with the same underlying database
        final freshRepo = PeopleRepository(db);
        final snapshot = await freshRepo.load();

        expect(snapshot.people.length, 1);
        final person = snapshot.people.single;
        expect(person.record.id, personId);
        expect(person.label, 'Alice');
        expect(person.aliases, contains('me'));
        expect(person.photoCount, 1);

        // f2 remains dismissed
        expect(snapshot.unassigned.length, 0);

        final photos = await freshRepo.photoIdsFor({personId});
        expect(photos, {'p1'});
      },
    );
  });

  group('People Name Search: Semantic Ranking with Person Filter', () {
    test('person-plus-scene query ranks only within eligible photos', () async {
      // 3 photos in gallery:
      // p1: Alice at beach
      // p2: Alice at office
      // p3: Other person at beach
      final corpus = [
        _mockPhoto('p1', labels: ['beach', 'sea']),
        _mockPhoto('p2', labels: ['office', 'desk']),
        _mockPhoto('p3', labels: ['beach', 'ocean']),
      ];

      final index = BruteForceVectorIndex(dim: 3)
        ..upsert(
          'p1',
          Float32List.fromList([1, 0, 0]),
        ) // high match for 'beach' (cosine 1.0)
        ..upsert(
          'p2',
          Float32List.fromList([0.3, 0.9539, 0]),
        ) // moderate match for 'beach' (cosine 0.3 > 0.15)
        ..upsert(
          'p3',
          Float32List.fromList([1, 0, 0]),
        ); // high match for 'beach' (cosine 1.0)

      final embedder = _FakeTextEmbedder({
        'beach': Float32List.fromList([1, 0, 0]),
      });

      final backend = SemanticSearchBackend(
        embedder: embedder,
        index: index,
        topK: 10,
      );

      // Search: "Alice at the beach"
      // Eligible photos for Alice: {'p1', 'p2'}
      final request = const SearchRequest(
        'beach',
        filters: SearchFilters(personIds: {'alice_id'}),
        eligiblePhotoIds: {'p1', 'p2'},
      );

      final response = await backend.searchDetailed(request, corpus);
      // Only Alice photos appear; p3 (other person at beach) is excluded
      expect(response.photos.map((p) => p.id), ['p1', 'p2']);
      expect(
        response.photos.first.id,
        'p1',
        reason: 'p1 is at the beach, ranks higher than p2',
      );
      expect(response.photos.contains(corpus[2]), isFalse);
    });

    test(
      'name-only query uses keyword search without running text embedder',
      () async {
        final corpus = [_mockPhoto('p1'), _mockPhoto('p2')];

        final request = const SearchRequest(
          '',
          filters: SearchFilters(personIds: {'alice_id'}),
          eligiblePhotoIds: {'p1'},
        );

        const backend = KeywordSearchBackend();
        final response = await backend.searchDetailed(request, corpus);
        expect(response.photos.map((p) => p.id), ['p1']);
      },
    );
  });
}
