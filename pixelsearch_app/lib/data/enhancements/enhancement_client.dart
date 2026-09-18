import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'online_policy.dart';

class RequestCancellation extends ChangeNotifier {
  bool cancelled = false;
  void cancel() {
    cancelled = true;
    notifyListeners();
  }
}

class EnhancementClient {
  EnhancementClient(
    this.policy, {
    Future<String?> Function()? token,
    http.Client Function()? client,
  }) : _token =
           token ??
           (() =>
               const FlutterSecureStorage().read(key: 'backend_install_token')),
       _client = client ?? http.Client.new;
  final OnlinePolicy policy;
  final Future<String?> Function() _token;
  final http.Client Function() _client;

  Future<Map<String, dynamic>> request(
    OnlineFeature feature,
    String path, {
    Map<String, Object?>? json,
    Uint8List? bytes,
    String filename = 'photo.jpg',
    RequestCancellation? cancellation,
  }) async {
    if (!policy.allows(feature)) {
      throw StateError('Enable this online feature in Settings first.');
    }
    final generation = policy.generation;
    final base = Uri.tryParse(policy.baseUrl);
    if (base == null || base.scheme != 'https' || base.host.isEmpty) {
      throw StateError('Configure the HTTPS backend in Settings.');
    }
    final token = await _token();
    if (!policy.allows(feature) || policy.generation != generation) {
      throw StateError('Request cancelled.');
    }
    if (token == null || token.isEmpty) {
      throw StateError('Set the per-install backend token in Settings.');
    }
    final client = _client();
    var cancelled = false;
    void cancel() {
      if (cancellation?.cancelled == true ||
          policy.generation != generation ||
          !policy.allows(feature)) {
        cancelled = true;
        client.close();
      }
    }

    policy.addListener(cancel);
    cancellation?.addListener(cancel);
    try {
      if (cancellation?.cancelled == true) {
        throw StateError('Request cancelled.');
      }
      final url = Uri.parse(
        '${policy.baseUrl.replaceAll(RegExp(r'/+$'), '')}/$path',
      );
      http.BaseRequest req;
      if (bytes != null) {
        if (bytes.length > 4 * 1024 * 1024) {
          throw ArgumentError('Upload exceeds 4 MB.');
        }
        req = http.MultipartRequest('POST', url)
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );
      } else {
        req = http.Request('POST', url)
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(json ?? {});
      }
      req.followRedirects = false;
      req.headers['Authorization'] = 'Bearer $token';
      final response = await (() async {
        final streamed = await client.send(req);
        final body = BytesBuilder(copy: false);
        await for (final chunk in streamed.stream) {
          if (body.length + chunk.length > 65536) {
            throw const FormatException('Response too large.');
          }
          body.add(chunk);
        }
        return http.Response.bytes(
          body.takeBytes(),
          streamed.statusCode,
          headers: streamed.headers,
        );
      })().timeout(const Duration(seconds: 100));
      if (cancelled || !policy.allows(feature)) {
        throw StateError('Request cancelled.');
      }
      if (response.statusCode != 200) {
        throw StateError(switch (response.statusCode) {
          401 => 'Backend token not accepted.',
          429 => 'Free quota reached. Try again later.',
          503 => 'Enhancement model unavailable. Local search still works.',
          _ =>
            'Online request failed (${response.statusCode}). Retry explicitly.',
        });
      }
      if (response.bodyBytes.length > 65536) {
        throw const FormatException('Response too large.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid response.');
      }
      return decoded;
    } finally {
      policy.removeListener(cancel);
      cancellation?.removeListener(cancel);
      client.close();
    }
  }
}
