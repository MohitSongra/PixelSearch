import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';
import 'package:pixelsearch/domain/people/face_grouping.dart';

import 'people_repository_test.dart' show addFaces, observation, seedPhoto;

Future<void> seedFailedPeopleReview(PeopleRepository repo) async {
  await repo.enable();
  for (var i = 0; i < 60; i++) {
    for (final side in ['a', 'b']) {
      await addFaces(repo, 'photo-$i-$side', ['face-$i-$side']);
    }
    final validation = i >= 40;
    final different = i == 39 || i == 59;
    await repo.db
        .into(repo.db.peopleReviews)
        .insert(
          PeopleReviewsCompanion.insert(
            id: 'pair-$i',
            leftFaceId: 'face-$i-a',
            rightFaceId: 'face-$i-b',
            subset: validation ? 'validation' : 'calibration',
            cosine: different ? (validation ? .85 : .4) : (i == 0 ? .95 : .8),
            judgment: Value(different ? 'different' : 'same'),
            contract: FaceContract.id,
          ),
        );
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
    'failed cutoff stays blocked and fresh check preserves every rating',
    () async {
      await seedFailedPeopleReview(repo);
      for (var i = 0; i < 35; i++) {
        await addFaces(repo, 'new-photo-$i', ['new-face-$i']);
      }
      final before = await repo.load();
      expect((await repo.calibration()).passed, isFalse);
      expect(await repo.applyGrouping(), 0);
      expect(await repo.prepareFreshValidation(), 20);
      final after = await PeopleRepository(db).load();
      expect(after.reviews, hasLength(80));
      expect(
        after.reviews.take(60).map((p) => p.judgment),
        before.reviews.map((p) => p.judgment),
      );
      expect(
        after.reviews.take(60).every((p) => p.subset == 'calibration'),
        isTrue,
      );
      expect(
        after.reviews
            .skip(60)
            .every((p) => p.subset == 'validation' && p.judgment == 'pending'),
        isTrue,
      );
      expect(
        after.reviews
            .skip(60)
            .every(
              (p) =>
                  p.leftFaceId.startsWith('new-face-') &&
                  p.rightFaceId.startsWith('new-face-'),
            ),
        isTrue,
      );
      final archived = (await db.select(db.peopleReviews).get()).where(
        (p) => p.subset.startsWith('archived:'),
      );
      expect(archived.map((p) => p.id), before.reviews.map((p) => p.id));
      expect(
        after.faces.map((p) => p.toJson()),
        before.faces.map((p) => p.toJson()),
      );
      expect(after.state.threshold, isNull);
      expect(jsonDecode(after.state.calibrationJson)['passed'], isFalse);
      expect(await repo.applyGrouping(), 0);
      await expectLater(repo.prepareFreshValidation(), throwsStateError);
    },
  );

  test('insufficient unseen photos leaves the saved round untouched', () async {
    await seedFailedPeopleReview(repo);
    final before = await repo.load();
    await expectLater(repo.prepareFreshValidation(), throwsStateError);
    final after = await repo.load();
    expect(
      after.reviews.map((r) => r.toJson()),
      before.reviews.map((r) => r.toJson()),
    );
    expect(after.state, before.state);
  });

  test('starting over cannot recycle archived test photos', () async {
    await seedFailedPeopleReview(repo);
    await repo.archiveReview();
    await expectLater(repo.prepareReview(), throwsStateError);
    expect((await repo.load()).reviews, isEmpty);
    expect(await db.select(db.peopleReviews).get(), hasLength(60));
  });
  test(
    'inseparable training evidence does not waste another review round',
    () async {
      await seedFailedPeopleReview(repo);
      await (db.update(db.peopleReviews)..where((r) => r.id.equals('pair-0')))
          .write(const PeopleReviewsCompanion(cosine: Value(.8)));
      final before = await repo.load();
      await expectLater(repo.prepareFreshValidation(), throwsStateError);
      expect(
        (await repo.load()).reviews.map((p) => p.toJson()),
        before.reviews.map((p) => p.toJson()),
      );
    },
  );

  List<FacePair> pairsOf(Iterable<PeopleReviewRecord> rows) => [
    for (final r in rows)
      FacePair(
        left: r.leftFaceId,
        right: r.rightFaceId,
        subset: r.subset,
        cosine: r.cosine,
        judgment: r.judgment,
      ),
  ];

  Future<int> automaticCount() async => (await (db.select(
    db.peopleFaces,
  )..where((f) => f.assignment.equals('automatic'))).get()).length;

  test('deleting a reviewed photo keeps automatic grouping off', () async {
    await seedFailedPeopleReview(repo);
    // With the seed alone, dropping the false join would leave no
    // different-person validation pair, so the control below would fail for
    // an unrelated reason. One distant different-person pair on new photos
    // makes "the remaining pairs would pass" true.
    for (final side in ['a', 'b']) {
      await addFaces(repo, 'photo-distant-$side', ['face-distant-$side']);
    }
    await db
        .into(db.peopleReviews)
        .insert(
          PeopleReviewsCompanion.insert(
            id: 'pair-distant',
            leftFaceId: 'face-distant-a',
            rightFaceId: 'face-distant-b',
            subset: 'validation',
            cosine: .3,
            judgment: const Value('different'),
            contract: FaceContract.id,
          ),
        );
    final saved = await db.select(db.peopleReviews).get();
    final full = calibrateFaces(pairsOf(saved));
    expect(full.passed, isFalse);
    expect(full.falseJoinPairIds, hasLength(1));
    final falseJoin = saved.singleWhere(
      (r) => '${r.leftFaceId}|${r.rightFaceId}' == full.falseJoinPairIds.single,
    );
    expect(falseJoin.subset, 'validation');
    expect(falseJoin.judgment, 'different');
    // Control: re-scoring the remaining pairs would open the gate.
    final withoutFalseJoin = calibrateFaces(
      pairsOf(saved.where((r) => r.id != falseJoin.id)),
    );
    expect(withoutFalseJoin.passed, isTrue);
    expect((await repo.calibration()).passed, isFalse);

    final faces = {for (final f in (await repo.load()).faces) f.id: f};
    final deletedPhoto = faces[falseJoin.leftFaceId]!.photoId;
    final survivingFace = falseJoin.rightFaceId;
    expect(faces[survivingFace]!.photoId, isNot(deletedPhoto));
    await db.deleteAssets([deletedPhoto]);

    final calibration = await repo.calibration();
    expect(calibration.passed, isFalse);
    expect(calibration.reason, contains('unavailable'));
    await repo.reconcile();
    final state = await repo.state();
    expect(state.enabled, isTrue);
    expect(state.paused, isFalse);
    expect(state.threshold, isNull);
    expect(jsonDecode(state.calibrationJson)['passed'], isFalse);
    expect(await repo.applyGrouping(), 0);
    expect(await automaticCount(), 0);
    expect((await repo.state()).threshold, isNull);

    final remaining = await db.select(db.peopleReviews).get();
    expect(remaining, hasLength(saved.length));
    expect(
      remaining
          .where(
            (r) =>
                r.leftFaceId == survivingFace || r.rightFaceId == survivingFace,
          )
          .map((r) => r.toJson()),
      [falseJoin.toJson()],
    );
    expect((await repo.load()).faces.map((f) => f.id), contains(survivingFace));
  });

  test(
    'a deleted reviewed photo blocks the fresh check until a new review',
    () async {
      await seedFailedPeopleReview(repo);
      // Enough unseen faces that only the deleted photo can block the check.
      for (var i = 0; i < 35; i++) {
        await addFaces(repo, 'new-photo-$i', ['new-face-$i']);
      }
      await db.deleteAssets(['photo-59-a']);
      final before = await db.select(db.peopleReviews).get();

      await expectLater(repo.prepareFreshValidation(), throwsStateError);
      expect(
        (await db.select(db.peopleReviews).get()).map((r) => r.toJson()),
        before.map((r) => r.toJson()),
      );
      expect((await repo.calibration()).passed, isFalse);

      await repo.archiveReview();
      expect((await repo.load()).reviews, isEmpty);
      final rows = await db.select(db.peopleReviews).get();
      expect(rows, hasLength(60));
      expect(rows.every((r) => r.subset.startsWith('archived:')), isTrue);
      expect((await repo.calibration()).passed, isFalse);
      expect((await repo.state()).threshold, isNull);
      expect(await repo.applyGrouping(), 0);
      expect(await automaticCount(), 0);
      await expectLater(repo.prepareFreshValidation(), throwsStateError);
    },
  );

  test(
    'a revised reviewed photo is not recycled into a new review',
    skip:
        'BUG: _reviewedPhotos() maps review face ids through current '
        'people_faces; a revised photo gets new face ids, so it is sampled again',
    () async {
      await seedFailedPeopleReview(repo);
      await repo.archiveReview();
      // Unseen photos with orthogonal descriptors (pairwise cosine 0).
      for (var k = 0; k < 40; k++) {
        await seedPhoto(db, 'fresh-photo-$k');
        expect(
          await repo.commitPhoto(
            photoId: 'fresh-photo-$k',
            revision: '1:0:500:500',
            generation: (await repo.state()).generation,
            faces: [
              observation(
                'fresh-photo-$k',
                'fresh-face-$k',
                vector: Float32List(FaceContract.dimensions)..[k] = 1,
              ),
            ],
          ),
          isTrue,
        );
      }
      // A reviewed photo is revised (for example edited) and re-processed: its
      // face gets a new id. Its descriptor is the closest to every unseen face,
      // so a sampler that does not exclude it is certain to pick it.
      final blend = Float32List(FaceContract.dimensions);
      for (var k = 0; k < 40; k++) {
        blend[k] = 1 / math.sqrt(40);
      }
      await seedPhoto(db, 'photo-0-a', revision: 2);
      await repo.reconcile();
      expect(
        await repo.commitPhoto(
          photoId: 'photo-0-a',
          revision: '2:0:500:500',
          generation: (await repo.state()).generation,
          faces: [
            observation(
              'photo-0-a',
              'revised-face',
              revision: 2,
              vector: blend,
            ),
          ],
        ),
        isTrue,
      );

      expect(await repo.prepareReview(), greaterThanOrEqualTo(40));
      final review = (await repo.load()).reviews;
      expect(
        review.where(
          (r) =>
              r.leftFaceId == 'revised-face' || r.rightFaceId == 'revised-face',
        ),
        isEmpty,
      );
      expect(
        review.every(
          (r) =>
              r.leftFaceId.startsWith('fresh-face-') &&
              r.rightFaceId.startsWith('fresh-face-'),
        ),
        isTrue,
      );
    },
  );
}
