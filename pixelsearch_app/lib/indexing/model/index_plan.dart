import 'asset_ref.dart';

/// Why an asset is (re)indexed — useful for logs, metrics, and tests.
enum IndexReason {
  /// New asset the store has never seen.
  added,

  /// Asset whose bytes changed (mtime or size differs from the stored record).
  changed,

  /// Asset whose stored embedding was produced by a different embedding_version
  /// (a model/preprocessing migration — see MIGRATIONS.md §B).
  staleVersion,
}

/// A single unit of indexing work.
class PlannedItem {
  const PlannedItem(this.asset, this.reason);
  final AssetRef asset;
  final IndexReason reason;
}

/// The reconciliation result: what to (re)index, what to delete, and how many
/// assets are already up to date (skipped — no duplicate work).
class IndexPlan {
  const IndexPlan({
    required this.toIndex,
    required this.toDelete,
    required this.upToDate,
  });

  final List<PlannedItem> toIndex;

  /// Asset ids present in the store but no longer in the gallery (deleted).
  final List<String> toDelete;

  /// Count of assets already indexed at the current version (skipped).
  final int upToDate;

  int get total => toIndex.length + toDelete.length + upToDate;
  bool get isEmpty => toIndex.isEmpty && toDelete.isEmpty;

  int reasonCount(IndexReason r) => toIndex.where((i) => i.reason == r).length;
}
