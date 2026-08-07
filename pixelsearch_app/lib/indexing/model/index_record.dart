/// What the store already knows about an asset — the minimal projection the
/// [IndexPlanner] needs to reconcile the gallery against the database.
class IndexRecord {
  const IndexRecord({
    required this.id,
    required this.mtimeMs,
    required this.byteSize,
    this.embeddingVersion,
  });

  final String id;
  final int mtimeMs;
  final int byteSize;

  /// The `embedding_version` of this asset's stored embedding, or `null` if it
  /// has no embedding yet. Compared against the current contract version to
  /// detect model/preprocessing migrations.
  final String? embeddingVersion;
}
