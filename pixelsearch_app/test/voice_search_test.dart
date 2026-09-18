import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/offline_speech.dart';

Future<void> _nativeState(int request, String state) async {
  final reply = Completer<void>();
  ui.channelBuffers.push(
    OfflineSpeechClient.channel.name,
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('state', {'requestId': request, 'state': state}),
    ),
    (_) => reply.complete(),
  );
  await reply.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  final responses = <Completer<String?>>[];
  setUp(() {
    calls.clear();
    responses.clear();
    messenger.setMockMethodCallHandler(OfflineSpeechClient.channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'recognize') {
        final response = Completer<String?>();
        responses.add(response);
        return response.future;
      }
      return null;
    });
  });
  tearDown(() async {
    await const OfflineSpeechClient().cancel();
    messenger.setMockMethodCallHandler(OfflineSpeechClient.channel, null);
  });

  testWidgets(
    'native ready/processing events and stop are scoped to recognition',
    (tester) async {
      const client = OfflineSpeechClient();
      final states = <String>[];
      final pending = client.recognize('en-US', onState: states.add);
      await tester.pump();
      final args = calls.single.arguments as Map;
      expect(args['language'], 'en-US');
      final id = args['requestId'] as int;
      await _nativeState(id + 1, 'listening');
      expect(states, isEmpty);
      await _nativeState(id, 'listening');
      await client.stop();
      expect(calls.last.method, 'stop');
      expect((calls.last.arguments as Map)['requestId'], id);
      await _nativeState(id, 'processing');
      responses.single.complete('two friends');
      expect(await pending, 'two friends');
      expect(states, ['listening', 'processing']);
      expect(calls.any((call) => call.method == 'download'), isFalse);
    },
  );

  testWidgets('old completion does not remove the newer native state handler', (
    tester,
  ) async {
    const client = OfflineSpeechClient();
    final old = client.recognize('en-US');
    await tester.pump();
    final oldId = (calls.single.arguments as Map)['requestId'] as int;
    await client.cancel();
    final states = <String>[];
    final current = client.recognize('hi-IN', onState: states.add);
    await tester.pump();
    final newId = (calls.last.arguments as Map)['requestId'] as int;
    responses.first.complete('old');
    await old;
    await _nativeState(oldId, 'processing');
    await _nativeState(newId, 'listening');
    expect(states, ['listening']);
    responses.last.complete('current');
    expect(await current, 'current');
  });

  testWidgets(
    'native response wait is bounded and cancellation carries its request id',
    (tester) async {
      final pending = const OfflineSpeechClient().recognize('en-US');
      final failure = expectLater(pending, throwsA(isA<TimeoutException>()));
      await tester.pump();
      final id = (calls.single.arguments as Map)['requestId'];
      await tester.pump(const Duration(seconds: 76));
      await failure;
      expect(calls.last.method, 'cancel');
      expect((calls.last.arguments as Map)['requestId'], id);
      responses.single.complete('too late');
      await tester.pump();
    },
  );

  test(
    'native errors expose useful actions without raw exception wrappers',
    () {
      for (final code in [
        'permission',
        'audio',
        'no_match',
        'no_speech',
        'timeout',
        'cancelled',
      ]) {
        final message = speechError(PlatformException(code: code));
        expect(message, isNotEmpty);
        expect(message, isNot(contains('PlatformException')));
      }
      expect(
        speechError(PlatformException(code: 'permission')),
        contains('permissions'),
      );
      expect(
        speechError(PlatformException(code: 'no_speech')),
        contains('No speech'),
      );
      expect(speechError(TimeoutException('internal')), contains('timed out'));
    },
  );
}
