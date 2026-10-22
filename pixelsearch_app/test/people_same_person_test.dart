import 'dart:async';

import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people/people_service.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/domain/people/face_grouping.dart';
import 'package:pixelsearch/domain/people/same_person.dart';
import 'package:pixelsearch/features/people/same_person_screen.dart';
import 'package:pixelsearch/state/people_providers.dart';
import 'package:pixelsearch/state/providers.dart';

import 'people_suggestions_test.dart'
    show addVectorFaces, automaticCount, axis, faceRow, unitAt;
import 'people_widgets_test.dart' show IdlePeople;

FaceVector face(String id, String photo, double degrees) =>
    FaceVector(id: id, photoId: photo, vector: unitAt(degrees));

/// Marks faces as grouped automatically into [personId] (as grouping does).
Future<void> markAutomatic(
  AppDatabase db,
  List<String> faceIds,
  String personId,
) async {
  for (final id in faceIds) {
    await (db.update(db.peopleFaces)..where((f) => f.id.equals(id))).write(
      PeopleFacesCompanion(
        personId: Value(personId),
        assignment: const Value('automatic'),
      ),
    );
  }
}

Future<String?> decision(
  AppDatabase db,
  String faceId,
  String personId,
) async =>
    (await (db.select(db.peopleDecisions)..where(
              (d) => d.faceId.equals(faceId) & d.personId.equals(personId),
            ))
            .getSingleOrNull())
        ?.decision;

void main() {
  group('buildSamePersonQuestions', () {
    test('automatic faces in named people come first, beside a confirmed '
        'face', () {
      final questions = buildSamePersonQuestions(
        SamePersonInput(
          groups: [
            FaceGroupInput(
              personId: 'asha',
              named: true,
              faces: [
                face('m1', 'p1', 0),
                face('m2', 'p2', 80),
                face('a1', 'p3', 10),
              ],
              photoIds: {'p1', 'p2', 'p3'},
              confirmedFaceIds: ['m1', 'm2'],
              size: 3,
            ),
            FaceGroupInput(
              personId: 'g1',
              named: false,
              faces: [face('g1a', 'p4', 5)],
              photoIds: {'p4'},
              size: 1,
            ),
          ],
          automaticFaces: [('asha', face('a1', 'p3', 10))],
        ),
      );
      expect(questions.first.kind, SamePersonKind.verifyAutomatic);
      expect(questions.first.leftPersonId, 'asha');
      expect(questions.first.rightFaceId, 'a1');
      // The closest confirmed face, never another automatic one.
      expect(questions.first.leftFaceId, 'm1');
      expect(questions[1].kind, SamePersonKind.mergeGroups);
    });

    test('a named person whose confirmed faces are all small is still '
        'verified', () {
      final questions = buildSamePersonQuestions(
        SamePersonInput(
          groups: [
            FaceGroupInput(
              personId: 'ben',
              named: true,
              faces: [face('a1', 'p3', 10)],
              confirmedFaceIds: ['small-1'],
              photoIds: {'p1', 'p3'},
              size: 2,
            ),
          ],
          automaticFaces: [('ben', face('a1', 'p3', 10))],
        ),
      );
      expect(questions.single.leftFaceId, 'small-1');
    });

    test('group pairs: closest first, never sharing a photo, never two '
        'named people, named group on the left, answered pairs skipped', () {
      FaceGroupInput g(
        String id,
        double degrees,
        String photo, {
        bool named = false,
        int size = 1,
      }) => FaceGroupInput(
        personId: id,
        named: named,
        faces: [face('$id-f', photo, degrees)],
        photoIds: {photo},
        confirmedFaceIds: named ? ['$id-f'] : const [],
        size: size,
      );
      final input = SamePersonInput(
        groups: [
          g('asha', 0, 'p1', named: true),
          g('ben', 2, 'p2', named: true),
          g('g-near', 5, 'p3'),
          g('g-far', 60, 'p4', size: 9),
          g('g-same-photo', 1, 'p1'),
        ],
      );
      final questions = buildSamePersonQuestions(input);
      final pairs = [
        for (final q in questions) '${q.leftPersonId}|${q.rightPersonId}',
      ];
      expect(pairs, isNot(contains('asha|ben')));
      expect(pairs, isNot(contains('asha|g-same-photo')));
      // g-same-photo shares a photo only with asha, so ben may still ask.
      expect(pairs.first, 'ben|g-same-photo');
      expect(
        questions.map((q) => q.similarity).toList(),
        orderedEquals(
          [...questions.map((q) => q.similarity)]
            ..sort((a, b) => b.compareTo(a)),
        ),
      );
      // The larger unnamed group anchors a pair of two unnamed groups.
      expect(pairs, contains('g-far|g-near'));
      final answered = buildSamePersonQuestions(
        SamePersonInput(
          groups: input.groups,
          decided: {
            'g-near-f': {'ben'},
          },
        ),
      );
      expect(
        answered.map((q) => '${q.leftPersonId}|${q.rightPersonId}'),
        isNot(contains('ben|g-near')),
      );
      expect(
        buildSamePersonQuestions(
          SamePersonInput(groups: input.groups, limit: 2),
        ),
        hasLength(2),
      );
      expect(
        () => buildSamePersonQuestions(const SamePersonInput(limit: 0)),
        throwsArgumentError,
      );
    });
  });

  test('pairs less alike than any reviewed same-person pair are not asked', () {
    FaceGroupInput g(String id, double degrees, String photo) => FaceGroupInput(
      personId: id,
      named: false,
      faces: [face('$id-f', photo, degrees)],
      photoIds: {photo},
      size: 1,
    );
    final groups = [g('g1', 0, 'p1'), g('g2', 20, 'p2'), g('g3', 80, 'p3')];
    final all = buildSamePersonQuestions(SamePersonInput(groups: groups));
    expect(all, hasLength(3));
    // cos(20°) ≈ 0.94 is kept; cos(60°) = 0.5 and cos(80°) ≈ 0.17 are not.
    final floored = buildSamePersonQuestions(
      SamePersonInput(groups: groups, minSimilarity: 0.6),
    );
    expect(floored.map((q) => {q.leftPersonId, q.rightPersonId}), [
      {'g1', 'g2'},
    ]);
  });

  group('answerSamePerson', () {
    late AppDatabase db;
    late PeopleRepository repo;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PeopleRepository(db);
      await repo.enable();
    });
    tearDown(() => db.close());

    Future<String> namedWithAutomatic() async {
      await addVectorFaces(repo, 'p-1', {'m1': axis(0)});
      await addVectorFaces(repo, 'p-2', {'a1': axis(0)});
      final asha = await repo.createPerson(['m1'], name: 'Asha');
      await markAutomatic(db, ['a1'], asha);
      return asha;
    }

    test('Yes confirms an automatic face; it is not asked again', () async {
      final asha = await namedWithAutomatic();
      final question = (await repo.samePersonQuestions()).single;
      expect(question.kind, SamePersonKind.verifyAutomatic);
      await repo.answerSamePerson(question, SamePersonAnswer.yes);
      final a1 = await faceRow(db, 'a1');
      expect(a1.personId, asha);
      expect(a1.assignment, 'manual');
      expect(await decision(db, 'a1', asha), 'accept');
      expect(await repo.samePersonQuestions(), isEmpty);
    });

    test('No removes an automatic face and remembers it', () async {
      final asha = await namedWithAutomatic();
      final question = (await repo.samePersonQuestions()).single;
      await repo.answerSamePerson(question, SamePersonAnswer.no);
      final a1 = await faceRow(db, 'a1');
      expect(a1.personId, isNull);
      expect(a1.assignment, 'unassigned');
      expect(await decision(db, 'a1', asha), 'reject');
      expect(await repo.samePersonQuestions(), isEmpty);
      // The face is no longer suggested for that person either.
      expect((await repo.suggestionsFor(asha)).items, isEmpty);
    });

    test('Not sure changes nothing but is not asked again', () async {
      final asha = await namedWithAutomatic();
      final question = (await repo.samePersonQuestions()).single;
      await repo.answerSamePerson(question, SamePersonAnswer.notSure);
      final a1 = await faceRow(db, 'a1');
      expect(a1.personId, asha);
      expect(a1.assignment, 'automatic');
      expect(await decision(db, 'a1', asha), 'unsure');
      expect(await repo.samePersonQuestions(), isEmpty);
    });

    Future<(String, String)> twoGroups() async {
      await addVectorFaces(repo, 'q-1', {'x1': unitAt(0)});
      await addVectorFaces(repo, 'q-2', {'y1': unitAt(10)});
      await addVectorFaces(repo, 'q-3', {'y2': unitAt(12)});
      final asha = await repo.createPerson(['x1'], name: 'Asha');
      final group = await repo.createPerson(['y1', 'y2']);
      return (asha, group);
    }

    test('Yes merges the unnamed group into the named person', () async {
      final (asha, group) = await twoGroups();
      final question = (await repo.samePersonQuestions()).single;
      expect(question.kind, SamePersonKind.mergeGroups);
      expect(question.leftPersonId, asha);
      expect(question.rightPersonId, group);
      await repo.answerSamePerson(question, SamePersonAnswer.yes);
      final snapshot = await repo.load();
      expect(snapshot.people.map((p) => p.record.id), [asha]);
      expect(await repo.photoIdsFor({asha}), {'q-1', 'q-2', 'q-3'});
      expect(await repo.samePersonQuestions(), isEmpty);
    });

    test('No keeps two groups apart and is remembered both ways', () async {
      final (asha, group) = await twoGroups();
      final question = (await repo.samePersonQuestions()).single;
      await repo.answerSamePerson(question, SamePersonAnswer.no);
      expect(await decision(db, 'y1', asha), 'reject');
      expect(await decision(db, 'x1', group), 'reject');
      expect((await repo.load()).people, hasLength(2));
      expect(await repo.samePersonQuestions(), isEmpty);
    });

    test('Not sure keeps both groups and does not ask again', () async {
      final (asha, group) = await twoGroups();
      final question = (await repo.samePersonQuestions()).single;
      await repo.answerSamePerson(question, SamePersonAnswer.notSure);
      expect(await decision(db, 'y1', asha), 'unsure');
      expect((await repo.load()).people, hasLength(2));
      expect(await repo.samePersonQuestions(), isEmpty);
      // "Unsure" never blocks a later explicit naming.
      await repo.assign(['y1'], asha);
      expect(await decision(db, 'y1', asha), 'accept');
      expect((await faceRow(db, 'y1')).personId, asha);
      expect(group, isNotEmpty);
    });

    test(
      'answers keep processing paused and assign nothing automatically',
      () async {
        final (asha, _) = await twoGroups();
        await repo.pause(true);
        final question = (await repo.samePersonQuestions()).single;
        await repo.answerSamePerson(question, SamePersonAnswer.yes);
        expect((await repo.state()).paused, isTrue);
        expect(await automaticCount(db), 0);
        // Paused People has no pending work, so nothing resumes processing.
        expect(await repo.hasPendingPhotos(), isFalse, reason: asha);
      },
    );

    test('a Not sure answer survives when its group is merged away', () async {
      await addVectorFaces(repo, 'r-1', {'n1': unitAt(0)});
      await addVectorFaces(repo, 'r-2', {'b1': unitAt(14)});
      await addVectorFaces(repo, 'r-3', {'b2': unitAt(16)});
      await addVectorFaces(repo, 'r-4', {'s1': unitAt(30)});
      final asha = await repo.createPerson(['n1'], name: 'Asha');
      final big = await repo.createPerson(['b1', 'b2']);
      final small = await repo.createPerson(['s1']);
      // Not sure: is the small group the same as the big one?
      final unsure = (await repo.samePersonQuestions()).firstWhere(
        (q) => q.leftPersonId == big && q.rightPersonId == small,
      );
      await repo.answerSamePerson(unsure, SamePersonAnswer.notSure);
      // Yes: the big group is Asha. Its earlier "not sure" carries over.
      final yes = (await repo.samePersonQuestions()).firstWhere(
        (q) => q.leftPersonId == asha && q.rightPersonId == big,
      );
      await repo.answerSamePerson(yes, SamePersonAnswer.yes);
      expect(await decision(db, 's1', asha), 'unsure');
      expect(
        (await repo.samePersonQuestions()).where(
          (q) => q.rightPersonId == small,
        ),
        isEmpty,
      );
    });

    test('Yes confirms only the two faces shown; other automatic faces stay '
        'automatic and are asked about next', () async {
      await addVectorFaces(repo, 'm-0', {'x1': unitAt(0)});
      await addVectorFaces(repo, 'm-1', {'y1': unitAt(8)});
      await addVectorFaces(repo, 'm-2', {'y2': unitAt(40)});
      final asha = await repo.createPerson(['x1'], name: 'Asha');
      final group = await repo.createPerson(['y1', 'y2']);
      await markAutomatic(db, ['y1', 'y2'], group);
      final question = (await repo.samePersonQuestions()).firstWhere(
        (q) => q.kind == SamePersonKind.mergeGroups,
      );
      expect(question.rightFaceId, 'y1');
      await repo.answerSamePerson(question, SamePersonAnswer.yes);
      expect((await faceRow(db, 'y1')).assignment, 'manual');
      expect(await decision(db, 'y1', asha), 'accept');
      final y2 = await faceRow(db, 'y2');
      expect(y2.personId, asha);
      expect(y2.assignment, 'automatic');
      expect(await decision(db, 'y2', asha), isNull);
      final next = await repo.samePersonQuestions();
      expect(
        next.where(
          (q) =>
              q.kind == SamePersonKind.verifyAutomatic && q.rightFaceId == 'y2',
        ),
        hasLength(1),
      );
    });

    test('a No outranks an earlier Not sure when groups merge', () async {
      await addVectorFaces(repo, 'n-0', {'a1': unitAt(0)});
      await addVectorFaces(repo, 'n-1', {'u1': unitAt(10)});
      await addVectorFaces(repo, 'n-2', {'v1': unitAt(12)});
      final asha = await repo.createPerson(['a1'], name: 'Asha');
      final u = await repo.createPerson(['u1']);
      final v = await repo.createPerson(['v1']);
      Future<SamePersonQuestion> pair(String left, String right) async =>
          (await repo.samePersonQuestions()).firstWhere(
            (q) => {q.leftPersonId, q.rightPersonId}.containsAll({left, right}),
          );
      await repo.answerSamePerson(
        await pair(asha, u),
        SamePersonAnswer.notSure,
      );
      await repo.answerSamePerson(await pair(u, v), SamePersonAnswer.no);
      await repo.answerSamePerson(await pair(asha, v), SamePersonAnswer.yes);
      // U is not V, V is Asha, so U is not Asha: the reject must win.
      expect(await decision(db, 'u1', asha), 'reject');
    });

    test('a named group with only automatic faces is checked against its '
        'cover', () async {
      await addVectorFaces(repo, 'c-0', {'c1': unitAt(0)});
      await addVectorFaces(repo, 'c-1', {'c2': unitAt(5)});
      final ben = await repo.createPerson(['c1', 'c2'], name: 'Ben');
      await markAutomatic(db, ['c1', 'c2'], ben);
      await repo.editPerson(ben, coverFaceId: 'c1');
      final questions = await repo.samePersonQuestions();
      final verify = questions.where(
        (q) => q.kind == SamePersonKind.verifyAutomatic,
      );
      expect(verify.map((q) => q.rightFaceId), ['c2']);
      expect(verify.single.leftFaceId, 'c1');
    });
    test('a stale question fails closed', () async {
      final (_, group) = await twoGroups();
      final question = (await repo.samePersonQuestions()).single;
      await repo.deletePerson(group);
      expect(
        () => repo.answerSamePerson(question, SamePersonAnswer.yes),
        throwsStateError,
      );
    });

    test('a group pair whose compared face has moved fails closed and '
        'changes nothing', () async {
      final (asha, group) = await twoGroups();
      final question = (await repo.samePersonQuestions()).single;
      expect(question.rightFaceId, 'y1');
      // The compared face leaves its group; the group itself still exists.
      await repo.assign(['y1'], null);
      for (final answer in SamePersonAnswer.values) {
        await expectLater(
          repo.answerSamePerson(question, answer),
          throwsStateError,
        );
      }
      expect(await repo.photoIdsFor({asha}), {'q-1'});
      expect(await repo.photoIdsFor({group}), {'q-3'});
      expect(await decision(db, 'y2', asha), isNull);
    });
  });

  testWidgets('the Same person? card shows both faces and three answers', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = PeopleRepository(db);
    late String asha;
    await tester.runAsync(() async {
      await repo.enable();
      await addVectorFaces(repo, 'q-1', {'x1': unitAt(0)});
      await addVectorFaces(repo, 'q-2', {'y1': unitAt(10)});
      asha = await repo.createPerson(['x1'], name: 'Asha');
      await repo.createPerson(['y1']);
    });
    final scope = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        peopleRepositoryProvider.overrideWithValue(repo),
        peopleControllerProvider.overrideWith(
          (ref) => IdlePeople(ref, repo, PeopleService(repo)),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      scope.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: const MaterialApp(home: SamePersonScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(() async {
        await scope.read(peopleSnapshotProvider.future);
        await scope.read(samePersonQuestionsProvider.future);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('Is this Asha?'), findsOneWidget);
    expect(find.byKey(const ValueKey('same-person-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('same-person-right')), findsOneWidget);
    expect(find.byKey(const ValueKey('same-person-no')), findsOneWidget);
    expect(find.byKey(const ValueKey('same-person-unsure')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('same-person-yes')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settle();
    expect(find.byKey(const ValueKey('same-person-empty')), findsOneWidget);
    expect(await tester.runAsync(() => repo.photoIdsFor({asha})), {
      'q-1',
      'q-2',
    });
    expect(tester.takeException(), isNull);
  });

  group('rounds of questions (Google-style prompts)', () {
    late AppDatabase db;
    late PeopleRepository repo;
    late ProviderContainer scope;

    Future<void> pumpScreen(
      WidgetTester tester,
      Widget home, {
      List<Override> overrides = const [],
      PeopleRepository Function(AppDatabase db) makeRepo = PeopleRepository.new,
    }) async {
      await tester.runAsync(() async {
        db = AppDatabase(NativeDatabase.memory());
        repo = makeRepo(db);
        await repo.enable();
        // Four unnamed look-alike groups in four photos: six possible pairs.
        for (var i = 0; i < 4; i++) {
          await addVectorFaces(repo, 'r-$i', {'r$i': unitAt(i * 3.0)});
          await repo.createPerson(['r$i']);
        }
      });
      scope = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          peopleRepositoryProvider.overrideWithValue(repo),
          peopleControllerProvider.overrideWith(
            (ref) => IdlePeople(ref, repo, PeopleService(repo)),
          ),
          samePersonSessionSizeProvider.overrideWithValue(2),
          ...overrides,
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        scope.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(home: home),
        ),
      );
      await settle(tester);
    }

    Future<void> answer(WidgetTester tester, String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await settle(tester);
    }

    String? currentPair(WidgetTester tester) {
      final card = tester.widget<SamePersonCard>(find.byType(SamePersonCard));
      return '${card.question.leftPersonId}|${card.question.rightPersonId}';
    }

    testWidgets('a round stops after its questions; Keep going asks more, '
        'and no question is ever repeated', (tester) async {
      await pumpScreen(tester, const SamePersonScreen());
      expect(find.text('Question 1 of 2'), findsOneWidget);
      final seen = <String?>{currentPair(tester)};
      await answer(tester, 'same-person-no');
      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(seen.add(currentPair(tester)), isTrue);
      await answer(tester, 'same-person-unsure');
      // The round of 2 is done; the rest waits for the next launch.
      expect(find.byKey(const ValueKey('same-person-empty')), findsOneWidget);
      expect(find.byType(SamePersonCard), findsNothing);
      await tester.tap(find.byKey(const ValueKey('same-person-more')));
      await settle(tester);
      expect(seen.add(currentPair(tester)), isTrue, reason: 'never repeated');
      expect(find.text('Question 3 of 4'), findsOneWidget);
    });

    testWidgets('the home prompt asks in place and Not now hides it', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SamePersonPrompt())),
      );
      expect(find.byKey(const ValueKey('same-person-prompt')), findsOneWidget);
      expect(find.text('Same or different person?'), findsOneWidget);
      expect(find.textContaining('1 of 2'), findsOneWidget);
      final first = currentPair(tester);
      await answer(tester, 'same-person-no');
      expect(find.textContaining('2 of 2'), findsOneWidget);
      expect(currentPair(tester), isNot(first));
      await tester.tap(find.byKey(const ValueKey('same-person-not-now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('same-person-prompt')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the home prompt disappears when the round is answered', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SamePersonPrompt())),
      );
      await answer(tester, 'same-person-no');
      await answer(tester, 'same-person-unsure');
      expect(find.byKey(const ValueKey('same-person-prompt')), findsNothing);
      expect(scope.read(samePersonAnsweredProvider), 2);
    });

    testWidgets('the home prompt takes no answer until the next question '
        'loads', (tester) async {
      var next = Completer<void>()..complete();
      await pumpScreen(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SamePersonPrompt())),
        overrides: [
          samePersonQuestionsProvider.overrideWith((ref) async {
            final snapshot = await ref.watch(peopleSnapshotProvider.future);
            await next.future;
            return repo.samePersonQuestions(snapshot: snapshot, limit: 1000);
          }),
        ],
      );
      FilledButton yes() => tester.widget<FilledButton>(
        find.byKey(const ValueKey('same-person-yes')),
      );
      TextButton open() => tester.widget<TextButton>(
        find.byKey(const ValueKey('same-person-open')),
      );
      final first = currentPair(tester);
      next = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('same-person-no')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      // The answered pair is still on screen, but cannot be answered again,
      // here or on the full screen.
      expect(scope.read(samePersonAnsweredProvider), 1);
      expect(currentPair(tester), first);
      expect(yes().onPressed, isNull);
      expect(open().onPressed, isNull);
      next.complete();
      await settle(tester);
      expect(currentPair(tester), isNot(first));
      expect(yes().onPressed, isNotNull);
      expect(open().onPressed, isNotNull);
    });

    // The prompt above the full screen, as when the screen is opened from it.
    const both = Scaffold(
      body: Column(
        children: [
          SamePersonPrompt(),
          Expanded(child: SamePersonScreen()),
        ],
      ),
    );

    testWidgets('while an answer saves, neither the prompt nor the full '
        'screen takes another', (tester) async {
      final gate = Completer<void>();
      await pumpScreen(
        tester,
        both,
        makeRepo: (db) => _SlowAnswers(db, gate.future),
      );
      final yes = find.byKey(const ValueKey('same-person-yes'));
      expect(yes, findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('same-person-no')).first);
      await tester.pump();
      expect(scope.read(samePersonSavingProvider), isTrue);
      for (final button in tester.widgetList<FilledButton>(yes)) {
        expect(button.onPressed, isNull);
      }
      gate.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await settle(tester);
      expect(scope.read(samePersonSavingProvider), isFalse);
      expect(scope.read(samePersonAnsweredProvider), 1);
      for (final button in tester.widgetList<FilledButton>(yes)) {
        expect(button.onPressed, isNotNull);
      }
    });

    testWidgets('if the next question fails to load, the answered pair is '
        'not shown again', (tester) async {
      var fail = false;
      await pumpScreen(
        tester,
        both,
        overrides: [
          samePersonQuestionsProvider.overrideWith((ref) async {
            final snapshot = await ref.watch(peopleSnapshotProvider.future);
            if (fail) throw StateError('questions failed');
            return repo.samePersonQuestions(snapshot: snapshot, limit: 1000);
          }),
        ],
      );
      expect(find.byType(SamePersonCard), findsNWidgets(2));
      fail = true;
      await tester.tap(find.byKey(const ValueKey('same-person-no')).first);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await scope.read(peopleSnapshotProvider.future);
        await scope
            .read(samePersonQuestionsProvider.future)
            .then<void>((_) {}, onError: (_) {});
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(scope.read(samePersonAnsweredProvider), 1);
      expect(find.byType(SamePersonCard), findsNothing);
      expect(find.byKey(const ValueKey('same-person-prompt')), findsNothing);
      expect(find.text('Questions are unavailable.'), findsOneWidget);
    });
  });
}

/// Holds every answer until [gate] completes, to observe a save in progress.
class _SlowAnswers extends PeopleRepository {
  _SlowAnswers(super.db, this.gate);
  final Future<void> gate;

  @override
  Future<void> answerSamePerson(
    SamePersonQuestion question,
    SamePersonAnswer answer,
  ) async {
    await gate;
    return super.answerSamePerson(question, answer);
  }
}

Future<void> settle(WidgetTester tester) async {
  final scope = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await tester.runAsync(() async {
    await scope.read(peopleSnapshotProvider.future);
    await scope.read(samePersonQuestionsProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}
