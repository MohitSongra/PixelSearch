import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ports/image_enricher.dart';

/// Google ML Kit Image Labeling + Face Detection. **Device-only** (Android/iOS).
/// Detectors are created once and reused; ML Kit takes an [InputImage] from a
/// file, so bytes are staged to a temp file per call and cleaned up.
class MlKitImageEnricher implements ImageEnricher {
  MlKitImageEnricher({double confidenceThreshold = 0.5})
      : _labeler = ImageLabeler(
            options: ImageLabelerOptions(confidenceThreshold: confidenceThreshold)),
        _faces = FaceDetector(options: FaceDetectorOptions());

  final ImageLabeler _labeler;
  final FaceDetector _faces;

  @override
  Future<EnrichmentResult> enrich(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final tmp = File(p.join(
        dir.path, 'mlkit_${DateTime.now().microsecondsSinceEpoch}.jpg'));
    await tmp.writeAsBytes(bytes, flush: true);
    try {
      final input = InputImage.fromFilePath(tmp.path);
      final labels = await _labeler.processImage(input);
      final faces = await _faces.processImage(input);
      return EnrichmentResult(
        labels: [for (final l in labels) l.label],
        faces: [
          for (final f in faces)
            // ML Kit boundingBox is in pixels; M6 normalizes if it needs to.
            FaceBox(f.boundingBox.left, f.boundingBox.top, f.boundingBox.width,
                f.boundingBox.height)
        ],
      );
    } finally {
      if (tmp.existsSync()) {
        try {
          tmp.deleteSync();
        } catch (_) {/* ignore cleanup errors */}
      }
    }
  }

  Future<void> dispose() async {
    await _labeler.close();
    await _faces.close();
  }
}
