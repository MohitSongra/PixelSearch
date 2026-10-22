import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/domain/search/search_response.dart';
import 'package:pixelsearch/features/timeline/timeline_screen.dart';
import 'package:pixelsearch/features/map/map_screen.dart';
import 'package:pixelsearch/features/settings/online_settings.dart';
import 'package:pixelsearch/features/viewer/caption_screen.dart';
import 'package:pixelsearch/features/viewer/search_explanation.dart';
import 'package:pixelsearch/features/search/conversation_sheet.dart';
import 'package:pixelsearch/models/photo.dart';
import 'package:pixelsearch/state/providers.dart';

import 'support/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('map attribution remains visible at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(body: MapAttribution()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('\u00a9 OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  setUpAll(loadTestFonts);
  final fixture = Photo(
    id: 'fixture',
    assetName: 'assets/samples/beach_sunset.jpg',
    title: 'A beach photo',
    caption: 'A beach at sunset.',
    tags: [],
    date: DateTime(2026, 9, 9),
    album: 'Camera',
    source: PhotoSource.sample,
  );
  final response = SearchResponse(
    request: const SearchRequest('beach at sunset'),
    photos: [fixture],
    mode: 'semantic',
    explanations: {
      'fixture': {
        'cosine': .25,
        'cosine_used': .25,
        'semantic': .71,
        'lexical': .2,
        'face': 0.0,
        'score': .547,
        'weighted': {'semantic': .497, 'lexical': .05, 'face': 0.0},
        'mlkit_labels_used': false,
        'matching_terms': ['beach'],
        'gate': .15,
        'pool': 60,
      },
    },
  );

  for (final size in [const Size(320, 740), const Size(412, 915)]) {
    testWidgets('five features render without overflow at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (call) async {
          if (call.method == 'create') {
            final id = (call.arguments as Map)['recorderId'];
            messenger.setMockMethodCallHandler(
              MethodChannel('com.llfbandit.record/events/$id'),
              (_) async => null,
            );
          }
          return null;
        },
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('pixelsearch/on_device_speech'),
        (_) async => null,
      );
      final db = AppDatabase(NativeDatabase.memory());
      await PhotoRepository(db).savePhotos([fixture]);
      final scope = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          userPreferencesProvider.overrideWithValue(
            UserPreferences(read: () async => null, write: (_) async {}),
          ),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await db.close();
      });
      final screens = <String, Widget>{
        'timeline': const TimelineScreen(),
        'explanation': Scaffold(
          body: SearchExplanation(response: response, photoId: 'fixture'),
        ),
        'map_empty': const MapScreen(),
        'caption': CaptionScreen(photo: fixture),
        'conversation': const Scaffold(body: ConversationSheet()),
        'privacy': const Scaffold(
          body: SingleChildScrollView(child: OnlineSettings()),
        ),
      };
      for (final entry in screens.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: MaterialApp(
              builder: (_, child) => MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(size.width == 320 ? 1.4 : 1),
                ),
                child: child!,
              ),
              home: RepaintBoundary(key: key, child: entry.value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = await Directory(
            'build/feature_screenshots',
          ).create(recursive: true);
          await File(
            '${directory.path}/${entry.key}_${size.width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull, reason: entry.key);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
