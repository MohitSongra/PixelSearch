import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../domain/people/face_contract.dart';
import '../domain/people/face_grouping.dart';
import 'local/app_database.dart';

String peopleRevision(PhotoRow photo) =>
    '${photo.mtimeMs}:${photo.byteSize}:${photo.width}:${photo.height}';

Uint8List encodeFaceVector(Float32List vector) {
  if (!validFaceVector(vector)) {
    throw const FormatException('Invalid face vector.');
  }
  final bytes = ByteData(vector.length * 4);
  for (var i = 0; i < vector.length; i++) {
    bytes.setFloat32(i * 4, vector[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

Float32List? decodeFaceVector(Uint8List? bytes) {
  if (bytes == null || bytes.length != FaceContract.dimensions * 4) return null;
  final data = ByteData.sublistView(bytes);
  final result = Float32List(FaceContract.dimensions);
  for (var i = 0; i < result.length; i++) {
    result[i] = data.getFloat32(i * 4, Endian.little);
  }
  return validFaceVector(result) ? result : null;
}

class PersonView {
  const PersonView(this.record, this.faces, this.latest);
  final PersonRecord record;
  final List<PeopleFaceRecord> faces;
  final DateTime latest;
  int get photoCount => faces.map((f) => f.photoId).toSet().length;
  String get label => record.name.isEmpty ? 'Unnamed person' : record.name;
  PeopleFaceRecord? get cover {
    for (final face in faces) {
      if (face.id == record.coverFaceId) return face;
    }
    return faces.isEmpty ? null : faces.first;
  }

  List<String> get aliases =>
      (jsonDecode(record.aliasesJson) as List).cast<String>();
}

class PeopleSnapshot {
  const PeopleSnapshot({
    required this.state,
    this.people = const [],
    this.faces = const [],
    this.reviews = const [],
    this.total = 0,
    this.processed = 0,
    this.inaccessible = 0,
    this.failed = 0,
  });
  final PeopleStateRecord state;
  final List<PersonView> people;
  final List<PeopleFaceRecord> faces;
  final List<PeopleReviewRecord> reviews;
  final int total, processed, inaccessible, failed;
  List<PeopleFaceRecord> get unassigned =>
      faces.where((f) => f.personId == null && !f.dismissed).toList();
  List<PersonView> get unnamedPeople => people
      .where(
        (p) =>
            p.record.name.trim().isEmpty &&
            !p.record.hidden &&
            p.faces.isNotEmpty,
      )
      .toList();
  int get facesToName =>
      unassigned.length +
      unnamedPeople.fold(0, (count, p) => count + p.faces.length);
}

class PeopleRepository {
  PeopleRepository(this.db, {this.accessiblePhotoIds});
  final AppDatabase db;
  final Future<Set<String>?> Function()? accessiblePhotoIds;

  Future<bool> hasPendingPhotos() async {
    final current = await state();
    if (!current.enabled || current.paused) return false;
    final row = await db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM photo_rows p '
          'LEFT JOIN people_scans s ON s.photo_id=p.id WHERE s.photo_id IS NULL OR '
          "s.revision != (p.mtime_ms || ':' || p.byte_size || ':' || p.width || ':' || p.height) OR s.contract != ?) AS pending",
          variables: [const Variable(FaceContract.id)],
        )
        .getSingle();
    return row.read<int>('pending') == 1;
  }

  Future<PeopleStateRecord> state() async =>
      await (db.select(
        db.peopleState,
      )..where((s) => s.id.equals(0))).getSingleOrNull() ??
      const PeopleStateRecord(
        id: 0,
        enabled: false,
        paused: false,
        generation: 0,
        calibrationJson: '{}',
      );

  Future<void> _advance({
    bool? enabled,
    bool? paused,
    Value<double?> threshold = const Value.absent(),
    String? calibration,
  }) async {
    final previous = await state();
    await db
        .into(db.peopleState)
        .insertOnConflictUpdate(
          PeopleStateCompanion(
            id: const Value(0),
            enabled: Value(enabled ?? previous.enabled),
            paused: Value(paused ?? previous.paused),
            generation: Value(previous.generation + 1),
            threshold: threshold.present
                ? threshold
                : Value(previous.threshold),
            calibrationJson: Value(calibration ?? previous.calibrationJson),
          ),
        );
  }

  Future<void> enable() =>
      db.transaction(() => _advance(enabled: true, paused: false));
  Future<void> pause(bool paused) =>
      db.transaction(() => _advance(paused: paused));

  /// Drop observations for deleted/revised photos, but retain names and audit
  /// decisions. A revision cannot inherit an old positional face identity.
  Future<void> reconcile() => db.transaction(() async {
    await db.customStatement(
      'DELETE FROM people_faces WHERE NOT EXISTS ('
      'SELECT 1 FROM photo_rows p WHERE p.id = people_faces.photo_id AND '
      "people_faces.revision = (p.mtime_ms || ':' || p.byte_size || ':' || p.width || ':' || p.height))",
    );
    await db.customStatement(
      'DELETE FROM people_scans WHERE NOT EXISTS ('
      'SELECT 1 FROM photo_rows p WHERE p.id = people_scans.photo_id)',
    );
    final result = await calibration();
    await (db.update(db.peopleState)..where((s) => s.id.equals(0))).write(
      PeopleStateCompanion(
        threshold: Value(result.threshold),
        calibrationJson: Value(jsonEncode(result.toJson())),
      ),
    );
  });

  Future<List<String>> disableAndDelete() => db.transaction(() async {
    await _advance(
      enabled: false,
      paused: false,
      threshold: const Value(null),
      calibration: '{}',
    );
    final paths = (await db.select(db.peopleFaces).get())
        .map((f) => f.cropPath)
        .whereType<String>()
        .toList();
    await db.delete(db.peopleReviews).go();
    await db.delete(db.peopleDecisions).go();
    await db.delete(db.peopleFaces).go();
    await db.delete(db.peopleScans).go();
    await db.delete(db.peoplePersons).go();
    return paths;
  });

  Future<PeopleSnapshot> load() => db.transaction(() async {
    final current = await state();
    final photos = {for (final p in await db.allPhotos()) p.id: p};
    if (!current.enabled) {
      return PeopleSnapshot(state: current, total: photos.length);
    }
    final accessible = await accessiblePhotoIds?.call();
    if (accessible != null) {
      photos.removeWhere((id, _) => !accessible.contains(id));
    }
    final scans = await db.select(db.peopleScans).get();
    final done = <String>{};
    var inaccessible = 0, failed = 0;
    for (final s in scans) {
      final photo = photos[s.photoId];
      if (photo == null ||
          s.revision != peopleRevision(photo) ||
          s.contract != FaceContract.id) {
        continue;
      }
      if (s.status == 'done') done.add(s.photoId);
      if (s.status == 'inaccessible') inaccessible++;
      if (s.status == 'failed') failed++;
    }
    final faces =
        (await db.select(db.peopleFaces).get())
            .where(
              (f) =>
                  done.contains(f.photoId) &&
                  f.contract == FaceContract.id &&
                  f.revision == peopleRevision(photos[f.photoId]!),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final persons = await db.select(db.peoplePersons).get();
    final people = <PersonView>[];
    for (final p in persons) {
      final members = faces
          .where((f) => f.personId == p.id && !f.dismissed)
          .toList();
      final dates = members.map((f) => photos[f.photoId]!.dateMs).toList()
        ..sort();
      people.add(
        PersonView(
          p,
          members,
          DateTime.fromMillisecondsSinceEpoch(
            dates.isEmpty ? p.createdMs : dates.last,
          ),
        ),
      );
    }
    final reviews = await (db.select(
      db.peopleReviews,
    )..where((r) => r.subset.isIn(['calibration', 'validation']))).get();
    return PeopleSnapshot(
      state: current,
      people: people,
      faces: faces,
      reviews: reviews,
      total: photos.length,
      processed: done.length,
      inaccessible: inaccessible,
      failed: failed,
    );
  });

  Future<bool> isCurrent(
    String photoId,
    String revision,
    int generation,
  ) async {
    final current = await state();
    if (!current.enabled ||
        current.paused ||
        current.generation != generation) {
      return false;
    }
    final photo = await (db.select(
      db.photoRows,
    )..where((p) => p.id.equals(photoId))).getSingleOrNull();
    return photo != null && peopleRevision(photo) == revision;
  }

  Future<bool> commitPhoto({
    required String photoId,
    required String revision,
    required int generation,
    required List<PeopleFacesCompanion> faces,
    String status = 'done',
  }) => db.transaction(() async {
    if (!await isCurrent(photoId, revision, generation)) return false;
    if (status == 'done') {
      // A revision never inherits old positional face identities.
      await (db.delete(db.peopleFaces)..where(
            (f) =>
                f.photoId.equals(photoId) & f.revision.equals(revision).not(),
          ))
          .go();
      for (final face in faces) {
        if (face.photoId.value != photoId ||
            face.revision.value != revision ||
            face.contract.value != FaceContract.id) {
          throw StateError('Face revision mismatch.');
        }
        if (face.vector.value != null &&
            decodeFaceVector(face.vector.value) == null) {
          throw const FormatException('Invalid descriptor bytes.');
        }
        // Repeated processing cannot overwrite user corrections.
        await db
            .into(db.peopleFaces)
            .insert(face, mode: InsertMode.insertOrIgnore);
      }
    }
    await db
        .into(db.peopleScans)
        .insertOnConflictUpdate(
          PeopleScansCompanion.insert(
            photoId: photoId,
            revision: revision,
            contract: FaceContract.id,
            status: status,
            faces: Value(faces.length),
            completedMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return true;
  });

  Future<PeopleFaceRecord> _face(String id) async {
    if (!(await state()).enabled) {
      throw StateError('People grouping is disabled.');
    }
    final face = (await load()).faces.where((f) => f.id == id).firstOrNull;
    if (face == null) throw StateError('This face is no longer available.');
    return face;
  }

  Future<String> createPerson(
    List<String> faceIds, {
    String name = '',
    List<String> aliases = const [],
  }) => db.transaction(() async {
    if (faceIds.isEmpty) throw ArgumentError('Select at least one face.');
    for (final id in faceIds) {
      await _face(id);
    }
    final id = 'manual:${DateTime.now().microsecondsSinceEpoch}';
    await db
        .into(db.peoplePersons)
        .insert(
          PeoplePersonsCompanion.insert(
            id: id,
            createdMs: DateTime.now().millisecondsSinceEpoch,
            name: Value(_name(name)),
            aliasesJson: Value(_aliases(aliases)),
            coverFaceId: Value(faceIds.first),
          ),
        );
    await _assign(faceIds, id);
    await _advance();
    return id;
  });

  String _name(String name) {
    final trimmed = name.trim();
    if (trimmed.length > 100) {
      throw ArgumentError('Names can have up to 100 characters.');
    }
    return trimmed;
  }

  String _aliases(List<String> aliases) => jsonEncode(
    aliases.map(_name).where((s) => s.isNotEmpty).toSet().toList(),
  );

  Future<void> editPerson(
    String id, {
    String? name,
    List<String>? aliases,
    String? coverFaceId,
    bool? hidden,
  }) => db.transaction(() async {
    if (!(await state()).enabled) {
      throw StateError('People grouping is disabled.');
    }
    if (coverFaceId != null && (await _face(coverFaceId)).personId != id) {
      throw ArgumentError('Choose a face belonging to this person.');
    }
    await (db.update(db.peoplePersons)..where((p) => p.id.equals(id))).write(
      PeoplePersonsCompanion(
        name: name == null ? const Value.absent() : Value(_name(name)),
        aliasesJson: aliases == null
            ? const Value.absent()
            : Value(_aliases(aliases)),
        coverFaceId: coverFaceId == null
            ? const Value.absent()
            : Value(coverFaceId),
        hidden: hidden == null ? const Value.absent() : Value(hidden),
      ),
    );
    await _advance();
  });

  Future<void> _assign(
    List<String> faceIds,
    String? personId, {
    bool dismiss = false,
  }) async {
    if (personId != null &&
        await (db.select(
              db.peoplePersons,
            )..where((p) => p.id.equals(personId))).getSingleOrNull() ==
            null) {
      throw StateError('Person no longer exists.');
    }
    for (final id in faceIds) {
      final face = await _face(id);
      if (face.personId != null && face.personId != personId) {
        await db
            .into(db.peopleDecisions)
            .insertOnConflictUpdate(
              PeopleDecisionsCompanion.insert(
                faceId: id,
                personId: face.personId!,
                decision: 'reject',
              ),
            );
      }
      if (personId != null) {
        await db
            .into(db.peopleDecisions)
            .insertOnConflictUpdate(
              PeopleDecisionsCompanion.insert(
                faceId: id,
                personId: personId,
                decision: 'accept',
              ),
            );
      }
      await (db.update(db.peopleFaces)..where((f) => f.id.equals(id))).write(
        PeopleFacesCompanion(
          personId: Value(personId),
          assignment: Value(personId == null ? 'unassigned' : 'manual'),
          dismissed: Value(dismiss),
        ),
      );
    }
  }

  Future<void> assign(
    List<String> ids,
    String? personId, {
    bool dismiss = false,
  }) => db.transaction(() async {
    await _assign(ids, personId, dismiss: dismiss);
    await _advance();
  });

  Future<void> merge(String source, String target) => db.transaction(() async {
    if (source == target) return;
    final snapshot = await load();
    final from = snapshot.people
        .where((p) => p.record.id == source)
        .firstOrNull;
    final to = snapshot.people.where((p) => p.record.id == target).firstOrNull;
    if (from == null || to == null) {
      throw StateError('Person no longer exists.');
    }
    await _assign(from.faces.map((f) => f.id).toList(), target);
    final aliases = {
      ...to.aliases,
      ...from.aliases,
      if (from.record.name.isNotEmpty && from.record.name != to.record.name)
        from.record.name,
    };
    await (db.update(
      db.peoplePersons,
    )..where((p) => p.id.equals(target))).write(
      PeoplePersonsCompanion(
        aliasesJson: Value(_aliases(aliases.toList())),
        coverFaceId: Value(to.record.coverFaceId ?? from.record.coverFaceId),
      ),
    );
    final rejected =
        await (db.select(db.peopleDecisions)..where(
              (d) => d.personId.equals(source) & d.decision.equals('reject'),
            ))
            .get();
    for (final r in rejected) {
      final targetDecision =
          await (db.select(db.peopleDecisions)..where(
                (d) => d.faceId.equals(r.faceId) & d.personId.equals(target),
              ))
              .getSingleOrNull();
      if (targetDecision == null) {
        await db
            .into(db.peopleDecisions)
            .insert(
              PeopleDecisionsCompanion.insert(
                faceId: r.faceId,
                personId: target,
                decision: 'reject',
              ),
            );
      }
    }
    // Retain explicit corrections for currently inaccessible observations too.
    await (db.update(
      db.peopleFaces,
    )..where((f) => f.personId.equals(source))).write(
      PeopleFacesCompanion(
        personId: Value(target),
        assignment: const Value('manual'),
      ),
    );
    await (db.delete(db.peoplePersons)..where((p) => p.id.equals(source))).go();
    await _advance();
  });

  Future<Set<String>> photoIdsFor(Set<String> personIds) async {
    if (personIds.isEmpty) throw ArgumentError('Person selection is empty.');
    final snapshot = await load();
    if (!snapshot.state.enabled) return {};
    Set<String>? matches;
    for (final id in personIds) {
      final photos = snapshot.faces
          .where((f) => f.personId == id && !f.dismissed)
          .map((f) => f.photoId)
          .toSet();
      matches = matches == null ? photos : matches.intersection(photos);
    }
    return matches ?? {};
  }

  List<FaceVector> vectors(
    PeopleSnapshot snapshot, [
    List<PeopleDecisionRecord> decisions = const [],
  ]) => [
    for (final face in snapshot.faces)
      if (!face.dismissed &&
          face.quality == 'ready' &&
          decodeFaceVector(face.vector) != null)
        FaceVector(
          id: face.id,
          photoId: face.photoId,
          vector: decodeFaceVector(face.vector)!,
          personId: face.personId,
          rejectedPeople: decisions
              .where((d) => d.faceId == face.id && d.decision == 'reject')
              .map((d) => d.personId)
              .toSet(),
        ),
  ];

  Future<int> prepareReview() async {
    final snapshot = await load();
    if (!snapshot.state.enabled) {
      throw StateError('Enable People grouping first.');
    }
    if (snapshot.reviews.isNotEmpty) return snapshot.reviews.length;
    final pairs = await compute(buildFaceReview, vectors(snapshot));
    if (pairs.length < 40) {
      throw StateError(
        'Not enough detailed faces for a 40-pair review yet. Manual naming remains available.',
      );
    }
    return db.transaction(() async {
      final current = await state();
      if (!current.enabled || current.generation != snapshot.state.generation) {
        return 0;
      }
      final existing = await (db.select(
        db.peopleReviews,
      )..where((r) => r.subset.isIn(['calibration', 'validation']))).get();
      if (existing.isNotEmpty) return existing.length;
      final prefix = DateTime.now().microsecondsSinceEpoch;
      await db.batch(
        (b) => b.insertAll(db.peopleReviews, [
          for (final p in pairs)
            PeopleReviewsCompanion.insert(
              id: '$prefix:${p.id}',
              leftFaceId: p.left,
              rightFaceId: p.right,
              subset: p.subset,
              cosine: p.cosine,
              contract: FaceContract.id,
            ),
        ]),
      );
      return pairs.length;
    });
  }

  Future<FaceCalibration> calibration() async {
    final snapshot = await load();
    final faces = {for (final f in snapshot.faces) f.id: f};
    final calPhotos = <String>{}, valPhotos = <String>{};
    for (final p in snapshot.reviews) {
      if (p.contract != FaceContract.id ||
          !faces.containsKey(p.leftFaceId) ||
          !faces.containsKey(p.rightFaceId)) {
        return const FaceCalibration(
          reason:
              'A reviewed photo changed or is unavailable. Start a new review.',
        );
      }
      final photos = p.subset == 'calibration' ? calPhotos : valPhotos;
      photos.addAll([
        faces[p.leftFaceId]!.photoId,
        faces[p.rightFaceId]!.photoId,
      ]);
    }
    if (calPhotos.intersection(valPhotos).isNotEmpty) {
      return const FaceCalibration(
        reason: 'Review subsets overlap. Automatic grouping is blocked.',
      );
    }
    if (snapshot.reviews.length < 40) {
      return const FaceCalibration(
        reason:
            'At least 40 frozen pairs are needed for the local review. More detailed faces are needed.',
      );
    }
    return calibrateFaces([
      for (final p in snapshot.reviews)
        FacePair(
          left: p.leftFaceId,
          right: p.rightFaceId,
          subset: p.subset,
          cosine: p.cosine,
          judgment: p.judgment,
        ),
    ]);
  }

  Future<void> judge(String pairId, String judgment) =>
      db.transaction(() async {
        if (!['same', 'different', 'unsure'].contains(judgment)) {
          throw ArgumentError('Invalid judgment.');
        }
        if (!(await state()).enabled) {
          throw StateError('People grouping is disabled.');
        }
        await (db.update(db.peopleReviews)..where(
              (r) =>
                  r.id.equals(pairId) &
                  r.subset.isIn(['calibration', 'validation']),
            ))
            .write(PeopleReviewsCompanion(judgment: Value(judgment)));
        final result = await calibration();
        await _advance(
          threshold: Value(result.threshold),
          calibration: jsonEncode(result.toJson()),
        );
      });

  Future<void> archiveReview() => db.transaction(() async {
    final current = await load();
    for (final row in current.reviews) {
      await (db.update(
        db.peopleReviews,
      )..where((r) => r.id.equals(row.id))).write(
        PeopleReviewsCompanion(subset: Value('archived:${row.subset}')),
      );
    }
    await _advance(threshold: const Value(null), calibration: '{}');
  });

  Future<int> applyGrouping() async {
    final snapshot = await load();
    if (!snapshot.state.enabled || snapshot.state.paused) return 0;
    final result = await calibration();
    if (!result.passed) return 0;
    final decisions = await db.select(db.peopleDecisions).get();
    final input = vectors(snapshot, decisions);
    final threshold = result.threshold!;
    final occupied = <String, Set<String>>{};
    for (final face in snapshot.faces) {
      if (face.personId != null && !face.dismissed) {
        occupied.putIfAbsent(face.personId!, () => {}).add(face.photoId);
      }
    }
    final assignments = await compute(_group, (input, threshold, occupied));
    return db.transaction(() async {
      final current = await state();
      if (!current.enabled ||
          current.paused ||
          current.generation != snapshot.state.generation) {
        return 0;
      }
      // Indexing may have revised photos while the worker was clustering.
      final live = {for (final f in (await load()).faces) f.id};
      if (input.any((f) => !live.contains(f.id))) return 0;
      var count = 0;
      for (final entry in assignments.entries) {
        if (entry.value == null) continue;
        await db
            .into(db.peoplePersons)
            .insert(
              PeoplePersonsCompanion.insert(
                id: entry.value!,
                coverFaceId: Value(entry.key),
                createdMs: DateTime.now().millisecondsSinceEpoch,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        count +=
            await (db.update(db.peopleFaces)..where(
                  (f) =>
                      f.id.equals(entry.key) &
                      f.personId.isNull() &
                      f.dismissed.equals(false),
                ))
                .write(
                  PeopleFacesCompanion(
                    personId: Value(entry.value),
                    assignment: const Value('automatic'),
                  ),
                );
      }
      return count;
    });
  }
}

Map<String, String?> _group(
  (List<FaceVector>, double, Map<String, Set<String>>) input,
) => groupFaces(input.$1, input.$2, personPhotos: input.$3);
