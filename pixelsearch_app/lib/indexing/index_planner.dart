import 'model/asset_ref.dart';
import 'model/index_plan.dart';
import 'model/index_record.dart';

/// Pure reconciliation between the live gallery and the indexed store.
///
/// This is the correctness heart of the engine and has a single responsibility:
/// given the current gallery and what the store already knows, decide exactly
/// what work is needed — nothing more. It is deterministic and side-effect free,
/// so every branch (added / changed / stale-version / deleted / up-to-date) is
/// unit-tested without a device, database, or model.
class IndexPlanner {
  const IndexPlanner();

  IndexPlan reconcile({
    required List<AssetRef> gallery,
    required List<IndexRecord> indexed,
    required String currentEmbeddingVersion,
    Set<String>? existingAssetIds,
    bool canDeleteMissing = true,
  }) {
    final byId = {for (final r in indexed) r.id: r};
    final galleryIds = <String>{};
    final toIndex = <PlannedItem>[];
    var upToDate = 0;

    for (final asset in gallery) {
      galleryIds.add(asset.id);
      final record = byId[asset.id];
      if (record == null) {
        toIndex.add(PlannedItem(asset, IndexReason.added));
      } else if (record.mtimeMs != asset.mtimeMs ||
          record.byteSize != asset.byteSize) {
        toIndex.add(PlannedItem(asset, IndexReason.changed));
      } else if (record.embeddingVersion != currentEmbeddingVersion) {
        toIndex.add(PlannedItem(asset, IndexReason.staleVersion));
      } else {
        upToDate++; // already indexed at the current version → skip (no dup work)
      }
    }

    final toDelete = [
      if (canDeleteMissing)
        for (final record in indexed)
          if (!(existingAssetIds ?? galleryIds).contains(record.id)) record.id,
    ];

    return IndexPlan(toIndex: toIndex, toDelete: toDelete, upToDate: upToDate);
  }
}
