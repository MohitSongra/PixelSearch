/// Photos that satisfy a person constraint, computed from assigned faces only.
///
/// Result = (photos of every [required] person) ∩ (photos of any [anyOf]
/// person) − (photos of any [excluded] person), restricted to [universe] when
/// given. Unknown person ids contribute no photos, so they fail closed.
Set<String> matchPeoplePhotos(
  Map<String, Set<String>> photosByPerson, {
  Set<String> required = const {},
  Set<String> anyOf = const {},
  Set<String> excluded = const {},
  Set<String>? universe,
}) {
  if (required.isEmpty && anyOf.isEmpty && excluded.isEmpty) {
    throw ArgumentError('Person selection is empty.');
  }
  Set<String>? result;
  for (final id in required) {
    final photos = photosByPerson[id] ?? const <String>{};
    result = result == null ? {...photos} : result.intersection(photos);
  }
  if (anyOf.isNotEmpty) {
    final union = {for (final id in anyOf) ...?photosByPerson[id]};
    result = result == null ? union : result.intersection(union);
  }
  if (result == null) {
    if (universe == null) {
      throw ArgumentError('Excluding people needs the photos to search.');
    }
    result = {...universe};
  } else if (universe != null) {
    result = result.intersection(universe);
  }
  for (final id in excluded) {
    result.removeAll(photosByPerson[id] ?? const <String>{});
  }
  return result;
}
