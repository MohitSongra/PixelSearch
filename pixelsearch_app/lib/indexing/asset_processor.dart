import 'package:image/image.dart' as img;

import '../ai/ai_logger.dart';
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
    this.log = const AiLog('AssetProcessor'),
  });

  final GallerySource gallery;
  final MetadataExtractor metadata;
  final ThumbnailGenerator thumbnails;
  final AssetEmbedder embedder;
  final ImageEnricher enricher;
  final AiLog log;

  // --- stage profile (instrumentation only; no effect on behaviour) ---------
  // Cumulative wall-clock per stage, logged every [_profileEvery] assets so a
  // device run reports where its time actually goes instead of being guessed at.
  int _n = 0;
  int _msLoad = 0,
      _msMeta = 0,
      _msDecode = 0,
      _msThumb = 0,
      _msEmbed = 0,
      _msEnrich = 0;

  Future<IndexedItem> process(AssetRef asset, IndexConfig config) async {
    try {
      final sw = Stopwatch()..start();
      final bytes = await gallery.loadBytes(asset.id);
      if (bytes == null) {
        throw StateError('gallery returned no bytes for ${asset.id}');
      }
      final tLoad = sw.elapsedMilliseconds;

      final meta = await metadata.extract(asset, bytes);
      final tMeta = sw.elapsedMilliseconds;

      // Decode ONCE. Thumbnailing and embedding both need the same pixels, and
      // each used to decode the JPEG itself — two full decodes per photo.
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException('could not decode image');
      }
      final tDecode = sw.elapsedMilliseconds;

      final thumb = config.generateThumbnails
          ? await thumbnails.generate(asset.id, decoded)
          : null;
      final tThumb = sw.elapsedMilliseconds;

      final embedding = await embedder.embed(decoded);
      final tEmbed = sw.elapsedMilliseconds;

      final enrichment = config.enrich
          ? await enricher.enrich(bytes)
          : EnrichmentResult.empty;
      final tEnrich = sw.elapsedMilliseconds;

      _n++;
      _msLoad += tLoad;
      _msMeta += tMeta - tLoad;
      _msDecode += tDecode - tMeta;
      _msThumb += tThumb - tDecode;
      _msEmbed += tEmbed - tThumb;
      _msEnrich += tEnrich - tEmbed;
      if (config.profileEvery > 0 && _n % config.profileEvery == 0) {
        final total =
            _msLoad + _msMeta + _msDecode + _msThumb + _msEmbed + _msEnrich;
        String avg(int ms) => (ms / _n).toStringAsFixed(0);
        String pct(int ms) =>
            total == 0 ? '0' : (100 * ms / total).toStringAsFixed(0);
        log.info(
          'profile over $_n assets (${(total / _n).toStringAsFixed(0)} ms/photo, '
          '${decoded.width}x${decoded.height}): '
          'loadBytes ${avg(_msLoad)}ms/${pct(_msLoad)}% · '
          'exif ${avg(_msMeta)}ms/${pct(_msMeta)}% · '
          'decode ${avg(_msDecode)}ms/${pct(_msDecode)}% · '
          'thumbnail ${avg(_msThumb)}ms/${pct(_msThumb)}% · '
          'embed ${avg(_msEmbed)}ms/${pct(_msEmbed)}% · '
          'mlkit ${avg(_msEnrich)}ms/${pct(_msEnrich)}%',
        );
      }

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
