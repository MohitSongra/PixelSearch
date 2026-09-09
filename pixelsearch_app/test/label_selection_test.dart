import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/indexing/adapters/mlkit_image_enricher.dart';

/// Label selection is the one part of the ML Kit adapter that is pure, and the
/// part that decides which automatic guesses are saved. Device runtime
/// stays device-verified; this pins the policy.
void main() {
  test('keeps every label at or above the threshold, best first', () {
    final out = selectLabels([
      (label: 'Dog', confidence: 0.91),
      (label: 'Grass', confidence: 0.52),
      (label: 'Frisbee', confidence: 0.31),
      (label: 'Pet', confidence: 0.77),
    ]);
    expect(out, ['Dog', 'Pet', 'Grass']); // 0.31 dropped, ordered by confidence
  });

  test('low-confidence guesses do not dilute confident labels', () {
    final out = selectLabels([
      (label: 'Cat', confidence: 0.99),
      (label: 'Whisker', confidence: 0.05),
    ]);
    expect(out, ['Cat'], reason: 'low-confidence noise must not dilute a hit');
  });

  test('no confident labels means no labels, not forced guesses', () {
    final out = selectLabels([
      (label: 'Text', confidence: 0.44),
      (label: 'Screenshot', confidence: 0.41),
      (label: 'Font', confidence: 0.29),
      (label: 'White', confidence: 0.22),
    ]);
    expect(out, isEmpty);
  });

  test('no candidates at all yields no labels rather than throwing', () {
    expect(selectLabels(const []), isEmpty);
  });

  test(
    'threshold boundary is inclusive and invalid confidences are rejected',
    () {
      final out = selectLabels([
        (label: 'boundary', confidence: 0.5),
        (label: 'weak', confidence: 0.4999),
        (label: 'invalid', confidence: double.nan),
        (label: 'infinite', confidence: double.infinity),
      ]);
      expect(out, ['boundary']);
    },
  );
}
