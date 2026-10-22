import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people/people_service.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';
import 'package:pixelsearch/domain/people/face_grouping.dart';
import 'package:pixelsearch/domain/people/face_suggestions.dart';
import 'package:pixelsearch/domain/people/people_query.dart';

import 'people_repository_test.dart' show FakeProcessor, observation, seedPhoto;

// ---------------------------------------------------------------------------
// Vectors
// ---------------------------------------------------------------------------

/// Unit descriptor at [degrees] in the plane of dimensions 0 and 1, so the
/// cosine between two of them is the cosine of their angle difference.
Float32List unitAt(double degrees) {
  final radians = degrees * math.pi / 180;
  return Float32List(FaceContract.dimensions)
    ..[0] = math.cos(radians)
    ..[1] = math.sin(radians);
}

/// Exact unit basis vector (dot products between these are exactly 0 or 1).
Float32List axis(int index) =>
    Float32List(FaceContract.dimensions)..[index] = 1;

FaceVector faceAt(String id, String photoId, Float32List vector) =>
    FaceVector(id: id, photoId: photoId, vector: vector);

double cosDegrees(double degrees) => math.cos(degrees * math.pi / 180);

List<String> idsOf(FaceSuggestionResult result) =>
    result.items.map((s) => s.faceId).toList();

// ---------------------------------------------------------------------------
// Database helpers
// ---------------------------------------------------------------------------

const _revision = '1:0:500:500';

/// Adds one indexed photo whose faces are 'ready' with the given descriptors.
Future<void> addVectorFaces(
  PeopleRepository repo,
  String photo,
  Map<String, Float32List> faces, {
  Map<String, double> x = const {},
}) => addRawFaces(repo, photo, [
  for (final entry in faces.entries)
    observation(
      photo,
      entry.key,
      vector: entry.value,
    ).copyWith(x: Value(x[entry.key] ?? .1)),
]);

/// A face without a usable descriptor (for example a 'small face').
PeopleFacesCompanion faceWithoutDescriptor(
  String photo,
  String id, {
  String quality = 'small face',
}) => PeopleFacesCompanion.insert(
  id: id,
  photoId: photo,
  revision: _revision,
  contract: FaceContract.id,
  x: .1,
  y: .1,
  w: .05,
  h: .05,
  quality: quality,
  vector: const Value(null),
);

Future<void> addRawFaces(
  PeopleRepository repo,
  String photo,
  List<PeopleFacesCompanion> faces,
) async {
  await seedPhoto(repo.db, photo);
  expect(
    await repo.commitPhoto(
      photoId: photo,
      revision: _revision,
      generation: (await repo.state()).generation,
      faces: faces,
    ),
    isTrue,
  );
}

/// Every column of every row, in a stable order (blobs compared byte-wise).
Future<List<Map<String, Object?>>> tableRows(
  AppDatabase db,
  String table,
  String orderBy,
) async => [
  for (final row
      in await db.customSelect('SELECT * FROM $table ORDER BY $orderBy').get())
    row.data,
];

Future<List<Map<String, Object?>>> faceRows(AppDatabase db) =>
    tableRows(db, 'people_faces', 'id');

Future<List<Map<String, Object?>>> decisionRows(AppDatabase db) =>
    tableRows(db, 'people_decisions', 'face_id, person_id');

Future<PeopleFaceRecord> faceRow(AppDatabase db, String id) =>
    (db.select(db.peopleFaces)..where((f) => f.id.equals(id))).getSingle();

Future<String?> decisionFor(
  AppDatabase db,
  String faceId,
  String personId,
) async =>
    (await (db.select(db.peopleDecisions)..where(
              (d) => d.faceId.equals(faceId) & d.personId.equals(personId),
            ))
            .getSingleOrNull())
        ?.decision;

Future<int> automaticCount(AppDatabase db) async => (await (db.select(
  db.peopleFaces,
)..where((f) => f.assignment.equals('automatic'))).get()).length;

Future<List<String>> aliasesOf(PeopleRepository repo, String personId) async =>
    (await repo.load()).people
        .singleWhere((p) => p.record.id == personId)
        .aliases;

/// 60 judged pairs on photos of their own. The calibration cutoff (0.8) has
/// no different-person pair at or above it in either subset, so
/// `calibration().passed` is true. Review faces use an axis that is orthogonal
/// to the person descriptors used in these tests.
Future<void> seedPassingPeopleReview(PeopleRepository repo) async {
  for (var i = 0; i < 60; i++) {
    for (final side in ['a', 'b']) {
      await addVectorFaces(repo, 'review-$i-$side', {
        'review-face-$i-$side': axis(5),
      });
    }
    final validation = i >= 40;
    final different = i == 39 || i == 59;
    await repo.db
        .into(repo.db.peopleReviews)
        .insert(
          PeopleReviewsCompanion.insert(
            id: 'passing-$i',
            leftFaceId: 'review-face-$i-a',
            rightFaceId: 'review-face-$i-b',
            subset: validation ? 'validation' : 'calibration',
            cosine: different ? (validation ? .3 : .4) : (i == 0 ? .95 : .8),
            judgment: Value(different ? 'different' : 'same'),
            contract: FaceContract.id,
          ),
        );
  }
}

void main() {
  group('rankFaceSuggestions', () {
    test('the nearest confirmed face outranks a blended centroid', () {
      final references = [
        faceAt('ref-0', 'photo-r0', unitAt(0)),
        faceAt('ref-90', 'photo-r90', unitAt(90)),
      ];
      final candidates = [
        faceAt('cand-45', 'photo-45', unitAt(45)),
        faceAt('cand-10', 'photo-10', unitAt(10)),
      ];
      final result = rankFaceSuggestions(
        FaceSuggestionInput(references: references, candidates: candidates),
      );
      expect(idsOf(result), ['cand-10', 'cand-45']);
      expect(result.items.first.nearestFaceId, 'ref-0');
      expect(result.items.first.similarity, closeTo(cosDegrees(10), 1e-5));
      expect(result.items.last.similarity, closeTo(cosDegrees(45), 1e-5));
      expect(result.references, 2);
      expect(result.eligible, 2);

      // Control: a centroid of the two looks (45°) would have ranked the
      // 45° face first, which is exactly what nearest-reference avoids.
      final centroid = unitAt(45);
      expect(
        faceCosine(candidates.first.vector, centroid),
        greaterThan(faceCosine(candidates.last.vector, centroid)),
      );
    });

    test(
      'ordering is deterministic; ties break by support, then by face id',
      () {
        // Exact basis vectors so that tied similarities are bit-identical.
        final mixed = Float32List(FaceContract.dimensions)
          ..[0] = .6
          ..[2] = .8;
        final half = math.sqrt1_2;
        final midway = Float32List(FaceContract.dimensions)
          ..[0] = half
          ..[1] = half;
        final references = [
          faceAt('r-a', 'photo-ra', axis(0)),
          faceAt('r-b', 'photo-rb', axis(1)),
          faceAt('r-c', 'photo-rc', mixed),
        ];
        final candidates = [
          // Similarity 1 with the highest support (also near r-c).
          faceAt('c-z', 'photo-z', axis(0)),
          // Similarity 1, lower support; c-a and c-b tie completely.
          faceAt('c-b', 'photo-b', axis(1)),
          faceAt('c-a', 'photo-a', axis(1)),
          // Similarity 0.8 to r-c.
          faceAt('c-0', 'photo-0', axis(2)),
          // Exactly as close to r-a as to r-b: nearest is the smaller id.
          faceAt('c-mid', 'photo-mid', midway),
        ];
        List<String> signature(FaceSuggestionResult result) => [
          for (final s in result.items)
            '${s.faceId}|${s.photoId}|${s.nearestFaceId}|'
                '${s.similarity}|${s.support}',
        ];
        final baseline = rankFaceSuggestions(
          FaceSuggestionInput(references: references, candidates: candidates),
        );
        expect(idsOf(baseline), ['c-z', 'c-a', 'c-b', 'c-0', 'c-mid']);
        expect(baseline.items[0].similarity, baseline.items[1].similarity);
        expect(
          baseline.items[0].support,
          greaterThan(baseline.items[1].support),
        );
        expect(baseline.items[1].similarity, baseline.items[2].similarity);
        expect(baseline.items[1].support, baseline.items[2].support);
        expect(baseline.items.map((s) => s.nearestFaceId), [
          'r-a',
          'r-b',
          'r-b',
          'r-c',
          'r-a',
        ]);

        final orders = <(List<FaceVector>, List<FaceVector>)>[
          (references.reversed.toList(), candidates.reversed.toList()),
          for (final seed in [1, 7, 42, 2026])
            (
              List.of(references)..shuffle(math.Random(seed)),
              List.of(candidates)..shuffle(math.Random(seed + 1)),
            ),
        ];
        for (final (refs, cands) in orders) {
          final result = rankFaceSuggestions(
            FaceSuggestionInput(references: refs, candidates: cands),
          );
          expect(signature(result), signature(baseline));
          expect(result.eligible, baseline.eligible);
          expect(result.references, baseline.references);
        }
      },
    );

    test(
      'one face per photo; occupied photos, rejections, invalid vectors and references are skipped',
      () {
        final nan = Float32List(FaceContract.dimensions)
          ..[0] = double.nan
          ..[1] = 1;
        final result = rankFaceSuggestions(
          FaceSuggestionInput(
            references: [
              faceAt('ref', 'photo-ref', unitAt(0)),
              // An invalid reference is not usable and not counted.
              faceAt('bad-ref', 'photo-bad-ref', Float32List(128)),
            ],
            candidates: [
              // Same photo: the better face is kept even though its id sorts
              // after the worse one.
              faceAt('p1-a-far', 'p1', unitAt(60)),
              faceAt('p1-b-near', 'p1', unitAt(5)),
              // The rejected face does not hide its photo's other face.
              faceAt('p2-rejected', 'p2', unitAt(1)),
              faceAt('p2-other', 'p2', unitAt(40)),
              faceAt('occupied', 'photo-occupied', unitAt(2)),
              // The reference itself is never suggested back.
              faceAt('ref', 'photo-ref', unitAt(0)),
              faceAt('zero', 'p3', Float32List(128)),
              faceAt('unnormalised', 'p4', Float32List(128)..[0] = 2),
              faceAt('short', 'p5', Float32List(64)..[0] = 1),
              faceAt('nan', 'p6', nan),
            ],
            occupiedPhotoIds: const {'photo-occupied'},
            rejectedFaceIds: const {'p2-rejected'},
          ),
        );
        expect(idsOf(result), ['p1-b-near', 'p2-other']);
        expect(result.eligible, 2);
        expect(result.references, 1);
        expect(result.items.every((s) => s.nearestFaceId == 'ref'), isTrue);
      },
    );

    test('there is no cutoff: a negative cosine is still listed, last', () {
      final result = rankFaceSuggestions(
        FaceSuggestionInput(
          references: [faceAt('ref', 'photo-ref', unitAt(0))],
          candidates: [
            faceAt('opposite', 'photo-opposite', unitAt(170)),
            faceAt('near', 'photo-near', unitAt(10)),
          ],
        ),
      );
      expect(idsOf(result), ['near', 'opposite']);
      expect(result.items.last.similarity, lessThan(0));
      expect(result.eligible, 2);
    });

    test(
      'no references gives an empty result; limit bounds items, not eligible',
      () {
        final candidates = [
          for (var i = 1; i <= 5; i++)
            faceAt('cand-$i', 'photo-$i', unitAt(i * 10.0)),
        ];
        for (final references in [
          <FaceVector>[],
          [faceAt('bad', 'photo-bad', Float32List(128))],
        ]) {
          final empty = rankFaceSuggestions(
            FaceSuggestionInput(references: references, candidates: candidates),
          );
          expect(empty.items, isEmpty);
          expect(empty.eligible, 0);
          expect(empty.references, 0);
        }

        final references = [faceAt('ref', 'photo-ref', unitAt(0))];
        final all = rankFaceSuggestions(
          FaceSuggestionInput(references: references, candidates: candidates),
        );
        final limited = rankFaceSuggestions(
          FaceSuggestionInput(
            references: references,
            candidates: candidates,
            limit: 2,
          ),
        );
        expect(idsOf(all), ['cand-1', 'cand-2', 'cand-3', 'cand-4', 'cand-5']);
        expect(idsOf(limited), ['cand-1', 'cand-2']);
        expect(limited.eligible, 5);
        expect(limited.references, 1);

        for (final limit in [0, -1]) {
          expect(
            () => rankFaceSuggestions(
              FaceSuggestionInput(
                references: references,
                candidates: candidates,
                limit: limit,
              ),
            ),
            throwsArgumentError,
          );
          expect(
            () => rankFaceSuggestions(
              FaceSuggestionInput(
                references: const [],
                candidates: const [],
                limit: limit,
              ),
            ),
            throwsArgumentError,
          );
        }
      },
    );
  });

  group('PeopleRepository suggestions', () {
    late AppDatabase db;
    late PeopleRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
    });
    tearDown(() => db.close());

    test('suggestions are read-only', () async {
      await repo.enable();
      await addVectorFaces(repo, '1', {'ref': axis(0)});
      await addVectorFaces(repo, '2', {'cand': axis(0)});
      final a = await repo.createPerson(['ref'], name: 'Person A');
      final facesBefore = await faceRows(db);
      final decisionsBefore = await decisionRows(db);
      final stateBefore = await repo.state();

      final result = await repo.suggestionsFor(a);
      expect(idsOf(result), ['cand']);
      expect(result.items.single.similarity, closeTo(1, 1e-6));
      expect(result.references, 1);

      final cand = await faceRow(db, 'cand');
      expect(cand.personId, isNull);
      expect(cand.assignment, 'unassigned');
      expect(await faceRows(db), facesBefore);
      expect(await decisionRows(db), decisionsBefore);
      expect((await repo.state()).generation, stateBefore.generation);
      expect(await repo.state(), stateBefore);
      expect(await automaticCount(db), 0);
    });

    test(
      'suggestions stay manual even when the validation gate has passed',
      () async {
        await repo.enable();
        await seedPassingPeopleReview(repo);
        await addVectorFaces(repo, 'ref-photo', {'ref': axis(0)});
        await addVectorFaces(repo, 'cand-photo', {'cand': axis(0)});
        final a = await repo.createPerson(['ref'], name: 'Person A');
        expect((await repo.calibration()).passed, isTrue);
        await repo.reconcile();
        final state = await repo.state();
        expect(state.enabled, isTrue);
        expect(state.paused, isFalse);
        expect(state.threshold, closeTo(.8, 1e-9));
        final facesBefore = await faceRows(db);
        final decisionsBefore = await decisionRows(db);

        final result = await repo.suggestionsFor(a);
        expect(result.items.first.faceId, 'cand');
        expect(await faceRows(db), facesBefore);
        expect(await decisionRows(db), decisionsBefore);
        expect(await repo.state(), state);
        expect(await automaticCount(db), 0);
        expect((await faceRow(db, 'cand')).personId, isNull);

        // Control: the gate really is open; only applyGrouping assigns.
        expect(await repo.applyGrouping(), greaterThan(0));
        expect(await automaticCount(db), greaterThan(0));
      },
    );

    test(
      'references are only manual, ready faces with a valid descriptor',
      () async {
        await repo.enable();
        await addVectorFaces(repo, 'p-manual', {'m1': unitAt(0)});
        await addVectorFaces(repo, 'p-auto', {'auto1': unitAt(90)});
        await addRawFaces(repo, 'p-small', [
          faceWithoutDescriptor('p-small', 'small1'),
        ]);
        await addRawFaces(repo, 'p-no-vector', [
          faceWithoutDescriptor('p-no-vector', 'novec1', quality: 'ready'),
        ]);
        await addVectorFaces(repo, 'p-c1', {'near-auto': unitAt(85)});
        await addVectorFaces(repo, 'p-c2', {'near-manual': unitAt(20)});
        final a = await repo.createPerson([
          'm1',
          'auto1',
          'small1',
          'novec1',
        ], name: 'Person A');

        // Control: while auto1 is a manual member it is a reference.
        var result = await repo.suggestionsFor(a);
        expect(result.references, 2);
        expect(idsOf(result), ['near-auto', 'near-manual']);

        await (db.update(db.peopleFaces)..where((f) => f.id.equals('auto1')))
            .write(const PeopleFacesCompanion(assignment: Value('automatic')));
        result = await repo.suggestionsFor(a);
        expect(result.references, 1);
        expect(idsOf(result), ['near-manual', 'near-auto']);
        expect(result.items.every((s) => s.nearestFaceId == 'm1'), isTrue);

        await addRawFaces(repo, 'p-small-2', [
          faceWithoutDescriptor('p-small-2', 'small2'),
        ]);
        final b = await repo.createPerson(['small2'], name: 'Person B');
        final none = await repo.suggestionsFor(b);
        expect(none.references, 0);
        expect(none.items, isEmpty);
        expect(none.eligible, 0);
      },
    );

    test(
      'confirmSuggestions assigns exactly the selected faces in one generation',
      () async {
        await repo.enable();
        await addVectorFaces(repo, 'p0', {'ref': unitAt(0)});
        for (var i = 1; i <= 30; i++) {
          await addVectorFaces(repo, 'p$i', {'c$i': unitAt(i.toDouble())});
        }
        final a = await repo.createPerson(['ref'], name: 'Person A');
        final suggestions = await repo.suggestionsFor(a);
        expect(suggestions.items, hasLength(30));
        final chosen = suggestions.items.take(25).map((s) => s.faceId).toList();
        expect(chosen.first, 'c1');

        final facesBefore = {
          for (final row in await faceRows(db)) row['id']! as String: row,
        };
        final decisionsBefore = await decisionRows(db);
        final generation = (await repo.state()).generation;

        await repo.confirmSuggestions(a, chosen);

        expect((await repo.state()).generation, generation + 1);
        for (final id in chosen) {
          final face = await faceRow(db, id);
          expect(face.personId, a, reason: id);
          expect(face.assignment, 'manual', reason: id);
          expect(face.dismissed, isFalse, reason: id);
          expect(await decisionFor(db, id, a), 'accept', reason: id);
        }
        final decisionsAfter = await decisionRows(db);
        expect(decisionsAfter, hasLength(decisionsBefore.length + 25));
        expect(decisionsAfter, containsAll(decisionsBefore));
        for (final row in await faceRows(db)) {
          final id = row['id']! as String;
          if (!chosen.contains(id)) expect(row, facesBefore[id], reason: id);
        }
        final person = (await repo.load()).people.single;
        expect(person.faces, hasLength(26));
        expect(await automaticCount(db), 0);
      },
    );

    test('confirmSuggestions fails closed without partial writes', () async {
      await repo.enable();
      await addVectorFaces(repo, 'pa', {'a1': axis(0), 'a-other': axis(0)});
      await addVectorFaces(repo, 'pb', {'b1': axis(0)});
      await addVectorFaces(repo, 'pc', {'c1': axis(0)});
      await addVectorFaces(repo, 'pd', {'d1': axis(0)});
      await addVectorFaces(repo, 'pe', {'e1': axis(0)});
      await addVectorFaces(repo, 'pt', {'t1': axis(0), 't2': axis(0)});
      final a = await repo.createPerson(['a1'], name: 'Person A');
      await repo.createPerson(['b1'], name: 'Person B');
      await repo.assign(['d1'], null, dismiss: true);
      final deleted = await repo.createPerson(['e1'], name: 'Test Person');
      await repo.deletePerson(deleted);

      final faces = await faceRows(db);
      final decisions = await decisionRows(db);
      final generation = (await repo.state()).generation;
      Future<void> failsClosed(
        String why,
        Future<void> Function() action,
        Matcher matcher,
      ) async {
        await expectLater(action(), matcher, reason: why);
        expect(await faceRows(db), faces, reason: why);
        expect(await decisionRows(db), decisions, reason: why);
        expect((await repo.state()).generation, generation, reason: why);
      }

      await failsClosed(
        'assigned elsewhere',
        () => repo.confirmSuggestions(a, ['c1', 'b1']),
        throwsStateError,
      );
      await failsClosed(
        'dismissed',
        () => repo.confirmSuggestions(a, ['c1', 'd1']),
        throwsStateError,
      );
      await failsClosed(
        'two faces from one photo',
        () => repo.confirmSuggestions(a, ['t1', 't2']),
        throwsArgumentError,
      );
      await failsClosed(
        'photo already contains the person',
        () => repo.confirmSuggestions(a, ['c1', 'a-other']),
        throwsArgumentError,
      );
      await failsClosed(
        'deleted person',
        () => repo.confirmSuggestions(deleted, ['c1']),
        throwsStateError,
      );
      await failsClosed(
        'empty selection',
        () => repo.confirmSuggestions(a, []),
        throwsArgumentError,
      );
      await failsClosed(
        'unknown face',
        () => repo.confirmSuggestions(a, ['c1', 'missing-face']),
        throwsStateError,
      );

      // Control: the valid face alone is accepted.
      await repo.confirmSuggestions(a, ['c1']);
      expect((await faceRow(db, 'c1')).personId, a);
    });

    test('rejected suggestions never reappear for that person', () async {
      await repo.enable();
      await addVectorFaces(repo, 'pa', {'a1': unitAt(0)});
      await addVectorFaces(repo, 'pb', {'b1': unitAt(0)});
      await addVectorFaces(repo, 'px', {'x': unitAt(5)});
      await addVectorFaces(repo, 'py', {'y': unitAt(30)});
      final a = await repo.createPerson(['a1'], name: 'Person A');
      final b = await repo.createPerson(['b1'], name: 'Person B');
      expect(idsOf(await repo.suggestionsFor(a)), ['x', 'y']);

      await repo.rejectSuggestions(a, ['x']);

      Future<void> expectHidden(
        PeopleRepository repository,
        String person,
        String step,
      ) async {
        expect(idsOf(await repository.suggestionsFor(person)), [
          'y',
        ], reason: step);
        final snapshot = await repository.load();
        expect(
          snapshot.unassigned.map((f) => f.id),
          contains('x'),
          reason: step,
        );
        expect(
          snapshot.newFacesInPhotoOrder.map((f) => f.id),
          contains('x'),
          reason: step,
        );
        final face = await faceRow(db, 'x');
        expect(face.personId, isNull, reason: step);
        expect(face.assignment, 'unassigned', reason: step);
        expect(face.dismissed, isFalse, reason: step);
      }

      await expectHidden(repo, a, 'after reject');
      await expectHidden(PeopleRepository(db), a, 'fresh repository');
      await repo.editPerson(a, name: 'Asha');
      await expectHidden(repo, a, 'after rename');
      await repo.reconcile();
      await expectHidden(repo, a, 'after reconcile');

      // Not rejected for Person B yet.
      expect(idsOf(await repo.suggestionsFor(b)), ['x', 'y']);
      await repo.merge(a, b);
      expect(await decisionFor(db, 'x', b), 'reject');
      await expectHidden(repo, b, 'after merge into another person');
    });

    test(
      'a rejection for one person does not hide the face from another',
      () async {
        await repo.enable();
        await addVectorFaces(repo, 'pa', {'a1': unitAt(0)});
        await addVectorFaces(repo, 'pb', {'b1': unitAt(0)});
        await addVectorFaces(repo, 'px', {'x': unitAt(5)});
        final a = await repo.createPerson(['a1'], name: 'Person A');
        final b = await repo.createPerson(['b1'], name: 'Person B');
        await repo.rejectSuggestions(a, ['x']);
        expect(idsOf(await repo.suggestionsFor(a)), isEmpty);
        expect(idsOf(await repo.suggestionsFor(b)), ['x']);
        expect(await decisionFor(db, 'x', b), isNull);
      },
    );

    test(
      'rejecting a face already assigned to the person throws and writes nothing',
      () async {
        await repo.enable();
        await addVectorFaces(repo, 'pa', {'a1': axis(0)});
        await addVectorFaces(repo, 'py', {'y': axis(0)});
        final a = await repo.createPerson(['a1'], name: 'Person A');
        final faces = await faceRows(db);
        final decisions = await decisionRows(db);
        final generation = (await repo.state()).generation;
        await expectLater(repo.rejectSuggestions(a, ['a1']), throwsStateError);
        await expectLater(
          repo.rejectSuggestions(a, ['y', 'a1']),
          throwsStateError,
        );
        expect(await faceRows(db), faces);
        expect(await decisionRows(db), decisions);
        expect((await repo.state()).generation, generation);
      },
    );

    test('manual naming overrides an earlier rejection', () async {
      await repo.enable();
      await addVectorFaces(repo, 'pa', {'a1': axis(0)});
      await addVectorFaces(repo, 'px', {'x': axis(0)});
      final a = await repo.createPerson(['a1'], name: 'Person A');
      await repo.rejectSuggestions(a, ['x']);
      expect(await decisionFor(db, 'x', a), 'reject');

      await repo.assign(['x'], a);
      final member = await faceRow(db, 'x');
      expect(member.personId, a);
      expect(member.assignment, 'manual');
      expect(await decisionFor(db, 'x', a), 'accept');
      expect(
        (await repo.load()).people.single.faces.map((f) => f.id),
        contains('x'),
      );

      await repo.assign(['x'], null);
      final removed = await faceRow(db, 'x');
      expect(removed.personId, isNull);
      expect(removed.assignment, 'unassigned');
      expect(await decisionFor(db, 'x', a), 'reject');
      expect(idsOf(await repo.suggestionsFor(a)), isEmpty);
    });

    test('undoSuggestionDecisions restores the exact previous rows', () async {
      await repo.enable();
      await addVectorFaces(repo, 'pa', {'a1': unitAt(0)});
      await addVectorFaces(repo, 'pb', {'b1': unitAt(90)});
      await addVectorFaces(repo, 'px', {'x': unitAt(5)});
      await addVectorFaces(repo, 'py', {'y': unitAt(10)});
      await addVectorFaces(repo, 'pz', {'z': unitAt(15)});
      final a = await repo.createPerson(['a1'], name: 'Person A');
      final b = await repo.createPerson(['b1'], name: 'Person B');
      // An unrelated decision on x (not Person B) must survive both undos.
      await repo.assign(['x'], b);
      await repo.assign(['x'], null);
      expect(await decisionFor(db, 'x', b), 'reject');

      var faces = await faceRows(db);
      var decisions = await decisionRows(db);
      await repo.confirmSuggestions(a, ['x', 'y']);
      expect(await faceRows(db), isNot(faces));
      await repo.undoSuggestionDecisions(a, confirmed: ['x', 'y']);
      expect(await faceRows(db), faces);
      expect(await decisionRows(db), decisions);

      faces = await faceRows(db);
      decisions = await decisionRows(db);
      await repo.rejectSuggestions(a, ['x', 'z']);
      expect(await decisionRows(db), isNot(decisions));
      await repo.undoSuggestionDecisions(a, rejected: ['x', 'z']);
      expect(await faceRows(db), faces);
      expect(await decisionRows(db), decisions);
      expect(idsOf(await repo.suggestionsFor(a)), ['x', 'y', 'z']);
    });

    test('paused stays paused and nothing becomes automatic', () async {
      final crops = await Directory.systemTemp.createTemp(
        'pixelsearch_suggestions_test_',
      );
      addTearDown(() => crops.delete(recursive: true));
      await repo.enable();
      await seedPassingPeopleReview(repo);
      for (final (photo, face) in [
        ('1', 'a1'),
        ('2', 'b1'),
        ('3', 'x'),
        ('4', 'y'),
        ('5', 'z'),
        ('6', 'w'),
      ]) {
        await addVectorFaces(repo, photo, {face: axis(0)});
      }
      await repo.pause(true);
      Future<void> stillPaused(String step) async {
        final state = await repo.state();
        expect(state.enabled, isTrue, reason: step);
        expect(state.paused, isTrue, reason: step);
        expect(state.threshold, isNull, reason: step);
        expect(await automaticCount(db), 0, reason: step);
      }

      await stillPaused('pause');
      final a = await repo.createPerson(['a1'], name: 'Person A');
      await stillPaused('createPerson');
      final b = await repo.createPerson(['b1'], name: 'Person B');
      await repo.editPerson(a, name: 'Asha', aliases: ['me']);
      await stillPaused('editPerson');
      await repo.suggestionsFor(a);
      await stillPaused('suggestionsFor');
      await repo.confirmSuggestions(a, ['x']);
      await stillPaused('confirmSuggestions');
      await repo.rejectSuggestions(a, ['y']);
      await stillPaused('rejectSuggestions');
      await repo.undoSuggestionDecisions(a, confirmed: ['x'], rejected: ['y']);
      await stillPaused('undoSuggestionDecisions');
      await repo.assign(['z'], b);
      await stillPaused('assign');
      await repo.merge(b, a);
      await stillPaused('merge');
      await repo.deletePerson(a);
      await stillPaused('deletePerson');
      await repo.assign(['w'], null, dismiss: true);
      await stillPaused('dismiss');

      // The reviewed sample passes; only the pause keeps grouping off.
      expect((await repo.calibration()).passed, isTrue);
      expect(await repo.applyGrouping(), 0);
      await stillPaused('applyGrouping');

      final processor = FakeProcessor();
      final progress = await PeopleService(
        repo,
        processor: () => processor,
        lookup: (_) async => 'path',
        authorized: () async => true,
        cropDirectory: () async => crops,
      ).run((_) {});
      expect(progress.phase, 'paused');
      expect(processor.loads, 0);
      expect(processor.calls, 0);
      await stillPaused('PeopleService.run');
    });

    test('bulk assignment validates every face with one snapshot', () async {
      var calls = 0;
      final counted = PeopleRepository(
        db,
        accessiblePhotoIds: () async {
          calls++;
          return null;
        },
      );
      await counted.enable();
      for (var i = 0; i < 75; i++) {
        await addVectorFaces(counted, 'bulk-$i', {'bulk-face-$i': axis(0)});
      }
      final first = [for (var i = 0; i < 25; i++) 'bulk-face-$i'];
      final second = [for (var i = 25; i < 50; i++) 'bulk-face-$i'];
      final third = [for (var i = 50; i < 75; i++) 'bulk-face-$i'];

      calls = 0;
      final person = await counted.createPerson(first, name: 'Test Person');
      expect(calls, inInclusiveRange(1, 2), reason: 'createPerson');

      calls = 0;
      await counted.assign(second, person);
      expect(calls, inInclusiveRange(1, 2), reason: 'assign');

      calls = 0;
      await counted.confirmSuggestions(person, third);
      expect(calls, inInclusiveRange(1, 2), reason: 'confirmSuggestions');

      final snapshot = await counted.load();
      expect(snapshot.people.single.faces, hasLength(75));
      expect(
        snapshot.faces.every(
          (f) => f.personId == person && f.assignment == 'manual',
        ),
        isTrue,
      );
    });

    test(
      '"This is me" belongs to one person; aliases are deduplicated',
      () async {
        await repo.enable();
        await addVectorFaces(repo, '1', {'a1': axis(0)});
        await addVectorFaces(repo, '2', {'b1': axis(1)});
        await addVectorFaces(repo, '3', {'c1': axis(2)});
        final a = await repo.createPerson(
          ['a1'],
          name: 'Person A',
          aliases: ['me', 'myself', 'Ace'],
        );
        expect(await aliasesOf(repo, a), ['me', 'myself', 'Ace']);
        expect((await repo.load()).self!.record.id, a);

        final b = await repo.createPerson(
          ['b1'],
          name: 'Person B',
          aliases: ['me'],
        );
        expect(await aliasesOf(repo, a), ['Ace']);
        expect(await aliasesOf(repo, b), ['me']);
        expect((await repo.load()).self!.record.id, b);

        await repo.editPerson(a, aliases: ['myself']);
        expect(await aliasesOf(repo, a), ['myself']);
        expect(await aliasesOf(repo, b), isEmpty);
        expect((await repo.load()).self!.record.id, a);

        await repo.editPerson(b, aliases: ['Casey', 'casey', ' CASEY ']);
        expect(await aliasesOf(repo, b), ['Casey']);
        await repo.editPerson(b, aliases: ['Person B', ' person b ', 'Ben']);
        expect(await aliasesOf(repo, b), ['Ben']);
        await repo.editPerson(b, name: 'Ben', aliases: ['Ben', 'Benny']);
        expect(await aliasesOf(repo, b), ['Benny']);
        final c = await repo.createPerson(
          ['c1'],
          name: 'Asha',
          aliases: ['asha', ' Ash ', 'ASHA'],
        );
        expect(await aliasesOf(repo, c), ['Ash']);

        // Self words are stored lower-case and still belong to one person.
        await repo.editPerson(a, aliases: [' ME ', 'myself']);
        expect(await aliasesOf(repo, a), ['me', 'myself']);

        final snapshot = await repo.load();
        expect(
          snapshot.people
              .where((p) => p.aliases.any(isSelfAlias))
              .map((p) => p.record.id),
          [a],
        );
        final query = resolvePeopleQuery(
          'photos of me',
          peopleDirectory(snapshot),
        );
        expect(query.needsChoice, isFalse);
        expect(query.ambiguous, isEmpty);
        expect(query.matched, {selfKey: a});
        expect(query.required, {a});
      },
    );

    test(
      'merging a named person into an unnamed group keeps the name',
      () async {
        await repo.enable();
        await addVectorFaces(repo, '1', {'t1': axis(0)});
        await addVectorFaces(repo, '2', {'s1': axis(0)});
        await addVectorFaces(repo, '3', {'p1': axis(1)});
        await addVectorFaces(repo, '4', {'q1': axis(1)});
        final target = await repo.createPerson(['t1']);
        final source = await repo.createPerson(
          ['s1'],
          name: 'Asha',
          aliases: ['Ash'],
        );
        expect((await repo.load()).unnamedPeople.map((p) => p.record.id), [
          target,
        ]);

        await repo.merge(source, target);
        var snapshot = await repo.load();
        final merged = snapshot.people.singleWhere(
          (p) => p.record.id == target,
        );
        expect(merged.record.name, 'Asha');
        expect(merged.label, 'Asha');
        expect(merged.aliases, ['Ash']);
        expect(snapshot.people.any((p) => p.record.id == source), isFalse);
        expect(snapshot.unnamedPeople, isEmpty);
        expect(await repo.photoIdsFor({target}), {'1', '2'});

        // Two named people: the source name becomes an alias of the target.
        final ben = await repo.createPerson(['p1'], name: 'Ben');
        final other = await repo.createPerson(['q1'], name: 'Test Person');
        await repo.merge(ben, other);
        snapshot = await repo.load();
        final kept = snapshot.people.singleWhere((p) => p.record.id == other);
        expect(kept.record.name, 'Test Person');
        expect(kept.aliases, contains('Ben'));
        expect(snapshot.people.any((p) => p.record.id == ben), isFalse);
        expect(await repo.photoIdsFor({other}), {'3', '4'});
      },
    );

    test(
      'deletePerson returns faces to New faces and remembers the rejection',
      () async {
        await repo.enable();
        await addVectorFaces(repo, '1', {'a1': axis(0)});
        await addVectorFaces(repo, '2', {'a2': axis(0)});
        await addVectorFaces(repo, '3', {'other': axis(1)});
        final a = await repo.createPerson(['a1', 'a2'], name: 'Person A');
        final b = await repo.createPerson(['other'], name: 'Person B');
        await repo.pause(true);
        final generation = (await repo.state()).generation;

        await repo.deletePerson(a);

        final state = await repo.state();
        expect(state.paused, isTrue);
        expect(state.enabled, isTrue);
        expect(state.generation, generation + 1);
        expect((await db.select(db.peoplePersons).get()).map((p) => p.id), [b]);
        for (final id in ['a1', 'a2']) {
          final face = await faceRow(db, id);
          expect(face.personId, isNull, reason: id);
          expect(face.assignment, 'unassigned', reason: id);
          expect(await decisionFor(db, id, a), 'reject', reason: id);
        }
        final snapshot = await repo.load();
        expect(snapshot.unassigned.map((f) => f.id), containsAll(['a1', 'a2']));
        expect((await faceRow(db, 'other')).personId, b);
        await expectLater(repo.deletePerson(a), throwsStateError);
        await expectLater(
          repo.deletePerson('missing-person'),
          throwsStateError,
        );
        expect((await repo.state()).paused, isTrue);
      },
    );

    test('restoring a dismissed face writes no decision', () async {
      await repo.enable();
      await addVectorFaces(repo, '1', {'f': axis(0)});
      await addVectorFaces(repo, '2', {'g': axis(0)});
      await addVectorFaces(repo, '3', {'a1': axis(0)});
      final a = await repo.createPerson(['a1', 'g'], name: 'Person A');
      final before = await decisionRows(db);

      await repo.assign(['f'], null, dismiss: true);
      // Dismissing a member records that it is not that person.
      await repo.assign(['g'], null, dismiss: true);
      var snapshot = await repo.load();
      expect(snapshot.dismissedFaces.map((f) => f.id), ['f', 'g']);
      expect(snapshot.unassigned, isEmpty);
      final afterDismiss = await decisionRows(db);
      // g's 'accept' for Person A became a 'reject'; f got no decision.
      expect(afterDismiss, hasLength(before.length));
      expect(await decisionFor(db, 'g', a), 'reject');
      expect(afterDismiss.where((d) => d['face_id'] == 'f'), isEmpty);

      await repo.assign(['f', 'g'], null);
      snapshot = await repo.load();
      expect(snapshot.dismissedFaces, isEmpty);
      expect(snapshot.unassigned.map((f) => f.id), ['f', 'g']);
      expect(await decisionRows(db), afterDismiss);
      for (final id in ['f', 'g']) {
        final face = await faceRow(db, id);
        expect(face.dismissed, isFalse, reason: id);
        expect(face.personId, isNull, reason: id);
        expect(face.assignment, 'unassigned', reason: id);
      }
    });

    test(
      'newFacesInPhotoOrder: newest photo first, then photo id, x, face id',
      () async {
        await repo.enable();
        await addVectorFaces(repo, '100', {'h1': axis(0)});
        await addVectorFaces(
          repo,
          '300',
          {'f-m': axis(0), 'f-z': axis(0), 'f-a': axis(0), 'f-b': axis(0)},
          x: {'f-z': .1, 'f-b': .3, 'f-a': .5, 'f-m': .5},
        );
        await addVectorFaces(
          repo,
          '200',
          {'g1': axis(0), 'g-assigned': axis(0), 'g-dismissed': axis(0)},
          x: {'g1': .2, 'g-assigned': .1, 'g-dismissed': .3},
        );
        // Ids that are not numbers share capture time 1 in seedPhoto.
        await addVectorFaces(repo, 'b-photo', {'j1': axis(0)});
        await addVectorFaces(repo, 'a-photo', {'i1': axis(0)});
        await repo.createPerson(['g-assigned'], name: 'Person A');
        await repo.assign(['g-dismissed'], null, dismiss: true);

        final snapshot = await repo.load();
        expect(snapshot.photoDates['300'], 300);
        expect(snapshot.photoDates['a-photo'], 1);
        expect(snapshot.newFacesInPhotoOrder.map((f) => f.id), [
          'f-z',
          'f-b',
          'f-a',
          'f-m',
          'g1',
          'h1',
          'i1',
          'j1',
        ]);
        expect(snapshot.dismissedFaces.map((f) => f.id), ['g-dismissed']);
        // The ordered view does not reorder the plain list.
        expect(snapshot.unassigned.map((f) => f.id), [
          'f-a',
          'f-b',
          'f-m',
          'f-z',
          'g1',
          'h1',
          'i1',
          'j1',
        ]);
      },
    );
  });

  group('user-requested grouping and the naming list (2026-10-22)', () {
    late AppDatabase db;
    late PeopleRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
    });
    tearDown(() => db.close());

    test(
      'Group similar faces runs while paused only after a passed review',
      () async {
        await repo.enable();
        await addVectorFaces(repo, 'g-1', {'g1': axis(0)});
        await addVectorFaces(repo, 'g-2', {'g2': axis(0)});
        await repo.pause(true);
        // No passed review yet: nothing is grouped, even when asked.
        expect(await repo.groupNow(), 0);
        expect(await automaticCount(db), 0);
        // Paused People accepts no new face data, so seed the review unpaused.
        await repo.pause(false);
        await seedPassingPeopleReview(repo);
        await repo.pause(true);
        expect((await repo.calibration()).passed, isTrue);
        // Background grouping still respects the pause.
        expect(await repo.applyGrouping(), 0);
        expect(await automaticCount(db), 0);
        // The explicit request groups the two look-alike faces together.
        expect(await repo.groupNow(), greaterThan(0));
        final g1 = await faceRow(db, 'g1'), g2 = await faceRow(db, 'g2');
        expect(g1.assignment, 'automatic');
        expect(g1.personId, isNotNull);
        expect(g2.personId, g1.personId);
        expect((await repo.state()).paused, isTrue);
      },
    );

    test('tiny faces and duplicate detections leave the naming list', () async {
      await repo.enable();
      await addRawFaces(repo, 'n-1', [
        observation('n-1', 'big'),
        // Same face detected twice: a slightly smaller, overlapping box.
        observation('n-1', 'dup').copyWith(
          x: const Value(.12),
          y: const Value(.12),
          w: const Value(.37),
          h: const Value(.37),
        ),
        faceWithoutDescriptor('n-1', 'tiny'),
      ]);
      final snapshot = await repo.load();
      expect(
        snapshot.facePixels(snapshot.faces.firstWhere((f) => f.id == 'big')),
        closeTo(200, 1e-6),
      );
      expect(snapshot.smallOrDuplicateFaces, {'dup', 'tiny'});
      expect(snapshot.namingQueue().map((f) => f.id), ['big']);
      expect(
        snapshot.namingQueue(includeSmall: true).map((f) => f.id).toSet(),
        {'big', 'dup', 'tiny'},
      );
      expect(snapshot.toName(), 1);
      expect(snapshot.toName(includeSmall: true), 3);
      // Hidden faces are not deleted and stay nameable from the photo.
      final person = await repo.createPerson(['tiny'], name: 'Person A');
      final after = await repo.load();
      expect(after.smallOrDuplicateFaces, {'dup'});
      expect(
        after.people.singleWhere((p) => p.record.id == person).faces.single.id,
        'tiny',
      );
    });

    test('an unnamed group counts once in the naming total', () async {
      await repo.enable();
      await addVectorFaces(repo, 'u-1', {'u1': axis(0)});
      await addVectorFaces(repo, 'u-2', {'u2': axis(0)});
      await addVectorFaces(repo, 'u-3', {'u3': axis(1)});
      await repo.createPerson(['u1', 'u2']);
      final snapshot = await repo.load();
      expect(snapshot.unnamedPeople, hasLength(1));
      expect(snapshot.facesToName, 3);
      expect(snapshot.toName(), 2);
    });
  });

  group('grouping safety (2026-10-22 review)', () {
    late AppDatabase db;
    late PeopleRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
    });
    tearDown(() => db.close());

    test('grouping skips duplicate detections, leaves no empty groups and '
        'advances the generation', () async {
      await repo.enable();
      await addRawFaces(repo, 'd-1', [
        observation('d-1', 'main', vector: axis(0)),
        observation('d-1', 'echo', vector: axis(0)).copyWith(
          x: const Value(.12),
          y: const Value(.12),
          w: const Value(.37),
          h: const Value(.37),
        ),
      ]);
      await addVectorFaces(repo, 'd-2', {'other': axis(0)});
      await seedPassingPeopleReview(repo);
      final generation = (await repo.state()).generation;
      expect(await repo.groupNow(), greaterThan(0));
      expect((await faceRow(db, 'echo')).personId, isNull);
      expect((await repo.state()).generation, greaterThan(generation));
      final persons = await db.select(db.peoplePersons).get();
      final faces = await db.select(db.peopleFaces).get();
      for (final p in persons) {
        expect(faces.any((f) => f.personId == p.id), isTrue, reason: p.id);
      }
    });

    test('face size follows the decoder: a 4160x3120 photo is prepared at '
        '1040x780', () async {
      await repo.enable();
      await repo.db.upsertPhotos([
        PhotoRowsCompanion.insert(
          id: 'big',
          source: 1,
          dateMs: 1,
          mtimeMs: const Value(1),
          width: const Value(4160),
          height: const Value(3120),
        ),
      ]);
      expect(
        await repo.commitPhoto(
          photoId: 'big',
          revision: '1:0:4160:3120',
          generation: (await repo.state()).generation,
          faces: [
            PeopleFacesCompanion.insert(
              id: 'small',
              photoId: 'big',
              revision: '1:0:4160:3120',
              contract: FaceContract.id,
              x: .1,
              y: .1,
              w: 30 / 1040,
              h: 30 / 780,
              quality: 'small face',
            ),
          ],
        ),
        isTrue,
      );
      final snapshot = await repo.load();
      final face = snapshot.faces.single;
      expect(snapshot.facePixels(face), closeTo(30, 1e-6));
      expect(snapshot.smallOrDuplicateFaces, {'small'});
    });
  });
}
