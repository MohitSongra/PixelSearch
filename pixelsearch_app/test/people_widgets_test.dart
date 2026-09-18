import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people/people_service.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/data/search/keyword_search_backend.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/domain/search/search_backend.dart';
import 'package:pixelsearch/domain/search/search_response.dart';
import 'package:pixelsearch/features/search/search_screen.dart';
import 'package:pixelsearch/features/people/people_screen.dart';
import 'package:pixelsearch/features/people/people_review_screen.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/people_providers.dart';
import 'package:pixelsearch/state/providers.dart';

import 'people_repository_test.dart' show addFaces;

class IdlePeople extends PeopleController {
  IdlePeople(super.ref, super.repository, super.service);
  @override
  Future<void> kick() async {}
}

class FixtureLibrary extends PhotoLibrary {
  FixtureLibrary(super.ref) {
    state = [
      for (var i = 0; i < 40; i++)
        Photo(
          id: '$i',
          title: '',
          caption: '',
          tags: [],
          date: DateTime(2024, 1, 1 + i),
          album: 'Camera',
          source: PhotoSource.sample,
          assetName: 'assets/samples/garden_flowers.jpg',
        ),
    ];
  }
  @override
  Future<void> refresh() async {}
}

class SearchProbe implements SearchBackend {
  final requests = <SearchRequest>[];
  @override
  String get name => 'test semantic backend';
  @override
  bool get isSemantic => true;
  @override
  Future<List<Photo>> search(String query, List<Photo> corpus) async =>
      (await searchDetailed(SearchRequest(query), corpus)).photos;
  @override
  Future<SearchResponse> searchDetailed(
    SearchRequest request,
    List<Photo> corpus,
  ) async {
    requests.add(request);
    return SearchResponse(
      request: request,
      photos: request.filterCorpus(corpus),
      mode: name,
    );
  }
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

  Future<(ProviderContainer, PeopleRepository)> fixture(
    WidgetTester tester, {
    SearchBackend? backend,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final people = PeopleRepository(db);
    await people.enable();
    for (var i = 0; i < 40; i++) {
      await addFaces(people, '$i', ['f$i']);
    }
    await people.createPerson([
      'f0',
      'f1',
    ], name: 'A long assigned name for layout testing');
    await people.createPerson(['f2'], name: 'Second person');
    await tester.runAsync(people.prepareReview);
    final scope = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        peopleRepositoryProvider.overrideWithValue(people),
        searchBackendProvider.overrideWith(
          (_) async => backend ?? const KeywordSearchBackend(),
        ),
        userPreferencesProvider.overrideWithValue(
          UserPreferences(read: () async => null, write: (_) async {}),
        ),
        photoLibraryProvider.overrideWith((ref) => FixtureLibrary(ref)),
        peopleControllerProvider.overrideWith(
          (ref) => IdlePeople(ref, people, PeopleService(people)),
        ),
      ],
    );
    await scope.read(peopleSnapshotProvider.future);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      await db.close();
    });
    return (scope, people);
  }

  for (final size in [
    const Size(320, 568),
    const Size(412, 915),
    const Size(1100, 760),
  ]) {
    testWidgets('People, person details and pair review fit ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (scope, people) = await fixture(tester);
      final person = (await people.load()).people.first;
      for (final entry in <(String, Widget)>[
        ('people', const PeopleScreen()),
        ('new_faces', const PeopleScreen(showNewFaces: true)),
        ('person', PersonScreen(personId: person.record.id)),
        ('review', const PeopleReviewScreen()),
      ]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(size.width == 320 ? 1.5 : 1),
                ),
                child: child!,
              ),
              home: RepaintBoundary(key: key, child: entry.$2),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/people_ui/${entry.$1}_${size.width.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });

    testWidgets(
      'face assignment and naming dialog fit ${size.width}px with keyboard',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final (scope, _) = await fixture(tester);
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(size.width == 320 ? 1.5 : 1),
                  ),
                  child: child!,
                ),
                home: const PeopleScreen(showNewFaces: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final face = find.byKey(const ValueKey('new-face-f10'));
        await tester.ensureVisible(face);
        await tester.tap(face);
        await tester.pumpAndSettle();
        await capture(tester, key, 'assign_${size.width.toInt()}');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('assign-person-filter')),
          'Second',
        );
        await tester.pumpAndSettle();
        final existing = find.widgetWithText(ListTile, 'Second person');
        await tester.ensureVisible(existing);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(existing).bottom,
          lessThanOrEqualTo(size.height - 240),
        );
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('assign-person-filter')),
          '',
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('New person'));
        await tester.tap(find.text('New person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Mohit');
        await tester.pumpAndSettle();
        await capture(tester, key, 'name_${size.width.toInt()}');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text('Save')).bottom,
          lessThanOrEqualTo(size.height - 240),
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'new-face notice opens naming; saved names immediately filter search',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final probe = SearchProbe();
      final (scope, people) = await fixture(tester, backend: probe);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('search-new-faces')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-new-faces')));
      await tester.pumpAndSettle();
      scope.read(searchQueryProvider.notifier).state = 'Rudra';
      await tester.pumpAndSettle();
      final face = find.byKey(const ValueKey('new-face-f10'));
      await tester.ensureVisible(face);
      await tester.tap(face);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New person'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name.'), findsOneWidget);
      expect((await people.load()).facesToName, 37);
      await tester.enterText(find.byType(TextFormField), 'Rudra');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-face-f10')), findsNothing);
      final saved = (await PeopleRepository(
        people.db,
      ).load()).people.singleWhere((p) => p.record.name == 'Rudra');
      expect(saved.faces.single.id, 'f10');
      expect((await people.load()).facesToName, 36);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['10'],
      );
      scope.read(searchQueryProvider.notifier).state = 'my friend Rudra';
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['10'],
      );
      scope.read(searchQueryProvider.notifier).state = 'Rudra at the beach';
      await tester.pumpAndSettle();
      expect(probe.requests.last.query, 'the beach');
      expect(probe.requests.last.eligiblePhotoIds, {'10'});
      expect(probe.requests.last.filters.personIds, {saved.record.id});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an unnamed group can be named once and another face assigned to it',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (scope, people) = await fixture(tester);
      final id = await people.createPerson(['f3', 'f4']);
      scope.read(peopleControllerProvider).changed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: PeopleScreen(showNewFaces: true)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-face-f3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a name').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Mohit');
      await tester.tap(find.text('This is me'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      var person = (await people.load()).people.singleWhere(
        (p) => p.record.id == id,
      );
      expect(person.aliases, containsAll(['me', 'myself']));
      expect(person.faces.map((f) => f.id), ['f3', 'f4']);
      final face = find.byKey(const ValueKey('new-face-f10'));
      await tester.ensureVisible(face);
      await tester.tap(face);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('assign-person-filter')),
        'Mohit',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('assign-person-$id')));
      await tester.tap(find.byKey(ValueKey('assign-person-$id')));
      await tester.pumpAndSettle();
      person = (await people.load()).people.singleWhere(
        (p) => p.record.id == id,
      );
      expect(person.faces.map((f) => f.id), containsAll(['f3', 'f4', 'f10']));
      expect((await people.load()).people, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'named people are searchable and retained names with no faces still render',
    (tester) async {
      final (scope, people) = await fixture(tester);
      final id = await people.createPerson(
        ['f3'],
        name: 'Rudra',
        aliases: ['Rudy'],
      );
      await people.assign(['f3'], null);
      scope.read(peopleControllerProvider).changed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: PeopleScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('people-name-filter')),
        'Rudy',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('named-person-$id')), findsOneWidget);
      expect(find.text('0 photos'), findsOneWidget);
      expect(find.text('Second person'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'me with my friend Rudra returns shared photos, including scene searches',
    (tester) async {
      final probe = SearchProbe();
      final (scope, people) = await fixture(tester, backend: probe);
      await addFaces(people, '3', ['f3', 'r3']);
      final me = await people.createPerson(
        ['f3', 'f4'],
        name: 'Mohit',
        aliases: ['me'],
      );
      final rudra = await people.createPerson(['r3', 'f5'], name: 'Rudra');
      scope.read(peopleControllerProvider).changed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      scope.read(searchQueryProvider.notifier).state =
          'me with my friend Rudra';
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['3'],
      );
      scope.read(searchQueryProvider.notifier).state =
          'me with my friend Rudra at sunset';
      await tester.pumpAndSettle();
      expect(probe.requests.last.query, 'sunset');
      expect(probe.requests.last.filters.personIds, {me, rudra});
      expect(probe.requests.last.eligiblePhotoIds, {'3'});
      scope.read(searchQueryProvider.notifier).state =
          'show me photos of Rudra';
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        unorderedEquals(['3', '5']),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'naming a group saves and pair judgment persists without invented labels',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (scope, people) = await fixture(tester);
      final person = (await people.load()).people.first;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(home: PersonScreen(personId: person.record.id)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Renamed locally',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await people.load()).people.first.record.name, 'Renamed locally');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await scope.read(peopleSnapshotProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: PeopleReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unsure'));
      await tester.pumpAndSettle();
      expect(
        (await people.load()).reviews.where((r) => r.judgment == 'unsure'),
        hasLength(1),
      );
      expect((await people.calibration()).passed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) =>
    tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/people_ui/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
