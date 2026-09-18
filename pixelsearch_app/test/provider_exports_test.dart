import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/state/providers.dart' as public;
import 'package:pixelsearch/state/indexing_providers.dart' as indexing;
import 'package:pixelsearch/state/library_providers.dart' as gallery;
import 'package:pixelsearch/state/online_providers.dart' as online;
import 'package:pixelsearch/state/preferences_providers.dart' as preferences;
import 'package:pixelsearch/state/query_providers.dart' as query;
import 'package:pixelsearch/state/search_providers.dart' as search;
import 'package:pixelsearch/state/storage_providers.dart' as storage;

void main() {
  test('public exports preserve provider identity and existing overrides', () {
    final pairs = [
      (public.appDatabaseProvider, storage.appDatabaseProvider),
      (public.photoRepositoryProvider, storage.photoRepositoryProvider),
      (public.userPreferencesProvider, preferences.userPreferencesProvider),
      (public.skipOnboardingProvider, preferences.skipOnboardingProvider),
      (public.onlinePolicyProvider, online.onlinePolicyProvider),
      (public.enhancementClientProvider, online.enhancementClientProvider),
      (public.photoLibraryProvider, gallery.photoLibraryProvider),
      (public.searchQueryProvider, query.searchQueryProvider),
      (public.searchFiltersProvider, query.searchFiltersProvider),
      (public.debouncedQueryProvider, query.debouncedQueryProvider),
      (public.indexingControllerProvider, indexing.indexingControllerProvider),
      (public.indexWarmupProvider, search.indexWarmupProvider),
      (public.searchResponseProvider, search.searchResponseProvider),
      (public.searchResultsProvider, search.searchResultsProvider),
    ];
    for (final (exported, owner) in pairs) {
      expect(identical(exported, owner), isTrue);
    }
  });
}
