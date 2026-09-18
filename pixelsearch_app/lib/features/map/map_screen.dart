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

class _ConsentedTiles extends NetworkTileProvider {
  _ConsentedTiles(OnlinePolicy policy) : this._(MapTileClient(policy));
  _ConsentedTiles._(this.client)
    : super(httpClient: client, attemptDecodeOfHttpErrorResponses: false);
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
          if (_scanning) const LinearProgressIndicator(),
          if (_status != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_status!)),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${summary.located} located | ${summary.missing} GPS not found | ${summary.unchecked} unchecked',
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
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map_outlined, size: 48),
                                      const SizedBox(height: 12),
                                      const Text('Online map tiles are off'),
                                      TextButton(
                                        onPressed: privacy,
                                        child: const Text('Map privacy'),
                                      ),
                                      if (locations.isNotEmpty)
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
                                  ),
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
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: widget.photos[entry.key]!.displayTitle,
              icon: const Icon(Icons.location_on),
              onPressed: () => widget.open([entry.key]),
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
                size: const Size(44, 44),
                zoomToBoundsOnClick: false,
                spiderfyCluster: false,
                onClusterTap: (node) => widget.open([
                  for (final m in node.markers)
                    (m.key as ValueKey<String>).value,
                ]),
                builder: (context, markers) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${markers.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
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
