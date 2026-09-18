import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/search/search_response.dart';

/// The current search text.
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFiltersProvider = StateProvider<SearchFilters>(
  (ref) => const SearchFilters(),
);

/// Debounced mirror of [searchQueryProvider]: a non-empty query is delayed
/// ~300 ms so we embed once the user pauses, not on every keystroke. Because
/// this is autoDispose, a superseding keystroke cancels the pending delay.
final debouncedQueryProvider = FutureProvider.autoDispose<String>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return '';
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return q;
});
