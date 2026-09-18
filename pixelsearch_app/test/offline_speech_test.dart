import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/offline_speech.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/features/search/offline_speech_setup.dart';
import 'package:pixelsearch/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(OfflineSpeechClient.channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'support') {
        return {
          'requested': (call.arguments as Map)['language'],
          'installed': ['en-US'],
          'pending': <String>[],
          'downloadable': ['en-IN', 'hi-IN'],
        };
      }
      if (call.method == 'download') return 'scheduled';
      return null;
    });
  });
  tearDown(
    () => messenger.setMockMethodCallHandler(OfflineSpeechClient.channel, null),
  );
  UserPreferences preferences() =>
      UserPreferences(read: () async => null, write: (_) async {});

  test(
    'support exposes variants without silently changing requested language',
    () async {
      final support = await const OfflineSpeechClient().support('en-IN');
      expect(support.ready, isFalse);
      expect(support.canDownload, isTrue);
      expect(support.choices, ['en-IN', 'en-US']);
      expect(calls.map((c) => c.method), ['support']);
    },
  );
  test('pending language is not ready and malformed responses fail closed', () {
    final s = OfflineSpeechSupport.parse({
      'requested': 'hi-IN',
      'installed': [],
      'pending': ['hi-IN'],
      'downloadable': ['hi-IN'],
    });
    expect(s.ready, isFalse);
    expect(s.scheduled, isTrue);
    expect(s.canDownload, isFalse);
    expect(
      () => OfflineSpeechSupport.parse({
        'requested': 'hi-IN',
        'installed': 'hi-IN',
      }),
      throwsFormatException,
    );
  });
  test(
    'language download requires explicit consent and offline switch off',
    () async {
      final policy = OnlinePolicy(preferences());
      await policy.load();
      const client = OfflineSpeechClient();
      await expectLater(
        client.download('en-IN', policy, confirmed: true),
        throwsStateError,
      );
      await policy.update(offline: false);
      await expectLater(
        client.download('en-IN', policy, confirmed: false),
        throwsStateError,
      );
      expect(calls, isEmpty);
      expect(
        await client.download('en-IN', policy, confirmed: true),
        'scheduled',
      );
      expect(calls.single.method, 'download');
      expect((calls.single.arguments as Map)['confirmed'], true);
      expect(policy.enabled, isEmpty);
      policy.dispose();
    },
  );
  test('platform errors never expose PlatformException wrapper', () {
    expect(
      speechError(
        PlatformException(
          code: 'language_missing',
          message: 'Open offline speech setup.',
        ),
      ),
      'Open offline speech setup.',
    );
    expect(
      speechError(PlatformException(code: 'unavailable')),
      isNot(contains('PlatformException')),
    );
  });
  test(
    'explicit speech choice survives reload without changing other preferences',
    () async {
      String? contents = jsonEncode({
        'online_settings': {'offline': true},
        'label_corrections': {
          'fixture': ['dog'],
        },
      });
      UserPreferences create() => UserPreferences(
        read: () async => contents,
        write: (text) async {
          contents = text;
        },
      );
      final first = create();
      await first.load();
      expect(first.offlineSpeechLocale('English'), 'en-IN');
      await first.saveOfflineSpeechLocale('English', 'en-US');
      final reloaded = create();
      await reloaded.load();
      expect(reloaded.offlineSpeechLocale('English'), 'en-US');
      expect(reloaded.offlineSpeechLocale('Hindi'), 'hi-IN');
      expect(reloaded.onlineSettings, {'offline': true});
      expect((jsonDecode(contents!) as Map)['label_corrections'], {
        'fixture': ['dog'],
      });
      expect(
        () => reloaded.saveOfflineSpeechLocale('English', 'hi-IN'),
        throwsArgumentError,
      );
    },
  );
  test(
    'offline revocation cancels pending native setup and ignores late completion',
    () async {
      final pending = Completer<String>();
      messenger.setMockMethodCallHandler(OfflineSpeechClient.channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'download' ? pending.future : null;
      });
      final policy = OnlinePolicy(preferences());
      await policy.load();
      await policy.update(offline: false);
      final result = expectLater(
        const OfflineSpeechClient().download('en-IN', policy, confirmed: true),
        throwsStateError,
      );
      await Future<void>.delayed(Duration.zero);
      await policy.update(offline: true);
      pending.complete('installed');
      await result;
      expect(calls.map((c) => c.method), ['download', 'cancel']);
      policy.dispose();
    },
  );
  testWidgets(
    'setup at narrow large-text viewport reports installed alternatives without downloading',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final policy = OnlinePolicy(preferences());
      await policy.load();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [onlinePolicyProvider.overrideWith((ref) => policy)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(body: OfflineSpeechSetup(language: 'en-IN')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Installed languages: en-US'), findsOneWidget);
      expect(
        find.text('Offline only is on. Downloads are disabled.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('en-US').last);
      await tester.pumpAndSettle();
      expect(find.text('Ready on this phone'), findsOneWidget);
      expect(find.text('Use language'), findsOneWidget);
      expect(
        calls.any((c) => c.method == 'download' || c.method == 'recognize'),
        false,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
