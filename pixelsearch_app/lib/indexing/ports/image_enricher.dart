import 'dart:typed_data';

/// A detected face region in source-image pixel coordinates.
class FaceBox {
  const FaceBox(this.x, this.y, this.w, this.h);
  final double x, y, w, h;

  Map<String, double> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

/// Labels + faces for an image, used for hybrid re-ranking in M6.
class EnrichmentResult {
  const EnrichmentResult({this.labels = const [], this.faces = const []});
  final List<String> labels;
  final List<FaceBox> faces;
  int get faceCount => faces.length;

  static const empty = EnrichmentResult();
}

/// Enriches an image with ML Kit Image Labeling + Face Detection.
/// Device adapter wraps `google_mlkit_*`; the fake returns deterministic data.
abstract interface class ImageEnricher {
  Future<EnrichmentResult> enrich(Uint8List bytes);
}
