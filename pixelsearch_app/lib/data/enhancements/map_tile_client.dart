import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'online_policy.dart';

/// One map-view lifetime, with immediate consent revocation and no HTTP retries.
class MapTileClient extends http.BaseClient {
  MapTileClient(
    this.policy, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client() {
    policy.addListener(_checkPolicy);
  }

  final OnlinePolicy policy;
  final http.Client _client;
  final Duration timeout;
  static const maxTileBytes = 2 * 1024 * 1024;
  bool _closed = false;
  static const userAgent =
      'PixelSearch/0.1 (com.pixelsearch.pixelsearch; '
      '+https://github.com/MohitSongra/PixelSearch)';

  void _checkPolicy() {
    if (!policy.allows(OnlineFeature.maps)) close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed || !policy.allows(OnlineFeature.maps)) {
      throw StateError('Online map tiles are disabled.');
    }
    if (request.method != 'GET' ||
        request.url.scheme != 'https' ||
        request.url.host != 'tile.openstreetmap.org' ||
        request.url.port != 443 ||
        !RegExp(r'^/\d+/\d+/\d+\.png$').hasMatch(request.url.path) ||
        request.url.hasQuery ||
        request.url.userInfo.isNotEmpty) {
      throw ArgumentError(
        'Only public OpenStreetMap tile requests are allowed.',
      );
    }
    request.followRedirects = false;
    request.headers['User-Agent'] = userAgent;
    return _readTile(request).timeout(
      timeout,
      onTimeout: () {
        close();
        throw TimeoutException('Map tile request timed out.');
      },
    );
  }

  Future<http.StreamedResponse> _readTile(http.BaseRequest request) async {
    final response = await _client.send(request);
    if (_closed || !policy.allows(OnlineFeature.maps)) {
      throw StateError('Map tile request cancelled.');
    }
    final body = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (_closed || !policy.allows(OnlineFeature.maps)) {
        throw StateError('Map tile request cancelled.');
      }
      if (body.length + chunk.length > maxTileBytes) {
        close();
        throw const FormatException('Map tile response too large.');
      }
      body.add(chunk);
    }
    if (_closed || !policy.allows(OnlineFeature.maps)) {
      throw StateError('Map tile request cancelled.');
    }
    return http.StreamedResponse(
      Stream.value(body.takeBytes()),
      response.statusCode,
      contentLength: response.contentLength,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    policy.removeListener(_checkPolicy);
    _client.close();
    super.close();
  }
}
