import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/indexing/asset_processor.dart';
import 'package:pixelsearch/indexing/index_store.dart';
import 'package:pixelsearch/indexing/indexing_service.dart';
import 'package:pixelsearch/indexing/model/index_config.dart';
import 'package:pixelsearch/indexing/model/index_progress.dart';
import 'package:pixelsearch/indexing/model_version_manager.dart';

import 'indexing_fakes.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  IndexStore storeFor(String version) =>
      IndexStore(db, embeddingVersion: version);

  IndexingService service(
    FakeGallery g, {
    required IndexStore store,
    required CountingEmbedder emb,
    String version = '1',
    int batchSize = 32,
  }) {
    final processor = AssetProcessor(
      gallery: g,
      metadata: FakeMetadata(),
      thumbnails: FakeThumbnails(),
      embedder: emb,
      enricher: FakeEnricher(),
    );
    return IndexingService(
      gallery: g,
      processor: processor,
      store: store,
      versionManager: ModelVersionManager(currentVersion: version),
      config: IndexConfig(batchSize: batchSize, profileEvery: 0),
      nowMs: () => 111,
    );
  }

  test(
    'full index persists all photos + embeddings; embeds once each',
    () async {
      final g = FakeGallery([asset('a'), asset('b'), asset('c')]);
      final emb = CountingEmbedder();
      final p = await service(g, store: storeFor('1'), emb: emb).run();
      expect(p.phase, IndexPhase.done);
      expect(p.completed, 3);
      expect(emb.total, 3);
      expect(await db.photoCount(), 3);
      expect(await db.embeddingCount('MobileCLIP-S1', '1'), 3);
    },
  );

  test('incremental re-run does no duplicate work', () async {
    final g = FakeGallery([asset('a'), asset('b')]);
    final emb = CountingEmbedder();
    final store = storeFor('1');
    await service(g, store: store, emb: emb).run();
    expect(emb.total, 2);
    final p = await service(g, store: store, emb: emb).run();
    expect(p.completed, 0);
    expect(emb.total, 2); // nothing re-embedded
  });

  test('new asset only indexes the new one', () async {
    final g = FakeGallery([asset('a')]);
    final emb = CountingEmbedder();
    final store = storeFor('1');
    await service(g, store: store, emb: emb).run();
    g.assets = [asset('a'), asset('b')];
    final p = await service(g, store: store, emb: emb).run();
    expect(p.completed, 1);
    expect(emb.total, 2);
    expect(await db.photoCount(), 2);
  });

  test('deleted asset is removed with its embedding', () async {
    final g = FakeGallery([asset('a'), asset('b')]);
    await service(g, store: storeFor('1'), emb: CountingEmbedder()).run();
    g.assets = [asset('a')];
    final p = await service(
      g,
      store: storeFor('1'),
      emb: CountingEmbedder(),
    ).run();
    expect(p.deleted, 1);
    expect(await db.photoCount(), 1);
    expect(await db.embeddingCount('MobileCLIP-S1', '1'), 1);
  });

  test('changed asset (mtime) is re-embedded', () async {
    final g = FakeGallery([asset('a', mtime: 1)]);
    await service(g, store: storeFor('1'), emb: CountingEmbedder()).run();
    g.assets = [asset('a', mtime: 2)];
    final emb2 = CountingEmbedder();
    final p = await service(g, store: storeFor('1'), emb: emb2).run();
    expect(p.completed, 1);
    expect(emb2.total, 1);
    expect(await db.photoCount(), 1); // upsert, not duplicate
  });

  test('model version migration re-embeds everything', () async {
    final g = FakeGallery([asset('a'), asset('b')]);
    await service(
      g,
      store: storeFor('1'),
      emb: CountingEmbedder(),
      version: '1',
    ).run();
    final emb2 = CountingEmbedder();
    final p = await service(
      g,
      store: storeFor('2'),
      emb: emb2,
      version: '2',
    ).run();
    expect(p.completed, 2);
    expect(emb2.total, 2);
    expect(await db.embeddingCount('MobileCLIP-S1', '2'), 2);
    expect(await db.embeddingCount('MobileCLIP-S1', '1'), 0); // v1 replaced
  });

  test('cancellation persists partial work; resume completes it', () async {
    final g = FakeGallery([for (var i = 0; i < 5; i++) asset('a$i')]);
    final store = storeFor('1');
    late IndexingService svc;
    final emb = CountingEmbedder(
      onEmbed: (n) {
        if (n == 3) svc.cancel();
      },
    );
    svc = service(g, store: store, emb: emb, batchSize: 2);
    final p = await svc.run();
    expect(p.phase, IndexPhase.cancelled);
    expect(await db.photoCount(), 3); // partial work persisted

    final emb2 = CountingEmbedder();
    final p2 = await service(g, store: store, emb: emb2, batchSize: 2).run();
    expect(p2.phase, IndexPhase.done);
    expect(emb2.total, 2); // only the remaining two
    expect(await db.photoCount(), 5);
  });

  test('per-asset failure is isolated; the rest succeed', () async {
    final g = FakeGallery([asset('good1'), asset('bad'), asset('good2')]);
    g.missingBytes.add('bad');
    final p = await service(
      g,
      store: storeFor('1'),
      emb: CountingEmbedder(),
    ).run();
    expect(p.phase, IndexPhase.done);
    expect(p.failed, 1);
    expect(p.completed, 2);
    expect(await db.photoCount(), 2);
  });

  test('stress: 200 assets index, persist, and checkpoint', () async {
    final g = FakeGallery([for (var i = 0; i < 200; i++) asset('s$i')]);
    final store = storeFor('1');
    final p = await service(
      g,
      store: store,
      emb: CountingEmbedder(),
      batchSize: 32,
    ).run();
    expect(p.completed, 200);
    expect(await db.photoCount(), 200);
    expect((await store.loadCheckpoint()).embedded, 200);
  });

  test('dispose releases composed resources once', () async {
    var releases = 0;
    final svc = IndexingService(
      gallery: FakeGallery(const []),
      processor: AssetProcessor(
        gallery: FakeGallery(const []),
        metadata: FakeMetadata(),
        thumbnails: FakeThumbnails(),
        embedder: CountingEmbedder(),
        enricher: FakeEnricher(),
      ),
      store: storeFor('1'),
      versionManager: const ModelVersionManager(),
      onDispose: () async => releases++,
    );

    await svc.dispose();
    await svc.dispose();

    expect(releases, 1);
  });
}
