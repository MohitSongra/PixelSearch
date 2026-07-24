import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/photo_grid.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoLibraryProvider);
    final located = photos.where((p) => p.hasLocation).toList();

    // group by place
    final byPlace = <String, List<Photo>>{};
    for (final p in located) {
      byPlace.putIfAbsent(p.place ?? 'Unknown', () => []).add(p);
    }
    final places = byPlace.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: located.isEmpty
          ? const EmptyState(
              icon: Icons.map_outlined,
              title: 'No located photos',
              message: 'Photos with GPS will appear here on a map.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FauxMap(located: located),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Interactive OpenStreetMap view is Milestone 11 — locations shown below.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...places.map((e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(e.key),
                        subtitle: Text('${e.value.length} photos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(e.key)),
                            body: PhotoGrid(photos: e.value),
                          ),
                        )),
                      ),
                    )),
              ],
            ),
    );
  }
}

/// A lightweight decorative "map": dots positioned by normalised lat/lng.
class _FauxMap extends StatelessWidget {
  final List<Photo> located;
  const _FauxMap({required this.located});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lats = located.map((p) => p.lat!).toList();
    final lngs = located.map((p) => p.lng!).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    double nx(double lng) =>
        (maxLng - minLng).abs() < 1e-6 ? 0.5 : (lng - minLng) / (maxLng - minLng);
    double ny(double lat) =>
        (maxLat - minLat).abs() < 1e-6 ? 0.5 : 1 - (lat - minLat) / (maxLat - minLat);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.5),
              scheme.secondaryContainer.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              for (final p in located)
                Positioned(
                  left: nx(p.lng!) * (c.maxWidth - 34) + 4,
                  top: ny(p.lat!) * (c.maxHeight - 34) + 4,
                  child: Icon(Icons.location_on, color: scheme.primary, size: 30),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
