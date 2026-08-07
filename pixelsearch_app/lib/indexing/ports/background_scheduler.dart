/// Schedules indexing to run in the background, surviving app restarts and reboot.
///
/// Device adapter wraps `workmanager` (Android) with a retry/exponential-backoff
/// policy; the fake records calls. The indexing *logic* is independent of how it
/// is scheduled, so the core is fully testable without a scheduler.
abstract interface class BackgroundScheduler {
  Future<void> scheduleIndexing();
  Future<void> cancel();
  Future<bool> isScheduled();
}
