import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Tiny logging facade for the AI layer.
///
/// Writes to **both** sinks on purpose:
/// * `dart:developer` — structured, named entries for DevTools.
/// * `debugPrint` (debug builds only) — the only one of the two that actually
///   reaches `adb logcat` / the `flutter run` console. `developer.log` output
///   goes to the VM service and is *not* mirrored to logcat, so a device run
///   instrumented with it alone produces nothing you can read over adb. That
///   was discovered the hard way on a real device run (2026-08-08).
class AiLog {
  const AiLog(this.tag);
  final String tag;

  void info(String message) {
    developer.log(message, name: 'pixelsearch.ai.$tag');
    if (kDebugMode) debugPrint('[pixelsearch.$tag] $message');
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'pixelsearch.ai.$tag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint(
        '[pixelsearch.$tag] ERROR $message'
        '${error == null ? '' : ' :: $error'}',
      );
    }
  }
}
