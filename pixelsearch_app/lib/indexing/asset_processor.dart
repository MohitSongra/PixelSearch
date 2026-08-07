import 'model/asset_ref.dart';
import 'model/index_config.dart';
import 'model/indexed_item.dart';
import 'ports/asset_embedder.dart';
import 'ports/gallery_source.dart';
import 'ports/image_enricher.dart';
import 'ports/metadata_extractor.dart';
import 'ports/thumbnail_generator.dart';

/// Raised when one asset fails to process; the run records it and continues, so
/// a single bad photo never aborts a 50k index.
class AssetProcessingException implements Exception {
  AssetProcessingException(this.assetId, this.cause);
  final String assetId;
  final Object cause;
  @override
  String toString() => 'AssetProcessingException($assetId): $cause';
}

/// Turns one asset into a persistable [IndexedItem] by running the pipeline
/// bytes → EXIF → thumbnail → embed → enrich. Single responsibility; every stage
/// is a port, so the processor is fully unit-testable with fakes.
class AssetProcessor {
  AssetProcessor({
    required this.gallery,
    required this.metadata,
    required this.thumbnails,
    required this.embedder,
    required this.enricher,
  });

  final GallerySource gallery;
  final MetadataExtractor metadata;
  final ThumbnailGenerator thumbnails;
  final AssetEmbedder embedder;
  final ImageEnricher enricher;

  Future<IndexedItem> process(AssetRef asset, IndexConfig config) async {
    try {
      final bytes = await gallery.loadBytes(asset.id);
      if (bytes == null) {
        throw StateError('gallery returned no bytes for ${asset.id}');
      }
      final meta = await metadata.extract(asset, bytes);
      final thumb =
          config.generateThumbnails ? await thumbnails.generate(asset.id, bytes) : null;
      final embedding = await embedder.embed(bytes);
      final enrichment =
          config.enrich ? await enricher.enrich(bytes) : EnrichmentResult.empty;
      return IndexedItem(
        asset: asset,
        meta: meta,
        embedding: embedding,
        thumbPath: thumb,
        labels: enrichment.labels,
        faces: enrichment.faces,
      );
    } catch (e) {
      throw AssetProcessingException(asset.id, e);
    }
  }
}
