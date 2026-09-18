import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelsearch/data/enhancements/enhancement_client.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/offline_speech.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/people_repository.dart';
import 'package:pixelsearch/state/people_providers.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/features/search/conversation_sheet.dart';
import 'package:pixelsearch/state/providers.dart';

class _Speech extends OfflineSpeechClient {
  final requests = <Completer<String?>>[];
  final languages = <String>[];
  final states = <void Function(String)?>[];
  int stops = 0, cancels = 0;
  @override
  Future<String?> recognize(String language, {void Function(String)? onState}) {
    languages.add(language);
    states.add(onState);
    onState?.call('listening');
    final result = Completer<String?>();
    requests.add(result);
    return result.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}

class _Recorder implements VoiceRecorder {
  _Recorder(this.owner);
  final _Services owner;
  String? path;
  bool active = false;
  int stops = 0, cancels = 0, disposals = 0;
  Future<void>? startGate;
  Future<String?>? stopGate;
  bool stopFails = false, stopNull = false, cleanupFails = false;
  @override
  Future<void> start(String path) async {
    this.path = path;
    await startGate;
    active = true;
    owner.files[path] = Uint8List.fromList(utf8.encode('fixture-audio'));
  }

  @override
  Future<String?> stop() async {
    stops++;
    if (stopFails) throw StateError('Recording failed.');
    if (stopGate != null) return stopGate;
    active = false;
    return stopNull ? null : path;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    active = false;
    if (cleanupFails) throw StateError('Fake cancel failed.');
  }

  @override
  Future<void> dispose() async {
    disposals++;
    if (cleanupFails) throw StateError('Fake dispose failed.');
  }
}

class _Services extends VoiceSearchServices {
  @override
  final _Speech speech = _Speech();
  Future<PermissionStatus> Function() permission = () async =>
      PermissionStatus.granted;
  int permissionCalls = 0, paths = 0;
  final recorders = <_Recorder>[];
  final files = <String, Uint8List>{};
  final deleted = <String>[];
  void Function(_Recorder)? configureRecorder;
  Future<Uint8List>? readGate;
  @override
  Future<PermissionStatus> requestPermission() {
    permissionCalls++;
    return permission();
  }

  @override
  VoiceRecorder createRecorder() {
    final recorder = _Recorder(this);
    configureRecorder?.call(recorder);
    recorders.add(recorder);
    return recorder;
  }

  @override
  Future<String> recordingPath() async => '/fake/voice_${++paths}.m4a';
  @override
  Future<Uint8List> readRecording(String path) async =>
      readGate ?? files[path]!;
  @override
  Future<void> deleteRecording(String path) async {
    deleted.add(path);
    files.remove(path);
  }
}

class _EmptyLibrary extends PhotoLibrary {
  _EmptyLibrary(super.ref);
  @override
  Future<void> refresh() async {}
}

// Simulates a transport that finishes even after the caller cancels it.
class _UncancellableClient extends EnhancementClient {
  _UncancellableClient(super.policy, {super.token, super.client});
  @override
  Future<Map<String, dynamic>> request(
    OnlineFeature feature,
    String path, {
    Map<String, Object?>? json,
    Uint8List? bytes,
    String filename = 'photo.jpg',
    RequestCancellation? cancellation,
  }) => super.request(
    feature,
    path,
    json: json,
    bytes: bytes,
    filename: filename,
  );
}

class _Fixture {
  _Fixture(this.services, this.policy, this.scope, this.requests);
  final _Services services;
  final OnlinePolicy policy;
  final ProviderContainer scope;
  final List<http.Request> requests;
}

Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _flush(tester);
}

Future<_Fixture> _open(
  WidgetTester tester, {
  _Services? services,
  bool auto = false,
  bool online = true,
  bool ignoreCancellation = false,
  Duration timeout = const Duration(seconds: 110),
  Future<http.Response> Function(http.Request)? respond,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  final device = services ?? _Services();
  final preferences = UserPreferences(
    read: () async => '{"offline_speech_locales":{"English":"en-US"}}',
    write: (_) async {},
  );
  final policy = OnlinePolicy(preferences);
  await policy.load();
  if (online) {
    await policy.update(
      offline: false,
      baseUrl: 'https://example.test',
      feature: OnlineFeature.speech,
      allow: true,
    );
    await policy.update(feature: OnlineFeature.assistant, allow: true);
  }
  final requests = <http.Request>[];
  http.Client transport() => MockClient((request) async {
    requests.add(request);
    if (respond != null) return respond(request);
    return http.Response(
      jsonEncode(
        request.url.path == '/assistant'
            ? {'query': 'friends at the beach', 'filters': <String, Object?>{}}
            : {'text': 'friends at the beach'},
      ),
      200,
    );
  });
  final client = ignoreCancellation
      ? _UncancellableClient(
          policy,
          token: () async => 'fixture-token',
          client: transport,
        )
      : EnhancementClient(
          policy,
          token: () async => 'fixture-token',
          client: transport,
        );
  final scope = ProviderContainer(
    overrides: [
      peopleRepositoryProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return PeopleRepository(db);
      }),
      userPreferencesProvider.overrideWithValue(preferences),
      onlinePolicyProvider.overrideWith((ref) => policy),
      enhancementClientProvider.overrideWithValue(client),
      photoLibraryProvider.overrideWith((ref) => _EmptyLibrary(ref)),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ConversationSheet(
                  services: device,
                  startListening: auto,
                  operationTimeout: timeout,
                ),
              ),
              child: const Text('Open voice'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Open voice'));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
    scope.dispose();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  return _Fixture(device, policy, scope, requests);
}

Finder get _message => find.widgetWithText(TextField, 'Query or follow-up');
String _text(WidgetTester tester) =>
    tester.widget<TextField>(_message).controller!.text;

void main() {
  testWidgets('assigned names and explicit person filters never reach the cloud assistant', (tester) async {
    final f = await _open(tester);
    final people = f.scope.read(peopleRepositoryProvider);
    await people.enable();
    await people.db.into(people.db.peoplePersons).insert(PeoplePersonsCompanion.insert(
      id: 'local-person', name: const Value('Mohit'), createdMs: 1));
    await tester.enterText(_message, 'Mohit at the beach');
    await _tap(tester, find.text('Refine / translate online'));
    expect(f.requests, isEmpty);
    expect(find.textContaining('Named people searches stay on this device'), findsOneWidget);
  });
  testWidgets(
    'permission focus loss does not cancel; capture waits for resume',
    (tester) async {
      final permission = Completer<PermissionStatus>();
      final services = _Services()..permission = () => permission.future;
      final f = await _open(tester, services: services, auto: true);
      expect(services.permissionCalls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      permission.complete(PermissionStatus.granted);
      await _flush(tester);
      expect(services.speech.requests, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(services.speech.languages, ['en-US']);
      expect(find.text('Listening on-device'), findsOneWidget);
      await _tap(tester, find.byTooltip('Stop listening'));
      expect(services.speech.stops, 1);
      services.speech.requests.single.complete('two friends');
      await _flush(tester);
      expect(_text(tester), 'two friends');
      await tester.enterText(_message, 'three friends');
      await _tap(tester, find.text('Search text locally'));
      expect(f.scope.read(searchQueryProvider), 'three friends');
      expect(f.requests, isEmpty);
    },
  );

  testWidgets(
    'background during permission cancels without starting after grant',
    (tester) async {
      final permission = Completer<PermissionStatus>();
      final services = _Services()..permission = () => permission.future;
      await _open(tester, services: services, auto: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      permission.complete(PermissionStatus.granted);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(services.speech.requests, isEmpty);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late permission cannot start capture for a replacement operation',
    (tester) async {
      final permission = Completer<PermissionStatus>();
      final services = _Services()..permission = () => permission.future;
      await _open(tester, services: services, auto: true);
      await _tap(tester, find.text('Cancel'));
      services.permission = () async => PermissionStatus.granted;
      await _tap(tester, find.byTooltip('Listen on-device'));
      permission.complete(PermissionStatus.granted);
      await _flush(tester);
      expect(services.speech.requests, hasLength(1));
      expect(find.text('Listening on-device'), findsOneWidget);
      services.speech.requests.single.complete('current');
      await _flush(tester);
      expect(_text(tester), 'current');
    },
  );

  testWidgets(
    'denied and permanently denied permission are actionable and idle',
    (tester) async {
      final services = _Services()
        ..permission = () async => PermissionStatus.denied;
      await _open(tester, services: services, auto: true);
      expect(find.text('Microphone access was not granted.'), findsOneWidget);
      services.permission = () async => PermissionStatus.permanentlyDenied;
      await _tap(tester, find.byTooltip('Listen on-device'));
      expect(
        find.textContaining('Enable it in Android app settings'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(services.speech.requests, isEmpty);
    },
  );

  testWidgets(
    'cancel and new attempt ignore late transcript, state, and old finally',
    (tester) async {
      final f = await _open(tester, auto: true);
      final speech = f.services.speech;
      await _tap(tester, find.text('Cancel'));
      await _tap(tester, find.byTooltip('Listen on-device'));
      speech.requests[0].complete('obsolete');
      speech.states[0]?.call('processing');
      await _flush(tester);
      expect(_text(tester), isEmpty);
      expect(find.text('Listening on-device'), findsOneWidget);
      speech.requests[1].complete('current query');
      await _flush(tester);
      expect(_text(tester), 'current query');
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('deadline clears busy and late recognition cannot revive input', (
    tester,
  ) async {
    final f = await _open(
      tester,
      auto: true,
      timeout: const Duration(seconds: 2),
    );
    await tester.pump(const Duration(seconds: 3));
    await _flush(tester);
    expect(find.textContaining('timed out'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    f.services.speech.requests.single.complete('late');
    await _flush(tester);
    expect(_text(tester), isEmpty);
  });

  testWidgets('new conversation ignores a late assistant proposal', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final f = await _open(
      tester,
      respond: (_) => response.future,
      ignoreCancellation: true,
    );
    await tester.enterText(_message, 'friends');
    await _tap(tester, find.text('Refine / translate online'));
    expect(f.requests, hasLength(1));
    await _tap(tester, find.byTooltip('New conversation'));
    response.complete(http.Response('{"query":"obsolete","filters":{}}', 200));
    await _flush(tester);
    expect(find.text('Apply local search'), findsNothing);
    expect(_text(tester), isEmpty);
    expect(f.scope.read(searchQueryProvider), isEmpty);
  });

  testWidgets(
    'new voice clears an existing proposal; Hindi requires explicit translation',
    (tester) async {
      final f = await _open(tester);
      await tester.enterText(_message, 'friends');
      await _tap(tester, find.text('Refine / translate online'));
      expect(find.text('Apply local search'), findsOneWidget);
      await _tap(tester, find.byTooltip('Listen on-device'));
      expect(find.text('Apply local search'), findsNothing);
      f.services.speech.requests.single.complete('new words');
      await _flush(tester);
      expect(find.text('Apply local search'), findsNothing);
      await _tap(tester, find.byType(DropdownButton<String>));
      await _tap(tester, find.text('Hindi').last);
      await _tap(tester, find.byTooltip('Listen on-device'));
      f.services.speech.requests.last.complete('do dost');
      await _flush(tester);
      expect(f.services.speech.languages.last, 'hi-IN');
      expect(find.text('Search text locally'), findsNothing);
      expect(f.requests, hasLength(1));
      await _tap(tester, find.text('Refine / translate online'));
      expect(jsonDecode(f.requests.last.body)['language'], 'Hindi');
      expect(find.text('Apply local search'), findsOneWidget);
    },
  );

  testWidgets(
    'cloud requires both feature consent and per-recording approval; multipart is real',
    (tester) async {
      final f = await _open(tester, online: false);
      await _tap(tester, find.text('Record for online transcription'));
      expect(f.services.permissionCalls, 0);
      expect(f.services.recorders, isEmpty);
      expect(f.requests, isEmpty);
      await f.policy.update(
        offline: false,
        baseUrl: 'https://example.test',
        feature: OnlineFeature.speech,
        allow: true,
      );
      await _flush(tester);
      await _tap(tester, find.text('Record for online transcription'));
      expect(find.text('Recording audio'), findsOneWidget);
      expect(f.requests, isEmpty);
      await _tap(tester, find.text('Stop recording'));
      expect(find.text('Transcribe this recording online?'), findsOneWidget);
      expect(f.requests, isEmpty);
      await _tap(tester, find.text('Send recording'));
      final request = f.requests.single;
      expect(request.url.path, '/transcribe');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(request.body, contains('name="file"; filename="speech.m4a"'));
      expect(request.body, contains('fixture-audio'));
      expect(request.headers['authorization'], 'Bearer fixture-token');
      expect(_text(tester), 'friends at the beach');
      expect(f.services.files, isEmpty);
      expect(f.services.recorders.single.disposals, greaterThan(0));
    },
  );

  testWidgets('recording permission focus loss continues only after resume', (
    tester,
  ) async {
    final permission = Completer<PermissionStatus>();
    final services = _Services()..permission = () => permission.future;
    await _open(tester, services: services);
    await _tap(tester, find.text('Record for online transcription'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    permission.complete(PermissionStatus.granted);
    await _flush(tester);
    expect(services.recorders, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    expect(find.text('Recording audio'), findsOneWidget);
    await _tap(tester, find.text('Cancel'));
    expect(services.files, isEmpty);
  });

  testWidgets('revoking consent while recorder starts cleans up late capture', (
    tester,
  ) async {
    final start = Completer<void>();
    final services = _Services()
      ..configureRecorder = (r) => r.startGate = start.future;
    final f = await _open(tester, services: services);
    await _tap(tester, find.text('Record for online transcription'));
    await f.policy.update(feature: OnlineFeature.speech, allow: false);
    await _flush(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    start.complete();
    await _flush(tester);
    expect(services.recorders.single.active, isFalse);
    expect(services.files, isEmpty);
    expect(f.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final failure in [
    'throw',
    'null',
    'cancel-dialog',
    'background',
    'dispose',
  ]) {
    testWidgets('recording cleanup on $failure has no upload', (tester) async {
      final f = await _open(tester);
      await _tap(tester, find.text('Record for online transcription'));
      final recorder = f.services.recorders.single;
      if (failure == 'dispose') {
        Navigator.of(tester.element(_message)).pop();
      } else if (failure == 'background') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      } else {
        recorder.stopFails = failure == 'throw';
        recorder.stopNull = failure == 'null';
        await _tap(tester, find.text('Stop recording'));
        if (failure == 'cancel-dialog') {
          await _tap(tester, find.text('Cancel').last);
        }
      }
      await _flush(tester);
      expect(recorder.active, isFalse);
      expect(recorder.disposals, greaterThan(0));
      expect(f.services.files, isEmpty);
      expect(f.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancelled stop cannot open approval over a new recording', (
    tester,
  ) async {
    final stop = Completer<String?>();
    final f = await _open(tester);
    await _tap(tester, find.text('Record for online transcription'));
    final old = f.services.recorders.single..stopGate = stop.future;
    await _tap(tester, find.text('Stop recording'));
    await _tap(tester, find.text('Cancel'));
    await _tap(tester, find.text('Record for online transcription'));
    stop.complete(old.path);
    await _flush(tester);
    expect(find.text('Transcribe this recording online?'), findsNothing);
    expect(find.text('Recording audio'), findsOneWidget);
    expect(f.services.recorders.last.active, isTrue);
    expect(f.services.files.keys, [f.services.recorders.last.path]);
    await _tap(tester, find.text('Cancel'));
  });

  testWidgets(
    'late cloud transcript after reset cannot overwrite a new attempt',
    (tester) async {
      final response = Completer<http.Response>();
      final f = await _open(
        tester,
        respond: (_) => response.future,
        ignoreCancellation: true,
      );
      await _tap(tester, find.text('Record for online transcription'));
      await _tap(tester, find.text('Stop recording'));
      await _tap(tester, find.text('Send recording'));
      await _tap(tester, find.byTooltip('New conversation'));
      await _tap(tester, find.byTooltip('Listen on-device'));
      response.complete(http.Response('{"text":"obsolete"}', 200));
      await _flush(tester);
      expect(_text(tester), isEmpty);
      expect(find.text('Listening on-device'), findsOneWidget);
      expect(f.services.files, isEmpty);
      f.services.speech.requests.single.complete('current');
      await _flush(tester);
      expect(_text(tester), 'current');
    },
  );

  testWidgets(
    '30 second recording limit opens approval and revoke dismisses it',
    (tester) async {
      final f = await _open(tester);
      await _tap(tester, find.text('Record for online transcription'));
      await tester.pump(const Duration(seconds: 31));
      await _flush(tester);
      expect(find.text('Transcribe this recording online?'), findsOneWidget);
      await f.policy.update(offline: true);
      await _flush(tester);
      expect(find.text('Transcribe this recording online?'), findsNothing);
      expect(f.services.files, isEmpty);
      expect(f.requests, isEmpty);
    },
  );

  testWidgets('cleanup errors are contained and deletion is still attempted', (
    tester,
  ) async {
    final services = _Services()
      ..configureRecorder = (r) => r.cleanupFails = true;
    await _open(tester, services: services);
    await _tap(tester, find.text('Record for online transcription'));
    await _tap(tester, find.text('Cancel'));
    expect(services.deleted, isNotEmpty);
    expect(services.files, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel during audio read sends no multipart request', (
    tester,
  ) async {
    final read = Completer<Uint8List>();
    final services = _Services()..readGate = read.future;
    final f = await _open(tester, services: services);
    await _tap(tester, find.text('Record for online transcription'));
    await _tap(tester, find.text('Stop recording'));
    await _tap(tester, find.text('Send recording'));
    await _tap(tester, find.text('Cancel'));
    read.complete(Uint8List.fromList([1, 2, 3]));
    await _flush(tester);
    expect(f.requests, isEmpty);
    expect(services.files, isEmpty);
  });

  for (final end in ['timeout', 'dispose']) {
    testWidgets('late recorder start after $end cannot leave audio active', (
      tester,
    ) async {
      final start = Completer<void>();
      final services = _Services()
        ..configureRecorder = (r) => r.startGate = start.future;
      final f = await _open(
        tester,
        services: services,
        timeout: const Duration(seconds: 2),
      );
      await _tap(tester, find.text('Record for online transcription'));
      if (end == 'timeout') {
        await tester.pump(const Duration(seconds: 3));
      } else {
        Navigator.of(tester.element(_message)).pop();
      }
      await _flush(tester);
      start.complete();
      await _flush(tester);
      expect(services.recorders.single.active, isFalse);
      expect(services.recorders.single.disposals, greaterThan(0));
      expect(services.files, isEmpty);
      expect(f.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hinglish stays editable and never auto translates or searches', (
    tester,
  ) async {
    final f = await _open(tester);
    await _tap(tester, find.byType(DropdownButton<String>));
    await _tap(tester, find.text('Hinglish').last);
    await _tap(tester, find.byTooltip('Listen on-device'));
    f.services.speech.requests.single.complete('do friends beach par');
    await _flush(tester);
    expect(f.services.speech.languages, ['hi-IN']);
    expect(_text(tester), 'do friends beach par');
    expect(find.text('Search text locally'), findsNothing);
    expect(f.requests, isEmpty);
    expect(f.scope.read(searchQueryProvider), isEmpty);
    await _tap(tester, find.text('Refine / translate online'));
    expect(jsonDecode(f.requests.single.body)['language'], 'Hinglish');
  });

  testWidgets(
    'overlong transcript stays editable and is not sent to the 2000 character assistant',
    (tester) async {
      final f = await _open(tester, auto: true);
      f.services.speech.requests.single.complete('x' * 2001);
      await _flush(tester);
      expect(_text(tester).length, 2001);
      await _tap(tester, find.text('Refine / translate online'));
      expect(find.textContaining('Shorten the transcript'), findsOneWidget);
      expect(f.requests, isEmpty);
    },
  );

  testWidgets('narrow voice sheet keeps capture state and controls in bounds', (
    tester,
  ) async {
    final f = await _open(tester, auto: true);
    tester.view.physicalSize = const Size(320, 740);
    await _flush(tester);
    expect(find.text('Listening on-device'), findsOneWidget);
    expect(tester.takeException(), isNull);
    f.services.speech.requests.single.complete('friends at the beach');
    await _flush(tester);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Record for online transcription'));
    expect(find.text('Recording audio'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Cancel'));
  });
}
