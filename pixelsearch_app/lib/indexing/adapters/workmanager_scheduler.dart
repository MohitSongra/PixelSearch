import 'package:workmanager/workmanager.dart';

import '../ports/background_scheduler.dart';

const String kIndexTaskName = 'pixelsearch.index';
const String kIndexUniqueName = 'pixelsearch.index.oneoff';

/// [BackgroundScheduler] backed by WorkManager. **Device-only** (Android) and
/// **not wired yet**: nothing schedules work through it (see
/// [BackgroundScheduler]). Once wired, the OS would persist the request and
/// apply the retry/backoff policy; reboot survival has never been verified.
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
  Future<bool> isScheduled() async => true; // WorkManager has no direct query; unused while nothing schedules.
}
