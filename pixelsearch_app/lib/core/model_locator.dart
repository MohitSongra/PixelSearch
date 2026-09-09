import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ai/ai_logger.dart';

/// **Native-only.** Import this from `*_io.dart` files only — it uses `dart:io`
/// and `path_provider`, so it must never be reachable from the web build.

/// The artifact that was selected, and enough detail to prove *which* one ran.
class ResolvedModel {
  const ResolvedModel({
    required this.path,
    required this.fileName,
    required this.precision,
    required this.bytes,
  });

  final String path;
  final String fileName;

  /// `'fp16'` (production) or `'fp32'` (development / CPU fallback).
  final String precision;
  final int bytes;

  String get sizeMb => (bytes / 1e6).toStringAsFixed(1);

  @override
  String toString() => '$fileName ($precision, $sizeMb MB)';
}

/// Finds the CLIP encoders provisioned under `<app support>/models/`.
///
/// **fp16 is the production artifact** (ADR-004, `INTERFACE_CONTRACT.md` §2) and
/// is always preferred. The fp32 export is accepted as a **development /
/// CPU-testing fallback**, because fp16 needs an fp16-capable execution provider
/// (NNAPI/XNNPACK) and will not run on plain CPU fp32 kernels — see KI-2. Both
/// precisions are numerically verified against the same reference, so falling
/// back changes speed and memory, not results.
///
/// The selected artifact is always logged, so a device run states on the record
/// which file it actually used.
class ModelLocator {
  const ModelLocator({this.log = const AiLog('Models')});

  final AiLog log;

  /// Preference order — production fp16 first, development fp32 second.
  static const List<String> imageCandidates = [
    'mobileclip_image_fp16.onnx',
    'mobileclip_image.onnx',
  ];
  static const List<String> textCandidates = [
    'mobileclip_text_fp16.onnx',
    'mobileclip_text.onnx',
  ];

  /// `<app support>/models` — where M12's model manager will provision to.
  static Future<String> modelsDir() async =>
      p.join((await getApplicationSupportDirectory()).path, 'models');

  /// The first present candidate, preferred order. Use [imageCandidatesPresent]
  /// when the caller can retry, since presence does not imply *loadable*.
  Future<ResolvedModel?> resolveImage() async =>
      (await imageCandidatesPresent()).firstOrNull;

  Future<ResolvedModel?> resolveText() async =>
      (await _present('text', textCandidates)).firstOrNull;

  /// Every image artifact that exists on disk, **preferred first**.
  ///
  /// Callers should try them in order and fall through on a *load* failure, not
  /// just on absence: the realistic failure is an artifact that is present but
  /// unusable — fp16 without a compatible EP (KI-2), or an incompatible/corrupt
  /// artifact (KI-9). Existence alone can't distinguish those.
  Future<List<ResolvedModel>> imageCandidatesPresent() =>
      _present('image', imageCandidates);

  Future<List<ResolvedModel>> _present(
      String label, List<String> candidates) async {
    final dir = await modelsDir();
    final found = <ResolvedModel>[];
    for (final name in candidates) {
      final file = File(p.join(dir, name));
      if (!file.existsSync()) continue;
      found.add(ResolvedModel(
        path: file.path,
        fileName: name,
        precision: name.contains('_fp16') ? 'fp16' : 'fp32',
        bytes: file.lengthSync(),
      ));
    }
    if (found.isEmpty) {
      log.info('$label encoder → NOT FOUND. Looked in $dir for '
          '${candidates.join(" then ")}');
    } else {
      log.info('$label encoder candidates in $dir: '
          '${found.map((m) => m.toString()).join(", ")}');
    }
    return found;
  }

  /// "Where I looked and what for" — surfaced verbatim in the UI so a missing
  /// model is self-diagnosing rather than a dead end.
  static Future<String> describeMissing(List<String> candidates) async =>
      '${await modelsDir()}/{${candidates.join(" | ")}}';
}
