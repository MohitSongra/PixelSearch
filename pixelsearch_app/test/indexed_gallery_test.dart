import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/domain/gallery/indexed_gallery.dart';
import 'package:pixelsearch/domain/search/library_suggestions.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo(String id, DateTime date, {List<String> labels = const []}) =>
    Photo(
      id: id,
      title: '',
      caption: 'beach at sunset',
      tags: ['unrelated tag'],
      date: date,
      album: 'Camera',
      source: PhotoSource.sample,
      labels: labels,
    );

void main() {
  test(
    'gallery keeps every indexed photo, newest first, with stable date ties',
    () {
      final source = [
        photo('z', DateTime(2023, 1, 2)),
        photo('b', DateTime(2026, 9, 9)),
        photo('a', DateTime(2026, 9, 9)),
        photo('x', DateTime(2026, 8, 1)),
      ];
      final gallery = IndexedGallery(source);
      expect(gallery.photos.map((p) => p.id), ['a', 'b', 'x', 'z']);
      expect(source.first.id, 'z');
      expect(gallery.days.map((d) => d.count), [2, 1, 1]);
      expect(gallery.months.map((m) => m.count), [2, 1, 1]);
      expect(gallery.months.map((m) => m.date), [
        DateTime(2026, 9),
        DateTime(2026, 8),
        DateTime(2023, 1),
      ]);
    },
  );

  test(
    'day grouping uses local calendar dates, including UTC source timestamps',
    () {
      final time = DateTime.utc(2026, 1, 1, 23, 30);
      final local = time.toLocal();
      final gallery = IndexedGallery([
        photo('utc', time),
        photo('local', local),
      ]);
      expect(
        gallery.days.single.date,
        DateTime(local.year, local.month, local.day),
      );
      expect(gallery.days.single.count, 2);
    },
  );

  test(
    'virtual rows cover thousands of photos exactly once and map date offsets',
    () {
      final gallery = IndexedGallery(
        List.generate(
          1916,
          (i) => photo(
            '$i',
            DateTime(2026, 9, 9).subtract(Duration(days: i ~/ 11)),
          ),
        ),
      );
      for (final columns in [3, 5, 8]) {
        final layout = GalleryLayout(
          gallery,
          columns: columns,
          photoExtent: 100,
          headerExtent: 48,
        );
        final indices = [
          for (final row in layout.entries.where((r) => !r.isHeader))
            for (var i = row.start; i < row.start + row.count; i++) i,
        ];
        expect(indices, List.generate(1916, (i) => i));
        for (var month = 0; month < gallery.months.length; month++) {
          final row =
              layout.entries[layout.entryAt(layout.monthOffsets[month])];
          expect(row.isHeader, isTrue);
          expect(row.day.monthIndex, month);
        }
        expect(layout.entryAt(-100), 0);
        expect(
          layout.entryAt(layout.totalExtent + 100),
          layout.entries.length - 1,
        );
      }
    },
  );

  test('empty gallery and suggestions do not introduce samples', () {
    final gallery = IndexedGallery([]);
    expect(gallery.photos, isEmpty);
    expect(gallery.days, isEmpty);
    expect(gallery.months, isEmpty);
    expect(librarySuggestions([]), isEmpty);
    expect(librarySuggestions([photo('no-label', DateTime(2026))]), isEmpty);
  });

  test(
    'suggestions count actual labels once per photo, never compose scenes',
    () {
      final suggestions = librarySuggestions([
        photo(
          '1',
          DateTime(2026),
          labels: ['Car', ' car ', 'Tree', 'photo', 'cool'],
        ),
        photo('2', DateTime(2026), labels: ['CAR', 'dog']),
      ]);
      expect(suggestions.map((s) => s.query), ['car', 'dog', 'tree']);
      expect(suggestions.map((s) => s.photoCount), [2, 1, 1]);
      expect(suggestions.any((s) => s.query.contains('beach')), isFalse);
      expect(suggestions.any((s) => s.query.contains('unrelated')), isFalse);
    },
  );

  test(
    'different libraries and corrected labels produce different suggestions',
    () {
      final original = photo('1', DateTime(2026), labels: ['car']);
      expect(librarySuggestions([original]).single.query, 'car');
      expect(
        librarySuggestions([
          original.withLabels(['flower']),
        ]).single.query,
        'flower',
      );
      expect(librarySuggestions([original.withLabels([])]), isEmpty);
      expect(librarySuggestions([original], limit: 0), isEmpty);
    },
  );
}
