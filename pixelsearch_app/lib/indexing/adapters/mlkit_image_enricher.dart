import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ports/image_enricher.dart';

/// A candidate label with the confidence ML Kit assigned it.
typedef ScoredLabel = ({String label, double confidence});

/// Chooses which labels to keep for one photo.
///
/// Low-confidence guesses are not substitutes for missing labels. An unlabelled
/// image still has its semantic embedding and remains searchable.
List<String> selectLabels(
  List<ScoredLabel> candidates, {
  double threshold = 0.5,
}) {
  final ranked = [...candidates]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final confident = [
    for (final c in ranked)
      if (c.confidence.isFinite &&
          c.confidence >= threshold &&
          c.confidence <= 1)
        c.label,
  ];
  return confident;
}

/// Google ML Kit Image Labeling + Face Detection. **Device-only** (Android/iOS).
/// Detectors are created once and reused; ML Kit takes an [InputImage] from a
/// file, so bytes are staged to a temp file per call and cleaned up.
class MlKitImageEnricher implements ImageEnricher {
  MlKitImageEnricher({this.confidenceThreshold = 0.5})
    : _labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: confidenceThreshold),
      ),
      _faces = FaceDetector(options: FaceDetectorOptions());

  /// Labels at or above this confidence are kept — the operating point.
  final double confidenceThreshold;

  final ImageLabeler _labeler;
  final FaceDetector _faces;

  @override
  Future<EnrichmentResult> enrich(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final tmp = File(
      p.join(dir.path, 'mlkit_${DateTime.now().microsecondsSinceEpoch}.jpg'),
    );
    await tmp.writeAsBytes(bytes, flush: true);
    try {
      final input = InputImage.fromFilePath(tmp.path);
      final labels = await _labeler.processImage(input);
      final faces = await _faces.processImage(input);
      return EnrichmentResult(
        labels: selectLabels([
          for (final l in labels) (label: l.label, confidence: l.confidence),
        ], threshold: confidenceThreshold),
        faces: [
          for (final f in faces)
            // ML Kit boundingBox is in pixels; M6 normalizes if it needs to.
            FaceBox(
              f.boundingBox.left,
              f.boundingBox.top,
              f.boundingBox.width,
              f.boundingBox.height,
            ),
        ],
      );
    } finally {
      if (tmp.existsSync()) {
        try {
          tmp.deleteSync();
        } catch (_) {
          /* ignore cleanup errors */
        }
      }
    }
  }

  Future<void> dispose() async {
    await _labeler.close();
    await _faces.close();
  }
}
