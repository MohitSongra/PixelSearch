import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'face_contract.dart';

/// Least-squares non-reflecting similarity transform, source -> SFace template.
/// This is the 2D closed form of the similarity fit used by OpenCV alignCrop.
List<double> faceTransform(List<(double, double)> points) {
  if (points.length != 5 ||
      points.any((p) => !p.$1.isFinite || !p.$2.isFinite)) {
    throw const FormatException('Five finite face landmarks are required.');
  }
  final target = FaceContract.landmarks;
  var sx = 0.0, sy = 0.0, tx = 0.0, ty = 0.0;
  for (var i = 0; i < 5; i++) {
    sx += points[i].$1 / 5;
    sy += points[i].$2 / 5;
    tx += target[i].$1 / 5;
    ty += target[i].$2 / 5;
  }
  var denominator = 0.0, a = 0.0, b = 0.0;
  for (var i = 0; i < 5; i++) {
    final x = points[i].$1 - sx, y = points[i].$2 - sy;
    final u = target[i].$1 - tx, v = target[i].$2 - ty;
    denominator += x * x + y * y;
    a += x * u + y * v;
    b += x * v - y * u;
  }
  if (denominator <= 1e-8) {
    throw const FormatException('Degenerate face landmarks.');
  }
  a /= denominator;
  b /= denominator;
  if (a * a + b * b <= 1e-12) {
    throw const FormatException('Degenerate face transform.');
  }
  return [a, -b, tx - a * sx + b * sy, b, a, ty - b * sx - a * sy];
}

img.Image alignFace(img.Image source, List<(double, double)> points) {
  final t = faceTransform(points);
  final a = t[0], b = t[3], d = a * a + b * b;
  final out = img.Image(width: 112, height: 112, numChannels: 3);
  double channel(int x, int y, int c) {
    if (x < 0 || y < 0 || x >= source.width || y >= source.height) return 0;
    final p = source.getPixel(x, y);
    return (c == 0
            ? p.r
            : c == 1
            ? p.g
            : p.b)
        .toDouble();
  }

  for (var y = 0; y < 112; y++) {
    for (var x = 0; x < 112; x++) {
      final dx = x - t[2], dy = y - t[5];
      // OpenCV INTER_LINEAR uses a 1/32-pixel interpolation table.
      final px = (((a * dx + b * dy) / d) * 32).round() / 32;
      final py = (((-b * dx + a * dy) / d) * 32).round() / 32;
      final ix = px.floor(),
          iy = py.floor(),
          fx = px - px.floor(),
          fy = py - py.floor();
      final rgb = <int>[];
      for (var c = 0; c < 3; c++) {
        rgb.add(
          ((1 - fx) * (1 - fy) * channel(ix, iy, c) +
                  fx * (1 - fy) * channel(ix + 1, iy, c) +
                  (1 - fx) * fy * channel(ix, iy + 1, c) +
                  fx * fy * channel(ix + 1, iy + 1, c))
              .round()
              .clamp(0, 255),
        );
      }
      out.setPixelRgb(x, y, rgb[0], rgb[1], rgb[2]);
    }
  }
  return out;
}

Float32List faceTensor(img.Image aligned) {
  if (aligned.width != 112 || aligned.height != 112) {
    throw const FormatException('SFace requires an aligned 112x112 crop.');
  }
  final out = Float32List(3 * 112 * 112);
  for (var y = 0; y < 112; y++) {
    for (var x = 0; x < 112; x++) {
      final p = aligned.getPixel(x, y), i = y * 112 + x;
      out[i] = p.r.toDouble();
      out[12544 + i] = p.g.toDouble();
      out[25088 + i] = p.b.toDouble();
    }
  }
  return out;
}
