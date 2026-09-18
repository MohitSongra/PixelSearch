import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../ai/ai_logger.dart';
import '../../domain/people/face_contract.dart';
import '../../domain/people/face_grouping.dart';
import 'face_processor_io.dart';

/// Numerical test images only. Never reads gallery content or assigns people.
Future<Map<String, Object?>> checkFaceModel() async {
  final reference =
      jsonDecode(
            await rootBundle.loadString('assets/models/sface_reference.json'),
          )
          as Map;
  final fixture = await rootBundle.load(
    'assets/models/sface_reference_source.png',
  );
  final temporary = await Directory(
    p.join((await getTemporaryDirectory()).path, 'sface_check'),
  ).create(recursive: true);
  final source = File(p.join(temporary.path, 'reference.png'));
  await source.writeAsBytes(
    fixture.buffer.asUint8List(fixture.offsetInBytes, fixture.lengthInBytes),
  );
  final watch = Stopwatch()..start();
  FaceWorker? worker;
  try {
    worker = await FaceWorker.start(await provisionFaceModel());
    final rows = <Map<String, Object?>>[];
    for (final row in reference['cases'] as List) {
      final points = [
        for (final point in row['landmarks'] as List)
          ((point[0] as num).toDouble(), (point[1] as num).toDouble()),
      ];
      final output = await worker.process(source.path, [
        DetectedFaceData(0, 0, 200, 200, points),
      ]);
      final vector = output.single.vector;
      if (vector == null || !validFaceVector(vector)) {
        throw StateError('Face model output is invalid.');
      }
      final expected = Float32List.fromList(
        (row['vector'] as List).cast<num>().map((v) => v.toDouble()).toList(),
      );
      final cosine = faceCosine(vector, expected);
      rows.add({
        'fixture': row['name'],
        'cosine': cosine,
        'dimensions': vector.length,
        'passed': cosine > .999,
      });
    }
    final report = <String, Object?>{
      'contract': FaceContract.id,
      'model_sha256': FaceContract.sha256,
      'platform': Platform.operatingSystem,
      'execution': 'CPU',
      'elapsed_ms': watch.elapsedMilliseconds,
      'passed': rows.every((r) => r['passed'] == true),
      'cases': rows,
      'scope': 'OpenCV numerical parity, not person-recognition accuracy',
    };
    const AiLog('PeopleModelCheck').info(jsonEncode(report));
    return report;
  } finally {
    await worker?.close();
    if (await source.exists()) await source.delete();
  }
}
