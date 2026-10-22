import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/indexing_preferences_repository.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/features/indexing/folder_picker.dart';
import 'package:pixelsearch/indexing/model/folder_selection.dart';
import 'package:pixelsearch/state/providers.dart';

const catalog = FolderCatalog([
  GalleryFolder(id: 'camera', name: 'Camera', count: 1101),
  GalleryFolder(id: 'trip', name: 'Trips', count: 12),
]);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> mount(
    WidgetTester tester, {
    FolderCatalog folders = catalog,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          indexFoldersProvider.overrideWith((ref) async => folders),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FolderPickerScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty selection disabled; checkbox count; confirmation persists',
    (tester) async {
      await mount(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      expect(find.text('12 photos in 1 folder'), findsOneWidget);
      await tester.tap(find.text('Index selected folders'));
      await tester.pumpAndSettle();
      expect((await IndexingPreferencesRepository(db).load()).folderIds, {
        'trip',
      });
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets('saved choice restored; cancelling edits preserves it', (
    tester,
  ) async {
    await IndexingPreferencesRepository(
      db,
    ).save(FolderSelection(folderIds: {'trip'}));
    await mount(tester);
    expect(
      tester.widget<CheckboxListTile>(find.byKey(const ValueKey('trip'))).value,
      isTrue,
    );
    await tester.tap(find.text('Camera'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect((await IndexingPreferencesRepository(db).load()).folderIds, {
      'trip',
    });
  });

  testWidgets('all folders can be narrowed by unchecking a folder', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('All folders'));
    await tester.pumpAndSettle();
    expect(find.text('1113 photos in 2 folders'), findsOneWidget);
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.text('12 photos in 1 folder'), findsOneWidget);
  });

  testWidgets('limited access and missing saved folder are explicit', (
    tester,
  ) async {
    await IndexingPreferencesRepository(
      db,
    ).save(FolderSelection(folderIds: {'gone'}));
    await mount(tester, folders: FolderCatalog(catalog.folders, limited: true));
    expect(find.text('Limited photo access'), findsOneWidget);
    expect(find.text('Unavailable folder'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('narrow screen with large text has no layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(
      tester,
      folders: const FolderCatalog([
        GalleryFolder(
          id: 'long',
          name: 'A very long camera folder name for testing wrapping',
          count: 19000,
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('long')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
