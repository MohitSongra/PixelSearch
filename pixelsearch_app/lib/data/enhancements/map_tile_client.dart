import 'dart:async';
import 'package:http/http.dart' as http;
import 'online_policy.dart';

/// One map-view lifetime, with immediate consent revocation and no HTTP retries.
class MapTileClient extends http.BaseClient {
  MapTileClient(this.policy, {http.Client? client})
    : _client = client ?? http.Client() {
    policy.addListener(_checkPolicy);
  }

  final OnlinePolicy policy;
  final http.Client _client;
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
    final response = await _client
        .send(request)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            close();
            throw TimeoutException('Map tile request timed out.');
          },
        );
    if (_closed || !policy.allows(OnlineFeature.maps)) {
      throw StateError('Map tile request cancelled.');
    }
    return http.StreamedResponse(
      _guardBody(response.stream),
      response.statusCode,
      contentLength: response.contentLength,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }

  Stream<List<int>> _guardBody(Stream<List<int>> stream) async* {
    try {
      await for (final chunk in stream.timeout(const Duration(seconds: 20))) {
        if (_closed || !policy.allows(OnlineFeature.maps)) {
          throw StateError('Map tile request cancelled.');
        }
        yield chunk;
      }
    } on TimeoutException {
      close();
      rethrow;
    }
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
