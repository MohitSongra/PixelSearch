import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pixelsearch/data/enhancements/backend_credentials.dart';
import 'package:pixelsearch/data/enhancements/enhancement_client.dart';
import 'package:pixelsearch/data/enhancements/online_policy.dart';
import 'package:pixelsearch/data/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const credentials = BackendCredentials();
  final original = Uri.parse('https://original.example/api');

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('token is bound to canonical HTTPS origin, including port', () async {
    await credentials.saveFor(original, ' synthetic-token ');
    expect(await credentials.readFor(original), 'synthetic-token');
    expect(
      await credentials.readFor(Uri.parse('https://original.example:443/v2')),
      'synthetic-token',
    );
    for (final url in [
      'https://new.example',
      'https://original.example:8443',
      'http://original.example',
      'https://someone@original.example',
      'https://original.example?token=x',
      'https://original.example#fragment',
    ]) {
      expect(await credentials.readFor(Uri.parse(url)), isNull);
    }
  });

  test(
    'unbound legacy token requires re-entry and is removed on save',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        BackendCredentials.legacyKey: 'old-secret',
      });
      expect(await credentials.readFor(original), isNull);
      await credentials.saveFor(original, 'reentered-token');
      expect(await credentials.readFor(original), 'reentered-token');
      expect(
        await const FlutterSecureStorage().read(
          key: BackendCredentials.legacyKey,
        ),
        isNull,
      );
    },
  );

  test('malformed storage and unsafe tokens fail closed', () async {
    for (final saved in [
      'not json',
      '[]',
      jsonEncode({'origin': original.origin, 'token': 42}),
      jsonEncode({'origin': original.origin, 'token': 'token\r\nX: injected'}),
    ]) {
      FlutterSecureStorage.setMockInitialValues({
        BackendCredentials.storageKey: saved,
      });
      expect(await credentials.readFor(original), isNull);
    }
    await expectLater(
      credentials.saveFor(original, 'a\nb'),
      throwsArgumentError,
    );
    await expectLater(
      credentials.saveFor(Uri.parse('http://original.example'), 'token'),
      throwsArgumentError,
    );
  });

  test(
    'changing server with blank token cannot disclose saved token',
    () async {
      final policy = OnlinePolicy(
        UserPreferences(read: () async => null, write: (_) async {}),
      );
      addTearDown(policy.dispose);
      await policy.load();
      await policy.update(
        baseUrl: original.toString(),
        offline: false,
        feature: OnlineFeature.assistant,
        allow: true,
      );
      await credentials.saveFor(original, 'synthetic-token');
      var calls = 0;
      final client = EnhancementClient(
        policy,
        client: () => MockClient((request) async {
          calls++;
          expect(request.url.origin, original.origin);
          expect(request.headers['authorization'], 'Bearer synthetic-token');
          expect(request.followRedirects, isFalse);
          return http.Response('{}', 200);
        }),
      );
      await client.request(OnlineFeature.assistant, 'assistant');
      await policy.update(baseUrl: 'https://new.example');
      await expectLater(
        client.request(OnlineFeature.assistant, 'assistant'),
        throwsStateError,
      );
      expect(calls, 1);
    },
  );

  test(
    'unsafe URL loaded from preferences is rejected before credentials',
    () async {
      final policy = OnlinePolicy(
        UserPreferences(read: () async => null, write: (_) async {}),
      );
      addTearDown(policy.dispose);
      await policy.load();
      await policy.update(
        offline: false,
        feature: OnlineFeature.assistant,
        allow: true,
      );
      policy.baseUrl = 'https://user@original.example';
      final client = EnhancementClient(
        policy,
        token: () async {
          fail('Unsafe endpoint must be rejected before reading secrets');
        },
      );
      await expectLater(
        client.request(OnlineFeature.assistant, 'assistant'),
        throwsStateError,
      );
    },
  );
}
