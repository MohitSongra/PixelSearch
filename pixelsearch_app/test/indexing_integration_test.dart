import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/indexing/asset_processor.dart';
import 'package:pixelsearch/indexing/index_store.dart';
import 'package:pixelsearch/indexing/indexing_service.dart';
import 'package:pixelsearch/indexing/model/index_progress.dart';
import 'package:pixelsearch/indexing/model_version_manager.dart';
import 'package:pixelsearch/indexing/ports/image_enricher.dart';
import 'package:pixelsearch/models/photo.dart';

import 'indexing_fakes.dart';

/// Enricher returning a fixed label set, standing in for ML Kit image labeling
/// (which needs a device and so cannot run in the sandbox).
class LabellingEnricher implements ImageEnricher {
  LabellingEnricher(this.labels);
  final List<String> labels;

  @override
  Future<EnrichmentResult> enrich(Uint8List bytes) async =>
      EnrichmentResult(labels: labels, faces: const [FaceBox(0, 0, 1, 1)]);
}

/// Regression tests for the two integration bugs: the app used to run a demo
/// gallery loader (hard-capped at 80 photos, synthesizing tags from EXIF
/// dimensions and dates) instead of this pipeline. These pin the properties that
/// were missing — full coverage, and real labels reaching the display model.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  IndexingService service(
    FakeGallery gallery, {
    ImageEnricher? enricher,
  }) {
    final processor = AssetProcessor(
      gallery: gallery,
      metadata: FakeMetadata(),
      thumbnails: FakeThumbnails(),
      embedder: CountingEmbedder(),
      enricher: enricher ?? FakeEnricher(),
    );
    return IndexingService(
      gallery: gallery,
      processor: processor,
      store: IndexStore(db),
      versionManager: const ModelVersionManager(),
      nowMs: () => 111,
    );
  }

  test('indexes the whole gallery — no 80-photo cap', () async {
    const count = 1500; // ≫ the old demo loader's `limit: 80`
    final gallery = FakeGallery([for (var i = 0; i < count; i++) asset('p$i')]);

    final result = await service(gallery).run();

    expect(result.phase, IndexPhase.done);
    expect(result.total, count);
    expect(result.completed, count);
    expect(result.fraction, 1.0); // the UI reaches 100%, not 5%
    expect(await db.photoCount(), count);
    expect(await db.embeddingCount('MobileCLIP-S1', '1'), count);
  });

  test('real labels survive the store and reach Photo.labels', () async {
    final gallery = FakeGallery([asset('dog1')]);
    await service(gallery, enricher: LabellingEnricher(['Dog', 'Pet', 'Animal']))
        .run();

    final photos = await PhotoRepository(db).loadPhotos();
    expect(photos, hasLength(1));
    final photo = photos.single;

    expect(photo.labels, ['dog', 'pet', 'animal']);
    expect(photo.faceCount, 1);
    expect(photo.displayTags, ['dog', 'pet', 'animal']);
    expect(photo.searchBlob, contains('dog'));

    // …and none of the demo loader's synthesized tags come back.
    expect(photo.tags, isEmpty);
    for (final synthetic in ['photo', 'portrait', 'landscape', 'travel']) {
      expect(photo.searchBlob, isNot(contains(synthetic)),
          reason: '"$synthetic" was a demo-loader tag, not an ML Kit label');
    }
  });

  test('indexed thumbnail path reaches Photo for display', () async {
    final gallery = FakeGallery([asset('a')]);
    await service(gallery).run();

    final photo = (await PhotoRepository(db).loadPhotos()).single;

    expect(photo.thumbPath, 'thumb/a.jpg');
    expect(photo.source, PhotoSource.device);
    expect(photo.assetName, isNull); // nothing bundled — this is a real photo
  });
}
