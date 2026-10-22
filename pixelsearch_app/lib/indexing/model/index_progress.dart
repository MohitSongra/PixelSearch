/// Coarse phase of an indexing run, surfaced to the UI and notifications.
enum IndexPhase {
  idle,
  scanning,
  planning,
  indexing,
  finalizing,
  done,
  cancelled,
  error,
}

/// Immutable progress snapshot streamed by the indexing service.
class IndexProgress {
  const IndexProgress({
    required this.phase,
    this.total = 0,
    this.completed = 0,
    this.failed = 0,
    this.deleted = 0,
    this.currentId,
    this.message,
  });

  final IndexPhase phase;
  final int total; // items to (re)index in this run
  final int completed;
  final int failed;
  final int deleted;
  final String? currentId;
  final String? message;

  /// 0..1 over the indexing work of this run (0 when nothing to do).
  double get fraction =>
      total == 0 ? (phase == IndexPhase.done ? 1.0 : 0.0) : completed / total;

  bool get isTerminal =>
      phase == IndexPhase.done ||
      phase == IndexPhase.cancelled ||
      phase == IndexPhase.error;

  IndexProgress copyWith({
    IndexPhase? phase,
    int? total,
    int? completed,
    int? failed,
    int? deleted,
    String? currentId,
    String? message,
  }) => IndexProgress(
    phase: phase ?? this.phase,
    total: total ?? this.total,
    completed: completed ?? this.completed,
    failed: failed ?? this.failed,
    deleted: deleted ?? this.deleted,
    currentId: currentId ?? this.currentId,
    message: message ?? this.message,
  );

  static const idle = IndexProgress(phase: IndexPhase.idle);
}
