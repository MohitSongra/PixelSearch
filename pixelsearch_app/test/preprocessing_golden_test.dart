import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixelsearch/ai/image_preprocess.dart';

/// Regression guard: preprocessing of a fixed synthetic image must be byte-stable.
/// Any silent change to resize / crop / scale / channel-order moves this
/// fingerprint and fails here — ORT-independent, runs in `flutter test`.
void main() {
  test('preprocessing fingerprint is stable', () {
    final src = img.Image(width: 320, height: 200);
    for (var y = 0; y < 200; y++) {
      for (var x = 0; x < 320; x++) {
        src.setPixelRgb(
          x,
          y,
          (x * 7 + y * 3) % 256,
          (x * 3 + 11) % 256,
          (y * 5 + 17) % 256,
        );
      }
    }
    final pre = preprocessForClip(src);
    expect(pre.shape, [1, 3, 256, 256]);

    var sum = 0.0;
    for (final v in pre.data) {
      sum += v;
    }
    // ignore: avoid_print
    print(
      'FINGERPRINT sum=${sum.toStringAsFixed(6)} '
      'a=${pre.data[0].toStringAsFixed(6)} '
      'b=${pre.data[100000].toStringAsFixed(6)} '
      'c=${pre.data[pre.data.length - 1].toStringAsFixed(6)}',
    );

    expect(sum, closeTo(_sum, 0.05));
    expect(pre.data[0], closeTo(_a, 1e-5));
    expect(pre.data[100000], closeTo(_b, 1e-5));
    expect(pre.data[pre.data.length - 1], closeTo(_c, 1e-5));
  });
}

// Pinned fingerprint (open_clip-faithful preprocessing; see ADR-010).
const double _sum = 100051.464714;
const double _a = 0.623529;
const double _b = 0.207843;
const double _c = 0.956863;
