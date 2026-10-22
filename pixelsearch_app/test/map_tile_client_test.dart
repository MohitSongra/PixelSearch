import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pixelsearch/data/enhancements/map_tile_client.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/user_preferences.dart';

void main() {
  Future<OnlinePolicy> policy({bool allow = false}) async {
    final policy = OnlinePolicy(
      UserPreferences(read: () async => null, write: (_) async {}),
    );
    await policy.load();
    if (allow) {
      await policy.update(
        offline: false,
        feature: OnlineFeature.maps,
        allow: true,
      );
    }
    addTearDown(policy.dispose);
    return policy;
  }

  final url = Uri.parse('https://tile.openstreetmap.org/0/0/0.png');

  test('tile bodies are bounded independently of Content-Length', () async {
    final settings = await policy(allow: true);
    final client = MapTileClient(
      settings,
      client: MockClient.streaming(
        (_, _) async => http.StreamedResponse(
          Stream.value(List.filled(MapTileClient.maxTileBytes + 1, 0)),
          200,
          contentLength: 1,
        ),
      ),
    );
    addTearDown(client.close);
    await expectLater(client.get(url), throwsFormatException);
    await expectLater(client.get(url), throwsStateError);
  });

  test('steady trickle cannot bypass the total tile deadline', () async {
    final settings = await policy(allow: true);
    var stopped = false;
    Stream<List<int>> trickle() async* {
      try {
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          yield [1];
        }
      } finally {
        stopped = true;
      }
    }

    final client = MapTileClient(
      settings,
      timeout: const Duration(milliseconds: 25),
      client: MockClient.streaming(
        (_, _) async => http.StreamedResponse(trickle(), 200),
      ),
    );
    addTearDown(client.close);
    await expectLater(client.get(url), throwsA(isA<TimeoutException>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(stopped, isTrue);
    await expectLater(client.get(url), throwsStateError);
  });

  test('map sends zero requests until separately consented', () async {
    var calls = 0;
    final settings = await policy();
    final client = MapTileClient(
      settings,
      client: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    addTearDown(client.close);
    await expectLater(client.get(url), throwsStateError);
    expect(calls, 0);
  });

  test(
    'tile requests identify app, retain caching headers and never retry',
    () async {
      var calls = 0;
      final settings = await policy(allow: true);
      final client = MapTileClient(
        settings,
        client: MockClient((request) async {
          calls++;
          expect(request.headers['User-Agent'], MapTileClient.userAgent);
          expect(request.headers['If-None-Match'], 'tile-etag');
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.headers.containsKey('Cache-Control'), isFalse);
          expect(request.followRedirects, isFalse);
          return http.Response('', 503);
        }),
      );
      addTearDown(client.close);
      final response = await client.get(
        url,
        headers: {'If-None-Match': 'tile-etag'},
      );
      expect(response.statusCode, 503);
      expect(calls, 1);
    },
  );

  test(
    'revocation discards in-flight response and blocks further requests',
    () async {
      final settings = await policy(allow: true);
      final started = Completer<void>();
      final finish = Completer<void>();
      var calls = 0;
      final client = MapTileClient(
        settings,
        client: MockClient((_) async {
          calls++;
          started.complete();
          await finish.future;
          return http.Response('tile', 200);
        }),
      );
      addTearDown(client.close);
      final rejected = expectLater(client.get(url), throwsStateError);
      await started.future;
      await settings.update(offline: true);
      finish.complete();
      await rejected;
      await settings.update(offline: false);
      await expectLater(client.get(url), throwsStateError);
      expect(calls, 1);
    },
  );

  test('unrelated consent change does not break the active map', () async {
    final settings = await policy(allow: true);
    final client = MapTileClient(
      settings,
      client: MockClient((_) async => http.Response('tile', 200)),
    );
    addTearDown(client.close);
    await settings.update(feature: OnlineFeature.captions, allow: true);
    expect((await client.get(url)).statusCode, 200);
  });

  test(
    'client cannot send private uploads or other service requests',
    () async {
      var calls = 0;
      final settings = await policy(allow: true);
      final client = MapTileClient(
        settings,
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
      );
      addTearDown(client.close);
      await expectLater(client.post(url, body: 'private'), throwsArgumentError);
      await expectLater(
        client.get(Uri.parse('https://example.test/tile')),
        throwsArgumentError,
      );
      expect(calls, 0);
    },
  );
}
