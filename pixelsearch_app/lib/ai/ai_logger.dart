import 'dart:developer' as developer;

/// Tiny logging facade for the AI layer. Routes through `dart:developer` so it
/// shows in DevTools / `flutter logs` without pulling a logging dependency.
class AiLog {
  const AiLog(this.tag);
  final String tag;

  void info(String message) =>
      developer.log(message, name: 'pixelsearch.ai.$tag');

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(message,
          name: 'pixelsearch.ai.$tag',
          level: 1000,
          error: error,
          stackTrace: stackTrace);
}
