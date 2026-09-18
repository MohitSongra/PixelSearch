import '../../models/photo.dart';
import 'search_response.dart';

SearchRequest parseAssistantResult(
  Map<String, dynamic> json,
  List<Photo> photos,
) {
  final query = json['query'];
  final filters = json['filters'];
  if (json['clarification'] is String &&
      (json['clarification'] as String).isNotEmpty) {
    throw StateError(json['clarification'] as String);
  }
  if (query is! String ||
      query.length > 2000 ||
      filters is! Map ||
      filters.keys.any(
        (k) => !['from', 'until', 'album', 'place'].contains(k),
      )) {
    throw const FormatException('Invalid search refinement.');
  }
  DateTime? date(String key) {
    final value = filters[key];
    if (value == null) return null;
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid date filter.');
    }
    final parsed = DateTime.parse(value);
    if (parsed.toIso8601String().substring(0, 10) != value) {
      throw const FormatException('Invalid date filter.');
    }
    return parsed;
  }

  String? resolve(String key, Iterable<String> values) {
    final value = filters[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const FormatException('Invalid filter.');
    }
    final matches = values
        .toSet()
        .where((v) => v.toLowerCase() == value.toLowerCase())
        .toList();
    if (matches.length != 1) {
      throw StateError('Choose an indexed $key matching "$value".');
    }
    return matches.single;
  }

  final from = date('from'), until = date('until');
  if (from != null && until != null && !until.isAfter(from)) {
    throw const FormatException('Invalid date range.');
  }
  return SearchRequest(
    query,
    filters: SearchFilters(
      from: from,
      until: until,
      album: resolve('album', photos.map((p) => p.album)),
      place: resolve('place', photos.map((p) => p.place).whereType<String>()),
    ),
  );
}
