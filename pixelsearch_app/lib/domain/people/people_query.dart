import '../search/query_text.dart';
import '../search/search_response.dart';

/// Aliases that mark the person who is the device owner ("This is me").
const selfAliases = {'me', 'myself'};
bool isSelfAlias(String alias) =>
    selfAliases.contains(alias.trim().toLowerCase());

/// The single directory key both self words resolve through.
const selfKey = 'me';

class NamedPerson {
  const NamedPerson(this.id, this.name, {this.aliases = const []});
  final String id, name;
  final List<String> aliases;
}

enum PersonRole { required, any, excluded }

/// One person reference in the query text, in query order.
class PersonMention {
  const PersonMention({
    required this.key,
    required this.text,
    required this.role,
    this.personId,
    this.label,
    this.isSelf = false,
  });

  /// Normalised directory key ([selfKey] for "me"/"myself").
  final String key;

  /// The words as typed.
  final String text;
  final PersonRole role;

  /// Null while the name is ambiguous or no person is marked "This is me".
  final String? personId;

  /// Display name of the resolved person.
  final String? label;
  final bool isSelf;
}

class PeopleQuery {
  const PeopleQuery({
    required this.query,
    required this.filters,
    this.matched = const {},
    this.ambiguous = const {},
    this.mentions = const [],
    this.selfMissing = false,
  });

  /// Remaining scene text for the image search.
  final String query;
  final SearchFilters filters;

  /// Resolved directory key → person id.
  final Map<String, String> matched;
  final Map<String, List<NamedPerson>> ambiguous;
  final List<PersonMention> mentions;

  /// The query names "me", but nobody is marked "This is me". Search must not
  /// run: the subject is unknown and "me" must not reach the image model.
  final bool selfMissing;
  bool get needsChoice => ambiguous.isNotEmpty;
  bool get hasPeople => filters.hasPeople;
  Set<String> get required => filters.personIds;
  Set<String> get anyOf => filters.anyPersonIds;
  Set<String> get excluded => filters.excludedPersonIds;
}

enum _Kind { name, self, selfMissing, selfIgnored }

class _NameMatch {
  _NameMatch(this.start, this.end, this.key, this.people, this.kind);
  final int start, end;
  final String key;
  final List<NamedPerson> people;
  final _Kind kind;
  late int effectiveStart = start, effectiveEnd = end;
  PersonRole role = PersonRole.required;
  bool get isPerson => kind != _Kind.selfIgnored;
}

const _boundaryBefore = r'(^|[^\p{L}\p{N}\p{M}_])';
const _boundaryAfter = r'(?=$|[^\p{L}\p{N}\p{M}_])';
final _selfWords = RegExp(
  '$_boundaryBefore(me|myself)$_boundaryAfter',
  caseSensitive: false,
  unicode: true,
);
// "show me photos of <name>": the pronoun is the addressee, not a subject.
final _requestVerbBefore = RegExp(
  r'\b(?:show|find|get|give|fetch|bring|send|let|help|tell|remind|display|pull\s+up)\s+$',
  caseSensitive: false,
);
// …unless it is coordinated or placed: "show me and <name>", "show me at the beach".
final _subjectAfterRequest = RegExp(
  r'^\s*(?:$|[,;.!?…&+]|(?:and|or|with|together|at|in|on|during|from)\b)',
  caseSensitive: false,
);
final _nonSubjectBefore = RegExp(
  r'\b(?:near|around|for|by|close\s+to)\s+$',
  caseSensitive: false,
);
final _relationshipBefore = RegExp(
  r'\b(?:(?:my|our|his|her|their|your|a|the)\s+)?(?:friend|brother|sister|mother|father|mom|mum|dad|wife|husband|partner|cousin)\s+$',
  caseSensitive: false,
);
final _possessiveAfter = RegExp(
  "^(?:'s|’s|'|’)(?![\\p{L}\\p{N}])",
  unicode: true,
);
final _exclusionBefore = RegExp(
  r'(?:^|[\s,;])(without|except(?:\s+for)?|excluding|but\s+not|not(?:\s+(?:of|with))?|no|neither|minus|apart\s+from|other\s+than|(?:everyone|everybody|everything|all)\s+but)\s*$',
  caseSensitive: false,
);
final _connectorOnly = RegExp(
  r'^(?:\s|,|&|\+|\band\b|\bor\b|\bnor\b)*$',
  caseSensitive: false,
);
final _orOnly = RegExp(r'^(?:\s|,|\bor\b)*$', caseSensitive: false);
final _hasOr = RegExp(r'\bor\b', caseSensitive: false);
final _requestPrefix = RegExp(
  r'^(?:(?:can|could|would|will)\s+you\s+)?(?:please\s+)?(?:'
  r'(?:show|find|get|give|fetch|bring|display|pull\s+up|search\s+for|look\s+for)\s+(?:me|myself)\b'
  r'|let\s+me\s+(?:see|look\s+at|view)\b'
  r'|help\s+me\s+find\b'
  r'|remind\s+me\s+of\b'
  r'|i\s+(?:want|wanna)\s+(?:to\s+)?see\b'
  r'|(?:show|find|get|give|fetch|bring|display|search\s+for|look\s+for)'
  r'(?=\s+(?:(?:all|the|my|some|any)\s+)?(?:photos?|pictures?|pics?|images?)\b|\s+(?:of|with|and|at|in|on)\b|\s*$)'
  r')\s*',
  caseSensitive: false,
);
final _mediaPrefix = RegExp(
  r'^(?:(?:all|the|my|some|any)\s+)?(?:photos?|pictures?|pics?|images?)(?:\s+(?:of|with|featuring|showing|from)\b|\s*$)\s*',
  caseSensitive: false,
);
final _trailingMedia = RegExp(
  r'(?<![a-z]ing)\s+(?:photos?|pictures?|pics?|images?)$',
  caseSensitive: false,
);
final _nonSubjectSelf = RegExp(
  r'\b(?:near|around|for|by|close\s+to)\s+(?:me|myself)\b',
  caseSensitive: false,
);
const _edgeFillers = {
  'and', 'with', 'at', 'on', 'in', 'of', 'or', 'nor', 'but', 'plus', //
  'together', 'only', 'just', 'both', 'also', 'too', 'please', 'either',
};
const _leftoverOnly = {
  ..._edgeFillers,
  'a', 'an', 'the', 'all', 'some', 'my', 'me', 'myself', 'show', 'find', //
  'photo', 'photos', 'picture', 'pictures', 'pic', 'pics', 'image', 'images',
};

RegExp _namePattern(String key, [Iterable<String> spellings = const []]) {
  String escape(String text) =>
      RegExp.escape(text.trim()).replaceAll(RegExp(r'\s+'), r'\s+');
  // Lower-casing is not reversible for every alphabet, so the saved
  // spellings are matched as well as the lower-cased key.
  final alternatives = {key, ...spellings}.map(escape).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final name = key == selfKey
      ? '(?:me|myself)'
      : '(?:${alternatives.join('|')})';
  return RegExp(
    '$_boundaryBefore($name)$_boundaryAfter',
    caseSensitive: false,
    unicode: true,
  );
}

String _key(String name) {
  final key = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return isSelfAlias(key) ? selfKey : key;
}

bool _selfIsSubject(String query, int start, int end) {
  final before = query.substring(0, start);
  if (_nonSubjectBefore.hasMatch(before)) return false;
  if (_requestVerbBefore.hasMatch(before)) {
    return _subjectAfterRequest.hasMatch(query.substring(end));
  }
  return true;
}

/// Whether [key] (a directory key, or [selfKey]) still occurs in [query].
bool mentionsNameKey(String query, String key) =>
    _namePattern(_key(key)).hasMatch(query);

/// Keeps name choices and dismissed chips only while their names are still in
/// the query, so typing more words does not reset them.
({Map<String, String> choices, Set<String> ignored}) prunePeopleSelections(
  String query,
  Map<String, String> choices,
  Set<String> ignored,
) => (
  choices: {
    for (final e in choices.entries)
      if (mentionsNameKey(query, e.key)) e.key: e.value,
  },
  ignored: {
    for (final key in ignored)
      if (mentionsNameKey(query, key)) key,
  },
);

/// Resolves names, nicknames and "me" against the people saved on this device.
///
/// Names joined by "and"/"with"/"," are all required; names joined only by
/// "or" are alternatives; names after "without"/"except"/"not" are excluded.
/// Mixed wording falls back to requiring everyone (the narrowest reading).
/// A query that mentions nobody is returned unchanged.
PeopleQuery resolvePeopleQuery(
  String query,
  List<NamedPerson> people, {
  SearchFilters filters = const SearchFilters(),
  Map<String, String> choices = const {},
  Set<String> ignoredNames = const {},
  bool detectMissingSelf = false,
  DateTime? now,
}) {
  final ignored = {for (final name in ignoredNames) _key(name)};
  final directory = <String, Map<String, NamedPerson>>{};
  final spellings = <String, Set<String>>{};
  for (final person in people) {
    for (final name in [person.name, ...person.aliases]) {
      final key = _key(name);
      if (key.isNotEmpty && !ignored.contains(key)) {
        directory.putIfAbsent(key, () => {})[person.id] = person;
        spellings.putIfAbsent(key, () => {}).add(name.trim());
      }
    }
  }
  final selfPeople = directory.remove(selfKey)?.values.toList() ?? const [];
  final matches = <_NameMatch>[];
  for (final entry in directory.entries) {
    final pattern = _namePattern(entry.key, spellings[entry.key] ?? const {});
    for (final m in pattern.allMatches(query)) {
      final start = m.start + m.group(1)!.length;
      matches.add(
        _NameMatch(
          start,
          m.end,
          entry.key,
          entry.value.values.toList(),
          _Kind.name,
        ),
      );
    }
  }
  final selfKind = ignored.contains(selfKey)
      ? _Kind.selfIgnored
      : selfPeople.isNotEmpty
      ? _Kind.self
      : detectMissingSelf
      ? _Kind.selfMissing
      : null;
  if (selfKind != null) {
    for (final m in _selfWords.allMatches(query)) {
      final start = m.start + m.group(1)!.length;
      if (_selfIsSubject(query, start, m.end)) {
        matches.add(_NameMatch(start, m.end, selfKey, selfPeople, selfKind));
      }
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
  selected.sort((a, b) => a.start.compareTo(b.start));
  final persons = selected.where((m) => m.isPerson).toList();
  final ignoredSelf = selected.where((m) => m.kind == _Kind.selfIgnored);
  if (persons.isEmpty && !filters.hasPeople && ignoredSelf.isEmpty) {
    return PeopleQuery(query: query, filters: filters);
  }

  // Spans: relationship wording before a saved name, a possessive after it.
  for (var i = 0; i < selected.length; i++) {
    final m = selected[i];
    final previousEnd = i == 0 ? 0 : selected[i - 1].end;
    if (m.kind == _Kind.name) {
      final relationship = _relationshipBefore.firstMatch(
        query.substring(0, m.start),
      );
      if (relationship != null && relationship.start >= previousEnd) {
        m.effectiveStart = relationship.start;
      }
    }
    final possessive = _possessiveAfter.firstMatch(query.substring(m.end));
    if (possessive != null) m.effectiveEnd = m.end + possessive.end;
  }

  // Roles from the words between consecutive person mentions.
  final removals = <(int, int)>[];
  _NameMatch? previous;
  for (final m in persons) {
    final gapStart = previous?.effectiveEnd ?? 0;
    final gap = query.substring(gapStart, m.effectiveStart);
    final marker = _exclusionBefore.firstMatch(gap);
    if (marker != null) {
      m.role = PersonRole.excluded;
      final word = marker.start + marker.group(0)!.indexOf(marker.group(1)!);
      removals.add((gapStart + word, gapStart + gap.length));
    } else if (previous?.role == PersonRole.excluded &&
        _connectorOnly.hasMatch(gap)) {
      m.role = PersonRole.excluded;
    }
    previous = m;
  }
  final included = persons.where((m) => m.role != PersonRole.excluded).toList();
  if (included.length >= 2) {
    var alternatives = true, sawOr = false;
    for (var i = 1; i < included.length; i++) {
      final gap = query.substring(
        included[i - 1].effectiveEnd,
        included[i].effectiveStart,
      );
      final excludedBetween = persons.any(
        (p) =>
            p.role == PersonRole.excluded &&
            p.start > included[i - 1].start &&
            p.start < included[i].start,
      );
      if (excludedBetween || !_orOnly.hasMatch(gap)) alternatives = false;
      if (_hasOr.hasMatch(gap)) sawOr = true;
    }
    if (alternatives && sawOr) {
      for (final m in included) {
        m.role = PersonRole.any;
      }
    }
  }

  // Resolve each mention.
  final required = <String>{}, any = <String>{}, excluded = <String>{};
  final named = <String, String>{};
  final ambiguous = <String, List<NamedPerson>>{};
  final mentions = <PersonMention>[];
  var selfMissing = false;
  for (final m in persons) {
    NamedPerson? person;
    if (m.kind == _Kind.selfMissing) {
      selfMissing = true;
    } else {
      final choice = m.people.where((p) => p.id == choices[m.key]).firstOrNull;
      person = choice ?? (m.people.length == 1 ? m.people.single : null);
      if (person == null) ambiguous[m.key] = m.people;
    }
    if (person != null) {
      named[m.key] = person.id;
      (switch (m.role) {
        PersonRole.required => required,
        PersonRole.any => any,
        PersonRole.excluded => excluded,
      }).add(person.id);
      removals.add((m.effectiveStart, m.effectiveEnd));
    } else if (m.kind == _Kind.selfMissing) {
      removals.add((m.effectiveStart, m.effectiveEnd));
    }
    mentions.add(
      PersonMention(
        key: m.key,
        text: query.substring(m.start, m.end),
        role: m.role,
        personId: person?.id,
        label: person == null || person.name.trim().isEmpty
            ? null
            : person.name.trim(),
        isSelf: m.key == selfKey,
      ),
    );
  }
  // The user chose to search without "me": drop the word and any
  // exclusion wording that applied only to it ("Asha without me").
  for (final m in ignoredSelf) {
    final index = selected.indexOf(m);
    final gapStart = index == 0 ? 0 : selected[index - 1].effectiveEnd;
    final gap = query.substring(gapStart, m.start);
    final marker = _exclusionBefore.firstMatch(gap);
    final from = marker == null
        ? m.start
        : gapStart + marker.start + marker.group(0)!.indexOf(marker.group(1)!);
    removals.add((from, m.end));
  }

  // Merge with filters chosen in the UI.
  required.addAll(filters.personIds);
  excluded.addAll(filters.excludedPersonIds);
  if (any.isNotEmpty && filters.anyPersonIds.isNotEmpty) {
    required
      ..addAll(any)
      ..addAll(filters.anyPersonIds);
    any.clear();
  } else {
    any.addAll(filters.anyPersonIds);
  }
  if (any.length == 1) {
    required.addAll(any);
    any.clear();
  }
  if (any.any(required.contains)) any.clear();
  final finalMentions = [
    for (final m in mentions)
      m.personId == null
          ? m
          : PersonMention(
              key: m.key,
              text: m.text,
              role: required.contains(m.personId)
                  ? PersonRole.required
                  : any.contains(m.personId)
                  ? PersonRole.any
                  : PersonRole.excluded,
              personId: m.personId,
              label: m.label,
              isSelf: m.isSelf,
            ),
  ];

  removals.sort((a, b) => b.$1.compareTo(a.$1));
  var remaining = query;
  var floor = query.length;
  for (final (start, end) in removals) {
    final clipped = end > floor ? floor : end;
    if (clipped <= start) continue;
    remaining = remaining.replaceRange(start, clipped, ' ');
    floor = start;
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
  remaining = _cleanRemainder(remaining);
  return PeopleQuery(
    query: remaining,
    filters: SearchFilters(
      from: from,
      until: until,
      album: filters.album,
      place: filters.place,
      personIds: required,
      anyPersonIds: any,
      excludedPersonIds: excluded,
    ),
    matched: named,
    ambiguous: ambiguous,
    mentions: finalMentions,
    selfMissing: selfMissing,
  );
}

String _cleanRemainder(String text) {
  var remaining = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  remaining = remaining.replaceAll(_nonSubjectSelf, ' ');
  remaining = remaining.replaceAll(RegExp(r'\s+'), ' ').trim();
  remaining = remaining.replaceFirst(_requestPrefix, '').trim();
  remaining = trimQueryEdges(remaining, fillers: _edgeFillers);
  remaining = remaining.replaceFirst(_mediaPrefix, '').trim();
  remaining = trimQueryEdges(remaining, fillers: _edgeFillers);
  final withoutMedia = remaining.replaceFirst(_trailingMedia, '').trim();
  if (withoutMedia.isNotEmpty) remaining = withoutMedia;
  remaining = trimQueryEdges(remaining, fillers: _edgeFillers);
  final tokens = remaining
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map(
        (t) => t.replaceAll(
          RegExp(r"^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$", unicode: true),
          '',
        ),
      )
      .where((t) => t.isNotEmpty);
  if (tokens.every(_leftoverOnly.contains)) return '';
  return remaining;
}
