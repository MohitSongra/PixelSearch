import 'package:workmanager/workmanager.dart';

import '../ports/background_scheduler.dart';

const String kIndexTaskName = 'pixelsearch.index';
const String kIndexUniqueName = 'pixelsearch.index.oneoff';

/// [BackgroundScheduler] backed by WorkManager. **Device-only** (Android). The
/// OS persists the request across app restarts and reboot, and applies the
/// retry/backoff policy. The indexing *logic* is scheduler-independent, so this
/// adapter is thin.
class WorkManagerScheduler implements BackgroundScheduler {
  const WorkManagerScheduler();

  @override
  Future<void> scheduleIndexing() => Workmanager().registerOneOffTask(
        kIndexUniqueName,
        kIndexTaskName,
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(seconds: 30),
        constraints: Constraints(networkType: NetworkType.notRequired),
      );

  @override
  Future<void> cancel() => Workmanager().cancelByUniqueName(kIndexUniqueName);

  @override
  Future<bool> isScheduled() async =>
      true; // WorkManager has no direct query; the app tracks intent itself.
}
