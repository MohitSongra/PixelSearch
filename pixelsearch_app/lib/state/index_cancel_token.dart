/// A platform-free handle for cancelling an in-flight indexing run.
///
/// The UI controller cannot hold the `IndexingService` itself — that type lives
/// behind the native-only conditional import — so it holds a token instead. The
/// native bridge [bind]s the service's `cancel` to it once the service exists.
///
/// Binding is late by design: assembling the pipeline loads the ONNX image
/// encoder, which takes long enough that a user can hit Cancel first. A cancel
/// requested before [bind] is remembered and replayed, so that tap is never lost.
class IndexCancelToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  /// Attach the underlying service's cancel hook, replaying an earlier request.
  void bind(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) onCancel();
  }

  /// Request cancellation. Idempotent; safe before or after [bind].
  void cancel() {
    _cancelled = true;
    _onCancel?.call();
  }
}
