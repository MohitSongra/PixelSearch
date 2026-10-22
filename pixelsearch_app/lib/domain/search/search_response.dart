import '../../models/photo.dart';

class SearchFilters {
  const SearchFilters({
    this.from,
    this.until,
    this.album,
    this.place,
    this.personIds = const {},
    this.anyPersonIds = const {},
    this.excludedPersonIds = const {},
  });
  final DateTime? from;
  final DateTime? until;
  final String? album;
  final String? place;

  /// Every person must appear (AND).
  final Set<String> personIds;

  /// At least one of these people must appear (OR).
  final Set<String> anyPersonIds;

  /// None of these people may appear (by assigned faces only).
  final Set<String> excludedPersonIds;

  bool get hasPeople =>
      personIds.isNotEmpty ||
      anyPersonIds.isNotEmpty ||
      excludedPersonIds.isNotEmpty;
  bool get isEmpty =>
      from == null && until == null && album == null && place == null && !hasPeople;
  bool allows(Photo p) =>
      (from == null || !p.date.isBefore(from!)) &&
      (until == null || p.date.isBefore(until!)) &&
      (album == null || p.album == album) &&
      (place == null || p.place == place);

  SearchFilters withPeople({
    Set<String> required = const {},
    Set<String> any = const {},
    Set<String> excluded = const {},
  }) => SearchFilters(
    from: from,
    until: until,
    album: album,
    place: place,
    personIds: required,
    anyPersonIds: any,
    excludedPersonIds: excluded,
  );
  SearchFilters withoutPeople() => withPeople();
  SearchFilters withDate(DateTime? from, DateTime? until) => SearchFilters(
    from: from,
    until: until,
    album: album,
    place: place,
    personIds: personIds,
    anyPersonIds: anyPersonIds,
    excludedPersonIds: excludedPersonIds,
  );
  SearchFilters withAlbum(String? album) => SearchFilters(
    from: from,
    until: until,
    album: album,
    place: place,
    personIds: personIds,
    anyPersonIds: anyPersonIds,
    excludedPersonIds: excludedPersonIds,
  );
  SearchFilters withPlace(String? place) => SearchFilters(
    from: from,
    until: until,
    album: album,
    place: place,
    personIds: personIds,
    anyPersonIds: anyPersonIds,
    excludedPersonIds: excludedPersonIds,
  );

  /// Person ids are local identifiers; pass `includePeople: false` for any
  /// payload that may leave the device.
  Map<String, Object?> toJson({bool includePeople = true}) => {
    if (from != null) 'from': from!.toIso8601String(),
    if (until != null) 'until': until!.toIso8601String(),
    if (album != null) 'album': album,
    if (place != null) 'place': place,
    if (includePeople && personIds.isNotEmpty) 'person_ids': personIds.toList()..sort(),
    if (includePeople && anyPersonIds.isNotEmpty)
      'any_person_ids': anyPersonIds.toList()..sort(),
    if (includePeople && excludedPersonIds.isNotEmpty)
      'excluded_person_ids': excludedPersonIds.toList()..sort(),
  };
}

class SearchRequest {
  const SearchRequest(this.query, {this.filters = const SearchFilters(), this.eligiblePhotoIds});
  final String query;
  final SearchFilters filters;
  final Set<String>? eligiblePhotoIds;
  bool get constrained => !filters.isEmpty || eligiblePhotoIds != null;
  List<Photo> filterCorpus(List<Photo> corpus) {
    if (filters.hasPeople && eligiblePhotoIds == null) {
      throw StateError('Person filters must be resolved locally before searching.');
    }
    return corpus.where((p) => filters.allows(p) &&
      (eligiblePhotoIds == null || eligiblePhotoIds!.contains(p.id))).toList();
  }
}

/// Local-only facts about a person-filtered search, used to explain empty
/// results. Never serialized or sent online.
class PersonFilterSummary {
  const PersonFilterSummary({
    required this.peopleEnabled,
    this.labels = const {},
    this.photoCounts = const {},
    this.together = 0,
    this.eligible = 0,
    this.inFilters = 0,
  });
  final bool peopleEnabled;

  /// Person id → display label.
  final Map<String, String> labels;

  /// Person id → number of library photos with a face assigned to them.
  final Map<String, int> photoCounts;

  /// Photos satisfying the required/any-of people, before exclusions.
  final int together;

  /// Photos satisfying every person constraint.
  final int eligible;

  /// Eligible photos that also pass the date/album/place filters.
  final int inFilters;
}

class SearchResponse {
  const SearchResponse({
    required this.request,
    required this.photos,
    required this.mode,
    this.explanations = const {},
    this.people,
  });
  final SearchRequest request;
  final List<Photo> photos;
  final String mode;
  final Map<String, Map<String, Object?>> explanations;
  final PersonFilterSummary? people;
}
