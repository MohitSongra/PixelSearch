import '../../models/photo.dart';
import 'memory_grouping.dart';

const maxMemoryStoryPhotos = 20;

int _photoOrder(Photo a, Photo b) {
  final time = a.date.compareTo(b.date);
  return time != 0 ? time : a.id.compareTo(b.id);
}

/// A read-only view. Saved membership, titles and covers remain repository-owned.
class TimelineMemory {
  TimelineMemory(this.event)
    : photos = List.unmodifiable(event.photos.toList()..sort(_photoOrder));

  final MemoryGroup event;
  final List<Photo> photos;
  DateTime get start => photos.first.date.toLocal();
  DateTime get end => photos.last.date.toLocal();
}

class MemoryMonth {
  const MemoryMonth(this.date, this.memories);
  final DateTime date;
  final List<TimelineMemory> memories;
}

class MemoryStory {
  MemoryStory._(this.year, this.peopleOnly, List<Photo> photos)
    : photos = List.unmodifiable(photos);

  final int year;
  final bool peopleOnly;
  final List<Photo> photos;
  String get id => '${peopleOnly ? 'people' : 'year'}:$year';
  String get title => peopleOnly ? 'People in $year' : 'Back in $year';
}

/// Calendar navigation and stories use only dates already in indexed photos.
/// No clock, random seed, photo inference, or persistence writes are involved.
class MemoryTimeline {
  MemoryTimeline(Iterable<MemoryGroup> events) {
    final byId = <String, Photo>{};
    for (final event in events) {
      if (event.photos.isEmpty) continue;
      final memory = TimelineMemory(event);
      final months = <DateTime>{};
      for (final photo in memory.photos) {
        byId.putIfAbsent(photo.id, () => photo);
        final date = photo.date.toLocal();
        months.add(DateTime(date.year, date.month));
      }
      for (final month in months) {
        (_byMonth[month] ??= []).add(memory);
      }
    }
    final photos = byId.values.toList()..sort(_photoOrder);
    for (final photo in photos) {
      (_byYear[photo.date.toLocal().year] ??= []).add(photo);
    }
    years = List.unmodifiable(_byYear.keys.toList()..sort((a, b) => b - a));
    for (final entry in _byMonth.entries) {
      DateTime latest(TimelineMemory memory) => memory.photos.lastWhere((p) {
        final date = p.date.toLocal();
        return date.year == entry.key.year && date.month == entry.key.month;
      }).date;
      entry.value.sort((a, b) {
        final date = latest(b).compareTo(latest(a));
        return date != 0 ? date : a.event.id.compareTo(b.event.id);
      });
    }
  }

  final _byYear = <int, List<Photo>>{};
  final _byMonth = <DateTime, List<TimelineMemory>>{};
  final _stories = <(int, bool), MemoryStory?>{};
  late final List<int> years;

  List<int> monthsIn(int year) => List.unmodifiable(
    _byMonth.keys.where((d) => d.year == year).map((d) => d.month).toList()
      ..sort((a, b) => b - a),
  );

  /// An event spanning months is shown once, under its latest matching month.
  /// Filtering another occupied month still exposes the original whole event.
  List<MemoryMonth> sections(int year, {int? month}) {
    final seen = <String>{};
    final result = <MemoryMonth>[];
    for (final m in monthsIn(year)) {
      if (month != null && month != m) continue;
      final date = DateTime(year, m);
      final memories = _byMonth[date]!
          .where((memory) => seen.add(memory.event.id))
          .toList();
      if (memories.isNotEmpty) {
        result.add(MemoryMonth(date, List.unmodifiable(memories)));
      }
    }
    return List.unmodifiable(result);
  }

  MemoryStory? story(int year, {bool peopleOnly = false}) =>
      _stories.putIfAbsent((year, peopleOnly), () {
        final photos = _byYear[year];
        if (photos == null) return null;
        final selected = selectStoryPhotos(
          peopleOnly ? photos.where((p) => p.faceCount > 0) : photos,
        );
        return selected.isEmpty
            ? null
            : MemoryStory._(year, peopleOnly, selected);
      });
}

/// Round-robin across evenly spaced calendar days before selecting more from a
/// burst. Date/id tie-breaking makes selection independent of input ordering.
List<Photo> selectStoryPhotos(
  Iterable<Photo> source, {
  int limit = maxMemoryStoryPhotos,
}) {
  final cap = limit.clamp(0, maxMemoryStoryPhotos);
  if (cap == 0) return const [];
  final sorted = source.toList()..sort(_photoOrder);
  final seen = <String>{};
  final days = <DateTime, List<Photo>>{};
  for (final photo in sorted) {
    if (!seen.add(photo.id)) continue;
    final date = photo.date.toLocal();
    (days[DateTime(date.year, date.month, date.day)] ??= []).add(photo);
  }
  final buckets = days.values.toList();
  if (buckets.isEmpty) return const [];
  final quotas = List.filled(buckets.length, 0);
  var total = 0;
  var depth = 0;
  int spread(int index, int count, int length) => count == 1
      ? (length - 1) ~/ 2
      : (index * (length - 1) / (count - 1)).round();
  while (total < cap) {
    final available = [
      for (var i = 0; i < buckets.length; i++)
        if (buckets[i].length > depth) i,
    ];
    if (available.isEmpty) break;
    final slots = (cap - total).clamp(0, available.length);
    for (var i = 0; i < slots; i++) {
      quotas[available[spread(i, slots, available.length)]]++;
      total++;
    }
    depth++;
  }
  final chosen = <Photo>[
    for (var day = 0; day < buckets.length; day++)
      for (var i = 0; i < quotas[day]; i++)
        buckets[day][spread(i, quotas[day], buckets[day].length)],
  ];
  return List.unmodifiable(chosen..sort(_photoOrder));
}
