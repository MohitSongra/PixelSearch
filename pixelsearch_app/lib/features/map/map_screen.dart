import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/location_repository.dart';
import '../../data/enhancements/map_tile_client.dart';
import '../../data/enhancements/online_policy.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../widgets/photo_grid.dart';
import '../settings/online_settings.dart';

final locationRepositoryProvider = Provider((ref) {
  final repo = LocationRepository(ref.watch(appDatabaseProvider));
  ref.onDispose(repo.cancel);
  return repo;
});
final locatedPhotosProvider = FutureProvider((ref) {
  ref.watch(photoLibraryProvider);
  return ref.read(locationRepositoryProvider).located();
});
final locationSummaryProvider = FutureProvider((ref) {
  ref.watch(photoLibraryProvider);
  return ref.read(locationRepositoryProvider).summary();
});
typedef MapTileFactory = TileProvider Function(OnlinePolicy policy);
final mapTileFactoryProvider = Provider<MapTileFactory>(
  (_) =>
      (policy) => _ConsentedTiles(policy),
);

/// Tiles fetched only with consent, and never written to disk: flutter_map's
/// built-in cache (up to 1 GB) would outlive a revoked map consent.
class _ConsentedTiles extends NetworkTileProvider {
  _ConsentedTiles(OnlinePolicy policy) : this._(MapTileClient(policy));
  _ConsentedTiles._(this.client)
    : super(
        httpClient: client,
        attemptDecodeOfHttpErrorResponses: false,
        cachingProvider: const DisabledMapCachingProvider(),
      );
  final MapTileClient client;
  @override
  Future<void> dispose() async {
    client.close();
    await super.dispose();
  }
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapState();
}

class _MapState extends ConsumerState<MapScreen> with WidgetsBindingObserver {
  late final LocationRepository _locations;
  bool _scanning = false, _cancelled = false, _foreground = true;
  String? _status;
  @override
  void initState() {
    super.initState();
    _locations = ref.read(locationRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  Future<void> scan({bool retryMissing = false}) async {
    setState(() {
      _scanning = true;
      _cancelled = false;
      _status = 'Reading photo locations';
    });
    try {
      final result = await _locations.scan((done, total) {
        if (mounted) {
          setState(() => _status = '$done / $total locations checked');
        }
      }, retryMissing: retryMissing);
      if (mounted) {
        setState(
          () => _status = _cancelled || result.cancelled
              ? 'Location check paused'
              : 'Checked ${result.total}: ${result.located} located, '
                    '${result.missing} GPS not found, ${result.inaccessible} inaccessible, '
                    '${result.failures} unreadable',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error is StateError
              ? error.message
              : 'Could not read photo locations. Check photo and photo-location permissions.',
        );
      }
    } finally {
      if (mounted) {
        ref.invalidate(locatedPhotosProvider);
        ref.invalidate(locationSummaryProvider);
        setState(() => _scanning = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locations.cancel();
    super.dispose();
  }

  void openPhotos(List<Photo> photos, String title) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: PhotoGrid(photos: photos),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(onlinePolicyProvider);
    final photos = {for (final p in ref.watch(photoLibraryProvider)) p.id: p};
    final summary = ref.watch(locationSummaryProvider).valueOrNull;
    final active = _foreground && TickerMode.valuesOf(context).enabled;
    void privacy() => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Online privacy')),
          body: const SingleChildScrollView(child: OnlineSettings()),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: _scanning
                ? 'Cancel location scan'
                : 'Read photo locations',
            icon: Icon(_scanning ? Icons.close : Icons.location_searching),
            onPressed: _scanning
                ? () {
                    _cancelled = true;
                    _locations.cancel();
                  }
                : () => scan(),
          ),
          PopupMenuButton<String>(
            tooltip: 'Location options',
            onSelected: (value) {
              if (value == 'retry') scan(retryMissing: true);
              if (value == 'privacy') privacy();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'retry',
                enabled: !_scanning,
                child: const Text('Retry photos without GPS'),
              ),
              const PopupMenuItem(value: 'privacy', child: Text('Map privacy')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (MediaQuery.textScalerOf(context).scale(16) <= 24 &&
              MediaQuery.sizeOf(context).height > 600)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Every place, a memory.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explore the locations recorded in your photos.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_scanning) const LinearProgressIndicator(),
          if (_status != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_status!)),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${summary.located} located · ${summary.unchecked} unchecked',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ref
                .watch(locatedPhotosProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text('Locations unavailable')),
                  data: (rows) {
                    final locations = {
                      for (final r in rows)
                        if (photos.containsKey(r.photoId))
                          r.photoId: LatLng(r.latitude!, r.longitude!),
                    };
                    final unknown = [
                      for (final p in photos.values)
                        if (!locations.containsKey(p.id)) p,
                    ]..sort((a, b) => b.date.compareTo(a.date));
                    return Column(
                      children: [
                        if (unknown.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.location_off_outlined),
                              label: Text(
                                '${unknown.length} photos without a verified location',
                              ),
                              onPressed: () =>
                                  openPhotos(unknown, 'Without a location'),
                            ),
                          ),
                        if (locations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: Text(
                              'No recorded photo locations. No photo pins are placed.',
                            ),
                          ),
                        Expanded(
                          child: !policy.allows(OnlineFeature.maps)
                              ? ListView(
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    const SizedBox(height: 16),
                                    Icon(
                                      Icons.explore_outlined,
                                      size: 56,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Online map tiles are off',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Your photo locations stay on this device. To see the map, allow OpenStreetMap to load map areas. No photos are sent.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: FilledButton.tonalIcon(
                                        onPressed: privacy,
                                        icon: const Icon(Icons.shield_outlined),
                                        label: const Text('Map privacy'),
                                      ),
                                    ),
                                    if (locations.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          for (final id in locations.keys.take(
                                            3,
                                          ))
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: InkWell(
                                                    onTap: () => openPhotos([
                                                      photos[id]!,
                                                    ], 'Located photos'),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image(
                                                        image:
                                                            photos[id]!.image,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => openPhotos([
                                          for (final id in locations.keys)
                                            photos[id]!,
                                        ], 'Located photos'),
                                        child: const Text(
                                          'Browse located photos',
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : !active
                              ? const SizedBox.shrink()
                              : _PhotoMap(
                                  policy: policy,
                                  tileFactory: ref.read(mapTileFactoryProvider),
                                  locations: locations,
                                  photos: photos,
                                  open: (ids) => openPhotos([
                                    for (final id in ids) photos[id]!,
                                  ], '${ids.length} located photos'),
                                ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _PhotoMap extends StatefulWidget {
  const _PhotoMap({
    required this.policy,
    required this.tileFactory,
    required this.locations,
    required this.photos,
    required this.open,
  });
  final OnlinePolicy policy;
  final MapTileFactory tileFactory;
  final Map<String, LatLng> locations;
  final Map<String, Photo> photos;
  final void Function(List<String>) open;
  @override
  State<_PhotoMap> createState() => _PhotoMapState();
}

class _PhotoMapState extends State<_PhotoMap> {
  final _controller = MapController();
  late TileProvider _tiles;
  LatLngBounds? _bounds;
  bool _tileError = false, _errorScheduled = false;
  int _attempt = 0;
  @override
  void initState() {
    super.initState();
    _tiles = widget.tileFactory(widget.policy);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose(); // TileLayer owns provider disposal.
  }

  @override
  Widget build(BuildContext context) {
    final markers = [
      for (final entry in widget.locations.entries)
        if (_bounds == null || _bounds!.contains(entry.value))
          Marker(
            key: ValueKey(entry.key),
            point: entry.value,
            width: 60,
            height: 64,
            child: Semantics(
              button: true,
              label: widget.photos[entry.key]!.displayTitle,
              child: GestureDetector(
                onTap: () => widget.open([entry.key]),
                child: _PhotoLocationPin(photo: widget.photos[entry.key]!),
              ),
            ),
          ),
    ];
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            // Neutral world view is a camera position, never an inferred photo pin.
            initialCenter: const LatLng(20, 0),
            initialZoom: 1,
            initialCameraFit: widget.locations.isEmpty
                ? null
                : CameraFit.coordinates(
                    coordinates: widget.locations.values.toList(),
                    padding: const EdgeInsets.all(48),
                    maxZoom: 14,
                  ),
            minZoom: 1,
            maxZoom: 18,
            onPositionChanged: (camera, _) =>
                setState(() => _bounds = camera.visibleBounds),
          ),
          children: [
            TileLayer(
              key: ValueKey(_attempt),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pixelsearch.pixelsearch',
              tileProvider: _tiles,
              maxNativeZoom: 19,
              panBuffer: 0,
              errorTileCallback: (_, _, _) {
                if (_tileError || _errorScheduled || !mounted) return;
                _errorScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _errorScheduled = false;
                  if (mounted) setState(() => _tileError = true);
                });
              },
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                markers: markers,
                maxClusterRadius: 60,
                size: const Size(64, 68),
                zoomToBoundsOnClick: false,
                spiderfyCluster: false,
                onClusterTap: (node) => widget.open([
                  for (final m in node.markers)
                    (m.key as ValueKey<String>).value,
                ]),
                builder: (context, markers) => Semantics(
                  button: true,
                  label: '${markers.length} photos at this place',
                  child: _PhotoLocationPin(
                    photo: widget
                        .photos[(markers.first.key as ValueKey<String>).value]!,
                    count: markers.length,
                  ),
                ),
              ),
            ),
            const MapAttribution(),
          ],
        ),
        if (_tileError)
          Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                title: const Text('Map tiles could not load'),
                trailing: IconButton(
                  tooltip: 'Retry map tiles',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    _tiles = widget.tileFactory(widget.policy);
                    _attempt++;
                    _tileError = false;
                  }),
                ),
              ),
            ),
          ),
        if (widget.locations.isNotEmpty)
          Positioned(
            right: 12,
            bottom: 52,
            child: IconButton.filledTonal(
              tooltip: 'Show all photo locations',
              icon: const Icon(Icons.zoom_out_map),
              onPressed: () => _controller.fitCamera(
                CameraFit.coordinates(
                  coordinates: widget.locations.values.toList(),
                  padding: const EdgeInsets.all(48),
                  maxZoom: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoLocationPin extends StatelessWidget {
  const _PhotoLocationPin({required this.photo, this.count});
  final Photo photo;
  final int? count;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          left: 3,
          right: 3,
          top: 0,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image(
                image: photo.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.photo_outlined, color: scheme.primary),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: count == null
                  ? Icon(Icons.place, size: 16, color: scheme.onPrimary)
                  : Text(
                      '$count',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: () =>
              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Text(
              '\u00a9 OpenStreetMap contributors',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    ),
  );
}
