import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/indexing/index_planner.dart';
import 'package:pixelsearch/indexing/model/asset_ref.dart';
import 'package:pixelsearch/indexing/model/index_plan.dart';
import 'package:pixelsearch/indexing/model/index_record.dart';

AssetRef _a(String id, {int mtime = 1, int size = 100}) =>
    AssetRef(id: id, mtimeMs: mtime, byteSize: size);
IndexRecord _r(String id, {int mtime = 1, int size = 100, String? v = '1'}) =>
    IndexRecord(id: id, mtimeMs: mtime, byteSize: size, embeddingVersion: v);

void main() {
  const planner = IndexPlanner();

  test('new assets added; already-indexed current-version assets skipped', () {
    final plan = planner.reconcile(
      gallery: [_a('p1'), _a('p2')],
      indexed: [_r('p1')],
      currentEmbeddingVersion: '1',
    );
    expect(plan.toIndex.map((i) => i.asset.id).toList(), ['p2']);
    expect(plan.reasonCount(IndexReason.added), 1);
    expect(plan.upToDate, 1); // duplicate work avoided
    expect(plan.toDelete, isEmpty);
  });

  test('changed asset (mtime or size) is re-indexed', () {
    expect(
        planner.reconcile(
          gallery: [_a('p1', mtime: 2)],
          indexed: [_r('p1', mtime: 1)],
          currentEmbeddingVersion: '1',
        ).reasonCount(IndexReason.changed),
        1);
    expect(
        planner.reconcile(
          gallery: [_a('p1', size: 200)],
          indexed: [_r('p1', size: 100)],
          currentEmbeddingVersion: '1',
        ).reasonCount(IndexReason.changed),
        1);
  });

  test('stale embedding_version triggers re-index (model migration)', () {
    final plan = planner.reconcile(
      gallery: [_a('p1')],
      indexed: [_r('p1', v: '1')],
      currentEmbeddingVersion: '2',
    );
    expect(plan.reasonCount(IndexReason.staleVersion), 1);
  });

  test('row present but no embedding yet → needs indexing', () {
    final plan = planner.reconcile(
      gallery: [_a('p1')],
      indexed: [_r('p1', v: null)],
      currentEmbeddingVersion: '1',
    );
    expect(plan.toIndex.single.reason, IndexReason.staleVersion);
  });

  test('deleted assets detected', () {
    final plan = planner.reconcile(
      gallery: [_a('p1')],
      indexed: [_r('p1'), _r('p2'), _r('p3')],
      currentEmbeddingVersion: '1',
    );
    expect(plan.toDelete, ['p2', 'p3']);
    expect(plan.upToDate, 1);
  });

  test('idempotent re-scan when everything current → empty plan', () {
    final plan = planner.reconcile(
      gallery: [_a('p1'), _a('p2')],
      indexed: [_r('p1'), _r('p2')],
      currentEmbeddingVersion: '1',
    );
    expect(plan.isEmpty, isTrue);
    expect(plan.upToDate, 2);
  });

  test('mixed: add + change + stale + delete + skip together', () {
    final plan = planner.reconcile(
      gallery: [_a('new'), _a('chg', mtime: 9), _a('stale'), _a('ok')],
      indexed: [_r('chg', mtime: 1), _r('stale', v: '0'), _r('ok'), _r('gone')],
      currentEmbeddingVersion: '1',
    );
    expect(plan.reasonCount(IndexReason.added), 1);
    expect(plan.reasonCount(IndexReason.changed), 1);
    expect(plan.reasonCount(IndexReason.staleVersion), 1);
    expect(plan.toDelete, ['gone']);
    expect(plan.upToDate, 1);
    expect(plan.total, 5); // 3 to-index + 1 delete + 1 up-to-date
  });
}
