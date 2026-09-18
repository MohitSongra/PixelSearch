import 'dart:typed_data';

class ProcessedFace {
  const ProcessedFace({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.landmarks,
    required this.quality,
    required this.preview,
    this.vector,
  });
  final double x, y, w, h;
  final List<(double, double)> landmarks;
  final String quality;
  final Uint8List preview;
  final Float32List? vector;
}

abstract interface class FaceProcessor {
  Future<void> load();
  Future<List<ProcessedFace>> process(String originalPath);
  Future<void> dispose();
}
