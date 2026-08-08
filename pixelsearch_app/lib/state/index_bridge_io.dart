import 'package:photo_manager/photo_manager.dart';

import '../core/model_locator.dart';
import '../data/local/app_database.dart';
import '../indexing/adapters/indexing_wiring.dart';
import '../indexing/indexing_service.dart';
import '../indexing/model/index_progress.dart';
import 'index_bridge.dart';
import 'index_cancel_token.dart';

/// Native: run one pass of the real M5 pipeline in the foreground.
///
/// Order matters. Media permission is requested **first** because
/// `PhotoManagerGallerySource` reports an empty gallery rather than an error
/// when access was never granted — an unprompted run would silently index zero
/// photos. The model check comes next so a missing encoder fails fast, before
/// the expensive ONNX session load.
///
/// Everything after that is delegated to the unmodified composition root
/// [buildDeviceIndexingService]; this file adds no indexing logic.
Future<IndexRunResult> runDeviceIndexing({
  required AppDatabase db,
  required void Function(IndexProgress) onProgress,
  required IndexCancelToken cancel,
}) async {
  final permission = await PhotoManager.requestPermissionExtend();
  if (!permission.isAuth && !permission.hasAccess) {
    return const IndexRunResult(IndexRunStatus.permissionDenied);
  }

  // fp16 preferred, fp32 accepted for development/CPU testing. Selection happens
  // by *loading*, not merely by existence: a present-but-unusable artifact (fp16
  // without an fp16-capable EP — KI-2; or a bad fp16 conversion — KI-9) must
  // fall through to the next candidate rather than fail the run.
  const locator = ModelLocator();
  final candidates = await locator.imageCandidatesPresent();
  if (candidates.isEmpty) {
    return IndexRunResult(
      IndexRunStatus.modelMissing,
      message: await ModelLocator.describeMissing(ModelLocator.imageCandidates),
    );
  }

  IndexingService? service;
  ResolvedModel? selected;
  final failures = <String>[];
  for (final candidate in candidates) {
    try {
      service =
          await buildDeviceIndexingService(db: db, imageModelPath: candidate.path);
      selected = candidate;
      locator.log.info('image encoder SELECTED → ${candidate.fileName} '
          '(${candidate.precision}, ${candidate.sizeMb} MB) at ${candidate.path}');
      break;
    } catch (e) {
      failures.add('${candidate.fileName}: $e');
      locator.log.error('image encoder ${candidate.fileName} failed to load '
          '— trying the next candidate', e);
    }
  }
  if (service == null || selected == null) {
    return IndexRunResult(IndexRunStatus.modelUnusable,
        message: failures.join(' | '));
  }

  cancel.bind(service.cancel);
  final subscription = service.progress.listen(onProgress);
  try {
    return IndexRunResult(IndexRunStatus.finished,
        progress: await service.run(), modelUsed: selected.toString());
  } finally {
    await subscription.cancel();
    await service.dispose();
  }
}
