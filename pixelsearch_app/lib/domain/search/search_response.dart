import '../../models/photo.dart';

class SearchFilters {
  const SearchFilters({this.from, this.until, this.album, this.place, this.personIds = const {}});
  final DateTime? from;
  final DateTime? until;
  final String? album;
  final String? place;
  final Set<String> personIds;
  bool get isEmpty =>
      from == null && until == null && album == null && place == null && personIds.isEmpty;
  bool allows(Photo p) =>
      (from == null || !p.date.isBefore(from!)) &&
      (until == null || p.date.isBefore(until!)) &&
      (album == null || p.album == album) &&
      (place == null || p.place == place);
  Map<String, Object?> toJson() => {
    if (from != null) 'from': from!.toIso8601String(),
    if (until != null) 'until': until!.toIso8601String(),
    if (album != null) 'album': album,
    if (place != null) 'place': place,
    if (personIds.isNotEmpty) 'person_ids': personIds.toList()..sort(),
  };
}

class SearchRequest {
  const SearchRequest(this.query, {this.filters = const SearchFilters(), this.eligiblePhotoIds});
  final String query;
  final SearchFilters filters;
  final Set<String>? eligiblePhotoIds;
  bool get constrained => !filters.isEmpty || eligiblePhotoIds != null;
  List<Photo> filterCorpus(List<Photo> corpus) {
    if (filters.personIds.isNotEmpty && eligiblePhotoIds == null) {
      throw StateError('Person filters must be resolved locally before searching.');
    }
    return corpus.where((p) => filters.allows(p) &&
      (eligiblePhotoIds == null || eligiblePhotoIds!.contains(p.id))).toList();
  }
}

class SearchResponse {
  const SearchResponse({
    required this.request,
    required this.photos,
    required this.mode,
    this.explanations = const {},
  });
  final SearchRequest request;
  final List<Photo> photos;
  final String mode;
  final Map<String, Map<String, Object?>> explanations;
}
