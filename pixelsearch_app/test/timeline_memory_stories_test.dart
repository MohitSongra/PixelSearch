import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/memory_repository.dart';
import 'package:pixelsearch/domain/timeline/memory_grouping.dart';
import 'package:pixelsearch/domain/timeline/memory_stories.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo(String id, DateTime date, {int faces = 0}) => Photo(
  id: id,
  title: '',
  caption: '',
  tags: const [],
  date: date,
  album: 'Camera',
  source: PhotoSource.device,
  faceCount: faces,
);

MemoryGroup event(String id, List<Photo> photos) =>
    MemoryGroup(id: id, photos: photos);

void main() {
  test('empty and empty-member events produce no invented stories', () {
    final timeline = MemoryTimeline([
      MemoryGroup(id: 'empty', photos: [], coverId: 'missing'),
    ]);
    expect(timeline.years, isEmpty);
    expect(timeline.monthsIn(2024), isEmpty);
    expect(timeline.sections(2024), isEmpty);
    expect(timeline.story(2024), isNull);
  });

  test(
    'sparse years and months come only from indexed dates, newest first',
    () {
      final timeline = MemoryTimeline([
        event('old', [photo('a', DateTime(2022, 2, 3))]),
        event('new', [photo('b', DateTime(2026, 9, 8))]),
        event('middle', [photo('c', DateTime(2026, 1, 1))]),
      ]);
      expect(timeline.years, [2026, 2022]);
      expect(timeline.monthsIn(2026), [9, 1]);
      expect(timeline.story(2024), isNull);
      expect(timeline.story(2022)!.title, 'Back in 2022');
      expect(timeline.story(2022)!.photos.single.id, 'a');
    },
  );

  test('sections and date ties have deterministic chronological ordering', () {
    final groups = [
      event('b', [photo('b', DateTime(2024, 8, 10))]),
      event('a', [photo('a', DateTime(2024, 8, 10))]),
      event('c', [photo('c', DateTime(2024, 8, 20))]),
      event('d', [photo('d', DateTime(2024, 12, 1))]),
    ];
    for (final source in [groups, groups.reversed]) {
      final sections = MemoryTimeline(source).sections(2024);
      expect(sections.map((s) => s.date.month), [12, 8]);
      expect(sections.last.memories.map((m) => m.event.id), ['c', 'a', 'b']);
    }
  });

  test(
    'cross-year membership is discoverable without copying or regrouping',
    () {
      final first = photo('a', DateTime(2023, 12, 31));
      final last = photo('b', DateTime(2024, 2, 1));
      final saved = MemoryGroup(
        id: 'saved',
        photos: [last, first],
        title: 'My chosen name',
        coverId: last.id,
      );
      final timeline = MemoryTimeline([saved]);
      expect(timeline.years, [2024, 2023]);
      expect(timeline.monthsIn(2024), [2]);
      expect(timeline.sections(2024, month: 1), isEmpty);
      final view = timeline.sections(2023).single.memories.single;
      expect(identical(view.event, saved), isTrue);
      expect(view.start, first.date);
      expect(view.end, last.date);
      expect(saved.photos, [last, first]);
      expect(saved.title, 'My chosen name');
      expect(saved.cover.id, 'b');
      expect(timeline.story(2024)!.photos.map((p) => p.id), ['b']);
      expect(timeline.story(2023)!.photos.map((p) => p.id), ['a']);
    },
  );

  test(
    'all-month view shows a spanning event once, filters keep whole event',
    () {
      final saved = event('span', [
        photo('jan', DateTime(2024, 1, 31)),
        photo('feb', DateTime(2024, 2, 1)),
      ]);
      final timeline = MemoryTimeline([saved]);
      expect(timeline.sections(2024).single.date.month, 2);
      final january = timeline.sections(2024, month: 1).single.memories.single;
      expect(january.event, same(saved));
      expect(january.photos.length, 2);
    },
  );

  test(
    'people requires detected faces, never title, tags or relationships',
    () {
      final withoutFaces = Photo(
        id: 'tag-only',
        title: 'Family and friends',
        caption: 'People',
        tags: const ['portrait'],
        labels: const ['face'],
        date: DateTime(2024),
        album: '',
        source: PhotoSource.device,
      );
      final timeline = MemoryTimeline([
        event('a', [
          withoutFaces,
          photo('negative', DateTime(2024, 1, 2), faces: -1),
          photo('detected', DateTime(2024, 1, 3), faces: 2),
        ]),
        event('b', [photo('none', DateTime(2025))]),
      ]);
      expect(timeline.story(2025, peopleOnly: true), isNull);
      final story = timeline.story(2024, peopleOnly: true)!;
      expect(story.title, 'People in 2024');
      expect(story.photos.map((p) => p.id), ['detected']);
    },
  );

  test('selections are bounded, unique, immutable and input-order stable', () {
    final photos = List.generate(
      400,
      (i) =>
          photo('p${i.toString().padLeft(3, '0')}', DateTime(2024, 1, 1, 0, i)),
    );
    final selected = selectStoryPhotos([...photos, photos.first]);
    expect(selected.length, maxMemoryStoryPhotos);
    expect(selected.first.id, 'p000');
    expect(selected.last.id, 'p399');
    expect(selected.map((p) => p.id).toSet().length, selected.length);
    expect(
      selectStoryPhotos(photos.reversed).map((p) => p.id),
      selected.map((p) => p.id),
    );
    expect(() => selected.add(photos.first), throwsUnsupportedError);
    expect(photos.first.id, 'p000');
    expect(selectStoryPhotos(photos, limit: 100).length, 20);
    expect(selectStoryPhotos(photos, limit: 0), isEmpty);
    expect(selectStoryPhotos(photos, limit: -1), isEmpty);
  });

  test('a large burst cannot displace photos from sparse other dates', () {
    final burst = List.generate(
      50000,
      (i) => photo('burst$i', DateTime(2024, 1, 1).add(Duration(seconds: i))),
    );
    final sparse = [
      photo('spring', DateTime(2024, 4, 1)),
      photo('summer', DateTime(2024, 7, 1)),
      photo('winter', DateTime(2024, 12, 1)),
    ];
    final selected = selectStoryPhotos([...burst, ...sparse]);
    expect(selected.length, 20);
    expect(selected, containsAll(sparse));
    expect(selected.last.id, 'winter');
  });

  test('many days sample across the year and play oldest to newest', () {
    final photos = List.generate(
      366,
      (i) => photo('$i', DateTime(2024, 1, 1).add(Duration(days: i))),
    );
    final selected = selectStoryPhotos(photos);
    expect(selected.first, photos.first);
    expect(selected.last, photos.last);
    expect(selected.map((p) => p.date.month).toSet().length, 12);
    for (var i = 1; i < selected.length; i++) {
      expect(selected[i].date.isAfter(selected[i - 1].date), isTrue);
    }
    expect(selectStoryPhotos(photos, limit: 1).single, photos[182]);
  });

  test('same-time photos use stable ID tie-breaking', () {
    final a = photo('a', DateTime(2024)), b = photo('b', DateTime(2024));
    expect(selectStoryPhotos([b, a]).map((p) => p.id), ['a', 'b']);
  });

  test(
    'browsing every story leaves persisted titles, covers and members intact',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = MemoryRepository(db);
      final photos = [
        photo('a', DateTime(2024, 1, 1), faces: 1),
        photo('b', DateTime(2024, 1, 1, 12)),
        photo('c', DateTime(2025, 9, 1)),
      ];
      final groups = await repository.reconcile(photos);
      final saved = groups.singleWhere((g) => g.photos.any((p) => p.id == 'a'));
      await repository.edit(saved.id, title: 'Keep this title', coverId: 'b');
      // Start with a valid daily event, then correct a date after curation.
      // Stories and later reconciles must preserve the now-multi-day memory.
      photos[1] = photo('b', DateTime(2024, 1, 2));
      final edited = await repository.reconcile(photos);
      expect(edited.singleWhere((g) => g.id == saved.id).photos.length, 2);
      final beforeEvents = await db.select(db.memoryEvents).get();
      final beforeMembers = await db.select(db.memoryMembers).get();
      final timeline = MemoryTimeline(edited);
      for (final year in timeline.years) {
        timeline.story(year);
        timeline.story(year, peopleOnly: true);
        for (final month in timeline.monthsIn(year)) {
          timeline.sections(year, month: month);
        }
      }
      expect(await db.select(db.memoryEvents).get(), beforeEvents);
      expect(await db.select(db.memoryMembers).get(), beforeMembers);
      final reread = (await repository.reconcile(
        photos,
      )).singleWhere((g) => g.id == saved.id);
      expect(reread.title, 'Keep this title');
      expect(reread.cover.id, 'b');
      expect(reread.photos.map((p) => p.id), ['a', 'b']);
    },
  );
}
