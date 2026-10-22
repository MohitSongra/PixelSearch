import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people/people_service.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/data/search/keyword_search_backend.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/domain/people/people_query.dart';
import 'package:pixelsearch/domain/search/search_backend.dart';
import 'package:pixelsearch/domain/search/search_response.dart';
import 'package:pixelsearch/features/search/search_screen.dart';
import 'package:pixelsearch/features/people/people_screen.dart';
import 'package:pixelsearch/features/people/people_review_screen.dart';
import 'package:pixelsearch/features/people/person_suggestions_screen.dart';
import 'package:pixelsearch/features/viewer/search_explanation.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/people_providers.dart';
import 'package:pixelsearch/state/providers.dart';

import 'people_repository_test.dart' show addFaces;

import 'support/test_fonts.dart';

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

/// New faces are listed newest photo first in a lazy grid; scroll the People
/// screen until the tile is built.
Future<void> revealNewFace(WidgetTester tester, Finder face) async {
  await tester.scrollUntilVisible(
    face,
    300,
    scrollable: find
        .descendant(
          of: find.byType(PeopleScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

class SearchProbe implements SearchBackend {
  SearchProbe({this.emptyForText = false});

  /// Simulates a scene search that matches nothing (non-empty query text).
  final bool emptyForText;
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
      photos: emptyForText && request.query.trim().isNotEmpty
          ? const []
          : request.filterCorpus(corpus),
      mode: name,
    );
  }
}

/// Counts resume requests; a paused People pipeline must stay paused.
class RecordingPeople extends IdlePeople {
  RecordingPeople(super.ref, super.repository, super.service);
  int resumes = 0;
  @override
  Future<void> resume() async {
    resumes++;
  }
}

/// Counts automatic grouping runs.
class SpyPeopleRepository extends PeopleRepository {
  SpyPeopleRepository(super.db);
  int groupingCalls = 0;
  @override
  Future<int> applyGrouping() async {
    groupingCalls++;
    return super.applyGrouping();
  }
}

/// Counts full People table loads.
class CountingPeopleRepository extends PeopleRepository {
  CountingPeopleRepository(super.db);
  int loads = 0;
  @override
  Future<PeopleSnapshot> load() {
    loads++;
    return super.load();
  }
}

void usePhone(WidgetTester tester, [Size size = const Size(412, 915)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Mounts [home] in a fresh MaterialApp (new Navigator and ScaffoldMessenger).
Future<void> mount(
  WidgetTester tester,
  ProviderContainer scope,
  Widget home, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: MaterialApp(
        key: UniqueKey(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Mounts [screen] above a plain first route, so it can be left with Back
/// and can pop itself.
Future<void> mountPushed(
  WidgetTester tester,
  ProviderContainer scope,
  Widget screen,
) async {
  await mount(
    tester,
    scope,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('Open screen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open screen'));
  await tester.pumpAndSettle();
}

Future<void> runQuery(
  WidgetTester tester,
  ProviderContainer scope,
  String text,
) async {
  scope.read(searchQueryProvider.notifier).state = text;
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  // skipOffstage: the People header may be scrolled out of the viewport.
  final target = find.byKey(ValueKey(key), skipOffstage: false);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Action SnackBars persist until handled; this is the user swiping one away.
Future<void> clearSnackBar(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .removeCurrentSnackBar();
  await tester.pumpAndSettle();
}

/// From the open naming sheet: New person, type [name], Save.
Future<void> saveNewPerson(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text('New person'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('New person'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), name);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// Turns on New faces selection and picks [faceIds].
Future<void> selectNewFaces(WidgetTester tester, List<String> faceIds) async {
  await tapKey(tester, 'new-faces-select');
  for (final id in faceIds) {
    final face = find.byKey(ValueKey('new-face-$id'));
    await revealNewFace(tester, face);
    await tester.tap(face);
    await tester.pumpAndSettle();
  }
  // Bring the selection bar back into view.
  await tester.ensureVisible(
    find.byKey(const ValueKey('new-faces-name-selected'), skipOffstage: false),
  );
  await tester.pumpAndSettle();
}

Future<Map<String, PeopleFaceRecord>> faceRows(
  PeopleRepository people,
) async => {
  for (final f in await people.db.select(people.db.peopleFaces).get()) f.id: f,
};

Future<List<String>> decisionRows(PeopleRepository people) async => [
  for (final d in await people.db.select(people.db.peopleDecisions).get())
    '${d.faceId} ${d.personId} ${d.decision}',
];

/// Every People row a review screen could change.
Future<List<String>> peopleRows(PeopleRepository people) async => [
  for (final f in (await faceRows(people)).values)
    'face ${f.id} ${f.personId} ${f.assignment} ${f.dismissed}',
  ...await decisionRows(people),
  for (final p in await people.db.select(people.db.peoplePersons).get())
    'person ${p.id} ${p.name} ${p.aliasesJson} ${p.hidden} ${p.coverFaceId}',
];

List<String> facesOf(Map<String, PeopleFaceRecord> faces, String personId) => [
  for (final f in faces.values)
    if (f.personId == personId) f.id,
];

Future<String> personIdNamed(PeopleRepository people, String name) async =>
    (await people.load()).people
        .singleWhere((p) => p.record.name == name)
        .record
        .id;

List<String> chipLabels(WidgetTester tester) => [
  for (final chip in tester.widgetList<InputChip>(find.byType(InputChip)))
    (chip.label as Text).data!,
];

List<String> resultIds(ProviderContainer scope) => scope
    .read(searchResponseProvider)
    .valueOrNull!
    .photos
    .map((p) => p.id)
    .toList();

void main() {
  setUpAll(loadTestFonts);

  Future<(ProviderContainer, PeopleRepository)> fixture(
    WidgetTester tester, {
    SearchBackend? backend,
    PeopleRepository Function(AppDatabase db)? repository,
    PeopleController Function(Ref ref, PeopleRepository people)? controller,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final people = repository?.call(db) ?? PeopleRepository(db);
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
          (ref) =>
              controller?.call(ref, people) ??
              IdlePeople(ref, people, PeopleService(people)),
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

  testWidgets(
    'failed review shows its cause and opens the exact conflicting pair',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (scope, people) = await fixture(tester);
      final pairs = (await people.load()).reviews;
      final lastCal = pairs.lastWhere((p) => p.subset == 'calibration');
      final lastVal = pairs.lastWhere((p) => p.subset == 'validation');
      for (final pair in pairs) {
        final different = pair.id == lastCal.id || pair.id == lastVal.id;
        await (people.db.update(
          people.db.peopleReviews,
        )..where((r) => r.id.equals(pair.id))).write(
          PeopleReviewsCompanion(
            judgment: drift.Value(different ? 'different' : 'same'),
            cosine: drift.Value(
              different ? (pair.id == lastCal.id ? .4 : .85) : .8,
            ),
          ),
        );
      }
      // Old installations have no diagnostic fields in their saved JSON.
      expect((await people.state()).calibrationJson, '{}');
      scope.invalidate(peopleSnapshotProvider);
      await scope.read(peopleSnapshotProvider.future);
      await scope.read(peopleCalibrationProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: PeopleReviewScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 of 1 different-person test pairs'),
        findsOneWidget,
      );
      await tester.tap(find.text('Review results'));
      await tester.pumpAndSettle();
      expect(find.text('Tested cosine cutoff: 0.8000'), findsOneWidget);
      final number = pairs.indexWhere((p) => p.id == lastVal.id) + 1;
      await tester.tap(find.text('Inspect pair $number'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pair $number of ${pairs.length}'),
        180,
      );
      expect(find.text('Pair $number of ${pairs.length}'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Check 20 new pairs'), 120);
      await tester.tap(find.text('Check 20 new pairs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await people.load()).reviews.map((p) => p.id),
        pairs.map((p) => p.id),
      );
      expect((await people.state()).threshold, isNull);
      expect(tester.takeException(), isNull);
    },
  );

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
        await revealNewFace(tester, face);
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
        await tester.enterText(find.byType(TextFormField), 'Alice');
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
      scope.read(searchQueryProvider.notifier).state = 'Bob';
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      final face = find.byKey(const ValueKey('new-face-f10'));
      await revealNewFace(tester, face);
      await tester.tap(face);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New person'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name.'), findsOneWidget);
      expect((await people.load()).facesToName, 37);
      await tester.enterText(find.byType(TextFormField), 'Bob');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-face-f10')), findsNothing);
      final saved = (await PeopleRepository(
        people.db,
      ).load()).people.singleWhere((p) => p.record.name == 'Bob');
      expect(saved.faces.single.id, 'f10');
      expect((await people.load()).facesToName, 36);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['10'],
      );
      scope.read(searchQueryProvider.notifier).state = 'my friend Bob';
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['10'],
      );
      scope.read(searchQueryProvider.notifier).state = 'Bob at the beach';
      await tester.pumpAndSettle();
      expect(probe.requests.last.query, 'the beach');
      expect(probe.requests.last.eligiblePhotoIds, {'10'});
      expect(probe.requests.last.filters.personIds, {saved.record.id});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('naming an automatic group confirms the face shown first', (
    tester,
  ) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester);
    final group = await people.createPerson(['f3', 'f4']);
    for (final id in ['f3', 'f4']) {
      await (people.db.update(
        people.db.peopleFaces,
      )..where((f) => f.id.equals(id))).write(
        const PeopleFacesCompanion(assignment: drift.Value('automatic')),
      );
    }
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const PeopleScreen(showNewFaces: true));
    await tester.tap(find.byKey(const ValueKey('new-face-f3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a name').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ben');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final snapshot = await people.load();
    final ben = snapshot.people.singleWhere((p) => p.record.id == group);
    expect(ben.record.name, 'Ben');
    final byId = {for (final f in ben.faces) f.id: f.assignment};
    // The first face shown was named by the user; the other stays automatic
    // and can be checked with "Is this Ben?".
    expect(byId['f3'], 'manual');
    expect(byId['f4'], 'automatic');
    expect(tester.takeException(), isNull);
  });

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
      await tester.enterText(find.byType(TextFormField), 'Alice');
      await tester.tap(find.text('This is me'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      var person = (await people.load()).people.singleWhere(
        (p) => p.record.id == id,
      );
      expect(person.aliases, containsAll(['me', 'myself']));
      expect(person.faces.map((f) => f.id), ['f3', 'f4']);
      final face = find.byKey(const ValueKey('new-face-f10'));
      await revealNewFace(tester, face);
      await tester.tap(face);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('assign-person-filter')),
        'Alice',
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
        name: 'Bob',
        aliases: ['Bobby'],
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
        'Bobby',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('named-person-$id')), findsOneWidget);
      expect(find.text('0 photos'), findsOneWidget);
      expect(find.text('Second person'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a named person without confirmed photos opens the New Faces recovery path',
    (tester) async {
      final (scope, people) = await fixture(tester);
      final bob = await people.createPerson(['f3'], name: 'Bob');
      await people.assign(['f3'], null);
      scope.read(peopleControllerProvider).changed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      scope.read(searchQueryProvider.notifier).state = 'Bob';
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('person-search-empty')), findsOneWidget);
      expect(find.text('No photos of Bob yet'), findsOneWidget);
      expect(find.text('Review new faces'), findsOneWidget);
      await tester.tap(find.text('Review new faces'));
      await tester.pumpAndSettle();
      expect(find.text('New faces'), findsWidgets);
      expect(
        (await people.load()).people.any((person) => person.record.id == bob),
        isTrue,
      );
    },
  );

  testWidgets(
    'me with my friend Bob returns shared photos, including scene searches',
    (tester) async {
      final probe = SearchProbe();
      final (scope, people) = await fixture(tester, backend: probe);
      await addFaces(people, '3', ['f3', 'r3']);
      final me = await people.createPerson(
        ['f3', 'f4'],
        name: 'Alice',
        aliases: ['me'],
      );
      final bob = await people.createPerson(['r3', 'f5'], name: 'Bob');
      scope.read(peopleControllerProvider).changed();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      scope.read(searchQueryProvider.notifier).state = 'me with my friend Bob';
      await tester.pumpAndSettle();
      expect(
        scope.read(searchResponseProvider).valueOrNull!.photos.map((p) => p.id),
        ['3'],
      );
      scope.read(searchQueryProvider.notifier).state =
          'me with my friend Bob at sunset';
      await tester.pumpAndSettle();
      expect(probe.requests.last.query, 'sunset');
      expect(probe.requests.last.filters.personIds, {me, bob});
      expect(probe.requests.last.eligiblePhotoIds, {'3'});
      scope.read(searchQueryProvider.notifier).state = 'show me photos of Bob';
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

  testWidgets(
    'suggestions need per-face confirmation and say they are not recognition',
    (tester) async {
      usePhone(tester);
      final (scope, people) = await fixture(tester);
      final asha = await people.createPerson(['f5'], name: 'Asha');
      scope.read(peopleControllerProvider).changed();
      final before = await peopleRows(people);
      await mountPushed(tester, scope, PersonSuggestionsScreen(personId: asha));
      final explanation = find.byKey(const ValueKey('suggestions-explanation'));
      expect(
        tester.widget<Text>(explanation).data,
        contains('This is not recognition'),
      );
      expect(find.byKey(const ValueKey('suggestion-f10')), findsOneWidget);
      expect(find.byKey(const ValueKey('suggestion-confirm')), findsNothing);
      // Opening the review and leaving it changes nothing.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(await peopleRows(people), before);

      await tester.tap(find.text('Open screen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-f10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-f11')));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('suggestion-confirm')));
      await tester.pumpAndSettle();
      var faces = await faceRows(people);
      expect(facesOf(faces, asha), unorderedEquals(['f5', 'f10', 'f11']));
      expect(faces['f10']!.assignment, 'manual');
      expect(faces['f11']!.assignment, 'manual');
      expect(find.text('Added 2 faces to Asha.'), findsOneWidget);
      expect(find.byKey(const ValueKey('suggestion-f10')), findsNothing);
      await clearSnackBar(tester);

      await tester.tap(find.byKey(const ValueKey('suggestion-f12')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-reject')));
      await tester.pumpAndSettle();
      expect(await decisionRows(people), contains('f12 $asha reject'));
      faces = await faceRows(people);
      expect(faces['f12']!.personId, isNull);
      expect(faces['f12']!.dismissed, isFalse);
      expect(find.byKey(const ValueKey('suggestion-f12')), findsNothing);
      expect(
        find.text("1 face won't be suggested for Asha again."),
        findsOneWidget,
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await decisionRows(people), isNot(contains('f12 $asha reject')));
      expect(find.byKey(const ValueKey('suggestion-f12')), findsOneWidget);
      // Undoing the rejection leaves the earlier confirmation alone.
      expect(
        facesOf(await faceRows(people), asha),
        unorderedEquals(['f5', 'f10', 'f11']),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a second suggestion decision offers its own Undo',
    (tester) async {
      usePhone(tester);
      final (scope, people) = await fixture(tester);
      final asha = await people.createPerson(['f5'], name: 'Asha');
      scope.read(peopleControllerProvider).changed();
      await mount(tester, scope, PersonSuggestionsScreen(personId: asha));
      await tester.tap(find.byKey(const ValueKey('suggestion-f10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-f11')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('suggestion-reject')));
      await tester.pumpAndSettle();
      expect(
        find.text("1 face won't be suggested for Asha again."),
        findsOneWidget,
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await decisionRows(people), isNot(contains('f11 $asha reject')));
      expect((await faceRows(people))['f10']!.personId, asha);
    },
    // SnackBars with an action persist by default (Flutter 3.44); each
    // decision now replaces the previous offer so Undo matches the last one.
  );

  testWidgets('no People flow resumes paused processing or starts grouping', (
    tester,
  ) async {
    usePhone(tester);
    late RecordingPeople controller;
    final (scope, people) = await fixture(
      tester,
      repository: SpyPeopleRepository.new,
      controller: (ref, people) =>
          controller = RecordingPeople(ref, people, PeopleService(people)),
    );
    final spy = people as SpyPeopleRepository;
    await people.pause(true);
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const PeopleScreen(showNewFaces: true));
    expect(find.textContaining('| Paused'), findsOneWidget);

    // Name one face from the New faces sheet.
    final first = find.byKey(const ValueKey('new-face-f39'));
    await revealNewFace(tester, first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    await saveNewPerson(tester, 'Asha');
    final asha = await personIdNamed(people, 'Asha');

    // Confirm one similar face and reject another.
    await mountPushed(tester, scope, PersonSuggestionsScreen(personId: asha));
    await tester.tap(find.byKey(const ValueKey('suggestion-f10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('suggestion-confirm')));
    await tester.pumpAndSettle();
    await clearSnackBar(tester);
    await tester.tap(find.byKey(const ValueKey('suggestion-f11')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('suggestion-reject')));
    await tester.pumpAndSettle();

    // Name two faces at once, then mark two as Not a face.
    await mount(tester, scope, const PeopleScreen(showNewFaces: true));
    expect(find.textContaining('| Paused'), findsOneWidget);
    await selectNewFaces(tester, ['f38', 'f37']);
    await tapKey(tester, 'new-faces-name-selected');
    await saveNewPerson(tester, 'Ben');
    await clearSnackBar(tester);
    await selectNewFaces(tester, ['f36', 'f35']);
    await tapKey(tester, 'new-faces-dismiss-selected');

    // Delete a person.
    final ben = await personIdNamed(people, 'Ben');
    await mountPushed(tester, scope, PersonScreen(personId: ben));
    await tester.tap(find.byTooltip('Person options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete person'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Ben?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete person'));
    await tester.pumpAndSettle();
    expect(find.text('Open screen'), findsOneWidget);

    final faces = await faceRows(people);
    expect(facesOf(faces, asha), unorderedEquals(['f39', 'f10']));
    expect(await decisionRows(people), contains('f11 $asha reject'));
    expect(faces['f36']!.dismissed, isTrue);
    expect(
      (await people.load()).people.any((p) => p.record.id == ben),
      isFalse,
    );
    expect(faces['f38']!.personId, isNull);
    expect(controller.resumes, 0);
    expect(spy.groupingCalls, 0);
    expect((await people.state()).paused, isTrue);
    expect(faces.values.where((f) => f.assignment == 'automatic'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'New faces multi-select names several faces at once and bulk dismiss can be undone',
    (tester) async {
      usePhone(tester);
      final (scope, people) = await fixture(tester);
      await mount(tester, scope, const PeopleScreen(showNewFaces: true));
      await selectNewFaces(tester, ['f39', 'f38', 'f37']);
      expect(find.text('3 selected'), findsOneWidget);
      await tapKey(tester, 'new-faces-name-selected');
      expect(find.text('Name 3 faces'), findsOneWidget);
      expect(
        find.text('All 3 faces will be named as one person.'),
        findsOneWidget,
      );
      await saveNewPerson(tester, 'Ben');
      final ben = await personIdNamed(people, 'Ben');
      var faces = await faceRows(people);
      expect(facesOf(faces, ben), unorderedEquals(['f39', 'f38', 'f37']));
      for (final id in ['f39', 'f38', 'f37']) {
        expect(faces[id]!.assignment, 'manual');
      }
      expect(find.byKey(const ValueKey('new-face-f39')), findsNothing);
      expect(find.text('3 selected'), findsNothing);
      await clearSnackBar(tester);

      await selectNewFaces(tester, ['f36', 'f35']);
      await tapKey(tester, 'new-faces-dismiss-selected');
      faces = await faceRows(people);
      expect(faces['f36']!.dismissed, isTrue);
      expect(faces['f35']!.dismissed, isTrue);
      expect(find.byKey(const ValueKey('new-face-f36')), findsNothing);
      expect(find.text('2 faces marked Not a face.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      faces = await faceRows(people);
      for (final id in ['f36', 'f35']) {
        expect(faces[id]!.dismissed, isFalse);
        expect(faces[id]!.personId, isNull);
      }
      expect(find.byKey(const ValueKey('new-face-f36')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'marking faces Not a face right after naming offers that Undo',
    (tester) async {
      usePhone(tester);
      final (scope, people) = await fixture(tester);
      await mount(tester, scope, const PeopleScreen(showNewFaces: true));
      final face = find.byKey(const ValueKey('new-face-f39'));
      await revealNewFace(tester, face);
      await tester.tap(face);
      await tester.pumpAndSettle();
      await saveNewPerson(tester, 'Ben');
      await selectNewFaces(tester, ['f38', 'f37']);
      await tapKey(tester, 'new-faces-dismiss-selected');
      expect(find.text('2 faces marked Not a face.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await faceRows(people))['f38']!.dismissed, isFalse);
    },
    // The "Saved Ben." offer no longer holds later SnackBars back.
  );

  testWidgets('naming a detailed face offers Review similar', (tester) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester);
    await mount(tester, scope, const PeopleScreen(showNewFaces: true));
    final face = find.byKey(const ValueKey('new-face-f39'));
    await revealNewFace(tester, face);
    await tester.tap(face);
    await tester.pumpAndSettle();
    expect(find.text('Who is this?'), findsOneWidget);
    await saveNewPerson(tester, 'Asha');
    expect(find.text('Saved Asha.'), findsOneWidget);
    await tester.tap(find.text('Review similar'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonSuggestionsScreen), findsOneWidget);
    expect(find.text('Similar faces'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('suggestions-explanation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('suggestion-f10')), findsOneWidget);
    // Opening the review assigns nothing.
    final asha = await personIdNamed(people, 'Asha');
    expect(facesOf(await faceRows(people), asha), ['f39']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('This is me shows who currently holds it and moves on save', (
    tester,
  ) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester);
    final dev = await people.createPerson(
      ['f3'],
      name: 'Dev',
      aliases: ['me', 'myself'],
    );
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const PeopleScreen(showNewFaces: true));
    final face = find.byKey(const ValueKey('new-face-f39'));
    await revealNewFace(tester, face);
    await tester.tap(face);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New person'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New person'));
    await tester.pumpAndSettle();
    final isMe = find.byKey(const ValueKey('person-is-me'));
    expect(tester.widget<CheckboxListTile>(isMe).value, isFalse);
    expect(
      find.descendant(of: isMe, matching: find.text('Currently Dev.')),
      findsOneWidget,
    );
    await tester.tap(isMe);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(isMe).value, isTrue);
    expect(
      find.descendant(
        of: isMe,
        matching: find.text('Currently Dev. Saving moves "me" here.'),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Asha');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final snapshot = await people.load();
    final devView = snapshot.people.singleWhere((p) => p.record.id == dev);
    final asha = snapshot.people.singleWhere((p) => p.record.name == 'Asha');
    expect(devView.aliases.where(isSelfAlias), isEmpty);
    expect(asha.aliases, containsAll(['me', 'myself']));
    expect(snapshot.self?.record.id, asha.record.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hidden This-is-me person still answers "me"', (tester) async {
    usePhone(tester);
    final probe = SearchProbe();
    final (scope, people) = await fixture(tester, backend: probe);
    final dev = await people.createPerson(
      ['f5'],
      name: 'Dev',
      aliases: ['me', 'myself'],
    );
    await people.editPerson(dev, hidden: true);
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'photos of me');
    expect(find.text('Which person is you?'), findsNothing);
    final query = scope.read(peopleQueryProvider).valueOrNull!;
    expect(query.selfMissing, isFalse);
    expect(query.required, {dev});
    expect(resultIds(scope), ['5']);
    // The hidden person's name is still not matched from typed text.
    await runQuery(tester, scope, 'Dev');
    expect(scope.read(peopleQueryProvider).valueOrNull!.hasPeople, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing self shows the This-is-me state and Search without me works',
    (tester) async {
      usePhone(tester);
      final probe = SearchProbe();
      final (scope, people) = await fixture(tester, backend: probe);
      final asha = await people.createPerson(['f5'], name: 'Asha');
      scope.read(peopleControllerProvider).changed();
      await mount(tester, scope, const SearchScreen());
      probe.requests.clear();
      await runQuery(tester, scope, 'photos of me with Asha');
      expect(find.byKey(const ValueKey('person-search-empty')), findsOneWidget);
      expect(find.text('Which person is you?'), findsOneWidget);
      expect(find.text('Open People'), findsOneWidget);
      expect(
        scope.read(searchResponseProvider).valueOrNull!.mode,
        'self missing',
      );
      expect(probe.requests, isEmpty);
      await tester.tap(find.text('Search without "me"'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Which person is you?'), findsNothing);
      expect(resultIds(scope), ['5']);
      expect(
        scope
            .read(searchResponseProvider)
            .valueOrNull!
            .request
            .filters
            .personIds,
        {asha},
      );
      // Name-only: the person's photos without the text model, and the
      // results header says so.
      expect(probe.requests, isEmpty);
      expect(find.byTooltip('Matched by assigned faces'), findsOneWidget);
      expect(
        find.byTooltip('Matched by on-device semantic search'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('person chips show You and display names, never alias keys', (
    tester,
  ) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester, backend: SearchProbe());
    await people.createPerson(['f3'], name: 'Dev', aliases: ['me', 'myself']);
    await people.createPerson(['f5'], name: 'Asha', aliases: ['Ash']);
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'me with Ash');
    expect(chipLabels(tester), ['You', 'Asha']);
    expect(find.byKey(const ValueKey('person-chip-me')), findsOneWidget);
    expect(find.byKey(const ValueKey('person-chip-ash')), findsOneWidget);
    for (final key in ['me', 'Me', 'myself', 'ash', 'Ash', 'Dev']) {
      expect(
        find.descendant(of: find.byType(InputChip), matching: find.text(key)),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scene miss offers all photos of the person', (tester) async {
    usePhone(tester);
    final probe = SearchProbe(emptyForText: true);
    final (scope, people) = await fixture(tester, backend: probe);
    final asha = await people.createPerson(['f5'], name: 'Asha');
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'Asha at the beach');
    expect(probe.requests.last.query, 'the beach');
    expect(probe.requests.last.eligiblePhotoIds, {'5'});
    expect(find.byKey(const ValueKey('person-search-empty')), findsOneWidget);
    expect(
      find.text('1 photo of Asha, none match "the beach"'),
      findsOneWidget,
    );
    await tester.tap(find.text('Show all 1 photo'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(scope.read(searchQueryProvider), '');
    expect(scope.read(searchFiltersProvider).personIds, {asha});
    expect(resultIds(scope), ['5']);
    expect(find.byKey(const ValueKey('person-search-empty')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('not together is told apart from no assigned photos', (
    tester,
  ) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester, backend: SearchProbe());
    await people.createPerson(['f5'], name: 'Asha');
    await people.createPerson(['f6'], name: 'Ben');
    await people.createPerson(['f7'], name: 'Chen');
    await people.assign(['f7'], null);
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'Asha and Ben');
    expect(find.byKey(const ValueKey('person-search-empty')), findsOneWidget);
    expect(find.text('No photos of Asha and Ben together'), findsOneWidget);
    await runQuery(tester, scope, 'Chen');
    expect(find.byKey(const ValueKey('person-search-empty')), findsOneWidget);
    expect(find.text('No photos of Chen yet'), findsOneWidget);
    expect(find.text('No photos of Asha and Ben together'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('or and without reach the backend as eligible photo ids', (
    tester,
  ) async {
    usePhone(tester);
    final probe = SearchProbe();
    final (scope, people) = await fixture(tester, backend: probe);
    // Asha: photos 5 and 7. Ben: photos 6 and 7.
    await addFaces(people, '7', ['f7', 'b7']);
    final asha = await people.createPerson(['f5', 'f7'], name: 'Asha');
    final ben = await people.createPerson(['f6', 'b7'], name: 'Ben');
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'Asha or Ben at the park');
    expect(probe.requests.last.query, 'the park');
    expect(probe.requests.last.eligiblePhotoIds, {'5', '6', '7'});
    expect(probe.requests.last.filters.anyPersonIds, {asha, ben});
    expect(chipLabels(tester), ['either Asha', 'either Ben']);
    await runQuery(tester, scope, 'Asha without Ben at the park');
    expect(probe.requests.last.query, 'the park');
    expect(probe.requests.last.eligiblePhotoIds, {'5'});
    expect(probe.requests.last.filters.personIds, {asha});
    expect(probe.requests.last.filters.excludedPersonIds, {ben});
    expect(chipLabels(tester), ['Asha', 'not Ben']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hidden people are not resolved from text, but their search action works',
    (tester) async {
      usePhone(tester);
      final probe = SearchProbe();
      final (scope, people) = await fixture(tester, backend: probe);
      final asha = await people.createPerson(['f5'], name: 'Asha');
      await people.editPerson(asha, hidden: true);
      scope.read(peopleControllerProvider).changed();
      await mount(tester, scope, const SearchScreen());
      await runQuery(tester, scope, 'Asha');
      expect(find.byType(InputChip), findsNothing);
      expect(probe.requests.last.query, 'Asha');
      expect(probe.requests.last.filters.hasPeople, isFalse);
      expect(probe.requests.last.eligiblePhotoIds, isNull);

      Navigator.of(tester.element(find.byType(SearchScreen))).push(
        MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: asha)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('person-search-photos')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(PersonScreen), findsNothing);
      expect(scope.read(searchQueryProvider), '');
      expect(scope.read(searchFiltersProvider).personIds, {asha});
      expect(resultIds(scope), ['5']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the People filter chip combines with scene text', (
    tester,
  ) async {
    usePhone(tester);
    final probe = SearchProbe();
    final (scope, people) = await fixture(tester, backend: probe);
    final asha = await people.createPerson(['f5', 'f8'], name: 'Asha');
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    // The filter bar is shown once a search is active.
    await runQuery(tester, scope, 'sunset');
    expect(probe.requests.last.filters.hasPeople, isFalse);
    await tester.tap(find.byKey(const ValueKey('people-filter-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('people-filter-$asha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('people-filter-done')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(scope.read(searchFiltersProvider).personIds, {asha});
    expect(probe.requests.last.query, 'sunset');
    expect(probe.requests.last.eligiblePhotoIds, {'5', '8'});
    expect(probe.requests.last.filters.personIds, {asha});
    await runQuery(tester, scope, 'beach');
    expect(probe.requests.last.query, 'beach');
    expect(probe.requests.last.eligiblePhotoIds, {'5', '8'});
    // Scene text within a person's photos is still ranked by the backend.
    expect(find.byTooltip('Matched by assigned faces'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chosen person for a shared name survives further typing', (
    tester,
  ) async {
    usePhone(tester);
    final probe = SearchProbe();
    final (scope, people) = await fixture(tester, backend: probe);
    final ben1 = await people.createPerson(['f5'], name: 'Ben');
    final ben2 = await people.createPerson(['f6'], name: 'Ben');
    scope.read(peopleControllerProvider).changed();
    await mount(tester, scope, const SearchScreen());
    probe.requests.clear();
    await runQuery(tester, scope, 'Ben');
    expect(scope.read(peopleQueryProvider).valueOrNull!.needsChoice, isTrue);
    expect(find.text('Choose ben'), findsOneWidget);
    expect(probe.requests, isEmpty);
    await tester.tap(find.text('Choose ben'));
    await tester.pumpAndSettle();
    final options = find.byType(PopupMenuItem<String>);
    expect(options, findsNWidgets(2));
    final chosen = tester.widget<PopupMenuItem<String>>(options.first).value!;
    expect({ben1, ben2}, contains(chosen));
    final photo = chosen == ben1 ? '5' : '6';
    await tester.tap(options.first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(scope.read(peopleNameChoicesProvider), {'ben': chosen});
    expect(resultIds(scope), [photo]);
    await runQuery(tester, scope, 'Ben at the park');
    expect(scope.read(peopleNameChoicesProvider), {'ben': chosen});
    expect(scope.read(peopleQueryProvider).valueOrNull!.needsChoice, isFalse);
    expect(find.text('Choose ben'), findsNothing);
    expect(probe.requests.last.query, 'the park');
    expect(probe.requests.last.filters.personIds, {chosen});
    expect(probe.requests.last.eligiblePhotoIds, {photo});
    expect(tester.takeException(), isNull);
  });

  testWidgets('a person query reuses the cached People snapshot', (
    tester,
  ) async {
    usePhone(tester);
    final (scope, people) = await fixture(
      tester,
      repository: CountingPeopleRepository.new,
    );
    final counting = people as CountingPeopleRepository;
    await mount(tester, scope, const SearchScreen());
    counting.loads = 0;
    await runQuery(tester, scope, 'Second person');
    expect(resultIds(scope), ['2']);
    expect(scope.read(searchResponseProvider).valueOrNull!.mode, 'people');
    expect(counting.loads, 0);
  });

  testWidgets('a name-only explanation shows names and no ids', (tester) async {
    usePhone(tester);
    final (scope, people) = await fixture(tester);
    final second = await personIdNamed(people, 'Second person');
    await mount(tester, scope, const SearchScreen());
    await runQuery(tester, scope, 'Second person');
    final response = scope.read(searchResponseProvider).valueOrNull!;
    expect(response.mode, 'people');
    expect(response.photos.map((p) => p.id), ['2']);
    expect(describeFilters(response), 'People: Second person');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchExplanation(response: response, photoId: '2'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Matched by assigned faces'), findsOneWidget);
    expect(find.text('Second person — face assigned manually'), findsOneWidget);
    expect(find.text('Filters: People: Second person'), findsOneWidget);
    expect(find.textContaining('ML Kit'), findsNothing);
    expect(find.textContaining(second), findsNothing);
    expect(find.textContaining('manual:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(320, 640), 1.5),
    (const Size(412, 915), 1.0),
  ]) {
    testWidgets(
      'similar faces and Not a face screens fit ${size.width.toInt()}px at ${scale}x text',
      (tester) async {
        usePhone(tester, size);
        final (scope, people) = await fixture(tester);
        final asha = await people.createPerson(['f5'], name: 'Asha');
        await people.assign(['f6', 'f7'], null, dismiss: true);
        scope.read(peopleControllerProvider).changed();
        await mount(
          tester,
          scope,
          PersonSuggestionsScreen(personId: asha),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final tile = find.byKey(const ValueKey('suggestion-f10'));
        await tester.scrollUntilVisible(
          tile,
          200,
          scrollable: find
              .descendant(
                of: find.byType(PersonSuggestionsScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('suggestion-confirm')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await mount(
          tester,
          scope,
          const DismissedFacesScreen(),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('dismissed-f6')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dismissed-restore')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
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
