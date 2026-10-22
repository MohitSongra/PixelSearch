import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A token is valid only for the HTTPS origin explicitly configured with it.
class BackendCredentials {
  const BackendCredentials({this.storage = const FlutterSecureStorage()});

  final FlutterSecureStorage storage;
  static const storageKey = 'backend_connection_v1';
  static const legacyKey = 'backend_install_token';

  static bool validBackend(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;

  static bool _validToken(String token) =>
      token.isNotEmpty &&
      token.length <= 4096 &&
      RegExp(r'^[\x21-\x7e]+$').hasMatch(token);

  Future<String?> readFor(Uri backend) async {
    if (!validBackend(backend)) return null;
    final saved = await storage.read(key: storageKey);
    if (saved == null) return null;
    try {
      final record = jsonDecode(saved);
      if (record is! Map<String, dynamic> ||
          record['origin'] != backend.origin) {
        return null;
      }
      final token = record['token'];
      return token is String && _validToken(token) ? token : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveFor(Uri backend, String value) async {
    final token = value.trim();
    if (!validBackend(backend) || !_validToken(token)) {
      throw ArgumentError('Enter a valid HTTPS server and access token.');
    }
    await storage.write(
      key: storageKey,
      value: jsonEncode({'origin': backend.origin, 'token': token}),
    );
    // Legacy tokens have no trustworthy origin. Require explicit re-entry;
    // automatically binding one to the current URL could disclose it.
    await storage.delete(key: legacyKey);
  }
}
