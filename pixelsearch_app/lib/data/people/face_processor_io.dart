import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../ai/embedding_math.dart';
import '../../domain/people/face_alignment.dart';
import '../../domain/people/face_contract.dart';
import '../../domain/people/face_grouping.dart';
import 'face_processor_api.dart';

class DetectedFaceData {
  const DetectedFaceData(this.x, this.y, this.w, this.h, this.landmarks);
  final double x, y, w, h;
  final List<(double, double)> landmarks;
}

FaceProcessor createFaceProcessor() => DeviceFaceProcessor();

Future<bool> _matchesHash(String path) async =>
    await File(path).exists() &&
    (await sha256.bind(File(path).openRead()).first).toString() ==
        FaceContract.sha256;

Future<String> provisionFaceModel() async {
  final support = await getApplicationSupportDirectory();
  final file = File(
    p.join(support.path, 'models', p.basename(FaceContract.asset)),
  );
  if (await Isolate.run(() => _matchesHash(file.path))) return file.path;
  final bundled = await rootBundle.load(FaceContract.asset);
  final bytes = bundled.buffer.asUint8List(
    bundled.offsetInBytes,
    bundled.lengthInBytes,
  );
  final data = TransferableTypedData.fromList([bytes]);
  final path = file.path;
  await Isolate.run(() async {
    final contents = data.materialize().asUint8List();
    if (sha256.convert(contents).toString() != FaceContract.sha256) {
      throw const FormatException(
        'Bundled face model failed integrity verification.',
      );
    }
    final target = File(path);
    await target.parent.create(recursive: true);
    final temporary = File('$path.pending');
    await temporary.writeAsBytes(contents, flush: true);
    await temporary.rename(path);
  });
  return path;
}

class DeviceFaceProcessor implements FaceProcessor {
  DeviceFaceProcessor();
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: false,
      enableTracking: false,
      enableClassification: false,
      minFaceSize: 0.02,
    ),
  );
  FaceWorker? _worker;
  static const _decoder = MethodChannel('pixelsearch/people_decode');

  @override
  Future<void> load() async {
    _worker ??= await FaceWorker.start(await provisionFaceModel());
  }

  @override
  Future<List<ProcessedFace>> process(String originalPath) async {
    final worker = _worker;
    if (worker == null) throw StateError('Face model is not loaded.');
    String? staged;
    try {
      if (!Platform.isAndroid) {
        throw UnsupportedError('People processing is Android-first.');
      }
      final prepared = await _decoder.invokeMapMethod<String, dynamic>(
        'prepare',
        {'path': originalPath},
      );
      staged = prepared?['path'] as String?;
      if (staged == null) {
        throw const FormatException('Photo could not be prepared.');
      }
      final faces = await _detector.processImage(
        InputImage.fromFilePath(staged),
      );
      final data = <DetectedFaceData>[];
      for (final face in faces) {
        final box = face.boundingBox;
        final landmarks = <(double, double)>[];
        for (final type in [
          FaceLandmarkType.leftEye,
          FaceLandmarkType.rightEye,
          FaceLandmarkType.noseBase,
          FaceLandmarkType.leftMouth,
          FaceLandmarkType.rightMouth,
        ]) {
          final point = face.landmarks[type]?.position;
          if (point != null) {
            landmarks.add((point.x.toDouble(), point.y.toDouble()));
          }
        }
        // ML Kit's left/right labels are anatomical; SFace expects image order.
        if (landmarks.length == 5) {
          if (landmarks[0].$1 > landmarks[1].$1) {
            final temp = landmarks[0];
            landmarks[0] = landmarks[1];
            landmarks[1] = temp;
          }
          if (landmarks[3].$1 > landmarks[4].$1) {
            final temp = landmarks[3];
            landmarks[3] = landmarks[4];
            landmarks[4] = temp;
          }
        }
        data.add(
          DetectedFaceData(box.left, box.top, box.width, box.height, landmarks),
        );
      }
      data.sort((a, b) {
        final x = a.x.compareTo(b.x);
        return x != 0 ? x : a.y.compareTo(b.y);
      });
      return await worker.process(staged, data);
    } finally {
      if (staged != null) {
        try {
          await File(staged).delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _detector.close();
    await _worker?.close();
    _worker = null;
    if (Platform.isAndroid) await _decoder.invokeMethod<void>('clearTemporary');
  }
}

class FaceWorker {
  FaceWorker._(this._isolate, this._receive, this._messages, this._send);
  final Isolate _isolate;
  final ReceivePort _receive;
  final StreamIterator<dynamic> _messages;
  final SendPort _send;
  bool _closed = false;

  static Future<FaceWorker> start(String path) async {
    final receive = ReceivePort();
    final messages = StreamIterator<dynamic>(receive);
    final isolate = await Isolate.spawn(_faceWorkerMain, receive.sendPort);
    try {
      if (!await messages.moveNext().timeout(const Duration(seconds: 30))) {
        throw StateError('Face worker stopped.');
      }
      final worker = FaceWorker._(
        isolate,
        receive,
        messages,
        messages.current as SendPort,
      );
      await worker._call({'operation': 'load', 'path': path});
      return worker;
    } catch (_) {
      isolate.kill();
      receive.close();
      await messages.cancel();
      rethrow;
    }
  }

  Future<dynamic> _call(Map<String, Object?> request) async {
    if (_closed) throw StateError('Face worker closed.');
    _send.send(request);
    try {
      if (!await _messages.moveNext().timeout(const Duration(minutes: 2))) {
        throw StateError('Face worker stopped.');
      }
    } catch (_) {
      _closed = true;
      _isolate.kill(priority: Isolate.immediate);
      _receive.close();
      await _messages.cancel();
      rethrow;
    }
    final response = _messages.current as Map;
    if (response['error'] != null) {
      throw StateError(response['error'] as String);
    }
    return response['value'];
  }

  Future<List<ProcessedFace>> process(
    String path,
    List<DetectedFaceData> faces,
  ) async =>
      ((await _call({'operation': 'process', 'path': path, 'faces': faces}))
              as List)
          .cast<ProcessedFace>();

  Future<void> close() async {
    if (_closed) return;
    try {
      await _call({'operation': 'close'});
    } finally {
      _closed = true;
      _receive.close();
      await _messages.cancel();
      _isolate.kill();
    }
  }
}

Future<void> _faceWorkerMain(SendPort parent) async {
  final receive = ReceivePort();
  parent.send(receive.sendPort);
  OrtSession? session;
  OrtSessionOptions? options;
  var ownsEnvironment = false;
  try {
    await for (final raw in receive) {
      final message = raw as Map;
      try {
        if (message['operation'] == 'close') {
          session?.release();
          session = null;
          options?.release();
          options = null;
          if (ownsEnvironment) {
            OrtEnv.instance.release();
            ownsEnvironment = false;
          }
          parent.send({'value': null});
          break;
        }
        if (message['operation'] == 'load') {
          OrtEnv.instance.init(level: OrtLoggingLevel.error);
          ownsEnvironment = true;
          options = OrtSessionOptions()
            ..setIntraOpNumThreads(2)
            ..setInterOpNumThreads(1);
          final file = File(message['path'] as String);
          // Plugin 1.4.1 passes UTF-8 filenames to Windows' UTF-16 ORT API.
          // Android uses file-backed loading; desktop parity uses the byte API.
          session = Platform.isWindows
              ? OrtSession.fromBuffer(await file.readAsBytes(), options)
              : OrtSession.fromFile(file, options);
          final probe = Float32List(3 * 112 * 112)
            ..fillRange(0, 3 * 112 * 112, 127);
          _embedFace(session, probe);
          parent.send({'value': true});
          continue;
        }
        if (session == null) throw StateError('Face model not loaded.');
        final decoded = img.decodeImage(
          await File(message['path'] as String).readAsBytes(),
        );
        if (decoded == null) {
          throw const FormatException('Prepared photo is unreadable.');
        }
        final output = <ProcessedFace>[];
        for (final face
            in (message['faces'] as List).cast<DetectedFaceData>()) {
          if (![face.x, face.y, face.w, face.h].every((v) => v.isFinite) ||
              face.w <= 0 ||
              face.h <= 0) {
            continue;
          }
          final x = face.x.round().clamp(0, decoded.width - 1);
          final y = face.y.round().clamp(0, decoded.height - 1);
          final w = face.w.round().clamp(1, decoded.width - x);
          final h = face.h.round().clamp(1, decoded.height - y);
          var quality = face.landmarks.length == 5
              ? 'ready'
              : 'missing landmarks';
          if (w < FaceContract.minFacePixels ||
              h < FaceContract.minFacePixels) {
            quality = 'small face';
          }
          Float32List? vector;
          img.Image? aligned;
          if (quality == 'ready') {
            try {
              aligned = alignFace(decoded, face.landmarks);
              vector = _embedFace(session, faceTensor(aligned));
            } catch (_) {
              quality = 'invalid descriptor';
            }
          }
          final preview =
              aligned ??
              img.copyResize(
                img.copyCrop(decoded, x: x, y: y, width: w, height: h),
                width: 112,
                height: 112,
                interpolation: img.Interpolation.linear,
              );
          output.add(
            ProcessedFace(
              x: x / decoded.width,
              y: y / decoded.height,
              w: w / decoded.width,
              h: h / decoded.height,
              landmarks: face.landmarks
                  .map((p) => (p.$1 / decoded.width, p.$2 / decoded.height))
                  .toList(),
              quality: quality,
              preview: Uint8List.fromList(img.encodeJpg(preview, quality: 90)),
              vector: vector,
            ),
          );
        }
        parent.send({'value': output});
      } catch (e) {
        parent.send({
          'error': const bool.fromEnvironment('SFACE_MODEL_TEST')
              ? '$e'
              : 'Offline face processing failed (${e.runtimeType}).',
        });
      }
    }
  } finally {
    session?.release();
    options?.release();
    receive.close();
    if (ownsEnvironment) OrtEnv.instance.release();
  }
}

Float32List _embedFace(OrtSession session, Float32List pixels) {
  final tensor = OrtValueTensor.createTensorWithDataList(pixels, [
    1,
    3,
    112,
    112,
  ]);
  final run = OrtRunOptions();
  List<OrtValue?>? outputs;
  try {
    outputs = session.run(
      run,
      {FaceContract.input: tensor},
      [FaceContract.output],
    );
    final batch = outputs.first?.value as List;
    final vector = l2Normalize(
      Float32List.fromList((batch.first as List).cast<double>()),
    );
    if (!validFaceVector(vector)) {
      throw const FormatException('SFace output is invalid.');
    }
    return vector;
  } finally {
    tensor.release();
    run.release();
    for (final output in outputs ?? <OrtValue?>[]) {
      output?.release();
    }
  }
}
