import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/people_membership.dart';
import 'package:pixelsearch/domain/people/people_query.dart';

import 'people_repository_test.dart' show addFaces, seedPhoto;

void main() {
  group('matchPeoplePhotos', () {
    final photosByPerson = <String, Set<String>>{
      'asha': {'p1', 'p2', 'p3'},
      'ben': {'p2', 'p3', 'p4'},
      'chen': {'p3', 'p5'},
      'dev': {'p2'},
    };
    const universe = {'p1', 'p2', 'p3', 'p4', 'p5', 'p6'};

    test('required people intersect', () {
      expect(matchPeoplePhotos(photosByPerson, required: {'asha', 'ben'}), {
        'p2',
        'p3',
      });
      expect(
        matchPeoplePhotos(photosByPerson, required: {'asha', 'ben', 'chen'}),
        {'p3'},
      );
      expect(matchPeoplePhotos(photosByPerson, required: {'asha'}), {
        'p1',
        'p2',
        'p3',
      });
    });

    test('any-of people union', () {
      expect(matchPeoplePhotos(photosByPerson, anyOf: {'ben', 'chen'}), {
        'p2',
        'p3',
        'p4',
        'p5',
      });
    });

    test('excluded people are subtracted', () {
      expect(
        matchPeoplePhotos(
          photosByPerson,
          required: {'asha'},
          excluded: {'chen'},
        ),
        {'p1', 'p2'},
      );
      expect(
        matchPeoplePhotos(
          photosByPerson,
          anyOf: {'asha', 'chen'},
          excluded: {'ben'},
        ),
        {'p1', 'p5'},
      );
    });

    test('required, any-of and excluded compose', () {
      // asha ∩ (ben ∪ chen) − dev = {p2, p3} − {p2}.
      expect(
        matchPeoplePhotos(
          photosByPerson,
          required: {'asha'},
          anyOf: {'ben', 'chen'},
          excluded: {'dev'},
        ),
        {'p3'},
      );
    });

    test('a universe restricts the result', () {
      expect(
        matchPeoplePhotos(
          photosByPerson,
          required: {'asha'},
          universe: {'p1', 'p9'},
        ),
        {'p1'},
      );
      expect(
        matchPeoplePhotos(
          photosByPerson,
          anyOf: {'ben', 'chen'},
          universe: {'p4', 'p5', 'p6'},
        ),
        {'p4', 'p5'},
      );
    });

    test('exclusion-only selections start from the universe', () {
      expect(
        matchPeoplePhotos(
          photosByPerson,
          excluded: {'ben'},
          universe: universe,
        ),
        {'p1', 'p5', 'p6'},
      );
      expect(
        matchPeoplePhotos(
          photosByPerson,
          excluded: {'ghost'},
          universe: universe,
        ),
        universe,
      );
    });

    test('exclusion-only without a universe throws', () {
      expect(
        () => matchPeoplePhotos(photosByPerson, excluded: {'ben'}),
        throwsArgumentError,
      );
    });

    test('an empty selection throws, with or without a universe', () {
      expect(() => matchPeoplePhotos(photosByPerson), throwsArgumentError);
      expect(
        () => matchPeoplePhotos(photosByPerson, universe: universe),
        throwsArgumentError,
      );
    });

    test('unknown person ids fail closed', () {
      expect(matchPeoplePhotos(photosByPerson, required: {'ghost'}), isEmpty);
      expect(
        matchPeoplePhotos(photosByPerson, required: {'asha', 'ghost'}),
        isEmpty,
      );
      expect(
        matchPeoplePhotos(photosByPerson, anyOf: {'ghost', 'phantom'}),
        isEmpty,
      );
      expect(
        matchPeoplePhotos(
          photosByPerson,
          anyOf: {'ghost', 'phantom'},
          universe: universe,
        ),
        isEmpty,
      );
      // An unknown alternative contributes nothing but does not block others.
      expect(matchPeoplePhotos(photosByPerson, anyOf: {'chen', 'ghost'}), {
        'p3',
        'p5',
      });
      expect(
        matchPeoplePhotos(
          photosByPerson,
          required: {'ghost'},
          universe: universe,
        ),
        isEmpty,
      );
    });

    test('inputs are never mutated', () {
      final universeCopy = {...universe};
      matchPeoplePhotos(photosByPerson, required: {'asha'}, excluded: {'ben'});
      matchPeoplePhotos(photosByPerson, anyOf: {'chen'}, excluded: {'ben'});
      matchPeoplePhotos(
        photosByPerson,
        excluded: {'ben'},
        universe: universeCopy,
      );
      expect(photosByPerson['asha'], {'p1', 'p2', 'p3'});
      expect(photosByPerson['chen'], {'p3', 'p5'});
      expect(universeCopy, universe);
    });
  });

  group('PeoplePhotoIndex and peopleDirectory', () {
    late AppDatabase db;
    late PeopleRepository repo;
    late String ashaId, benId, devId, unnamedId, aliasOnlyId;

    Future<void> setAutomatic(String faceId, String personId) =>
        (db.update(db.peopleFaces)..where((f) => f.id.equals(faceId))).write(
          PeopleFacesCompanion(
            personId: Value(personId),
            assignment: const Value('automatic'),
          ),
        );

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
      await repo.enable();
      await addFaces(repo, 'p1', ['f1a', 'f1b']); // Asha + Ben (manual)
      await addFaces(repo, 'p2', ['f2a']); // Asha (manual)
      await addFaces(repo, 'p3', ['f3a']); // Asha (automatic only)
      await addFaces(repo, 'p4', ['f4a']); // Asha, dismissed
      await addFaces(repo, 'p5', ['f5a', 'f5b']); // Ben manual, Ben automatic
      await addFaces(repo, 'p6', ['f6a', 'f6b']); // Asha automatic, manual
      await addFaces(repo, 'p7', ['f7a', 'f7b']); // Dev (self) + unnamed
      await addFaces(repo, 'p8', ['f8a', 'f8b']); // alias-only + unassigned

      ashaId = await repo.createPerson(
        ['f1a', 'f2a'],
        name: 'Asha',
        aliases: ['Ash'],
      );
      benId = await repo.createPerson(['f1b', 'f5a'], name: 'Ben');
      devId = await repo.createPerson(
        ['f7a'],
        name: 'Dev',
        aliases: ['me', 'myself'],
      );
      unnamedId = await repo.createPerson(['f7b']);
      aliasOnlyId = await repo.createPerson(['f8a'], aliases: ['Kai']);

      await repo.assign(['f4a'], ashaId, dismiss: true);
      await repo.assign(['f6b'], ashaId);
      await setAutomatic('f3a', ashaId);
      await setAutomatic('f5b', benId);
      await setAutomatic('f6a', ashaId);
      await repo.editPerson(benId, hidden: true);
    });
    tearDown(() => db.close());

    test('photosByPerson uses assigned, non-dismissed faces only', () async {
      final snapshot = await repo.load();
      // Precondition: the dismissed face is still assigned in the snapshot.
      final dismissed = snapshot.faces.singleWhere((f) => f.id == 'f4a');
      expect(dismissed.dismissed, isTrue);
      expect(dismissed.personId, ashaId);

      final index = PeoplePhotoIndex.of(snapshot);
      expect(index.enabled, isTrue);
      expect(index.photosByPerson, {
        ashaId: {'p1', 'p2', 'p3', 'p6'},
        benId: {'p1', 'p5'},
        devId: {'p7'},
        unnamedId: {'p7'},
        aliasOnlyId: {'p8'},
      });
      expect(
        index.photosByPerson.values.expand((photos) => photos),
        isNot(contains('p4')),
      );
    });

    test('assignments record manual over automatic per photo', () async {
      final index = PeoplePhotoIndex.of(await repo.load());
      expect(index.assignments['p3'], {ashaId: 'automatic'});
      // Manual face sorts before the automatic one.
      expect(index.assignments['p5'], {benId: 'manual'});
      // Automatic face sorts before the manual one.
      expect(index.assignments['p6'], {ashaId: 'manual'});
      expect(index.assignments['p1'], {ashaId: 'manual', benId: 'manual'});
      expect(index.assignments.containsKey('p4'), isFalse);
      expect(index.assignments['p8'], {aliasOnlyId: 'manual'});
    });

    test('labels and hidden people', () async {
      final index = PeoplePhotoIndex.of(await repo.load());
      expect(index.labels, {
        ashaId: 'Asha',
        benId: 'Ben',
        devId: 'Dev',
        unnamedId: 'Unnamed person',
        aliasOnlyId: 'Unnamed person',
      });
      expect(index.hidden, {benId});
    });

    test('disabling People empties the index', () async {
      await repo.disableAndDelete();
      final cleared = PeoplePhotoIndex.of(await repo.load());
      expect(cleared.enabled, isFalse);
      expect(cleared.photosByPerson, isEmpty);
      expect(cleared.assignments, isEmpty);
      expect(cleared.labels, isEmpty);
      expect(cleared.hidden, isEmpty);
    });

    test('peopleDirectory leaves out hidden and nameless people', () async {
      final snapshot = await repo.load();
      final visible = {for (final p in peopleDirectory(snapshot)) p.id: p};
      expect(visible.keys.toSet(), {ashaId, devId, aliasOnlyId});
      expect(visible[ashaId]!.name, 'Asha');
      expect(visible[ashaId]!.aliases, ['Ash']);
      expect(visible[devId]!.aliases, ['me', 'myself']);
      expect(visible[aliasOnlyId]!.name, isEmpty);
      expect(visible[aliasOnlyId]!.aliases, ['Kai']);

      final all = peopleDirectory(snapshot, includeHidden: true);
      expect(all.map((p) => p.id).toSet(), {ashaId, benId, devId, aliasOnlyId});
      expect(peopleDirectory(null), isEmpty);
    });

    test('directory names resolve to people ids', () async {
      final directory = peopleDirectory(await repo.load());
      final query = resolvePeopleQuery('me with Ash at the beach', directory);
      expect(query.required, {devId, ashaId});
      expect(query.query, 'the beach');
      // Hidden Ben is not in the default directory.
      final hidden = resolvePeopleQuery('Ben at the beach', directory);
      expect(hidden.hasPeople, isFalse);
      expect(hidden.query, 'Ben at the beach');
    });

    test(
      'photoIdsFor is AND across people and includes hidden people',
      () async {
        expect(await repo.photoIdsFor({ashaId}), {'p1', 'p2', 'p3', 'p6'});
        expect(await repo.photoIdsFor({ashaId, benId}), {'p1'});
        expect(await repo.photoIdsFor({benId}), {'p1', 'p5'});
        expect(await repo.photoIdsFor({devId, unnamedId}), {'p7'});
        expect(await repo.photoIdsFor({ashaId, 'ghost'}), isEmpty);
        final index = PeoplePhotoIndex.of(await repo.load());
        expect(
          await repo.photoIdsFor({ashaId, benId}),
          matchPeoplePhotos(index.photosByPerson, required: {ashaId, benId}),
        );
      },
    );

    test('photoIdsFor rejects an empty selection', () async {
      await expectLater(repo.photoIdsFor({}), throwsArgumentError);
    });

    test('photoIdsFor returns nothing after People is disabled', () async {
      await repo.disableAndDelete();
      expect(await repo.photoIdsFor({ashaId}), isEmpty);
    });
  });

  group('People never enabled', () {
    late AppDatabase db;
    late PeopleRepository repo;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
      await seedPhoto(db, 'p1');
    });
    tearDown(() => db.close());

    test('the index is disabled and empty', () async {
      final index = PeoplePhotoIndex.of(await repo.load());
      expect(index.enabled, isFalse);
      expect(index.photosByPerson, isEmpty);
      expect(index.assignments, isEmpty);
      expect(index.labels, isEmpty);
      expect(index.hidden, isEmpty);
      expect(peopleDirectory(await repo.load()), isEmpty);
    });

    test('photoIdsFor returns an empty set', () async {
      expect(await repo.photoIdsFor({'anyone'}), isEmpty);
      await expectLater(repo.photoIdsFor({}), throwsArgumentError);
    });
  });
}
