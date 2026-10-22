import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/core/theme.dart';
import 'package:pixelsearch/features/search/indexed_gallery_view.dart';
import 'package:pixelsearch/features/search/search_screen.dart';
import 'package:pixelsearch/features/settings/settings_screen.dart';
import 'package:pixelsearch/features/viewer/photo_viewer.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/providers.dart';
import 'indexed_gallery_widgets_test.dart' show fixtures, scope;

void main() {
  testWidgets('album filter narrows the query and Back restores the gallery', (
    tester,
  ) async {
    final container = scope([
      ...fixtures(12),
      Photo(
        id: 'shared-flower',
        title: 'A flower',
        caption: '',
        tags: [],
        date: DateTime(2026, 9, 9),
        album: 'Shared',
        source: PhotoSource.sample,
        assetName: 'assets/samples/garden_flowers.jpg',
        labels: ['flower'],
      ),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'flower');
    await tester.pumpAndSettle();
    expect(
      container.read(searchResponseProvider).valueOrNull!.photos,
      hasLength(7),
    );
    await tester.tap(find.text('Album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(container.read(searchFiltersProvider).album, 'Camera');
    expect(
      container.read(searchResponseProvider).valueOrNull!.photos,
      hasLength(6),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(container.read(searchQueryProvider), isEmpty);
    expect(container.read(searchFiltersProvider).isEmpty, isTrue);
    expect(find.byType(IndexedGalleryView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final screen in ['search', 'privacy', 'viewer']) {
      testWidgets(
        '$screen uses the production theme at 320px, double text, dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final photos = fixtures(30);
          final container = scope(photos);
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: switch (screen) {
                  'search' => const SearchScreen(),
                  'privacy' => const SettingsScreen(),
                  _ => PhotoViewerScreen(photos: photos, initialIndex: 0),
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen == 'search') {
            expect(
              find.byKey(const ValueKey('indexed-photo-photo-0')).hitTestable(),
              findsOneWidget,
            );
          }
          if (screen == 'privacy') {
            await tester.scrollUntilVisible(find.text('Appearance'), 400);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.text('About PixelSearch'),
              250,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          if (screen == 'viewer') {
            await tester.tap(find.text('Details'));
            await tester.pumpAndSettle();
            expect(find.text('Photo details'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
