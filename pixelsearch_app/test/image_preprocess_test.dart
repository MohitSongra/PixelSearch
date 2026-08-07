import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixelsearch/ai/image_preprocess.dart';

void main() {
  test('produces a [1,3,256,256] CHW tensor scaled into [0,1]', () {
    final src = img.Image(width: 400, height: 300); // non-square
    img.fill(src, color: img.ColorRgb8(255, 128, 0)); // solid orange
    final pre = preprocessForClip(src);

    expect(pre.shape, [1, 3, 256, 256]);
    expect(pre.data.length, 3 * 256 * 256);

    const area = 256 * 256;
    expect(pre.data[0], closeTo(1.0, 1e-6)); // R plane
    expect(pre.data[area], closeTo(128 / 255, 1e-6)); // G plane
    expect(pre.data[2 * area], closeTo(0.0, 1e-6)); // B plane

    for (final v in pre.data) {
      expect(v, inInclusiveRange(0.0, 1.0));
    }
  });

  test('center-crops a very wide image to a square tensor', () {
    final src = img.Image(width: 1000, height: 256);
    img.fill(src, color: img.ColorRgb8(10, 20, 30));
    final pre = preprocessForClip(src);
    expect(pre.shape, [1, 3, 256, 256]);
  });
}
