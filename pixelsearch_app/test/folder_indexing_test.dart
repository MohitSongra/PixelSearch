import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/indexing/asset_processor.dart';
import 'package:pixelsearch/indexing/index_store.dart';
import 'package:pixelsearch/indexing/indexing_service.dart';
import 'package:pixelsearch/indexing/model/index_config.dart';
import 'package:pixelsearch/indexing/model/index_progress.dart';
import 'package:pixelsearch/indexing/model_version_manager.dart';
import 'package:pixelsearch/indexing/ports/gallery_source.dart';

import 'indexing_fakes.dart';

class ScopedFakeGallery extends FakeGallery {
  ScopedFakeGallery()
    : super([asset('camera'), asset('trip'), asset('deleted')]);
  Set<String> selection = {'camera', 'trip', 'deleted'};
  bool limited = false;

  @override
  Future<GallerySnapshot> listAssets() async => GallerySnapshot(
    assets.where((a) => selection.contains(a.id)).toList(),
    existingAssetIds: assets.map((a) => a.id).toSet(),
    canDeleteMissing: !limited,
  );
}

void main() {
  test(
    'folder changes retain searchable rows, skip existing, and remove real deletions',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final gallery = ScopedFakeGallery();
      final embedder = CountingEmbedder();
      final service = IndexingService(
        gallery: gallery,
        processor: AssetProcessor(
          gallery: gallery,
          metadata: FakeMetadata(),
          thumbnails: FakeThumbnails(),
          embedder: embedder,
          enricher: FakeEnricher(),
        ),
        store: IndexStore(db),
        versionManager: const ModelVersionManager(),
        config: const IndexConfig(profileEvery: 0),
      );
      addTearDown(service.dispose);
      await service.run();
      expect(embedder.total, 3);
      gallery.assets = [
        asset('camera', mtime: 2),
        asset('trip'),
        asset('new'),
        asset('excluded'),
      ];
      gallery.selection = {'trip', 'new'};
      final result = await service.run();
      expect(result.phase, IndexPhase.done);
      expect(result.total, 1);
      expect(result.completed, 1);
      expect(result.fraction, 1);
      expect(result.deleted, 1);
      expect(embedder.total, 4);
      final photos = await PhotoRepository(db).loadPhotos();
      expect(photos.map((p) => p.id).toSet(), {'camera', 'trip', 'new'});
      expect((await PhotoRepository(db).loadEmbeddings()).keys.toSet(), {
        'camera',
        'trip',
        'new',
      });
      gallery.selection = {'camera'};
      final reselected = await service.run();
      expect(reselected.completed, 1); // changed while deselected
      expect(embedder.total, 5);
      expect((await service.run()).completed, 0); // unchanged repeat
    },
  );

  test(
    'limited access never deletes already-indexed unlisted photos',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final gallery = ScopedFakeGallery();
      final service = IndexingService(
        gallery: gallery,
        processor: AssetProcessor(
          gallery: gallery,
          metadata: FakeMetadata(),
          thumbnails: FakeThumbnails(),
          embedder: CountingEmbedder(),
          enricher: FakeEnricher(),
        ),
        store: IndexStore(db),
        versionManager: const ModelVersionManager(),
        config: const IndexConfig(profileEvery: 0),
      );
      addTearDown(service.dispose);
      await service.run();
      gallery.limited = true;
      gallery.assets = [asset('camera')];
      gallery.selection = {'camera'};
      expect((await service.run()).deleted, 0);
      expect(await db.photoCount(), 3);
    },
  );
}
