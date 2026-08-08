import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../core/ai_contract.dart';
import 'ai_logger.dart';
import 'embedding_math.dart';

/// Thrown for any encoder failure (missing model, bad output shape, …).
class OnnxEncoderException implements Exception {
  OnnxEncoderException(this.message);
  final String message;
  @override
  String toString() => 'OnnxEncoderException: $message';
}

/// Shared ONNX Runtime session lifecycle for the CLIP encoders (image & text).
///
/// Owns the single responsibility both encoders have in common — load a model
/// once, reuse the session for every call, run a single input tensor to an
/// L2-normalized 512-d embedding, and release everything — so each concrete
/// encoder only has to build its own input tensor. See ADR-011.
abstract class OnnxEncoder {
  OnnxEncoder({required this.modelPath, this.log = const AiLog('OnnxEncoder')});

  final String modelPath;
  final AiLog log;

  OrtSession? _session;
  OrtSessionOptions? _options;
  static bool _envInitialized = false;

  /// One-shot flag so the "inference actually ran" proof is logged once per
  /// session rather than once per photo.
  bool _loggedFirstInference = false;

  /// Short label for logs/errors, e.g. 'image' or 'text'.
  String get label;

  /// Half the cores, clamped to [1,4]: leaves headroom for the JPEG decode and
  /// ML Kit passes that run alongside inference during an indexing sweep.
  static int get _intraOpThreads {
    final half = Platform.numberOfProcessors ~/ 2;
    return half < 1 ? 1 : (half > 4 ? 4 : half);
  }

  bool get isLoaded => _session != null;

  Future<void> load() async {
    if (_session != null) return;
    try {
      if (!_envInitialized) {
        OrtEnv.instance.init();
        _envInitialized = true;
      }
      final file = File(modelPath);
      if (!file.existsSync()) {
        throw OnnxEncoderException('$label model not found at "$modelPath"');
      }
      _options = OrtSessionOptions();
      // ORT defaults to a single intra-op thread here, which left 7 of 8 cores
      // idle while indexing. Convolutions parallelise well, so give it half the
      // cores — enough to speed inference without starving the decode/ML Kit
      // work sharing the device. Thread count changes only summation order
      // inside the graph (~1e-7 on an L2-normalised vector), never the model.
      final threads = _intraOpThreads;
      _options!.setIntraOpNumThreads(threads);
      log.info('$label session: intraOpThreads=$threads '
          '(${Platform.numberOfProcessors} cores)');
      final sw = Stopwatch()..start();
      _session = OrtSession.fromFile(file, _options!);
      sw.stop();
      log.info('loaded ${AiContract.modelId} $label encoder in '
          '${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      log.error('$label load failed', e, st);
      await dispose();
      rethrow;
    }
  }

  /// Run the session on a single [input] tensor (named [inputName]) and return
  /// the L2-normalized 512-d embedding. Always releases [input] and the outputs.
  Future<Float32List> runEmbedding(OrtValueTensor input, String inputName) async {
    final session = _session;
    if (session == null) {
      input.release();
      throw OnnxEncoderException('$label: embed() called before load()');
    }
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;
    try {
      runOptions = OrtRunOptions();
      final sw = _loggedFirstInference ? null : (Stopwatch()..start());
      outputs = session.run(runOptions, {inputName: input});
      final embedding = l2Normalize(_extract512(outputs));
      if (sw != null) {
        // Proof, on the record, that the real ONNX encoder executed on this
        // device — not just that the file loaded. Logged once per session.
        _loggedFirstInference = true;
        var sumSq = 0.0;
        for (final v in embedding) {
          sumSq += v * v;
        }
        log.info('$label encoder ran its first inference in '
            '${sw.elapsedMilliseconds}ms → ${embedding.length}-d embedding, '
            'norm=${sqrt(sumSq).toStringAsFixed(6)} (want 1.000000)');
      }
      return embedding;
    } on OnnxEncoderException {
      rethrow;
    } catch (e, st) {
      log.error('$label inference failed', e, st);
      throw OnnxEncoderException('$label inference failed: $e');
    } finally {
      input.release();
      runOptions?.release();
      if (outputs != null) {
        for (final o in outputs) {
          o?.release();
        }
      }
    }
  }

  Future<void> dispose() async {
    _session?.release();
    _session = null;
    _options?.release();
    _options = null;
    // OrtEnv is process-global and cheap to keep; leave it for session reuse.
  }

  Float32List _extract512(List<OrtValue?> outputs) {
    if (outputs.isEmpty || outputs.first == null) {
      throw OnnxEncoderException('$label model produced no output');
    }
    final batch = outputs.first!.value as List;
    final row = (batch.first as List).cast<double>();
    if (row.length != AiContract.embeddingDim) {
      throw OnnxEncoderException(
          '$label expected ${AiContract.embeddingDim}-d embedding, got ${row.length}');
    }
    return Float32List.fromList(row);
  }
}
