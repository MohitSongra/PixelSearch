import '../data/local/app_database.dart';
import '../indexing/model/index_progress.dart';
import 'index_bridge.dart';
import 'index_cancel_token.dart';

/// Web: there is no gallery, no ML Kit and no local database, so indexing is a
/// no-op. The UI shows the `unsupported` message instead of an index button.
Future<IndexRunResult> runDeviceIndexing({
  required AppDatabase db,
  required void Function(IndexProgress) onProgress,
  required IndexCancelToken cancel,
}) async =>
    const IndexRunResult(IndexRunStatus.unsupported);
