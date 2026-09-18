import '../../models/photo.dart';

class MemoryGroup {
  MemoryGroup({
    required this.id,
    required this.photos,
    this.title = '',
    String? coverId,
  }) : coverId = coverId ?? photos.first.id;
  final String id;
  final List<Photo> photos;
  final String title;
  final String coverId;
  DateTime get start => photos.first.date;
  DateTime get end => photos.last.date;
  Photo get cover =>
      photos.firstWhere((p) => p.id == coverId, orElse: () => photos.first);
}

int _chronologicalOrder(Photo a, Photo b) {
  final date = a.date.compareTo(b.date);
  return date != 0 ? date : a.id.compareTo(b.id);
}

DateTime _localDay(Photo photo) {
  final date = photo.date.toLocal();
  return DateTime(date.year, date.month, date.day);
}

class _DayMembership {
  _DayMembership(this.group, this.automatic, this.start) : end = start;
  final MemoryGroup group;
  final bool automatic;
  DateTime start;
  DateTime end;

  void include(DateTime date) {
    if (date.isBefore(start)) start = date;
    if (date.isAfter(end)) end = date;
  }

  int distance(DateTime date) => date.isBefore(start)
      ? start.difference(date).inMicroseconds
      : date.isAfter(end)
      ? date.difference(end).inMicroseconds
      : 0;
}

/// Untouched automatic events are local calendar days, never rolling gap chains.
/// Named/custom-cover events retain their membership; additions may join only a
/// day already occupied by that event. Established events never auto-merge.
List<MemoryGroup> reconcileMemories(
  List<Photo> photos,
  List<MemoryGroup> previous,
) {
  final sorted = photos.toList()..sort(_chronologicalOrder);
  final byId = <String, Photo>{};
  for (final photo in sorted) {
    byId.putIfAbsent(photo.id, () => photo);
  }
  final assigned = <String>{};
  final groups = <MemoryGroup>[];
  final byDay = <DateTime, List<_DayMembership>>{};
  final usedIds = previous.map((group) => group.id).toSet();

  String freshId(Photo photo) {
    final base = 'memory:${photo.id}';
    var id = base;
    var suffix = 2;
    while (!usedIds.add(id)) {
      id = '$base:${suffix++}';
    }
    return id;
  }

  void register(MemoryGroup group, {required bool automatic}) {
    groups.add(group);
    final days = <DateTime, _DayMembership>{};
    for (final photo in group.photos) {
      (days[_localDay(photo)] ??= _DayMembership(
        group,
        automatic,
        photo.date,
      )).include(photo.date);
    }
    for (final entry in days.entries) {
      (byDay[entry.key] ??= []).add(entry.value);
    }
  }

  final established = previous.toList()..sort((a, b) => a.id.compareTo(b.id));
  for (final old in established) {
    final members = [
      for (final p in old.photos)
        if (byId.containsKey(p.id) && assigned.add(p.id)) byId[p.id]!,
    ]..sort(_chronologicalOrder);
    if (members.isEmpty) continue;
    final hasCover = members.any((photo) => photo.id == old.coverId);
    final automatic =
        old.title.isEmpty && hasCover && old.coverId == members.first.id;
    if (automatic) {
      final days = <DateTime, List<Photo>>{};
      for (final photo in members) {
        (days[_localDay(photo)] ??= []).add(photo);
      }
      for (final day in days.values) {
        final keepsId = day.any((photo) => photo.id == old.coverId);
        register(
          MemoryGroup(
            id: keepsId ? old.id : freshId(day.first),
            photos: day,
            coverId: keepsId ? old.coverId : day.first.id,
          ),
          automatic: true,
        );
      }
    } else {
      // A missing cover erases the default/custom distinction. For an untitled
      // group, the last survivor is a non-default replacement (unless singleton),
      // so the next persisted reconcile cannot mistake it for a splittable group.
      final coverId = hasCover
          ? old.coverId
          : old.title.isEmpty
          ? members.last.id
          : members.first.id;
      register(
        MemoryGroup(
          id: old.id,
          photos: members,
          title: old.title,
          coverId: coverId,
        ),
        automatic: false,
      );
    }
  }
  final additions = byId.values.where((p) => !assigned.contains(p.id));
  for (final photo in additions) {
    final candidates = byDay[_localDay(photo)] ?? const <_DayMembership>[];
    final hasAutomatic = candidates.any((candidate) => candidate.automatic);
    _DayMembership? nearest;
    int? distance;
    for (final candidate in candidates) {
      // Prefer automatic groups rather than absorbing a new automatic event
      // into a curated one that happens to occupy the same day.
      if (hasAutomatic && !candidate.automatic) continue;
      final gap = candidate.distance(photo.date);
      if (distance == null ||
          gap < distance ||
          (gap == distance &&
              candidate.group.id.compareTo(nearest!.group.id) < 0)) {
        distance = gap;
        nearest = candidate;
      }
    }
    if (nearest == null) {
      register(
        MemoryGroup(id: freshId(photo), photos: [photo]),
        automatic: true,
      );
    } else {
      nearest.group.photos.add(photo);
      nearest.include(photo.date);
    }
  }
  for (final group in groups) {
    group.photos.sort(_chronologicalOrder);
  }
  groups.sort((a, b) {
    final date = b.start.compareTo(a.start);
    return date != 0 ? date : a.id.compareTo(b.id);
  });
  return groups;
}
