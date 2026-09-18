import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/memory_repository.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/domain/timeline/memory_grouping.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo(String id, DateTime date) => Photo(
  id: id,
  title: '',
  caption: '',
  tags: const [],
  date: date,
  album: 'Camera',
  source: PhotoSource.device,
);

DateTime day(Photo p) {
  final date = p.date.toLocal();
  return DateTime(date.year, date.month, date.day);
}

List<Object> snapshot(List<MemoryGroup> groups) => [
  for (final group in groups)
    [
      group.id,
      group.title,
      group.coverId,
      group.photos.map((p) => p.id).toList(),
    ],
];

void expectConserved(List<Photo> photos, List<MemoryGroup> groups) {
  final expected = photos.map((p) => p.id).toSet();
  final actual = groups.expand((g) => g.photos).map((p) => p.id).toList();
  expect(actual.length, expected.length);
  expect(actual.toSet(), expected);
  expect(groups.map((g) => g.id).toSet().length, groups.length);
  for (final group in groups) {
    expect(group.photos, isNotEmpty);
    expect(group.photos.any((p) => p.id == group.coverId), isTrue);
    for (var i = 1; i < group.photos.length; i++) {
      final previous = group.photos[i - 1];
      final current = group.photos[i];
      expect(!current.date.isBefore(previous.date), isTrue);
      if (current.date == previous.date) {
        expect(previous.id.compareTo(current.id), lessThan(0));
      }
    }
  }
}

// Matches the observed photo count and Aug 21-Dec 8 span, not private device
// contents: 110 occupied days, 93 with 11 photos and 17 with 10 photos.
List<Photo> chainFixture() {
  final photos = <Photo>[];
  for (var d = 0; d < 110; d++) {
    for (var i = 0; i < (d < 93 ? 11 : 10); i++) {
      photos.add(
        photo(
          'chain-${photos.length.toString().padLeft(4, '0')}',
          DateTime(2023, 8, 21 + d, 9, i * 5),
        ),
      );
    }
  }
  return photos;
}

Future<void> seedEvents(AppDatabase db, List<MemoryGroup> groups) =>
    db.batch((batch) {
      for (final group in groups) {
        batch.insert(
          db.memoryEvents,
          MemoryEventsCompanion.insert(
            id: group.id,
            title: Value(group.title),
            coverId: group.coverId,
            createdMs: group.start.millisecondsSinceEpoch,
          ),
        );
        batch.insertAll(db.memoryMembers, [
          for (final photo in group.photos)
            MemoryMembersCompanion.insert(photoId: photo.id, eventId: group.id),
        ]);
      }
    });

void main() {
  test(
    'automatic memories are calendar days, including across local midnight',
    () {
      final photos = [
        photo('a', DateTime(2024, 3, 31, 0, 1)),
        photo('b', DateTime(2024, 3, 31, 23, 59)),
        photo('c', DateTime(2024, 4, 1, 0, 1)),
      ];
      final result = reconcileMemories(photos.reversed.toList(), []);
      expect(result.length, 2);
      expect(result.first.photos.map((p) => p.id), ['c']);
      expect(result.last.photos.map((p) => p.id), ['a', 'b']);
      expectConserved(photos, result);
    },
  );

  test('UTC timestamps are assigned to their LOCAL calendar day', () {
    final photos = [
      photo('before', DateTime(2024, 6, 1, 23, 59).toUtc()),
      photo('after', DateTime(2024, 6, 2, 0, 1).toUtc()),
      photo('later', DateTime(2024, 6, 2, 23, 59)),
    ];
    final groups = reconcileMemories(photos, []);
    expect(groups.length, 2);
    expect(groups.first.photos.map((p) => p.id), ['after', 'later']);
    expect(groups.last.photos.single.id, 'before');
    expectConserved(photos, groups);
  });

  test('1193-photo Aug-Dec rolling chain becomes 110 stable daily memories', () {
    final photos = chainFixture();
    expect(photos.length, 1193);
    expect(day(photos.first), DateTime(2023, 8, 21));
    expect(day(photos.last), DateTime(2023, 12, 8));
    // Every successive gap qualified under the old rule, explaining one event.
    for (var i = 1; i < photos.length; i++) {
      expect(
        photos[i].date.difference(photos[i - 1].date).inHours,
        lessThanOrEqualTo(48),
      );
    }
    final legacy = MemoryGroup(id: 'original-chain-id', photos: photos);
    final before = snapshot([legacy]);
    final result = reconcileMemories(photos.reversed.toList(), [legacy]);
    expect(result.length, 110);
    expect(result.where((g) => g.photos.length == 11).length, 93);
    expect(result.where((g) => g.photos.length == 10).length, 17);
    expect(result.every((g) => g.photos.map(day).toSet().length == 1), isTrue);
    expect(result.every((g) => g.title.isEmpty), isTrue);
    expect(result.last.id, legacy.id);
    expect(result.last.coverId, legacy.coverId);
    expectConserved(photos, result);
    expect(snapshot([legacy]), before);
    expect(
      snapshot(reconcileMemories(photos, result.reversed.toList())),
      snapshot(result),
    );
    expect(result.map((g) => g.photos.length).reduce(max), 11);
  });

  test(
    'split retains arbitrary old ID in default cover day and does not mutate inputs',
    () {
      final a = photo('a', DateTime(2024, 1, 1, 9));
      final b = photo('b', DateTime(2024, 1, 2, 9));
      final old = MemoryGroup(
        id: 'a-user-visible-id',
        photos: [b, a],
        coverId: 'a',
      );
      final result = reconcileMemories([b, a], [old]);
      expect(result.map((g) => g.id), ['memory:b', 'a-user-visible-id']);
      expect(result.last.coverId, 'a');
      expect(old.photos, [b, a]);
      expect(snapshot(reconcileMemories([a, b], result)), snapshot(result));
    },
  );

  test(
    'named and custom-cover multi-day memories remain whole across reconciles',
    () {
      final photos = [
        photo('a', DateTime(2023, 8, 21)),
        photo('b', DateTime(2023, 12, 8)),
        photo('c', DateTime(2024, 1, 1)),
        photo('d', DateTime(2024, 5, 1)),
      ];
      final named = MemoryGroup(
        id: 'named',
        title: 'My saved title',
        photos: photos.take(2).toList(),
      );
      final custom = MemoryGroup(
        id: 'custom',
        photos: photos.skip(2).toList(),
        coverId: 'd',
      );
      final result = reconcileMemories(photos, [named, custom]);
      expect(result.length, 2);
      expect(result.first.id, 'custom');
      expect(result.first.coverId, 'd');
      expect(result.first.photos.map((p) => p.id), ['c', 'd']);
      expect(result.last.id, 'named');
      expect(result.last.title, 'My saved title');
      expect(result.last.coverId, 'a');
      expect(result.last.photos.map((p) => p.id), ['a', 'b']);
      expect(
        snapshot(reconcileMemories(photos.reversed.toList(), result)),
        snapshot(result),
      );
      expectConserved(photos, result);
    },
  );

  test(
    'curated additions require an already occupied local day, not an interval bridge',
    () {
      final a = photo('a', DateTime(2024, 1, 1, 12));
      final b = photo('b', DateTime(2024, 1, 3, 12));
      final previous = [
        MemoryGroup(id: 'curated', photos: [a, b], title: 'Keep'),
      ];
      final photos = [
        a,
        b,
        photo('same', DateTime(2024, 1, 1, 23, 59)),
        photo('gap', DateTime(2024, 1, 2, 12)),
        photo('outside', DateTime(2024, 1, 4, 0, 1)),
      ];
      final result = reconcileMemories(photos, previous);
      expect(result.length, 3);
      final curated = result.singleWhere((g) => g.id == 'curated');
      expect(curated.title, 'Keep');
      expect(curated.coverId, 'a');
      expect(curated.photos.map((p) => p.id), ['a', 'same', 'b']);
      expect(snapshot(reconcileMemories(photos, result)), snapshot(result));
      expectConserved(photos, result);
    },
  );

  test(
    'same-day additions choose nearest automatic group with stable ID ties',
    () {
      final a = photo('a', DateTime(2024, 1, 1, 9));
      final b = photo('b', DateTime(2024, 1, 1, 17));
      final previous = [
        MemoryGroup(id: 'a-event', photos: [a]),
        MemoryGroup(id: 'b-event', photos: [b]),
      ];
      final near = photo('near', DateTime(2024, 1, 1, 16));
      final nearResult = reconcileMemories([
        b,
        near,
        a,
      ], previous.reversed.toList());
      expect(nearResult.length, 2);
      expect(
        nearResult
            .singleWhere((g) => g.id == 'b-event')
            .photos
            .map((p) => p.id),
        ['near', 'b'],
      );
      final tie = photo('tie', DateTime(2024, 1, 1, 13));
      final tied = reconcileMemories([tie, b, a], previous);
      expect(
        tied.singleWhere((g) => g.id == 'a-event').photos.map((p) => p.id),
        ['a', 'tie'],
      );
      expect(
        snapshot(reconcileMemories([a, tie, b], previous.reversed.toList())),
        snapshot(tied),
      );
      expectConserved([a, b, tie], tied);
    },
  );

  test(
    'newer bridging photos never merge established same-day or adjacent-day events',
    () {
      final a = photo('a', DateTime(2024, 1, 1, 8));
      final b = photo('b', DateTime(2024, 1, 1, 18));
      final c = photo('c', DateTime(2024, 1, 3, 8));
      final previous = [
        MemoryGroup(id: 'first', photos: [a]),
        MemoryGroup(id: 'second', photos: [b]),
        MemoryGroup(id: 'third', photos: [c]),
      ];
      final photos = [
        a,
        b,
        c,
        photo('bridge-hour', DateTime(2024, 1, 1, 13)),
        photo('bridge-day', DateTime(2024, 1, 2, 8)),
      ];
      final result = reconcileMemories(photos, previous);
      expect(result.length, 4);
      for (final old in previous) {
        final retained = result.singleWhere((g) => g.id == old.id);
        expect(retained.coverId, old.coverId);
        expect(retained.photos, containsAll(old.photos));
      }
      expect(
        result.singleWhere((g) => g.id == 'memory:bridge-day').photos.single.id,
        'bridge-day',
      );
      expectConserved(photos, result);
    },
  );

  test(
    'automatic candidates take priority over curated memories on the same day',
    () {
      final a = photo('a', DateTime(2024, 1, 1, 8));
      final b = photo('b', DateTime(2024, 1, 1, 18));
      final added = photo('new', DateTime(2024, 1, 1, 17));
      final result = reconcileMemories(
        [a, b, added],
        [
          MemoryGroup(id: 'automatic', photos: [a]),
          MemoryGroup(id: 'curated', photos: [b], title: 'Keep'),
        ],
      );
      expect(
        result.singleWhere((g) => g.id == 'automatic').photos.map((p) => p.id),
        ['a', 'new'],
      );
      expect(result.singleWhere((g) => g.id == 'curated').photos, [b]);
    },
  );

  test(
    'split and addition IDs reserve all old IDs and resolve photo-ID collisions',
    () {
      final a = photo('a', DateTime(2024, 1, 1));
      final split = photo('split', DateTime(2024, 1, 2));
      final other = photo('other', DateTime(2024, 2, 1));
      final other2 = photo('other2', DateTime(2024, 3, 1));
      final fresh = photo('fresh', DateTime(2024, 4, 1));
      final previous = [
        MemoryGroup(id: 'memory:split', photos: [a, split]),
        MemoryGroup(id: 'memory:split:2', photos: [other]),
        MemoryGroup(id: 'memory:fresh', photos: [other2]),
      ];
      final photos = [a, split, other, other2, fresh];
      final result = reconcileMemories(photos, previous);
      expect(
        result.singleWhere((g) => g.photos.any((p) => p.id == 'a')).id,
        'memory:split',
      );
      expect(
        result.singleWhere((g) => g.photos.any((p) => p.id == 'split')).id,
        'memory:split:3',
      );
      expect(
        result.singleWhere((g) => g.photos.any((p) => p.id == 'fresh')).id,
        'memory:fresh:2',
      );
      expectConserved(photos, result);
      expect(
        snapshot(
          reconcileMemories(
            photos.reversed.toList(),
            previous.reversed.toList(),
          ),
        ),
        snapshot(result),
      );
      expect(snapshot(reconcileMemories(photos, result)), snapshot(result));
    },
  );

  test(
    'deleted cover uncertainty preserves multi-day groups through subsequent reconciles',
    () {
      final a = photo('a', DateTime(2024, 1, 1));
      final b = photo('b', DateTime(2024, 2, 1));
      // Repository reconstruction contains surviving members only, so the old
      // cover cannot be classified as default or custom from this snapshot.
      final unknown = MemoryGroup(
        id: 'unknown',
        photos: [a, b],
        coverId: 'deleted',
      );
      final result = reconcileMemories([a, b], [unknown]);
      expect(result.length, 1);
      expect(result.single.id, 'unknown');
      expect(result.single.title, isEmpty);
      expect(result.single.coverId, 'b');
      expect(snapshot(reconcileMemories([a, b], result)), snapshot(result));
      final one = reconcileMemories([a], result);
      expect(one.single.id, 'unknown');
      expect(one.single.coverId, 'a');
      expect(reconcileMemories([], one), isEmpty);
      expectConserved([a, b], result);
    },
  );

  test(
    'empty removal, duplicate source IDs and stale repeated memberships conserve every photo',
    () {
      final a = photo('a', DateTime(2024, 1, 1));
      final b = photo('b', DateTime(2024, 1, 2));
      final result = reconcileMemories(
        [b, a, a, b],
        [
          MemoryGroup(id: 'a-event', photos: [a, a]),
          MemoryGroup(id: 'b-event', photos: [a, b]),
          MemoryGroup(id: 'empty', photos: [], coverId: 'gone'),
        ],
      );
      expect(result.any((g) => g.id == 'empty'), isFalse);
      expectConserved([a, b], result);
      expect(snapshot(reconcileMemories([a, b], result)), snapshot(result));
    },
  );

  test(
    'seeded mixed migrations conserve counts and are stable under reordering and retries',
    () {
      for (var seed = 0; seed < 30; seed++) {
        final random = Random(seed);
        final old = <MemoryGroup>[];
        final library = <Photo>[];
        for (var event = 0; event < 10; event++) {
          final members = List.generate(
            15,
            (i) => photo(
              'e$event-p$i',
              DateTime(2024, 1, 1 + random.nextInt(45), i),
            ),
          )..sort((a, b) => a.date.compareTo(b.date));
          old.add(
            MemoryGroup(
              id: 'e$event',
              photos: members,
              title: event % 3 == 0 ? 'Saved $event' : '',
              coverId: event % 3 == 1 ? members.last.id : members.first.id,
            ),
          );
          library.addAll(members.where((_) => random.nextInt(4) != 0));
        }
        library.addAll(
          List.generate(
            20,
            (i) => photo('new$i', DateTime(2024, 1, 1 + random.nextInt(60), i)),
          ),
        );
        final result = reconcileMemories(library, old);
        expectConserved(library, result);
        expect(
          snapshot(reconcileMemories(library, result)),
          snapshot(result),
          reason: 'seed $seed repeat',
        );
        final shuffledPhotos = library.toList()..shuffle(random);
        final shuffledGroups = old.toList()..shuffle(random);
        expect(
          snapshot(reconcileMemories(shuffledPhotos, shuffledGroups)),
          snapshot(result),
          reason: 'seed $seed reorder',
        );
      }
    },
  );

  test(
    'repository persists 1193-member migration atomically with strict counts and repeat stability',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final photos = chainFixture();
      await PhotoRepository(db).savePhotos(photos);
      final old = MemoryGroup(id: 'persisted-chain', photos: photos);
      await seedEvents(db, [old]);
      expect((await db.select(db.memoryEvents).get()).length, 1);
      expect((await db.select(db.memoryMembers).get()).length, 1193);
      final repo = MemoryRepository(db);
      final result = await repo.reconcile(photos);
      expect(result.length, 110);
      expect(result.last.id, 'persisted-chain');
      expectConserved(photos, result);
      expect((await db.select(db.memoryEvents).get()).length, 110);
      expect((await db.select(db.memoryMembers).get()).length, 1193);
      expect(await PhotoRepository(db).photoCount(), 1193);
      final rows = await db.select(db.memoryEvents).get();
      final members = await db.select(db.memoryMembers).get();
      expect(
        snapshot(await repo.reconcile(photos.reversed.toList())),
        snapshot(result),
      );
      expect(await db.select(db.memoryEvents).get(), rows);
      expect(await db.select(db.memoryMembers).get(), members);
    },
  );

  test(
    'repository keeps curated covers/titles and missing-cover uncertainty after repeated reloads',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final a = photo('a', DateTime(2024, 1, 1));
      final b = photo('b', DateTime(2024, 2, 1));
      final c = photo('c', DateTime(2024, 3, 1));
      final d = photo('d', DateTime(2024, 4, 1));
      final e = photo('e', DateTime(2024, 5, 1));
      final f = photo('f', DateTime(2024, 6, 1));
      final photos = [a, b, c, d, e, f];
      await seedEvents(db, [
        MemoryGroup(id: 'named', photos: [a, b], title: 'My name'),
        MemoryGroup(id: 'custom', photos: [c, d], coverId: 'd'),
        MemoryGroup(id: 'unknown', photos: [e, f], coverId: 'deleted'),
      ]);
      final repo = MemoryRepository(db);
      final first = await repo.reconcile(photos);
      expect(first.length, 3);
      expect(first.singleWhere((g) => g.id == 'named').title, 'My name');
      expect(first.singleWhere((g) => g.id == 'custom').coverId, 'd');
      expect(first.singleWhere((g) => g.id == 'unknown').coverId, 'f');
      expect(snapshot(await repo.reconcile(photos)), snapshot(first));
      final afterDeletion = await repo.reconcile([a, b, c, e, f]);
      expect(afterDeletion.length, 3);
      expect(afterDeletion.singleWhere((g) => g.id == 'custom').coverId, 'c');
      expect(
        snapshot(await repo.reconcile([a, b, c, e, f])),
        snapshot(afterDeletion),
      );
      expectConserved([a, b, c, e, f], afterDeletion);
      expect((await db.select(db.memoryMembers).get()).length, 5);
    },
  );
}
