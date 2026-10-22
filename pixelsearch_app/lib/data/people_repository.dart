import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../domain/people/face_contract.dart';
import '../domain/people/face_grouping.dart';
import '../domain/people/face_suggestions.dart';
import '../domain/people/people_membership.dart';
import '../domain/people/people_query.dart';
import '../domain/people/same_person.dart';
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
  PeopleSnapshot({
    required this.state,
    this.people = const [],
    this.faces = const [],
    this.reviews = const [],
    this.photoDates = const {},
    this.photoSizes = const {},
    this.total = 0,
    this.processed = 0,
    this.inaccessible = 0,
    this.failed = 0,
  });
  final PeopleStateRecord state;
  final List<PersonView> people;
  final List<PeopleFaceRecord> faces;
  final List<PeopleReviewRecord> reviews;

  /// Photo id → capture time (ms) for the accessible indexed photos.
  final Map<String, int> photoDates;

  /// Photo id → (width, height) in pixels, for face-size estimates.
  final Map<String, (int, int)> photoSizes;
  final int total, processed, inaccessible, failed;

  /// Approximate side length in pixels of [face] in the prepared image
  /// (long side at most 2048 px). Face boxes are fractions of the upright
  /// image; their area is the same whichever way the photo was rotated.
  double facePixels(PeopleFaceRecord face) {
    final size = photoSizes[face.photoId];
    if (size == null || size.$1 <= 0 || size.$2 <= 0) return double.infinity;
    // Same arithmetic as the Android decoder: halve until the long side fits.
    var sample = 1;
    final longest = math.max(size.$1, size.$2);
    while (longest / sample > 2048) {
      sample *= 2;
    }
    return math.sqrt(face.w * face.h * size.$1 * size.$2) / sample;
  }

  /// Faces kept out of the naming list by default: tiny background faces, and
  /// second detections overlapping a larger face in the same photo. Only
  /// unassigned faces and automatic faces in unnamed groups are considered;
  /// nothing the user named is ever hidden.
  /// They are not deleted and can still be named from the photo. Computed once
  /// per snapshot: the People and Search screens ask for it on every build.
  late final Set<String> smallOrDuplicateFaces = _smallOrDuplicateFaces();

  Set<String> _smallOrDuplicateFaces() {
    final byPhoto = <String, List<PeopleFaceRecord>>{};
    for (final face in faces) {
      if (!face.dismissed) {
        byPhoto.putIfAbsent(face.photoId, () => []).add(face);
      }
    }
    final named = {
      for (final p in people)
        if (p.record.name.trim().isNotEmpty) p.record.id,
    };
    final hidden = <String>{};
    for (final group in byPhoto.values) {
      for (final face in group) {
        if (face.personId != null &&
            (face.assignment != 'automatic' || named.contains(face.personId))) {
          continue;
        }
        if (facePixels(face) < tinyFacePixels) {
          hidden.add(face.id);
          continue;
        }
        final area = face.w * face.h;
        for (final other in group) {
          final otherArea = other.w * other.h;
          final larger =
              otherArea > area ||
              (otherArea == area && other.id.compareTo(face.id) < 0);
          if (other.id != face.id && larger && _overlap(face, other) > 0.5) {
            hidden.add(face.id);
            break;
          }
        }
      }
    }
    return hidden;
  }

  /// New faces to name: all unassigned faces, or only the clearly visible ones.
  List<PeopleFaceRecord> namingQueue({bool includeSmall = false}) {
    final ordered = newFacesInPhotoOrder;
    if (includeSmall) return ordered;
    final hidden = smallOrDuplicateFaces;
    return ordered.where((f) => !hidden.contains(f.id)).toList();
  }

  /// Unnamed groups to name; a single-face group whose face is tiny or a
  /// duplicate detection is hidden like that face would be.
  List<PersonView> namingGroups({bool includeSmall = false}) {
    if (includeSmall) return unnamedPeople;
    final hidden = smallOrDuplicateFaces;
    return unnamedPeople
        .where(
          (p) => !(p.faces.length == 1 && hidden.contains(p.faces.single.id)),
        )
        .toList();
  }

  /// Entries to name: each unnamed group counts once, like one person.
  int toName({bool includeSmall = false}) =>
      namingGroups(includeSmall: includeSmall).length +
      namingQueue(includeSmall: includeSmall).length;
  List<PeopleFaceRecord> get unassigned =>
      faces.where((f) => f.personId == null && !f.dismissed).toList();

  /// Unassigned faces with one event's faces together: newest photo first.
  List<PeopleFaceRecord> get newFacesInPhotoOrder => unassigned
    ..sort((a, b) {
      final byDate = (photoDates[b.photoId] ?? 0).compareTo(
        photoDates[a.photoId] ?? 0,
      );
      if (byDate != 0) return byDate;
      final byPhoto = a.photoId.compareTo(b.photoId);
      if (byPhoto != 0) return byPhoto;
      final byX = a.x.compareTo(b.x);
      return byX != 0 ? byX : a.id.compareTo(b.id);
    });
  List<PeopleFaceRecord> get dismissedFaces =>
      faces.where((f) => f.dismissed).toList();

  /// The person marked "This is me" (at most one after any edit).
  PersonView? get self =>
      people.where((p) => p.aliases.any(isSelfAlias)).firstOrNull;
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

/// Faces smaller than this (side length in the prepared image) are hidden
/// from the naming list by default.
const tinyFacePixels = 40.0;

double _overlap(PeopleFaceRecord a, PeopleFaceRecord b) =>
    _boxOverlap((a.x, a.y, a.w, a.h), (b.x, b.y, b.w, b.h));

/// Intersection over union of two (x, y, w, h) boxes.
double _boxOverlap(
  (double, double, double, double) a,
  (double, double, double, double) b,
) {
  final width = math.max(
    0.0,
    math.min(a.$1 + a.$3, b.$1 + b.$3) - math.max(a.$1, b.$1),
  );
  final height = math.max(
    0.0,
    math.min(a.$2 + a.$4, b.$2 + b.$4) - math.max(a.$2, b.$2),
  );
  final intersection = width * height;
  final union = a.$3 * a.$4 + b.$3 * b.$4 - intersection;
  return union <= 0 ? 0 : intersection / union;
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
    // Photo → the contract of its finished scan. A photo still scanned under
    // a compatible earlier contract shows those faces until it is re-scanned;
    // only scans under the current contract count as processed.
    final scannedWith = <String, String>{};
    var processed = 0, inaccessible = 0, failed = 0;
    for (final s in scans) {
      final photo = photos[s.photoId];
      if (photo == null ||
          s.revision != peopleRevision(photo) ||
          !FaceContract.compatible.contains(s.contract)) {
        continue;
      }
      final current = s.contract == FaceContract.id;
      if (s.status == 'done') {
        scannedWith[s.photoId] = s.contract;
        if (current) processed++;
      }
      if (current && s.status == 'inaccessible') inaccessible++;
      if (current && s.status == 'failed') failed++;
    }
    final faces =
        (await db.select(db.peopleFaces).get())
            .where(
              (f) =>
                  scannedWith[f.photoId] == f.contract &&
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
    final reviews =
        await (db.select(db.peopleReviews)
              ..where((r) => r.subset.isIn(['calibration', 'validation']))
              ..orderBy([
                (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
              ]))
            .get();
    return PeopleSnapshot(
      state: current,
      people: people,
      faces: faces,
      reviews: reviews,
      photoDates: {for (final p in photos.values) p.id: p.dateMs},
      photoSizes: {for (final p in photos.values) p.id: (p.width, p.height)},
      total: photos.length,
      processed: processed,
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
      }
      // A newer face contract re-detects the same photo revision. The
      // detector is unchanged, so a face whose box matches an earlier
      // observation is the same detection: it keeps that observation's id,
      // and with it the person, the assignment, "Not a face" and every
      // decision or review that names it.
      final earlier =
          await (db.select(db.peopleFaces)..where(
                (f) =>
                    f.photoId.equals(photoId) &
                    f.revision.equals(revision) &
                    f.contract.equals(FaceContract.id).not(),
              ))
              .get();
      final carried = _matchEarlierFaces(faces, earlier);
      for (var i = 0; i < faces.length; i++) {
        final old = carried[i];
        if (old == null) {
          // Repeated processing cannot overwrite user corrections.
          await db
              .into(db.peopleFaces)
              .insert(faces[i], mode: InsertMode.insertOrIgnore);
        } else {
          await (db.update(db.peopleFaces)..where((f) => f.id.equals(old.id)))
              .write(faces[i].copyWith(id: const Value.absent()));
        }
      }
      // An earlier observation nothing matched is dropped unless it carries
      // the user's decision, which stays on record (it is no longer shown).
      final kept = carried.values.map((f) => f.id).toSet();
      final dropped = [
        for (final f in earlier)
          if (!kept.contains(f.id) && f.personId == null && !f.dismissed) f.id,
      ];
      if (dropped.isNotEmpty) {
        await (db.delete(
          db.peopleFaces,
        )..where((f) => f.id.isIn(dropped))).go();
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

  /// Pairs new detections with earlier observations of the same photo
  /// revision by box overlap, closest first, each used at most once. Index of
  /// the new face → the earlier observation it continues.
  Map<int, PeopleFaceRecord> _matchEarlierFaces(
    List<PeopleFacesCompanion> faces,
    List<PeopleFaceRecord> earlier,
  ) {
    final candidates = <(double, int, PeopleFaceRecord)>[
      for (var i = 0; i < faces.length; i++)
        for (final old in earlier)
          (
            _boxOverlap(
              (
                faces[i].x.value,
                faces[i].y.value,
                faces[i].w.value,
                faces[i].h.value,
              ),
              (old.x, old.y, old.w, old.h),
            ),
            i,
            old,
          ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    final matched = <int, PeopleFaceRecord>{};
    final used = <String>{};
    for (final (overlap, index, old) in candidates) {
      if (overlap < 0.5) break;
      if (matched.containsKey(index) || used.contains(old.id)) continue;
      matched[index] = old;
      used.add(old.id);
    }
    return matched;
  }

  /// Validates every face against one snapshot (one [load], not one per face).
  Future<Map<String, PeopleFaceRecord>> _faces(
    Iterable<String> ids, {
    PeopleSnapshot? snapshot,
  }) async {
    if (!(await state()).enabled) {
      throw StateError('People grouping is disabled.');
    }
    final wanted = ids.toSet();
    final found = {
      for (final f in (snapshot ?? await load()).faces)
        if (wanted.contains(f.id)) f.id: f,
    };
    if (found.length != wanted.length) {
      throw StateError('This face is no longer available.');
    }
    return found;
  }

  Future<PeopleFaceRecord> _face(String id) async => (await _faces([id]))[id]!;

  Future<String> createPerson(
    List<String> faceIds, {
    String name = '',
    List<String> aliases = const [],
  }) => db.transaction(() async {
    if (faceIds.isEmpty) throw ArgumentError('Select at least one face.');
    final faces = await _faces(faceIds);
    final id = 'manual:${DateTime.now().microsecondsSinceEpoch}';
    await db
        .into(db.peoplePersons)
        .insert(
          PeoplePersonsCompanion.insert(
            id: id,
            createdMs: DateTime.now().millisecondsSinceEpoch,
            name: Value(_name(name)),
            aliasesJson: Value(_aliases(aliases, name: name)),
            coverFaceId: Value(faceIds.first),
          ),
        );
    if (aliases.any(isSelfAlias)) await _releaseSelfAliases(id);
    await _assign(faceIds, id, faces: faces);
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

  /// Trims, drops entries equal to the name, keeps self aliases lower-case and
  /// removes duplicates ignoring case (first spelling wins).
  String _aliases(Iterable<String> aliases, {String name = ''}) {
    final seen = {name.trim().toLowerCase()};
    final kept = <String>[];
    for (final alias in aliases) {
      var value = _name(alias);
      if (value.isEmpty) continue;
      if (isSelfAlias(value)) value = value.toLowerCase();
      if (seen.add(value.toLowerCase())) kept.add(value);
    }
    return jsonEncode(kept);
  }

  /// "This is me" belongs to one person: remove the self aliases elsewhere.
  Future<void> _releaseSelfAliases(String keepPersonId) async {
    final others = await (db.select(
      db.peoplePersons,
    )..where((p) => p.id.equals(keepPersonId).not())).get();
    for (final person in others) {
      final aliases = (jsonDecode(person.aliasesJson) as List).cast<String>();
      if (!aliases.any(isSelfAlias)) continue;
      await (db.update(
        db.peoplePersons,
      )..where((p) => p.id.equals(person.id))).write(
        PeoplePersonsCompanion(
          aliasesJson: Value(
            _aliases(aliases.where((a) => !isSelfAlias(a)), name: person.name),
          ),
        ),
      );
    }
  }

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
    final existing = await (db.select(
      db.peoplePersons,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    await (db.update(db.peoplePersons)..where((p) => p.id.equals(id))).write(
      PeoplePersonsCompanion(
        name: name == null ? const Value.absent() : Value(_name(name)),
        aliasesJson: aliases == null
            ? const Value.absent()
            : Value(_aliases(aliases, name: name ?? existing?.name ?? '')),
        coverFaceId: coverFaceId == null
            ? const Value.absent()
            : Value(coverFaceId),
        hidden: hidden == null ? const Value.absent() : Value(hidden),
      ),
    );
    if (existing != null && aliases != null && aliases.any(isSelfAlias)) {
      await _releaseSelfAliases(id);
    }
    await _advance();
  });

  /// Writes explicit user assignments in one batch. A move away from a person
  /// records that person as rejected for the face.
  Future<void> _assign(
    List<String> faceIds,
    String? personId, {
    bool dismiss = false,
    Map<String, PeopleFaceRecord>? faces,
  }) async {
    if (personId != null &&
        await (db.select(
              db.peoplePersons,
            )..where((p) => p.id.equals(personId))).getSingleOrNull() ==
            null) {
      throw StateError('Person no longer exists.');
    }
    final ids = faceIds.toSet().toList();
    final records = faces ?? await _faces(ids);
    if (ids.any((id) => !records.containsKey(id))) {
      throw StateError('This face is no longer available.');
    }
    await db.batch((b) {
      for (final id in ids) {
        final face = records[id]!;
        if (face.personId != null && face.personId != personId) {
          b.insert(
            db.peopleDecisions,
            PeopleDecisionsCompanion.insert(
              faceId: id,
              personId: face.personId!,
              decision: 'reject',
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
        if (personId != null) {
          b.insert(
            db.peopleDecisions,
            PeopleDecisionsCompanion.insert(
              faceId: id,
              personId: personId,
              decision: 'accept',
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
        b.update(
          db.peopleFaces,
          PeopleFacesCompanion(
            personId: Value(personId),
            assignment: Value(personId == null ? 'unassigned' : 'manual'),
            dismissed: Value(dismiss),
          ),
          where: (f) => f.id.equals(id),
        );
      }
    });
  }

  Future<void> assign(
    List<String> ids,
    String? personId, {
    bool dismiss = false,
  }) => db.transaction(() async {
    await _assign(ids, personId, dismiss: dismiss);
    await _advance();
  });

  /// Merges two people the user chose to merge: every face becomes a manual
  /// assignment of [target].
  Future<void> merge(String source, String target) => _merge(source, target);

  /// [keepAutomatic]: faces grouped automatically stay automatic (so they can
  /// still be checked with "Is this X?"), except the faces in [confirm], which
  /// the user actually saw and confirmed.
  Future<void> _merge(
    String source,
    String target, {
    bool keepAutomatic = false,
    Set<String> confirm = const {},
  }) => db.transaction(() async {
    if (source == target) return;
    final snapshot = await load();
    final from = snapshot.people
        .where((p) => p.record.id == source)
        .firstOrNull;
    final to = snapshot.people.where((p) => p.record.id == target).firstOrNull;
    if (from == null || to == null) {
      throw StateError('Person no longer exists.');
    }
    bool staysAutomatic(PeopleFaceRecord f) =>
        keepAutomatic && f.assignment == 'automatic' && !confirm.contains(f.id);
    final confirmed = from.faces.where((f) => !staysAutomatic(f)).toList();
    final automatic = from.faces
        .where(staysAutomatic)
        .map((f) => f.id)
        .toList();
    if (confirmed.isNotEmpty) {
      await _assign(
        confirmed.map((f) => f.id).toList(),
        target,
        faces: {for (final f in confirmed) f.id: f},
      );
    }
    if (automatic.isNotEmpty) {
      await (db.update(db.peopleFaces)..where((f) => f.id.isIn(automatic)))
          .write(PeopleFacesCompanion(personId: Value(target)));
    }
    // An unnamed group adopts the name; otherwise the old name becomes an alias.
    final adoptName =
        to.record.name.trim().isEmpty && from.record.name.trim().isNotEmpty;
    final targetName = adoptName ? from.record.name : to.record.name;
    final aliases = [
      ...to.aliases,
      ...from.aliases,
      if (!adoptName &&
          from.record.name.trim().isNotEmpty &&
          from.record.name.trim().toLowerCase() !=
              to.record.name.trim().toLowerCase())
        from.record.name,
    ];
    await (db.update(
      db.peoplePersons,
    )..where((p) => p.id.equals(target))).write(
      PeoplePersonsCompanion(
        name: adoptName ? Value(_name(from.record.name)) : const Value.absent(),
        aliasesJson: Value(_aliases(aliases, name: targetName)),
        coverFaceId: Value(to.record.coverFaceId ?? from.record.coverFaceId),
      ),
    );
    // Carry the user's earlier answers about the source over to the target:
    // rejects (never regroup) and "not sure" (never ask again).
    final rejected =
        await (db.select(db.peopleDecisions)..where(
              (d) =>
                  d.personId.equals(source) &
                  d.decision.isIn(['reject', 'unsure']),
            ))
            .get();
    for (final r in rejected) {
      final targetDecision =
          await (db.select(db.peopleDecisions)..where(
                (d) => d.faceId.equals(r.faceId) & d.personId.equals(target),
              ))
              .getSingleOrNull();
      // A reject outranks an earlier "not sure"; "not sure" never replaces
      // a real answer.
      if (targetDecision == null ||
          (r.decision == 'reject' && targetDecision.decision == 'unsure')) {
        await db
            .into(db.peopleDecisions)
            .insert(
              PeopleDecisionsCompanion.insert(
                faceId: r.faceId,
                personId: target,
                decision: r.decision,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    }
    // Retain explicit corrections for currently inaccessible observations too.
    await (db.update(
      db.peopleFaces,
    )..where((f) => f.personId.equals(source))).write(
      PeopleFacesCompanion(
        personId: Value(target),
        assignment: keepAutomatic
            ? const Value.absent()
            : const Value('manual'),
      ),
    );
    await (db.delete(db.peoplePersons)..where((p) => p.id.equals(source))).go();
    await _advance();
  });

  /// Removes a person. Its faces return to New faces with this person id
  /// recorded as rejected for them. A later validated grouping run may still
  /// group those faces again under a new id; it cannot revive this one.
  Future<void> deletePerson(String personId) => db.transaction(() async {
    if (!(await state()).enabled) {
      throw StateError('People grouping is disabled.');
    }
    final person = await (db.select(
      db.peoplePersons,
    )..where((p) => p.id.equals(personId))).getSingleOrNull();
    if (person == null) throw StateError('Person no longer exists.');
    // Includes faces in photos that are currently inaccessible.
    final faces = await (db.select(
      db.peopleFaces,
    )..where((f) => f.personId.equals(personId))).get();
    await db.batch((b) {
      for (final face in faces) {
        b.insert(
          db.peopleDecisions,
          PeopleDecisionsCompanion.insert(
            faceId: face.id,
            personId: personId,
            decision: 'reject',
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      b.update(
        db.peopleFaces,
        const PeopleFacesCompanion(
          personId: Value(null),
          assignment: Value('unassigned'),
        ),
        where: (f) => f.personId.equals(personId),
      );
      b.deleteWhere(db.peoplePersons, (p) => p.id.equals(personId));
    });
    await _advance();
  });

  /// Unnamed faces ordered by similarity to the person's manually confirmed
  /// faces. Read-only: nothing is assigned until [confirmSuggestions].
  Future<FaceSuggestionResult> suggestionsFor(
    String personId, {
    PeopleSnapshot? snapshot,
    int limit = 60,
  }) async {
    snapshot ??= await load();
    if (!snapshot.state.enabled) return const FaceSuggestionResult();
    final rejected =
        (await (db.select(db.peopleDecisions)..where(
                  (d) =>
                      d.personId.equals(personId) & d.decision.equals('reject'),
                ))
                .get())
            .map((d) => d.faceId)
            .toSet();
    const descriptor = _descriptor;

    final input = FaceSuggestionInput(
      references: [
        for (final face in snapshot.faces)
          if (face.personId == personId && face.assignment == 'manual')
            descriptor(face),
      ].whereType<FaceVector>().toList(),
      candidates: [
        for (final face in snapshot.unassigned) descriptor(face),
      ].whereType<FaceVector>().toList(),
      occupiedPhotoIds: {
        for (final face in snapshot.faces)
          if (face.personId == personId && !face.dismissed) face.photoId,
      },
      rejectedFaceIds: rejected,
      limit: limit,
    );
    // Small inputs run inline (fast, and deterministic in tests).
    if (input.references.length * input.candidates.length <= 50000) {
      return rankFaceSuggestions(input);
    }
    return compute(rankFaceSuggestions, input);
  }

  /// Assigns exactly the faces the user confirmed. Fails closed, writing
  /// nothing, if any face changed or two faces would put the person twice in
  /// one photo.
  Future<void> confirmSuggestions(String personId, List<String> faceIds) =>
      db.transaction(() async {
        if (faceIds.isEmpty) throw ArgumentError('Select at least one face.');
        final snapshot = await load();
        if (!snapshot.state.enabled) {
          throw StateError('People grouping is disabled.');
        }
        if (!snapshot.people.any((p) => p.record.id == personId)) {
          throw StateError('Person no longer exists.');
        }
        final ids = faceIds.toSet();
        final faces = {
          for (final f in snapshot.faces)
            if (ids.contains(f.id)) f.id: f,
        };
        if (faces.length != ids.length ||
            faces.values.any((f) => f.personId != null || f.dismissed)) {
          throw StateError('Some faces changed. Review the suggestions again.');
        }
        final occupied = {
          for (final f in snapshot.faces)
            if (f.personId == personId && !f.dismissed) f.photoId,
        };
        final photos = <String>{};
        for (final face in faces.values) {
          if (occupied.contains(face.photoId) || !photos.add(face.photoId)) {
            throw ArgumentError('A person can be confirmed once per photo.');
          }
        }
        await _assign(ids.toList(), personId, faces: faces);
        await _advance();
      });

  /// Records "not this person" for unassigned faces. The faces stay in New
  /// faces and are never suggested for this person again.
  Future<void> rejectSuggestions(String personId, List<String> faceIds) =>
      db.transaction(() async {
        if (faceIds.isEmpty) throw ArgumentError('Select at least one face.');
        final snapshot = await load();
        if (!snapshot.state.enabled) {
          throw StateError('People grouping is disabled.');
        }
        if (!snapshot.people.any((p) => p.record.id == personId)) {
          throw StateError('Person no longer exists.');
        }
        final ids = faceIds.toSet();
        final faces = [
          for (final f in snapshot.faces)
            if (ids.contains(f.id)) f,
        ];
        if (faces.length != ids.length) {
          throw StateError('Some faces changed. Review the suggestions again.');
        }
        if (faces.any((f) => f.personId == personId)) {
          throw StateError(
            'This face is assigned to the person. Use Remove assignment.',
          );
        }
        await db.batch((b) {
          for (final id in ids) {
            b.insert(
              db.peopleDecisions,
              PeopleDecisionsCompanion.insert(
                faceId: id,
                personId: personId,
                decision: 'reject',
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        await _advance();
      });

  /// Restores the state before a suggestion decision (SnackBar Undo).
  Future<void> undoSuggestionDecisions(
    String personId, {
    List<String> confirmed = const [],
    List<String> rejected = const [],
  }) => db.transaction(() async {
    if (!(await state()).enabled) {
      throw StateError('People grouping is disabled.');
    }
    await db.batch((b) {
      for (final id in confirmed) {
        b.update(
          db.peopleFaces,
          const PeopleFacesCompanion(
            personId: Value(null),
            assignment: Value('unassigned'),
          ),
          where: (f) =>
              f.id.equals(id) &
              f.personId.equals(personId) &
              f.assignment.equals('manual'),
        );
        b.deleteWhere(
          db.peopleDecisions,
          (d) =>
              d.faceId.equals(id) &
              d.personId.equals(personId) &
              d.decision.equals('accept'),
        );
      }
      for (final id in rejected) {
        b.deleteWhere(
          db.peopleDecisions,
          (d) =>
              d.faceId.equals(id) &
              d.personId.equals(personId) &
              d.decision.equals('reject'),
        );
      }
    });
    await _advance();
  });

  /// "Same person?" questions (read-only): faces automatic grouping added to
  /// named people first, then groups that may be one person, closest first.
  Future<List<SamePersonQuestion>> samePersonQuestions({
    PeopleSnapshot? snapshot,
    int limit = 20,
  }) async {
    snapshot ??= await load();
    if (!snapshot.state.enabled) return const [];
    final decided = <String, Set<String>>{};
    for (final d in await (db.select(
      db.peopleDecisions,
    )..where((d) => d.decision.isIn(['reject', 'unsure']))).get()) {
      decided.putIfAbsent(d.faceId, () => {}).add(d.personId);
    }
    final visible = snapshot.people
        .where((p) => !p.record.hidden && p.faces.isNotEmpty)
        .toList();
    // A named person whose faces were all grouped automatically has no face
    // the user confirmed; the cover (the face shown when it was named) is
    // the anchor, and is never asked about itself.
    final anchors = <String, List<String>>{};
    for (final p in visible) {
      final manual = [
        for (final f in p.faces)
          if (f.assignment == 'manual') f.id,
      ];
      if (manual.isEmpty && p.record.name.trim().isNotEmpty) {
        final cover = p.faces
            .where((f) => f.id == p.record.coverFaceId)
            .firstOrNull;
        manual.add((cover ?? p.faces.first).id);
      }
      anchors[p.record.id] = manual;
    }
    final input = SamePersonInput(
      groups: [
        for (final p in visible)
          FaceGroupInput(
            personId: p.record.id,
            named: p.record.name.trim().isNotEmpty,
            faces: p.faces.map(_descriptor).whereType<FaceVector>().toList(),
            photoIds: {for (final f in p.faces) f.photoId},
            confirmedFaceIds: anchors[p.record.id]!,
            size: p.faces.length,
          ),
      ],
      automaticFaces: [
        for (final p in visible)
          if (p.record.name.trim().isNotEmpty)
            for (final f in p.faces)
              if (f.assignment == 'automatic' &&
                  !anchors[p.record.id]!.contains(f.id) &&
                  _descriptor(f) != null)
                (p.record.id, _descriptor(f)!),
      ],
      decided: decided,
      minSimilarity: await _lowestSameScore(snapshot),
      limit: limit,
    );
    // Every pair of groups is compared, so estimate the work: small libraries
    // run inline (fast, deterministic in tests), larger ones off the UI isolate.
    var work = 0, seen = 0;
    for (final g in input.groups) {
      work += seen * g.faces.length;
      seen += g.faces.length;
    }
    if (work <= 20000) return buildSamePersonQuestions(input);
    return compute(buildSamePersonQuestions, input);
  }

  /// The lowest score among review pairs the user judged the same person.
  /// Pairs scoring below every judged "same" pair are not worth asking about.
  /// While a new round is still unjudged, the archived rounds' answers keep
  /// the floor, so questions do not fall back to every pair.
  Future<double?> _lowestSameScore(PeopleSnapshot snapshot) async {
    var scores = [
      for (final r in snapshot.reviews)
        if (r.judgment == 'same') r.cosine,
    ];
    if (scores.isEmpty) {
      scores = [
        for (final r in await (db.select(
          db.peopleReviews,
        )..where((r) => r.judgment.equals('same'))).get())
          r.cosine,
      ];
    }
    return scores.isEmpty ? null : scores.reduce(math.min);
  }

  /// Records the user's answer. Yes joins (or confirms), No keeps apart and is
  /// remembered, Not sure is remembered so the pair is not asked again.
  Future<void> answerSamePerson(
    SamePersonQuestion question,
    SamePersonAnswer answer,
  ) async {
    final snapshot = await load();
    if (!snapshot.state.enabled) {
      throw StateError('People grouping is disabled.');
    }
    PersonView? person(String? id) =>
        snapshot.people.where((p) => p.record.id == id).firstOrNull;
    final left = person(question.leftPersonId);
    if (left == null) {
      throw StateError('These faces changed. Try the next question.');
    }
    if (question.kind == SamePersonKind.verifyAutomatic) {
      final face = left.faces
          .where((f) => f.id == question.rightFaceId)
          .firstOrNull;
      if (face == null) {
        throw StateError('This face changed. Try the next question.');
      }
      return db.transaction(() async {
        switch (answer) {
          case SamePersonAnswer.yes:
            // Confirmed: becomes a manual assignment with an accept decision.
            await _assign([face.id], left.record.id, faces: {face.id: face});
          case SamePersonAnswer.no:
            // Removed from the person; the reject stops it coming back.
            await _assign([face.id], null, faces: {face.id: face});
          case SamePersonAnswer.notSure:
            await _remember([face.id], left.record.id, 'unsure');
        }
        await _advance();
      });
    }
    final right = person(question.rightPersonId);
    // The answer is about the two faces the user compared; if either has left
    // its group since, the question is stale.
    final leftFace = left.faces
        .where((f) => f.id == question.leftFaceId)
        .firstOrNull;
    if (right == null ||
        leftFace == null ||
        !right.faces.any((f) => f.id == question.rightFaceId)) {
      throw StateError('These faces changed. Try the next question.');
    }
    if (answer == SamePersonAnswer.yes) {
      // The left group is the named (or larger) one and keeps its identity.
      // Only the two faces the user compared become confirmed; other faces
      // grouped automatically stay automatic and can be checked later.
      if (leftFace.assignment == 'automatic') {
        await db.transaction(() async {
          await _assign(
            [leftFace.id],
            left.record.id,
            faces: {leftFace.id: leftFace},
          );
          await _advance();
        });
      }
      return _merge(
        right.record.id,
        left.record.id,
        keepAutomatic: true,
        confirm: {question.rightFaceId},
      );
    }
    return db.transaction(() async {
      if (answer == SamePersonAnswer.no) {
        await _remember(right.faces.map((f) => f.id), left.record.id, 'reject');
        await _remember(left.faces.map((f) => f.id), right.record.id, 'reject');
      } else {
        await _remember(right.faces.map((f) => f.id), left.record.id, 'unsure');
      }
      await _advance();
    });
  }

  /// Writes a decision for each face about [personId]. A reject replaces an
  /// earlier answer; "unsure" never overwrites an existing decision.
  Future<void> _remember(
    Iterable<String> faceIds,
    String personId,
    String decision,
  ) => db.batch((b) {
    for (final id in faceIds.toSet()) {
      b.insert(
        db.peopleDecisions,
        PeopleDecisionsCompanion.insert(
          faceId: id,
          personId: personId,
          decision: decision,
        ),
        mode: decision == 'reject'
            ? InsertMode.insertOrReplace
            : InsertMode.insertOrIgnore,
      );
    }
  });

  Future<Set<String>> photoIdsFor(Set<String> personIds) async {
    if (personIds.isEmpty) throw ArgumentError('Person selection is empty.');
    final snapshot = await load();
    if (!snapshot.state.enabled) return {};
    return matchPeoplePhotos(
      PeoplePhotoIndex.of(snapshot).photosByPerson,
      required: personIds,
    );
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
    final excluded = await _reviewedPhotos();
    final pairs = await compute(
      buildFaceReview,
      vectors(snapshot).where((f) => !excluded.contains(f.photoId)).toList(),
    );
    if (pairs.length < 40) {
      throw StateError(
        'Not enough unreviewed detailed faces for a 40-pair review yet. Manual naming remains available.',
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
      final photoOf = {for (final f in snapshot.faces) f.id: f.photoId};
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
              leftPhotoId: Value(photoOf[p.left]),
              rightPhotoId: Value(photoOf[p.right]),
            ),
        ]),
      );
      return pairs.length;
    });
  }

  /// Every photo used in any review round, archived ones included. Stored
  /// photo ids still name a photo after it is edited (its faces get new ids);
  /// the join covers rows written before v7 whose faces still exist.
  Future<Set<String>> _reviewedPhotos() async {
    final rows = await db
        .customSelect(
          'SELECT left_photo_id AS photo_id FROM people_reviews '
          'WHERE left_photo_id IS NOT NULL '
          'UNION SELECT right_photo_id FROM people_reviews '
          'WHERE right_photo_id IS NOT NULL '
          'UNION SELECT f.photo_id FROM people_faces f JOIN people_reviews r '
          'ON f.id=r.left_face_id OR f.id=r.right_face_id',
        )
        .get();
    return rows.map((r) => r.read<String>('photo_id')).toSet();
  }

  /// A failed holdout becomes training evidence only for a NEW round. The next
  /// holdout uses previously unseen photos and is frozen before any new labels.
  Future<int> prepareFreshValidation() async {
    final snapshot = await load();
    final result = await calibration(snapshot: snapshot);
    if (!snapshot.state.enabled ||
        result.passed ||
        result.candidateThreshold == null ||
        snapshot.reviews.any((p) => p.judgment == 'pending')) {
      throw StateError(
        'Complete the current review before starting a fresh check.',
      );
    }
    final differentScores = snapshot.reviews
        .where((p) => p.judgment == 'different')
        .map((p) => p.cosine)
        .toList();
    if (!snapshot.reviews.any(
      (p) =>
          p.judgment == 'same' &&
          differentScores.every((score) => p.cosine > score),
    )) {
      throw StateError(
        'These ratings cannot calibrate a safe cutoff. '
        'Manual naming remains available; a face-quality investigation is needed.',
      );
    }
    final excluded = await _reviewedPhotos();
    final pairs = await compute(
      buildFreshFaceValidation,
      vectors(snapshot).where((f) => !excluded.contains(f.photoId)).toList(),
    );
    if (pairs.length < 20) {
      throw StateError(
        'Not enough unreviewed detailed faces for 20 new pairs. '
        'Continue People processing, then try again. Your ratings are saved.',
      );
    }
    return db.transaction(() async {
      final current = await state();
      if (!current.enabled || current.generation != snapshot.state.generation) {
        throw StateError('People data changed. Try again.');
      }
      // Metadata may change without advancing the People generation.
      final live = await load();
      final liveIds = {for (final f in live.faces) f.id};
      if ([
            for (final p in pairs) ...[p.left, p.right],
          ].any((id) => !liveIds.contains(id)) ||
          (await calibration(snapshot: live)).candidateThreshold == null) {
        throw StateError('A reviewed photo changed. Your ratings are saved.');
      }
      await archiveReview();
      final prefix = DateTime.now().microsecondsSinceEpoch;
      final photoOf = {for (final f in live.faces) f.id: f.photoId};
      await db.batch(
        (b) => b.insertAll(db.peopleReviews, [
          for (final p in snapshot.reviews)
            PeopleReviewsCompanion.insert(
              id: '$prefix:carried:${p.id}',
              leftFaceId: p.leftFaceId,
              rightFaceId: p.rightFaceId,
              subset: 'calibration',
              cosine: p.cosine,
              judgment: Value(p.judgment),
              contract: p.contract,
              leftPhotoId: Value(p.leftPhotoId ?? photoOf[p.leftFaceId]),
              rightPhotoId: Value(p.rightPhotoId ?? photoOf[p.rightFaceId]),
            ),
          for (final p in pairs)
            PeopleReviewsCompanion.insert(
              id: '$prefix:${p.id}',
              leftFaceId: p.left,
              rightFaceId: p.right,
              subset: 'validation',
              cosine: p.cosine,
              contract: FaceContract.id,
              leftPhotoId: Value(photoOf[p.left]),
              rightPhotoId: Value(photoOf[p.right]),
            ),
        ]),
      );
      final pending = await calibration();
      await _advance(
        threshold: const Value(null),
        calibration: jsonEncode(pending.toJson()),
      );
      return pairs.length;
    });
  }

  Future<FaceCalibration> calibration({PeopleSnapshot? snapshot}) async {
    snapshot ??= await load();
    final faces = {for (final f in snapshot.faces) f.id: f};
    final calPhotos = <String>{}, valPhotos = <String>{};
    // A review under an earlier contract did not cover the faces this one
    // compares (for example smaller ones), so it cannot validate a cutoff.
    if (snapshot.reviews.any((p) => p.contract != FaceContract.id)) {
      return const FaceCalibration(
        reason:
            'Face settings changed: smaller faces can now be compared. '
            'Start a new review to turn automatic grouping back on.',
      );
    }
    for (final p in snapshot.reviews) {
      if (!faces.containsKey(p.leftFaceId) ||
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

  /// Automatic grouping after a full processing pass. Never runs while the
  /// user has paused processing.
  Future<int> applyGrouping() => _applyGrouping(allowWhilePaused: false);

  /// Grouping the user asked for explicitly ("Group similar faces"). It uses
  /// the same validated cutoff and refuses unless the review gate passed, but
  /// does not need processing to be resumed.
  Future<int> groupNow() => _applyGrouping(allowWhilePaused: true);

  Future<int> _applyGrouping({required bool allowWhilePaused}) async {
    final snapshot = await load();
    if (!snapshot.state.enabled ||
        (snapshot.state.paused && !allowWhilePaused)) {
      return 0;
    }
    final result = await calibration();
    if (!result.passed) return 0;
    final decisions = await db.select(db.peopleDecisions).get();
    // A second detection of the same face would only become a stray group.
    final duplicates = snapshot.smallOrDuplicateFaces;
    final input = vectors(
      snapshot,
      decisions,
    ).where((f) => f.personId != null || !duplicates.contains(f.id)).toList();
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
          (current.paused && !allowWhilePaused) ||
          current.generation != snapshot.state.generation) {
        return 0;
      }
      // Indexing may have revised photos while the worker was clustering.
      final live = {for (final f in (await load()).faces) f.id};
      if (input.any((f) => !live.contains(f.id))) return 0;
      var count = 0;
      for (final entry in assignments.entries) {
        if (entry.value == null) continue;
        final updated =
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
        // Create a new group only when a face actually joined it.
        if (updated == 0) continue;
        count += updated;
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
      }
      // A run computed from an older snapshot must now fail its check.
      if (count > 0) await _advance();
      return count;
    });
  }
}

FaceVector? _descriptor(PeopleFaceRecord face) {
  if (face.dismissed || face.quality != 'ready') return null;
  final vector = decodeFaceVector(face.vector);
  return vector == null
      ? null
      : FaceVector(
          id: face.id,
          photoId: face.photoId,
          vector: vector,
          personId: face.personId,
        );
}

Map<String, String?> _group(
  (List<FaceVector>, double, Map<String, Set<String>>) input,
) => groupFaces(input.$1, input.$2, personPhotos: input.$3);

/// Person → photos from assigned, non-dismissed faces, built once per People
/// snapshot so a search does not reload the People tables.
class PeoplePhotoIndex {
  const PeoplePhotoIndex({
    required this.enabled,
    this.photosByPerson = const {},
    this.assignments = const {},
    this.labels = const {},
    this.hidden = const {},
  });

  factory PeoplePhotoIndex.of(PeopleSnapshot snapshot) {
    if (!snapshot.state.enabled) return const PeoplePhotoIndex(enabled: false);
    final photos = <String, Set<String>>{};
    final assignments = <String, Map<String, String>>{};
    for (final face in snapshot.faces) {
      final person = face.personId;
      if (person == null || face.dismissed) continue;
      photos.putIfAbsent(person, () => {}).add(face.photoId);
      final kinds = assignments.putIfAbsent(face.photoId, () => {});
      if (kinds[person] != 'manual') kinds[person] = face.assignment;
    }
    return PeoplePhotoIndex(
      enabled: true,
      photosByPerson: photos,
      assignments: assignments,
      labels: {for (final p in snapshot.people) p.record.id: p.label},
      hidden: {
        for (final p in snapshot.people)
          if (p.record.hidden) p.record.id,
      },
    );
  }

  final bool enabled;
  final Map<String, Set<String>> photosByPerson;

  /// Photo id → person id → 'manual' | 'automatic'.
  final Map<String, Map<String, String>> assignments;
  final Map<String, String> labels;
  final Set<String> hidden;
}

/// People that typed names can resolve to. Hidden people are left out unless
/// [includeHidden] (the online privacy guard must still see every name).
List<NamedPerson> peopleDirectory(
  PeopleSnapshot? snapshot, {
  bool includeHidden = false,
}) => [
  for (final p in snapshot?.people ?? const <PersonView>[])
    if ((includeHidden || !p.record.hidden) &&
        (p.record.name.trim().isNotEmpty || p.aliases.isNotEmpty))
      NamedPerson(p.record.id, p.record.name, aliases: p.aliases),
];
