import 'package:workmanager/workmanager.dart';

import '../../ai/image_embedder.dart';
import '../../core/model_locator.dart';
import '../../data/local/app_database.dart';
import '../../data/local/processing_lease.dart';
import '../../data/people_repository.dart';
import '../../data/people/people_service.dart';
import '../../data/indexing_preferences_repository.dart';
import '../asset_processor.dart';
import '../index_store.dart';
import '../indexing_service.dart';
import '../model/index_progress.dart';
import '../model/folder_selection.dart';
import '../model_version_manager.dart';
import 'exif_metadata_extractor.dart';
import 'file_thumbnail_generator.dart';
import 'mlkit_image_enricher.dart';
import 'onnx_asset_embedder.dart';
import 'photo_manager_gallery.dart';

/// Composition root (DI): assembles the production indexing pipeline from the
/// device adapters + the (unmodified) AI core. **Device-only.**
///
Future<IndexingService> buildDeviceIndexingService({
  required AppDatabase db,
  required String imageModelPath,
  required FolderSelection selection,
}) async {
  final embedder = OnnxImageEmbedder(modelPath: imageModelPath);
  await embedder.load();
  final gallery = PhotoManagerGallerySource(selection: selection);
  final enricher = MlKitImageEnricher();
  final processor = AssetProcessor(
    gallery: gallery,
    metadata: const ExifMetadataExtractor(),
    thumbnails: const FileThumbnailGenerator(),
    embedder: OnnxAssetEmbedder(embedder),
    enricher: enricher,
  );
  return IndexingService(
    gallery: gallery,
    processor: processor,
    store: IndexStore(db),
    versionManager: const ModelVersionManager(),
    onDispose: () async {
      try {
        // The indexing lease excludes face scanning. Cleanup must not depend
        // on the user enabling/resuming People or producing new face results.
        final people = PeopleRepository(db);
        await people.reconcile();
        await PeopleService(people).pruneCrops();
      } finally {
        try {
          await enricher.dispose();
        } finally {
          await embedder.dispose();
        }
      }
    },
  );
}

/// WorkManager entrypoint — runs in a background isolate on Android.
@pragma('vm:entry-point')
void indexCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) => runBackgroundIndex());
}

/// Assemble + run one indexing pass in the background. Returns `false`
/// (retryable) if the model has not been provisioned yet (M12 model manager).
Future<bool> runBackgroundIndex() async {
  final db = AppDatabase();
  ProcessingLease? lease;
  try {
    lease = await ProcessingLease.acquire(db, 'background-index');
    if (lease == null) return false;
    final selection = await IndexingPreferencesRepository(db).load();
    if (selection.isEmpty) return true;
    const locator = ModelLocator();
    final candidates = await locator.imageCandidatesPresent();
    if (candidates.isEmpty) return false;

    // Match foreground behavior: fp16 is preferred, but a candidate is only
    // selected after it actually creates a session. That keeps an unsupported
    // or device-incompatible fp16 image artifact from blocking fp32 fallback.
    for (final candidate in candidates) {
      IndexingService? service;
      try {
        service = await buildDeviceIndexingService(
          db: db,
          imageModelPath: candidate.path,
          selection: selection,
        );
        locator.log.info('background image encoder selected: $candidate');
        final result = await service.run();
        return result.phase == IndexPhase.done;
      } catch (e, st) {
        locator.log.error(
          'background image encoder ${candidate.fileName} failed to load',
          e,
          st,
        );
      } finally {
        await service?.dispose();
      }
    }
    return false;
  } finally {
    await lease?.release();
    await db.close();
  }
}
