import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/indexing/adapters/mlkit_image_enricher.dart';

/// Label selection is the one part of the ML Kit adapter that is pure, and the
/// part that decides whether a photo ends up searchable at all. Device runtime
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

  test('a confident photo is unaffected by the fallback', () {
    final out = selectLabels([
      (label: 'Cat', confidence: 0.99),
      (label: 'Whisker', confidence: 0.05),
    ]);
    expect(out, ['Cat'], reason: 'low-confidence noise must not dilute a hit');
  });

  test('falls back to the best few when nothing clears the threshold', () {
    // The ~0.6% real-library case: screenshots/documents that cleared nothing
    // at 0.5 and used to be stored with no labels at all.
    final out = selectLabels([
      (label: 'Text', confidence: 0.44),
      (label: 'Screenshot', confidence: 0.41),
      (label: 'Font', confidence: 0.29),
      (label: 'White', confidence: 0.22),
    ]);
    expect(out, ['Text', 'Screenshot', 'Font']); // capped at maxFallback = 3
    expect(out, isNotEmpty, reason: 'every photo must get some tag');
  });

  test('no candidates at all yields no labels rather than throwing', () {
    expect(selectLabels(const []), isEmpty);
  });

  test('maxFallback is honoured', () {
    final out = selectLabels(
      [
        (label: 'a', confidence: 0.4),
        (label: 'b', confidence: 0.3),
        (label: 'c', confidence: 0.2),
      ],
      maxFallback: 1,
    );
    expect(out, ['a']);
  });
}
