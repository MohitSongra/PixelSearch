import '../data/local/app_database.dart';
import '../indexing/model/index_progress.dart';
import '../indexing/model/folder_selection.dart';
import 'index_bridge.dart';
import 'index_cancel_token.dart';

/// Web: there is no gallery, no ML Kit and no local database, so indexing is a
/// no-op. The UI shows the `unsupported` message instead of an index button.
Future<IndexRunResult> runDeviceIndexing({
  required AppDatabase db,
  required void Function(IndexProgress) onProgress,
  required IndexCancelToken cancel,
  required FolderSelection selection,
}) async => const IndexRunResult(IndexRunStatus.unsupported);

Future<FolderCatalog> loadIndexFolders() async => const FolderCatalog([]);
