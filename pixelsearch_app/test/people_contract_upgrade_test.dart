import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';
import 'package:pixelsearch/domain/people/same_person.dart';

import 'people_repository_test.dart' show seedPhoto;
import 'people_suggestions_test.dart' show addVectorFaces, unitAt;

/// The contract before v2 lowered the minimum face size to 64 px.
const previous = 'sface-2021dec-mlkit-landmarks-v1';
const revision = '1:0:500:500';

PeopleFacesCompanion face(
  String id,
  (double, double, double, double) box, {
  String contract = FaceContract.id,
  String quality = 'ready',
  Float32List? vector,
}) => PeopleFacesCompanion.insert(
  id: id,
  photoId: 'p',
  revision: revision,
  contract: contract,
  x: box.$1,
  y: box.$2,
  w: box.$3,
  h: box.$4,
  quality: quality,
  vector: Value(vector == null ? null : encodeFaceVector(vector)),
);

void main() {
  late AppDatabase db;
  late PeopleRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PeopleRepository(db);
    await repo.enable();
  });
  tearDown(() => db.close());

  Future<PeopleFaceRecord?> row(String id) => (db.select(
    db.peopleFaces,
  )..where((f) => f.id.equals(id))).getSingleOrNull();

  test('a re-scan under the new contract keeps each matching face, its '
      'name, "Not a face" and decisions', () async {
    await seedPhoto(db, 'p');
    await db
        .into(db.peoplePersons)
        .insert(
          PeoplePersonsCompanion.insert(
            id: 'asha',
            name: const Value('Asha'),
            coverFaceId: const Value('named'),
            createdMs: 1,
          ),
        );
    // Under the earlier contract: a named face, a small face marked
    // "Not a face", an unassigned face the new scan no longer finds, and a
    // named face the new scan no longer finds.
    for (final (id, box, quality) in [
      ('named', (.10, .10, .30, .30), 'ready'),
      ('dismissed', (.50, .50, .15, .15), 'small face'),
      ('vanished', (.80, .80, .05, .05), 'small face'),
      ('vanished-named', (.10, .70, .10, .10), 'small face'),
    ]) {
      await db
          .into(db.peopleFaces)
          .insert(
            face(
              id,
              box,
              contract: previous,
              quality: quality,
              vector: quality == 'ready' ? unitAt(0) : null,
            ),
          );
    }
    await (db.update(
      db.peopleFaces,
    )..where((f) => f.id.isIn(['named', 'vanished-named']))).write(
      const PeopleFacesCompanion(
        personId: Value('asha'),
        assignment: Value('manual'),
      ),
    );
    await (db.update(db.peopleFaces)..where((f) => f.id.equals('dismissed')))
        .write(const PeopleFacesCompanion(dismissed: Value(true)));
    await db
        .into(db.peopleDecisions)
        .insert(
          PeopleDecisionsCompanion.insert(
            faceId: 'named',
            personId: 'asha',
            decision: 'accept',
          ),
        );
    await db
        .into(db.peopleDecisions)
        .insert(
          PeopleDecisionsCompanion.insert(
            faceId: 'dismissed',
            personId: 'asha',
            decision: 'reject',
          ),
        );

    // The new scan finds the same boxes (a little shifted), now with a
    // descriptor for the 64-99 px face, plus one face it did not find before.
    expect(
      await repo.commitPhoto(
        photoId: 'p',
        revision: revision,
        generation: (await repo.state()).generation,
        faces: [
          face('new-0', (.11, .10, .30, .30), vector: unitAt(5)),
          face('new-1', (.50, .51, .15, .15), vector: unitAt(90)),
          face('new-2', (.30, .40, .12, .12), vector: unitAt(45)),
        ],
      ),
      isTrue,
    );

    final named = (await row('named'))!;
    expect(named.contract, FaceContract.id);
    expect(named.personId, 'asha');
    expect(named.assignment, 'manual');
    expect(named.x, closeTo(.11, 1e-9));
    expect(decodeFaceVector(named.vector), unitAt(5));
    final dismissed = (await row('dismissed'))!;
    expect(dismissed.dismissed, isTrue);
    expect(dismissed.contract, FaceContract.id);
    expect(dismissed.quality, 'ready');
    expect(await row('new-0'), isNull, reason: 'continued as "named"');
    expect(await row('new-1'), isNull, reason: 'continued as "dismissed"');
    expect((await row('new-2'))!.personId, isNull);
    expect(await row('vanished'), isNull, reason: 'nothing to keep');
    // A named face the new scan misses stays on record but is not shown.
    expect((await row('vanished-named'))!.contract, previous);

    final decisions = await db.select(db.peopleDecisions).get();
    expect(decisions.map((d) => (d.faceId, d.decision)), [
      ('named', 'accept'),
      ('dismissed', 'reject'),
    ]);
    final snapshot = await repo.load();
    expect(snapshot.faces.map((f) => f.id).toSet(), {
      'named',
      'dismissed',
      'new-2',
    });
    final asha = snapshot.people.singleWhere((p) => p.record.id == 'asha');
    expect(asha.faces.map((f) => f.id), ['named']);
    expect(asha.cover?.id, 'named');
  });

  test('until a photo is re-scanned, its earlier faces stay visible and it '
      'does not count as processed', () async {
    await seedPhoto(db, 'p');
    await db
        .into(db.peopleFaces)
        .insert(
          face('old', (.1, .1, .3, .3), contract: previous, vector: unitAt(0)),
        );
    await db
        .into(db.peopleScans)
        .insert(
          PeopleScansCompanion.insert(
            photoId: 'p',
            revision: revision,
            contract: previous,
            status: 'done',
            faces: const Value(1),
            completedMs: 1,
          ),
        );
    var snapshot = await repo.load();
    expect(snapshot.faces.map((f) => f.id), ['old']);
    expect(snapshot.processed, 0);
    expect(await repo.hasPendingPhotos(), isTrue);

    await repo.commitPhoto(
      photoId: 'p',
      revision: revision,
      generation: (await repo.state()).generation,
      faces: [face('new', (.1, .1, .3, .3), vector: unitAt(0))],
    );
    snapshot = await repo.load();
    expect(snapshot.faces.map((f) => (f.id, f.contract)), [
      ('old', FaceContract.id),
    ]);
    expect(snapshot.processed, 1);
    expect(await repo.hasPendingPhotos(), isFalse);
  });

  test('reviews under the earlier contract keep grouping off until a new '
      'review, and say why', () async {
    await addVectorFaces(repo, 'a', {'fa': unitAt(0)});
    await addVectorFaces(repo, 'b', {'fb': unitAt(1)});
    await db
        .into(db.peopleReviews)
        .insert(
          PeopleReviewsCompanion.insert(
            id: 'old-pair',
            leftFaceId: 'fa',
            rightFaceId: 'fb',
            subset: 'calibration',
            cosine: .99,
            judgment: const Value('same'),
            contract: previous,
          ),
        );
    final calibration = await repo.calibration();
    expect(calibration.passed, isFalse);
    expect(calibration.reason, contains('smaller faces'));
    expect(calibration.reason, contains('Start a new review'));
    expect(await repo.groupNow(), 0);
    await repo.archiveReview();
    expect((await repo.calibration()).reason, isNot(contains('smaller')));
  });

  test('while a new review is unjudged, archived answers keep the question '
      'floor', () async {
    // Two unnamed look-alike groups, 20 degrees apart (cosine about 0.94),
    // and a far pair (cosine 0).
    await addVectorFaces(repo, 'g1', {'g1': unitAt(0)});
    await addVectorFaces(repo, 'g2', {'g2': unitAt(20)});
    await addVectorFaces(repo, 'g3', {'g3': unitAt(90)});
    for (final id in ['g1', 'g2', 'g3']) {
      await repo.createPerson([id]);
    }
    await db
        .into(db.peopleReviews)
        .insert(
          PeopleReviewsCompanion.insert(
            id: 'archived-same',
            leftFaceId: 'g1',
            rightFaceId: 'g2',
            subset: 'archived:calibration',
            cosine: .9,
            judgment: const Value('same'),
            contract: previous,
          ),
        );
    final questions = await repo.samePersonQuestions(limit: 100);
    expect(questions, isNotEmpty);
    expect(
      questions.every((q) => q.kind == SamePersonKind.mergeGroups),
      isTrue,
    );
    // Only the close pair clears the archived floor of 0.9.
    expect(questions.map((q) => {q.leftFaceId, q.rightFaceId}), [
      {'g1', 'g2'},
    ]);
  });
}
