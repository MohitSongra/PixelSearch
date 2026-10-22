/// Schedules indexing to run in the background.
///
/// **Not wired yet (2026-10-22):** nothing in the app calls [scheduleIndexing];
/// WorkManager is initialised at startup but no work is ever scheduled, so
/// indexing runs only in the foreground. Background indexing is a roadmap item
/// (OEM screen-off behaviour is KI-10). The device adapter wraps `workmanager`
/// (Android) with a retry/exponential-backoff policy. The indexing *logic* is
/// independent of how it is scheduled, so the core is testable without one.
abstract interface class BackgroundScheduler {
  Future<void> scheduleIndexing();
  Future<void> cancel();
  Future<bool> isScheduled();
}
