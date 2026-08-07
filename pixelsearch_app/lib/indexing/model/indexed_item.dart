import 'dart:typed_data';

import '../ports/image_enricher.dart';
import '../ports/metadata_extractor.dart';
import 'asset_ref.dart';

/// A fully-processed asset ready to be persisted in one batch transaction.
class IndexedItem {
  const IndexedItem({
    required this.asset,
    required this.meta,
    required this.embedding,
    this.thumbPath,
    this.labels = const [],
    this.faces = const [],
  });

  final AssetRef asset;
  final PhotoMetadata meta;
  final Float32List embedding;
  final String? thumbPath;
  final List<String> labels;
  final List<FaceBox> faces;
}
