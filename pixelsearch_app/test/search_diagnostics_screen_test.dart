import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/evaluation/retrieval_evaluation.dart';
import 'package:pixelsearch/features/search/search_diagnostics_screen.dart';
import 'package:pixelsearch/state/providers.dart';

import 'search_diagnostics_test.dart'
    show fixturePhoto, fixtureVector, DiagnosticFakeEmbedder;

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  late AppDatabase db;
  late Directory temp;
  late PathProviderPlatform original;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    temp = await Directory.systemTemp.createTemp(
      'pixelsearch-evaluation-test-',
    );
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(temp.path);
    await PhotoRepository(db).savePhotos([fixturePhoto('test_photo')]);
    await PhotoRepository(db).saveEmbedding('test_photo', fixtureVector(.3));
  });
  tearDown(() async {
    await db.close();
    PathProviderPlatform.instance = original;
    expect(
      temp.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    await temp.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester) async {
    final backend = SemanticSearchBackend(
      embedder: DiagnosticFakeEmbedder(),
      index: BruteForceVectorIndex()..upsert('test_photo', fixtureVector(.3)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          indexWarmupProvider.overrideWith((ref) async => 1),
          searchBackendProvider.overrideWith((ref) async => backend),
          evaluationDatasetProvider.overrideWith(
            (ref) async => const EvaluationDataset('test', [
              EvaluationQuery(id: 'q', query: 'a dog on a beach'),
            ]),
          ),
        ],
        child: const MaterialApp(home: SearchDiagnosticsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finishIo(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 120; i++) {
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) return;
    }
    fail('Search Diagnostics did not finish I/O within the test budget.');
  }

  testWidgets(
    'compare, switch rankings, judge and persist without changing the library',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'a dog on a beach');
      await tester.tap(find.byTooltip('Compare rankings'));
      await finishIo(tester);
      expect(find.text('1 vectors | 0 judged'), findsOneWidget);
      expect(find.text('test_photo.jpg'), findsWidgets);
      await tester.tap(find.text('Final'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('score 0.6000'), findsWidgets);
      await tester.tap(
        find
            .widgetWithText(DropdownButton<int>, 'Unjudged')
            .hitTestable()
            .first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Relevant').last);
      await finishIo(tester);
      expect(find.text('1 vectors | 1 judged'), findsOneWidget);
      final saved = EvaluationDataset.parse(
        File('${temp.path}/search_evaluation/queries.json').readAsStringSync(),
      );
      expect(saved.queries.single.judgments, {'test_photo': 2});
      expect(await db.photoCount(), 1);
      final report =
          jsonDecode(
                File(
                  '${temp.path}/search_evaluation/latest_report.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(report['trace']['query'], 'a dog on a beach');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320px screen with large text has no layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'a dog on a beach');
    await tester.tap(find.byTooltip('Compare rankings'));
    await finishIo(tester);
    expect(tester.takeException(), isNull);
  });
}
