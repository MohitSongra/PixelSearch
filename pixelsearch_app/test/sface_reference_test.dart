import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixelsearch/data/people/face_processor_io.dart';
import 'package:pixelsearch/domain/people/face_alignment.dart';
import 'package:pixelsearch/domain/people/face_grouping.dart';

void main() {
  final root = Directory('test/fixtures/sface');
  final reference =
      jsonDecode(File('${root.path}/reference.json').readAsStringSync()) as Map;
  for (final row in reference['cases'] as List) {
    final name = row['name'] as String;
    final landmarks = [
      for (final p in row['landmarks'] as List)
        ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    test('Dart alignment matches OpenCV alignCrop: $name', () {
      final source = img.decodePng(
        File('${root.path}/source.png').readAsBytesSync(),
      )!;
      final expected = img.decodePng(
        File('${root.path}/$name.png').readAsBytesSync(),
      )!;
      final actual = alignFace(source, landmarks);
      var maximum = 0.0, total = 0.0;
      for (var y = 0; y < 112; y++) {
        for (var x = 0; x < 112; x++) {
          final a = actual.getPixel(x, y), b = expected.getPixel(x, y);
          for (final error in [
            (a.r - b.r).abs(),
            (a.g - b.g).abs(),
            (a.b - b.b).abs(),
          ]) {
            maximum = math.max(maximum, error.toDouble());
            total += error;
          }
        }
      }
      final mae = total / (112 * 112 * 3);
      // Raster interpolation tolerance only, never an identity threshold.
      // ignore: avoid_print
      print('OpenCV alignment $name: mean_abs_pixel_error=$mae max=$maximum');
      expect(mae, lessThan(.25));
      expect(maximum, lessThanOrEqualTo(10));
    });
  }

  test(
    'production worker CPU output matches OpenCV reference descriptors',
    () async {
      final worker = await FaceWorker.start(
        'assets/models/face_recognition_sface_2021dec.onnx',
      );
      addTearDown(worker.close);
      for (final row in reference['cases'] as List) {
        final landmarks = [
          for (final p in row['landmarks'] as List)
            ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
        ];
        final faces = await worker.process('${root.path}/source.png', [
          DetectedFaceData(0, 0, 200, 200, landmarks),
        ]);
        final vector = faces.single.vector!;
        expect(vector.length, 128);
        expect(validFaceVector(vector), isTrue);
        final expected = Float32List.fromList(
          (row['vector'] as List).cast<num>().map((v) => v.toDouble()).toList(),
        );
        final cosine = faceCosine(vector, expected);
        // ignore: avoid_print
        print('SFace worker/OpenCV ${row['name']}: cosine=$cosine');
        expect(cosine, greaterThan(.999));
      }
    },
    skip: !const bool.fromEnvironment('SFACE_MODEL_TEST'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
