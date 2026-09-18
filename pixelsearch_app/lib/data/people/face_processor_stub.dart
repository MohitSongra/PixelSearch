import 'face_processor_api.dart';

FaceProcessor createFaceProcessor() => _Unavailable();

class _Unavailable implements FaceProcessor {
  @override
  Future<void> load() async =>
      throw UnsupportedError('People processing needs Android.');
  @override
  Future<List<ProcessedFace>> process(String originalPath) async => [];
  @override
  Future<void> dispose() async {}
}
