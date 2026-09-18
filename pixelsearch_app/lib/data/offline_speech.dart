import 'dart:async';
import 'package:flutter/services.dart';
import 'enhancements/online_policy.dart';

class OfflineSpeechSupport {
  const OfflineSpeechSupport(
    this.requested,
    this.installed,
    this.pending,
    this.downloadable,
  );
  final String requested;
  final List<String> installed, pending, downloadable;

  factory OfflineSpeechSupport.parse(Map<dynamic, dynamic> value) {
    List<String> languages(String key) {
      final values = value[key];
      if (values is! List || values.any((v) => v is! String)) {
        throw const FormatException('Invalid offline language response.');
      }
      return values
          .cast<String>()
          .map((v) => v.replaceAll('_', '-'))
          .toSet()
          .toList()
        ..sort();
    }

    final requested = value['requested'];
    if (requested is! String) {
      throw const FormatException('Missing requested language.');
    }
    return OfflineSpeechSupport(
      requested,
      languages('installed'),
      languages('pending'),
      languages('downloadable'),
    );
  }

  bool _has(List<String> tags) => tags.any(
    (tag) =>
        tag.toLowerCase() == requested.toLowerCase() ||
        tag.toLowerCase() == requested.split('-').first.toLowerCase(),
  );
  bool get ready => _has(installed);
  bool get scheduled => _has(pending);
  bool get canDownload => !ready && !scheduled && _has(downloadable);
  List<String> get choices => {
    requested,
    // These are selectable probes, not a claim that either variant is installed.
    if (requested.split('-').first.toLowerCase() == 'en') ...['en-IN', 'en-US'],
    for (final tag in [...installed, ...pending, ...downloadable])
      if (tag.split('-').first.toLowerCase() ==
          requested.split('-').first.toLowerCase())
        tag,
  }.toList()..sort();
}

class OfflineSpeechClient {
  const OfflineSpeechClient();
  static const channel = MethodChannel('pixelsearch/on_device_speech');
  static int _nextRequest = 0;
  static int? _listeningRequest;
  Future<OfflineSpeechSupport> support(String language) async {
    final data = await channel.invokeMapMethod<dynamic, dynamic>('support', {
      'language': language,
    });
    if (data == null) {
      throw const FormatException('Offline speech status unavailable.');
    }
    return OfflineSpeechSupport.parse(data);
  }

  Future<String?> recognize(
    String language, {
    void Function(String state)? onState,
  }) async {
    final request = ++_nextRequest;
    _listeningRequest = request;
    channel.setMethodCallHandler((call) async {
      final data = call.arguments;
      if (call.method == 'state' &&
          data is Map &&
          data['requestId'] == request &&
          _listeningRequest == request &&
          data['state'] is String) {
        onState?.call(data['state'] as String);
      }
    });
    try {
      return await channel
          .invokeMethod<String>('recognize', {
            'language': language,
            'requestId': request,
          })
          .timeout(const Duration(seconds: 75));
    } on TimeoutException {
      unawaited(
        channel
            .invokeMethod<void>('cancel', {'requestId': request})
            .timeout(const Duration(seconds: 3))
            .catchError((Object _) {}),
      );
      rethrow;
    } finally {
      if (_listeningRequest == request) {
        _listeningRequest = null;
        channel.setMethodCallHandler(null);
      }
    }
  }

  Future<void> stop() => channel
      .invokeMethod<void>('stop', {'requestId': _listeningRequest})
      .timeout(const Duration(seconds: 3));
  Future<void> cancel() {
    _listeningRequest = null;
    channel.setMethodCallHandler(null);
    return channel
        .invokeMethod<void>('cancel')
        .timeout(const Duration(seconds: 3));
  }

  Future<String> download(
    String language,
    OnlinePolicy policy, {
    required bool confirmed,
  }) async {
    if (!confirmed) throw StateError('Download approval is required.');
    if (!policy.loaded || policy.offline) {
      throw StateError('Offline only is on. No language download was started.');
    }
    var revoked = false;
    void checkPolicy() {
      if (!revoked && (policy.offline || !policy.loaded)) {
        revoked = true;
        cancel().catchError((Object _) {});
      }
    }

    policy.addListener(checkPolicy);
    try {
      final result = await channel.invokeMethod<String>('download', {
        'language': language,
        'confirmed': true,
      });
      if (revoked) {
        throw StateError(
          'Offline only is on. The app stopped waiting for the download.',
        );
      }
      return result ?? 'requested';
    } finally {
      policy.removeListener(checkPolicy);
    }
  }
}

String speechError(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'language_missing' =>
        error.message ??
            'Open offline speech setup to check language availability.',
      'unavailable' =>
        error.message ??
            'Offline speech is unavailable for this language or device. Open offline speech setup.',
      'permission' =>
        'Microphone access is unavailable. Check app permissions.',
      'no_speech' => 'No speech was heard. Please try again.',
      'no_match' => 'Speech was not understood. Please try again.',
      'audio' =>
        'The microphone could not start. Close other recording apps and retry.',
      'cancelled' => 'Speech cancelled.',
      'timeout' => 'Speech timed out. Please try again.',
      'busy' => 'A speech request is already running.',
      _ => error.message ?? 'Speech could not be completed. Please try again.',
    };
  }
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  if (error is TimeoutException) {
    return 'The voice request timed out. Please try again.';
  }
  return 'The request could not be completed. Please try again.';
}
