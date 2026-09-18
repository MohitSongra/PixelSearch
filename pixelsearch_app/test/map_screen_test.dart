import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/location_repository.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/features/map/map_screen.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/providers.dart';
import 'package:pixelsearch/widgets/photo_grid.dart';

class _Library extends PhotoLibrary {
  _Library(super.ref, List<Photo> photos) {
    state = photos;
  }
  @override
  Future<void> refresh() async {}
}

class _Tiles extends TileProvider {
  int disposed = 0;
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/samples/garden_flowers.jpg');
  @override
  Future<void> dispose() async {
    disposed++;
  }
}

void main() {
  final photos = List.generate(
    2,
    (i) => Photo(
      id: '$i',
      title: 'Photo $i',
      caption: '',
      tags: [],
      assetName: 'assets/samples/garden_flowers.jpg',
      date: DateTime(2024, 1, i + 1),
      album: 'Fixture',
      source: PhotoSource.sample,
    ),
  );
  final rows = [
    for (final p in photos)
      PhotoLocation(
        photoId: p.id,
        revision: 0,
        latitude: 18,
        longitude: 73,
        status: 'located',
        provenance: 'fixture',
      ),
  ];

  Future<
    ({ProviderContainer container, OnlinePolicy policy, List<_Tiles> tiles})
  >
  mount(
    WidgetTester tester, {
    bool allowed = true,
    bool located = false,
    double width = 412,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    final prefs = UserPreferences(read: () async => null, write: (_) async {});
    final policy = OnlinePolicy(prefs);
    await policy.load();
    if (allowed) {
      await policy.update(
        offline: false,
        feature: OnlineFeature.maps,
        allow: true,
      );
    }
    final tiles = <_Tiles>[];
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userPreferencesProvider.overrideWithValue(prefs),
        onlinePolicyProvider.overrideWith((_) => policy),
        photoLibraryProvider.overrideWith((ref) => _Library(ref, photos)),
        locatedPhotosProvider.overrideWith((_) async => located ? rows : []),
        locationSummaryProvider.overrideWith(
          (_) async => LocationSummary(
            total: 2,
            located: located ? 2 : 0,
            missing: located ? 0 : 2,
            unchecked: 0,
          ),
        ),
        mapTileFactoryProvider.overrideWithValue((_) {
          final tile = _Tiles();
          tiles.add(tile);
          return tile;
        }),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container: container, policy: policy, tiles: tiles);
  }

  testWidgets('consented map renders without GPS and invents no photo pins', (
    tester,
  ) async {
    final fixture = await mount(tester);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.text('No recorded photo locations. No photo pins are placed.'),
      findsOneWidget,
    );
    final layer = tester.widget<MarkerClusterLayerWidget>(
      find.byType(MarkerClusterLayerWidget),
    );
    expect(layer.options.markers, isEmpty);
    expect(fixture.tiles.length, 1);
    await tester.drag(find.byType(FlutterMap), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(
      fixture.tiles.length,
      1,
      reason: 'Panning must retain one HTTP provider',
    );
    expect(find.text('\u00a9 OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.text('2 photos without a verified location'));
    await tester.pumpAndSettle();
    expect(tester.widget<PhotoGrid>(find.byType(PhotoGrid)).photos.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled map creates no tile provider; revocation disposes it', (
    tester,
  ) async {
    final fixture = await mount(tester, allowed: false);
    expect(find.byType(FlutterMap), findsNothing);
    expect(fixture.tiles, isEmpty);
    await fixture.policy.update(
      offline: false,
      feature: OnlineFeature.maps,
      allow: true,
    );
    await tester.pumpAndSettle();
    expect(fixture.tiles.length, 1);
    await fixture.policy.update(offline: true);
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsNothing);
    expect(fixture.tiles.single.disposed, 1);
  });

  testWidgets(
    'real location records become cluster photos, not unknown photos',
    (tester) async {
      await mount(tester, located: true);
      final layer = tester.widget<MarkerClusterLayerWidget>(
        find.byType(MarkerClusterLayerWidget),
      );
      expect(layer.options.markers.length, 2);
      expect(find.text('2 photos without a verified location'), findsNothing);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('2 located photos'), findsOneWidget);
      expect(
        tester
            .widget<PhotoGrid>(find.byType(PhotoGrid))
            .photos
            .map((p) => p.id),
        ['0', '1'],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('backgrounding removes tile requests until foreground', (
    tester,
  ) async {
    final fixture = await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsNothing);
    expect(fixture.tiles.single.disposed, 1);
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(fixture.tiles.length, 2);
  });

  testWidgets('GPS status and attribution fit 320px at double text size', (
    tester,
  ) async {
    await mount(tester, width: 320, textScale: 2);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('\u00a9 OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
