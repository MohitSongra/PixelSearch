import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/gallery/indexed_gallery.dart';
import '../domain/search/library_suggestions.dart';
import '../models/photo.dart';
import 'preferences_providers.dart';
import 'storage_providers.dart';

/// Whether this platform can index a device gallery at all. Web has no gallery,
/// no ML Kit and no local database, so its UI hides the indexing controls.
bool get indexingSupported => !kIsWeb;

/// The photo library: everything the M5 indexer has persisted, newest first.
///
/// This is a *view* of the database — the only writer is the indexing pipeline
/// (via the indexing controller), which calls [refresh] when a run finishes.
class PhotoLibrary extends StateNotifier<List<Photo>> {
  PhotoLibrary(this._ref) : super(const <Photo>[]) {
    refresh();
  }

  final Ref _ref;

  /// Re-reads the indexed photos from the store. Never throws: on web (and in
  /// unit tests) there is no database, and an unreadable store should leave the
  /// UI empty rather than take the app down.
  Future<void> refresh() async {
    if (!indexingSupported) return;
    try {
      final photos = await _ref.read(photoRepositoryProvider).loadPhotos();
      final preferences = _ref.read(userPreferencesProvider);
      await preferences.load();
      if (mounted) {
        state = photos.map(preferences.applyLabelCorrection).toList();
      }
    } catch (_) {
      // No store on this platform / not opened yet → stay empty.
    }
  }
}

final photoLibraryProvider = StateNotifierProvider<PhotoLibrary, List<Photo>>(
  (ref) => PhotoLibrary(ref),
);

final indexedGalleryProvider = Provider(
  (ref) => IndexedGallery(ref.watch(photoLibraryProvider)),
);
final librarySuggestionsProvider = Provider(
  (ref) => librarySuggestions(ref.watch(photoLibraryProvider)),
);
