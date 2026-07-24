import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_gallery.dart';
import '../data/sample_data.dart';
import '../data/search_engine.dart';
import '../models/photo.dart';

/// Light/dark/system theme selection.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// "Privacy mode" master switch (mock): when on, all cloud features are off.
final privacyModeProvider = StateProvider<bool>((ref) => true);

/// The current search text.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Whether device photos have been loaded (for UI state).
final deviceLoadedProvider = StateProvider<bool>((ref) => false);

/// The photo library = bundled samples, optionally merged with device photos.
class PhotoLibrary extends StateNotifier<List<Photo>> {
  PhotoLibrary(this.ref) : super(samplePhotos);

  final Ref ref;
  bool _loadingDevice = false;

  bool get deviceSupported => DeviceGallery.isSupported;

  /// Loads real device photos (mobile only) and merges them in, newest first.
  /// Returns the number of device photos added.
  Future<int> loadDevicePhotos() async {
    if (_loadingDevice) return 0;
    _loadingDevice = true;
    try {
      final device = await DeviceGallery.load(limit: 80);
      if (device.isNotEmpty) {
        final merged = [...device, ...samplePhotos]
          ..sort((a, b) => b.date.compareTo(a.date));
        state = merged;
        ref.read(deviceLoadedProvider.notifier).state = true;
      }
      return device.length;
    } finally {
      _loadingDevice = false;
    }
  }
}

final photoLibraryProvider =
    StateNotifierProvider<PhotoLibrary, List<Photo>>((ref) => PhotoLibrary(ref));

/// Ranked search results derived from the library + current query.
final searchResultsProvider = Provider<List<Photo>>((ref) {
  final all = ref.watch(photoLibraryProvider);
  final query = ref.watch(searchQueryProvider);
  return searchPhotos(all, query);
});
