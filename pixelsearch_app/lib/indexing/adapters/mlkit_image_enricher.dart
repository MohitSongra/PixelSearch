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
/// Primary rule is unchanged: keep everything at or above [threshold], ordered
/// by confidence. The addition is the **fallback**: when nothing clears the bar,
/// keep the best [maxFallback] candidates anyway rather than storing no labels
/// at all. On a real library ~0.6% of photos (screenshots, documents, very dark
/// frames) cleared nothing at 0.5 and ended up untagged and effectively
/// unsearchable by keyword.
///
/// The fallback never dilutes a photo that *did* clear the bar — those get
/// exactly the labels they got before — so precision on confident photos is
/// untouched. Pure and synchronous so it is unit-testable without a device.
List<String> selectLabels(
  List<ScoredLabel> candidates, {
  double threshold = 0.5,
  int maxFallback = 3,
}) {
  final ranked = [...candidates]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final confident = [
    for (final c in ranked)
      if (c.confidence >= threshold) c.label
  ];
  if (confident.isNotEmpty) return confident;
  return [for (final c in ranked.take(maxFallback)) c.label];
}

/// Google ML Kit Image Labeling + Face Detection. **Device-only** (Android/iOS).
/// Detectors are created once and reused; ML Kit takes an [InputImage] from a
/// file, so bytes are staged to a temp file per call and cleaned up.
class MlKitImageEnricher implements ImageEnricher {
  MlKitImageEnricher({
    this.confidenceThreshold = 0.5,
    this.fallbackFloor = 0.2,
    this.maxFallbackLabels = 3,
  })  : _labeler = ImageLabeler(
            // Ask ML Kit for everything down to the fallback floor in a SINGLE
            // pass, then apply the real threshold in Dart. Same one inference as
            // before — the coverage fallback costs no extra model run.
            options: ImageLabelerOptions(confidenceThreshold: fallbackFloor)),
        _faces = FaceDetector(options: FaceDetectorOptions());

  /// Labels at or above this confidence are kept — the operating point.
  final double confidenceThreshold;

  /// Lowest confidence ML Kit is asked to report, used only when nothing clears
  /// [confidenceThreshold].
  final double fallbackFloor;

  /// How many best-effort labels to keep for an otherwise-unlabelled photo.
  final int maxFallbackLabels;

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
        labels: selectLabels(
          [for (final l in labels) (label: l.label, confidence: l.confidence)],
          threshold: confidenceThreshold,
          maxFallback: maxFallbackLabels,
        ),
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
