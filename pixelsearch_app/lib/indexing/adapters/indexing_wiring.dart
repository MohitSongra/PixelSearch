import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../ai/image_embedder.dart';
import '../../data/local/app_database.dart';
import '../asset_processor.dart';
import '../index_store.dart';
import '../indexing_service.dart';
import '../model/index_progress.dart';
import '../model_version_manager.dart';
import 'exif_metadata_extractor.dart';
import 'file_thumbnail_generator.dart';
import 'mlkit_image_enricher.dart';
import 'onnx_asset_embedder.dart';
import 'photo_manager_gallery.dart';

/// Composition root (DI): assembles the production indexing pipeline from the
/// device adapters + the (unmodified) AI core. **Device-only.**
///
/// The app's `main()` registers the background entrypoint with
/// `Workmanager().initialize(indexCallbackDispatcher)` (Android).
Future<IndexingService> buildDeviceIndexingService({
  required AppDatabase db,
  required String imageModelPath,
}) async {
  final embedder = OnnxImageEmbedder(modelPath: imageModelPath);
  await embedder.load();
  const gallery = PhotoManagerGallerySource();
  final processor = AssetProcessor(
    gallery: gallery,
    metadata: const ExifMetadataExtractor(),
    thumbnails: const FileThumbnailGenerator(),
    embedder: OnnxAssetEmbedder(embedder),
    enricher: MlKitImageEnricher(),
  );
  return IndexingService(
    gallery: gallery,
    processor: processor,
    store: IndexStore(db),
    versionManager: const ModelVersionManager(),
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
  try {
    final support = await getApplicationSupportDirectory();
    final modelPath = p.join(support.path, 'models', 'mobileclip_image.onnx');
    if (!File(modelPath).existsSync()) return false;
    final service =
        await buildDeviceIndexingService(db: db, imageModelPath: modelPath);
    final result = await service.run();
    await service.dispose();
    return result.phase == IndexPhase.done;
  } finally {
    await db.close();
  }
}
