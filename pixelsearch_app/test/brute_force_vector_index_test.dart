import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';

Float32List _unit(List<double> xs) {
  var norm = 0.0;
  for (final x in xs) {
    norm += x * x;
  }
  norm = math.sqrt(norm);
  return Float32List.fromList([for (final x in xs) x / norm]);
}

void main() {
  test('ranks by cosine similarity and respects topK', () {
    final idx = BruteForceVectorIndex(dim: 3)
      ..upsert('a', _unit([1, 0, 0])) // identical to query
      ..upsert('c', _unit([1, 1, 0])) // 45°
      ..upsert('b', _unit([0, 1, 0])); // 90°

    final q = _unit([1, 0, 0]);

    final top2 = idx.query(q, topK: 2);
    expect(top2.length, 2);
    expect(top2.first.id, 'a');
    expect(top2.first.score, closeTo(1.0, 1e-6));

    // Full ranking: a (0°) > c (45°) > b (90°).
    final all = idx.query(q, topK: 10);
    expect(all.map((m) => m.id).toList(), ['a', 'c', 'b']);
    expect(all[1].score, closeTo(math.cos(math.pi / 4), 1e-6));
    expect(all[2].score, closeTo(0.0, 1e-6));
  });

  test('upsert replaces, remove drops, clear empties', () {
    final idx = BruteForceVectorIndex(dim: 2)
      ..upsert('x', _unit([1, 0]))
      ..upsert('y', _unit([0, 1]));
    expect(idx.length, 2);

    idx.upsert('x', _unit([0, 1])); // replace, not duplicate
    expect(idx.length, 2);
    expect(idx.query(_unit([0, 1]), topK: 1).first.score, closeTo(1.0, 1e-6));

    idx.remove('y');
    expect(idx.length, 1);

    idx.clear();
    expect(idx.length, 0);
    expect(idx.query(_unit([1, 0])), isEmpty);
  });
}
