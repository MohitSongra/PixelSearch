import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/core/theme.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/memory_repository.dart';
import 'package:pixelsearch/domain/timeline/memory_grouping.dart';
import 'package:pixelsearch/domain/timeline/memory_stories.dart';
import 'package:pixelsearch/features/timeline/memory_story_viewer.dart';
import 'package:pixelsearch/features/timeline/timeline_photo_image.dart';
import 'package:pixelsearch/features/timeline/timeline_screen.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo(String id, DateTime date, {int faces = 0, String? asset}) => Photo(
  id: id,
  title: 'Photo $id',
  caption: '',
  tags: const [],
  date: date,
  album: 'Camera',
  source: PhotoSource.sample,
  assetName: asset ?? 'assets/samples/beach_sunset.jpg',
  faceCount: faces,
);

List<MemoryGroup> fixtures() => [
  MemoryGroup(id: 'older', photos: [photo('old', DateTime(2022, 2, 1))]),
  MemoryGroup(
    id: 'trip',
    title: 'A saved memory',
    coverId: 'second',
    photos: [
      photo('first', DateTime(2024, 4, 2), faces: 1),
      photo('second', DateTime(2024, 4, 3)),
      photo('third', DateTime(2024, 4, 4), faces: 2),
    ],
  ),
  MemoryGroup(id: 'april', photos: [photo('later', DateTime(2024, 4, 25))]),
  MemoryGroup(id: 'december', photos: [photo('dec', DateTime(2024, 12, 1))]),
  MemoryGroup(id: 'latest', photos: [photo('new', DateTime(2026, 9, 9))]),
];

MemoryStory story({int year = 2024, int count = 3}) => MemoryTimeline([
  MemoryGroup(
    id: 'story',
    photos: List.generate(count, (i) => photo('p$i', DateTime(year, 4, i + 1))),
  ),
]).story(year)!;

Finder control(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == tooltip,
);

class EditableMemories extends MemoryRepository {
  EditableMemories(super.db, this.events);
  List<MemoryGroup> events;
  final edits = <({String id, String? title, String? cover})>[];

  @override
  Future<void> edit(String id, {String? title, String? coverId}) async {
    edits.add((id: id, title: title, cover: coverId));
    events = [
      for (final e in events)
        if (e.id == id)
          MemoryGroup(
            id: e.id,
            photos: e.photos,
            title: title?.trim() ?? e.title,
            coverId: coverId ?? e.coverId,
          )
        else
          e,
    ];
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  GlobalKey? screenshotKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light().copyWith(
        appBarTheme: AppTheme.light().appBarTheme.copyWith(
          titleTextStyle: AppTheme.light().appBarTheme.titleTextStyle!.copyWith(
            fontFamily: 'Roboto',
          ),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(key: screenshotKey, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

Widget timeline(List<MemoryGroup> events) => ProviderScope(
  overrides: [memoriesProvider.overrideWith((ref) async => events)],
  child: const TimelineScreen(),
);

Future<void> chooseYear(WidgetTester tester, int current, int next) async {
  await tester.tap(find.byKey(ValueKey('timeline-year-$current')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$next').last);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await Directory(
      'build/timeline_screenshots',
    ).create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  testWidgets('empty timeline never fabricates a year or a story', (
    tester,
  ) async {
    await mount(tester, timeline([]));
    expect(find.text('No indexed memories yet'), findsOneWidget);
    expect(find.text('Back in 2024'), findsNothing);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
  });

  testWidgets('year/month navigation uses actual years and exact dates', (
    tester,
  ) async {
    await mount(tester, timeline(fixtures()));
    expect(find.text('Back in 2026'), findsOneWidget);
    expect(find.text('Back in 2024'), findsNothing);
    await chooseYear(tester, 2026, 2024);
    expect(find.text('Back in 2024'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timeline-month-2024-null')));
    await tester.pumpAndSettle();
    expect(find.text('January 2024'), findsNothing);
    await tester.tap(find.text('April 2024').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('memory-trip')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2 Apr 2024 - 4 Apr 2024'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-december')), findsNothing);
    final card = find.byKey(const ValueKey('memory-trip'));
    expect(
      find.descendant(of: card, matching: find.text('A saved memory')),
      findsOneWidget,
    );
    final cover = tester.widget<TimelinePhotoImage>(
      find.descendant(of: card, matching: find.byType(TimelinePhotoImage)),
    );
    expect(cover.photo.id, 'second');
  });

  testWidgets(
    'no-face year disables people and sparse year has a single frame',
    (tester) async {
      await mount(tester, timeline(fixtures()));
      final selector = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(selector.segments.singleWhere((s) => s.value).enabled, isFalse);
      await tester.tap(find.byKey(const ValueKey('open-memory-story')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 1'), findsOneWidget);
      expect(
        tester.widget<IconButton>(control('Play story')).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(control('Next photo')).onPressed,
        isNull,
      );
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('1 of 1'), findsOneWidget);
    },
  );

  testWidgets(
    'people story contains only detected-face photos in chosen year',
    (tester) async {
      // Scope surrounds the Navigator as it does in the app.
      final container = ProviderContainer(
        overrides: [memoriesProvider.overrideWith((ref) async => fixtures())],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await chooseYear(tester, 2026, 2024);
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();
      expect(find.text('People in 2024'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-memory-story')));
      await tester.pumpAndSettle();
      final viewer = tester.widget<MemoryStoryViewer>(
        find.byType(MemoryStoryViewer),
      );
      expect(viewer.story.photos.map((p) => p.id), ['first', 'third']);
      expect(find.text('1 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Close story'));
      await tester.pumpAndSettle();
      expect(find.text('People in 2024'), findsOneWidget);
    },
  );

  testWidgets('playback is opt-in, finite and manual navigation pauses it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await mount(tester, MemoryStoryViewer(story: story()));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('1 of 3'), findsOneWidget);
      expect(
        tester.widget<IconButton>(control('Previous photo')).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Play story'));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('2 of 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause story'));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('2 of 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Play story'));
      await tester.tap(find.byTooltip('Previous photo'));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('1 of 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Next photo'));
      await tester.pump();
      await tester.tap(find.byTooltip('Play story'));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('3 of 3'), findsOneWidget);
      expect(
        tester.widget<IconButton>(control('Next photo')).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(control('Play story')).onPressed,
        isNull,
      );
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.byType(TimelinePhotoImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'closing a playing story preserves year selection and cancels playback',
    (tester) async {
      await mount(tester, timeline(fixtures()));
      await chooseYear(tester, 2026, 2024);
      await tester.tap(find.byKey(const ValueKey('open-memory-story')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play story'));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('2 of 5'), findsOneWidget);
      await tester.tap(find.byTooltip('Close story'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Back in 2024'), findsOneWidget);
      expect(find.byType(MemoryStoryViewer), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-memory-story')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh removes unavailable years without inventing replacement memories',
    (tester) async {
      var events = fixtures();
      final container = ProviderContainer(
        overrides: [memoriesProvider.overrideWith((ref) async => events)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await chooseYear(tester, 2026, 2024);
      events = [events.first];
      container.invalidate(memoriesProvider);
      await tester.pumpAndSettle();
      expect(find.text('Back in 2022'), findsOneWidget);
      expect(find.text('Back in 2024'), findsNothing);
      expect(find.byKey(const ValueKey('timeline-year-2022')), findsOneWidget);
      events = [];
      container.invalidate(memoriesProvider);
      await tester.pumpAndSettle();
      expect(find.text('No indexed memories yet'), findsOneWidget);
    },
  );

  testWidgets('backgrounding and disposal cancel playback timers', (
    tester,
  ) async {
    await mount(tester, MemoryStoryViewer(story: story()));
    await tester.tap(find.byTooltip('Play story'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('1 of 3'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Play story'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a playing story resets selection and timer', (
    tester,
  ) async {
    await mount(tester, MemoryStoryViewer(story: story()));
    await tester.tap(find.byTooltip('Play story'));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('2 of 3'), findsOneWidget);
    await mount(tester, MemoryStoryViewer(story: story(year: 2022, count: 1)));
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Back in 2022'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rename and choose-cover still target the original saved event', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = EditableMemories(db, fixtures());
    final scope = ProviderContainer(
      overrides: [
        memoryRepositoryProvider.overrideWithValue(repo),
        memoriesProvider.overrideWith((ref) async => repo.events),
      ],
    );
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: const MaterialApp(home: TimelineScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await chooseYear(tester, 2026, 2024);
    final event = find.byKey(const ValueKey('memory-trip'));
    await tester.scrollUntilVisible(
      event,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(event);
    await tester.pumpAndSettle();
    expect(find.byType(MemoryDetail), findsOneWidget);
    await tester.tap(find.byTooltip('Rename memory'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'A name I chose');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('A name I chose'), findsOneWidget);
    await tester.tap(find.byTooltip('Choose cover'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Use photo 3 as cover'));
    await tester.pumpAndSettle();
    expect(repo.edits, [
      (id: 'trip', title: 'A name I chose', cover: null),
      (id: 'trip', title: null, cover: 'third'),
    ]);
    final saved = repo.events.singleWhere((e) => e.id == 'trip');
    expect(saved.title, 'A name I chose');
    expect(saved.coverId, 'third');
    expect(saved.photos.map((p) => p.id), ['first', 'second', 'third']);
  });

  testWidgets('unavailable thumbnails fail gracefully', (tester) async {
    await mount(
      tester,
      Scaffold(
        body: TimelinePhotoImage(
          photo: photo(
            'missing',
            DateTime(2024),
            asset: 'assets/samples/not-present.jpg',
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (size: const Size(320, 740), scale: 2.0),
    (size: const Size(412, 915), scale: 1.0),
    (size: const Size(1000, 800), scale: 1.0),
  ]) {
    testWidgets(
      'timeline and story fit ${config.size} at ${config.scale}x text',
      (tester) async {
        tester.view.physicalSize = config.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await mount(
          tester,
          timeline(fixtures()),
          scale: config.scale,
          screenshotKey: key,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'timeline_${config.size.width.toInt()}');
        await tester.tap(
          find.byKey(const ValueKey('timeline-month-2026-null')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('September 2026').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('memory-latest')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('9 Sep 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await mount(
          tester,
          MemoryStoryViewer(story: story()),
          scale: config.scale,
          screenshotKey: key,
        );
        await capture(tester, key, 'story_${config.size.width.toInt()}');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Next photo'));
        await tester.pump();
        expect(find.text('2 of 3'), findsOneWidget);
      },
    );
  }

  testWidgets('story controls remain reachable in landscape with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, MemoryStoryViewer(story: story()), scale: 2);
    await tester.ensureVisible(find.byTooltip('Next photo'));
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pump();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
