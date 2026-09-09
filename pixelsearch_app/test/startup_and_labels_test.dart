import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/features/onboarding/startup_screen.dart';
import 'package:pixelsearch/features/viewer/label_editor.dart';
import 'package:pixelsearch/state/providers.dart';

import 'user_preferences_test.dart' show photo;

void main() {
  testWidgets('startup waits for saved state without flashing onboarding', (
    tester,
  ) async {
    final ready = Completer<bool>();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const StartupScreen()),
        GoRoute(
          path: '/home/search',
          builder: (_, _) => const Scaffold(body: Text('Search home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [skipOnboardingProvider.overrideWith((ref) => ready.future)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Index my photos'), findsNothing);
    ready.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Search home'), findsOneWidget);
    expect(find.text('Index my photos'), findsNothing);
  });

  testWidgets('Not now saves setup completion before navigating home', (
    tester,
  ) async {
    String? disk;
    final preferences = UserPreferences(
      read: () async => disk,
      write: (s) async => disk = s,
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const StartupScreen()),
        GoRoute(
          path: '/home/search',
          builder: (_, _) => const Scaffold(body: Text('Search home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(preferences),
          skipOnboardingProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Search home'), findsOneWidget);
    expect(preferences.onboardingComplete, true);
    expect(disk, contains('onboarding_complete'));
  });

  testWidgets('label editor removes a false label and persists a replacement', (
    tester,
  ) async {
    String? disk;
    final preferences = UserPreferences(
      read: () async => disk,
      write: (s) async => disk = s,
    );
    await preferences.load();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => LabelEditor(photo: photo()),
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
    await tester.tap(find.byTooltip('Remove dog'));
    await tester.enterText(find.byType(TextField), 'Document');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(preferences.applyLabelCorrection(photo()).labels, ['document']);
    expect(disk, contains('document'));
    expect(find.byType(LabelEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
