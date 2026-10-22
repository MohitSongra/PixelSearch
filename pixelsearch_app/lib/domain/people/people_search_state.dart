import '../search/search_response.dart';
import 'people_query.dart';

enum PeopleEmptyKind {
  selfMissing,
  peopleOff,
  noAssignedPhotos,
  notTogether,
  allExcluded,
  noneInFilters,
  noSceneMatch,
}

/// Why a person search returned nothing, so the screen can say what is true.
class PeopleEmptyState {
  const PeopleEmptyState(
    this.kind, {
    this.names = const [],
    this.count = 0,
    this.remainder = '',
  });
  final PeopleEmptyKind kind;

  /// Display names in query order ("you" for the device owner).
  final List<String> names;

  /// Photos matching the people before the scene or other filters.
  final int count;
  final String remainder;
}

String joinNames(List<String> names, {String conjunction = 'and'}) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  return '${names.sublist(0, names.length - 1).join(', ')} $conjunction ${names.last}';
}

/// Null when the response has photos or the query names nobody.
PeopleEmptyState? explainEmptyPeopleSearch(
  PeopleQuery query,
  SearchResponse response,
) {
  if (query.selfMissing) {
    return const PeopleEmptyState(PeopleEmptyKind.selfMissing);
  }
  if (response.photos.isNotEmpty || !query.filters.hasPeople) return null;
  final summary = response.people;
  if (summary == null) return null;
  String label(String id) {
    final mention = query.mentions.where((m) => m.personId == id).firstOrNull;
    if (mention != null && mention.isSelf) return 'you';
    return summary.labels[id] ?? mention?.label ?? 'this person';
  }

  List<String> ordered(Set<String> ids) {
    final result = <String>[];
    for (final m in query.mentions) {
      if (m.personId != null &&
          ids.contains(m.personId) &&
          !result.contains(label(m.personId!))) {
        result.add(label(m.personId!));
      }
    }
    for (final id in ids) {
      if (!result.contains(label(id))) result.add(label(id));
    }
    return result;
  }

  final required = query.filters.personIds;
  final any = query.filters.anyPersonIds;
  final included = {...required, ...any};
  if (!summary.peopleEnabled) {
    return PeopleEmptyState(
      PeopleEmptyKind.peopleOff,
      names: ordered(included),
    );
  }
  final missing = {
    for (final id in required)
      if ((summary.photoCounts[id] ?? 0) == 0) id,
  };
  if (any.isNotEmpty &&
      any.every((id) => (summary.photoCounts[id] ?? 0) == 0)) {
    missing.addAll(any);
  }
  if (missing.isNotEmpty) {
    return PeopleEmptyState(
      PeopleEmptyKind.noAssignedPhotos,
      names: ordered(missing),
    );
  }
  if (summary.together == 0) {
    return PeopleEmptyState(
      PeopleEmptyKind.notTogether,
      names: ordered(included),
    );
  }
  if (summary.eligible == 0) {
    return PeopleEmptyState(
      PeopleEmptyKind.allExcluded,
      names: ordered(included),
      count: summary.together,
    );
  }
  if (summary.inFilters == 0) {
    return PeopleEmptyState(
      PeopleEmptyKind.noneInFilters,
      names: ordered(included),
      count: summary.eligible,
    );
  }
  if (query.query.trim().isNotEmpty) {
    return PeopleEmptyState(
      PeopleEmptyKind.noSceneMatch,
      names: ordered(included),
      count: summary.inFilters,
      remainder: query.query.trim(),
    );
  }
  return null;
}
