import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/state/people_providers.dart';
import 'package:pixelsearch/data/search/keyword_search_backend.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/features/search/search_screen.dart';
import 'package:pixelsearch/features/search/indexed_gallery_view.dart';
import 'package:pixelsearch/features/viewer/photo_viewer.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/providers.dart';

class TestLibrary extends PhotoLibrary {
  TestLibrary(super.ref, List<Photo> photos) {
    state = photos;
  }
  @override
  Future<void> refresh() async {}
  void replace(List<Photo> photos) {
    state = photos;
  }
}

List<Photo> fixtures(int count) => List.generate(
  count,
  (i) => Photo(
    id: 'photo-$i',
    title: 'Photo $i',
    caption: '',
    tags: [],
    assetName:
        'assets/samples/${['garden_flowers.jpg', 'dog_park.jpg', 'road_trip.jpg'][i % 3]}',
    date: i < count ~/ 2
        ? DateTime(2026, 9, 9, 12).subtract(Duration(minutes: i))
        : DateTime(2023, 1, 2, 12).subtract(Duration(seconds: i)),
    album: 'Camera',
    source: PhotoSource.sample,
    labels: i.isEven ? ['flower'] : ['dog'],
  ),
);

ProviderContainer scope(List<Photo> photos) => ProviderContainer(
  overrides: [
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    peopleRepositoryProvider.overrideWith((ref) => PeopleRepository(ref.watch(appDatabaseProvider))),
    photoLibraryProvider.overrideWith((ref) => TestLibrary(ref, photos)),
    searchBackendProvider.overrideWith(
      (_) async => const KeywordSearchBackend(),
    ),
    userPreferencesProvider.overrideWithValue(
      UserPreferences(read: () async => null, write: (_) async {}),
    ),
  ],
);

Future<void> mount(
  WidgetTester tester,
  ProviderContainer container, {
  double scale = 1,
  GlobalKey? screenshotKey,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(key: screenshotKey, child: const SearchScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (await font.exists()) {
      await (FontLoader(
        'Roboto',
      )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'main page is a lazy indexed gallery with live suggestions and unchanged query wiring',
    (tester) async {
      final container = scope(fixtures(1916));
      addTearDown(container.dispose);
      await mount(tester, container);
      expect(find.byType(IndexedGalleryView), findsOneWidget);
      expect(find.text('1916 photos indexed'), findsOneWidget);
      expect(find.text('Continue indexing'), findsOneWidget);
      expect(find.text('beach at sunset'), findsNothing);
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-0')),
        findsOneWidget,
      );
      final rendered = find.byWidgetPredicate(
        (w) => w is InkWell && w.key.toString().contains('indexed-photo-'),
      );
      expect(rendered.evaluate().length, lessThan(50));
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-1915')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('library-suggestion-flower')));
      await tester.pumpAndSettle();
      expect(container.read(searchQueryProvider), 'flower');
      expect(find.byType(IndexedGalleryView), findsNothing);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.byType(IndexedGalleryView), findsOneWidget);
      (container.read(photoLibraryProvider.notifier) as TestLibrary).replace([
        fixtures(1).single.withLabels(['car']),
      ]);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('library-suggestion-car')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('library-suggestion-flower')),
        findsNothing,
      );
      expect(find.text('1 photo indexed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month jump, date scrubber, oldest photo viewer and scroll restoration',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = scope(fixtures(120));
      addTearDown(container.dispose);
      await mount(tester, container);
      await tester.tap(find.byKey(const ValueKey('gallery-month-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('January 2023'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-60')),
        findsOneWidget,
      );
      final rail = find.byKey(const ValueKey('gallery-date-scrubber'));
      final bounds = tester.getRect(rail);
      final gesture = await tester.startGesture(
        Offset(bounds.center.dx, bounds.top + 28),
      );
      await gesture.moveTo(Offset(bounds.center.dx, bounds.bottom - 4));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-119')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('indexed-photo-photo-119')));
      await tester.pumpAndSettle();
      final viewer = tester.widget<PhotoViewerScreen>(
        find.byType(PhotoViewerScreen),
      );
      expect(viewer.initialIndex, 119);
      expect(viewer.photos.length, 120);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-119')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('library-suggestion-dog')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('indexed-photo-photo-119')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('gallery-month-picker')),
          matching: find.text('January 2023'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty library shows no invented suggestions or sample photos', (
    tester,
  ) async {
    final container = scope([]);
    addTearDown(container.dispose);
    await mount(tester, container);
    expect(find.text('No indexed photos yet'), findsOneWidget);
    expect(find.text('Index photos'), findsOneWidget);
    expect(find.text('Try searching'), findsNothing);
    expect(find.byType(IndexedGalleryView), findsNothing);
  });

  for (final size in [
    const Size(320, 740),
    const Size(412, 915),
    const Size(1100, 800),
  ]) {
    testWidgets(
      'gallery fits ${size.width}px with accessible text and visible images',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = scope(fixtures(120));
        addTearDown(container.dispose);
        final key = GlobalKey();
        await mount(
          tester,
          container,
          scale: size.width == 320 ? 2 : 1,
          screenshotKey: key,
        );
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = await Directory(
            'build/gallery_screenshots',
          ).create(recursive: true);
          await File(
            '${directory.path}/gallery_${size.width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(
          find.byKey(const ValueKey('indexed-photo-photo-0')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
