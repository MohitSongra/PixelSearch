import '../search/search_response.dart';

class NamedPerson {
  const NamedPerson(this.id, this.name, {this.aliases = const []});
  final String id, name;
  final List<String> aliases;
}

class PeopleQuery {
  const PeopleQuery({
    required this.query,
    required this.filters,
    this.matched = const {},
    this.ambiguous = const {},
  });
  final String query;
  final SearchFilters filters;
  final Map<String, String> matched;
  final Map<String, List<NamedPerson>> ambiguous;
  bool get needsChoice => ambiguous.isNotEmpty;
}

class _NameMatch {
  const _NameMatch(this.start, this.end, this.alias, this.people);
  final int start, end;
  final String alias;
  final List<NamedPerson> people;
}

PeopleQuery resolvePeopleQuery(
  String query,
  List<NamedPerson> people, {
  SearchFilters filters = const SearchFilters(),
  Map<String, String> choices = const {},
  Set<String> ignoredNames = const {},
  DateTime? now,
}) {
  final aliases = <String, Map<String, NamedPerson>>{};
  for (final person in people) {
    for (final name in [person.name, ...person.aliases]) {
      final key = name.trim().toLowerCase();
      if (key.isNotEmpty && !ignoredNames.contains(key)) {
        aliases.putIfAbsent(key, () => {})[person.id] = person;
      }
    }
  }
  final matches = <_NameMatch>[];
  for (final entry in aliases.entries) {
    final name = RegExp.escape(entry.key).replaceAll(' ', r'\s+');
    final expression = RegExp(
      r'(^|[^\p{L}\p{N}\p{M}_])(' + name + r')(?=$|[^\p{L}\p{N}\p{M}_])',
      caseSensitive: false,
      unicode: true,
    );
    for (final m in expression.allMatches(query)) {
      final start = m.start + m.group(1)!.length;
      // In a request such as "show me photos of Rudra", "me" is not a subject.
      if (entry.key == 'me' &&
          RegExp(
            r'\b(?:show|find|get|give)\s+$',
            caseSensitive: false,
          ).hasMatch(query.substring(0, start)) &&
          RegExp(
            r'^\s+(?:(?:all|the|some|my)\s+)?(?:photos?|pictures?|images?)\b',
            caseSensitive: false,
          ).hasMatch(query.substring(m.end))) {
        continue;
      }
      matches.add(
        _NameMatch(start, m.end, entry.key, entry.value.values.toList()),
      );
    }
  }
  matches.sort((a, b) {
    final length = (b.end - b.start).compareTo(a.end - a.start);
    return length != 0 ? length : a.start.compareTo(b.start);
  });
  final selected = <_NameMatch>[];
  for (final m in matches) {
    if (!selected.any((s) => m.start < s.end && m.end > s.start)) {
      selected.add(m);
    }
  }
  if (selected.isEmpty && filters.personIds.isEmpty) {
    return PeopleQuery(query: query, filters: filters);
  }
  final ids = {...filters.personIds};
  final named = <String, String>{};
  final ambiguous = <String, List<NamedPerson>>{};
  for (final m in selected) {
    final choice = m.people.where((p) => p.id == choices[m.alias]).firstOrNull;
    final person = choice ?? (m.people.length == 1 ? m.people.single : null);
    if (person == null) {
      ambiguous[m.alias] = m.people;
    } else {
      ids.add(person.id);
      named[m.alias] = person.id;
    }
  }
  selected.sort((a, b) => b.start.compareTo(a.start));
  var remaining = query;
  for (final match in selected) {
    if (named.containsKey(match.alias)) {
      var start = match.start;
      // Remove relationship wording only when it immediately qualifies a saved name.
      final relationship = RegExp(
        r'\b(?:(?:my|our|his|her|their|your|a|the)\s+)?(?:friend|brother|sister|mother|father|mom|mum|dad|wife|husband|partner|cousin)\s+$',
        caseSensitive: false,
      ).firstMatch(remaining.substring(0, start));
      if (relationship != null &&
          !selected.any(
            (other) =>
                other.start < match.start && other.end > relationship.start,
          )) {
        start = relationship.start;
      }
      remaining = remaining.replaceRange(start, match.end, ' ');
    }
  }
  DateTime? from = filters.from, until = filters.until;
  final clock = now ?? DateTime.now();
  final years = RegExp(
    r'\b(?:(?:in|from|during)\s+)?((?:19|20)\d{2})\b|\b(this year|last year)\b',
    caseSensitive: false,
  );
  final dates = years.allMatches(remaining).toList();
  if (dates.length == 1) {
    final match = dates.single;
    final year = match.group(1) != null
        ? int.parse(match.group(1)!)
        : clock.year - (match.group(2)!.toLowerCase() == 'last year' ? 1 : 0);
    from = DateTime(year);
    until = DateTime(year + 1);
    remaining = remaining.replaceRange(match.start, match.end, ' ');
  }
  remaining = remaining.replaceAll(RegExp(r'\s+'), ' ').trim();
  remaining = remaining
      .replaceFirst(
        RegExp(
          r'^(?:(?:show|find|get|give)\s+(?:me\s+)?)?(?:(?:all|the|my|some)\s+)?(?:photos?|pictures?|images?)\b\s*(?:(?:of|with)\b)?\s*',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
  remaining = remaining
      .replaceFirst(
        RegExp(
          r'^(?:(?:and|with|at|on|in)\b\s*|[,;&+]\s*)+',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
  remaining = remaining
      .replaceFirst(
        RegExp(
          r'(?:\s*\b(?:and|with|at|on|in)|\s*[,;&+])+$',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
  return PeopleQuery(
    query: remaining,
    filters: SearchFilters(
      from: from,
      until: until,
      album: filters.album,
      place: filters.place,
      personIds: ids,
    ),
    matched: named,
    ambiguous: ambiguous,
  );
}
