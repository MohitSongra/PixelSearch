/// Tuning knobs for an indexing run. Defaults chosen for mid-range Android:
/// small batches keep memory bounded and give frequent, cheap checkpoints.
class IndexConfig {
  const IndexConfig({
    this.batchSize = 32,
    this.enrich = true,
    this.generateThumbnails = true,
  });

  /// Items persisted per transaction (batch commit — never one txn per image).
  final int batchSize;

  /// Run ML Kit labeling + face detection during indexing.
  final bool enrich;

  /// Generate + store thumbnails during indexing.
  final bool generateThumbnails;

  static const IndexConfig defaults = IndexConfig();
}
