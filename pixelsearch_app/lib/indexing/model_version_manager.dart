import '../core/ai_contract.dart';

/// Owns the current model/embedding version and decides when a stored embedding
/// is stale. A version bump (e.g. artifact/embedding change in the contract)
/// makes every prior embedding stale, so reconciliation schedules a full,
/// resumable re-index. See MIGRATIONS.md §B.
class ModelVersionManager {
  const ModelVersionManager({this.currentVersion = AiContract.embeddingVersion});

  final String currentVersion;

  bool isStale(String? storedVersion) => storedVersion != currentVersion;
}
