import 'dart:typed_data';

import 'package:pixelsearch/indexing/model/asset_ref.dart';
import 'package:pixelsearch/indexing/ports/asset_embedder.dart';
import 'package:pixelsearch/indexing/ports/gallery_source.dart';
import 'package:pixelsearch/indexing/ports/image_enricher.dart';
import 'package:pixelsearch/indexing/ports/metadata_extractor.dart';
import 'package:pixelsearch/indexing/ports/thumbnail_generator.dart';

/// In-memory gallery. Mutate [assets] to simulate add/remove/change between runs.
class FakeGallery implements GallerySource {
  FakeGallery(this.assets);
  List<AssetRef> assets;
  final Set<String> missingBytes = {}; // ids that fail to load (failure path)

  @override
  Future<List<AssetRef>> listAssets() async => List.of(assets);

  @override
  Future<Uint8List?> loadBytes(String assetId) async =>
      missingBytes.contains(assetId) ? null : Uint8List.fromList([1, 2, 3, 4]);
}

class FakeMetadata implements MetadataExtractor {
  @override
  Future<PhotoMetadata> extract(AssetRef a, Uint8List bytes) async =>
      PhotoMetadata(
          width: a.width,
          height: a.height,
          lat: a.lat,
          lng: a.lng,
          dateTakenMs: a.dateTakenMs);
}

class FakeThumbnails implements ThumbnailGenerator {
  @override
  Future<String> generate(String assetId, Uint8List bytes) async =>
      'thumb/$assetId.jpg';
}

class FakeEnricher implements ImageEnricher {
  @override
  Future<EnrichmentResult> enrich(Uint8List bytes) async =>
      const EnrichmentResult(labels: ['object', 'outdoor'], faces: []);
}

/// Embedder that counts calls, so tests can assert "each asset embedded once"
/// and that no duplicate work happens on incremental re-runs.
class CountingEmbedder implements AssetEmbedder {
  CountingEmbedder({this.onEmbed});
  final void Function(int totalCalls)? onEmbed;
  int total = 0;

  @override
  Future<Float32List> embed(Uint8List imageBytes) async {
    total++;
    onEmbed?.call(total);
    final v = Float32List(512);
    v[0] = total.toDouble(); // deterministic, distinguishable
    return v;
  }
}

AssetRef asset(String id, {int mtime = 1, int size = 100}) =>
    AssetRef(id: id, mtimeMs: mtime, byteSize: size, album: 'Camera');
