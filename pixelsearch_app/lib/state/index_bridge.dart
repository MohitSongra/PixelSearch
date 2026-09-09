import '../data/local/app_database.dart';
import '../indexing/model/index_progress.dart';
import '../indexing/model/folder_selection.dart';
import 'index_cancel_token.dart';

// Native assembles and runs the real M5 pipeline (pulls in photo_manager, ML Kit,
// ONNX and dart:io); web gets the stub that reports `unsupported`. This
// conditional import is what keeps the web build compiling — providers.dart never
// imports the indexing adapters directly, exactly as it never imports the AI
// stack directly (see semantic_wiring.dart, ADR-014).
import 'index_bridge_stub.dart'
    if (dart.library.io) 'index_bridge_io.dart'
    as impl;

/// Why an indexing run ended, for platforms/preconditions the pipeline itself
/// doesn't model. [finished] means the pipeline actually ran — read [IndexRunResult.progress]
/// for done / cancelled / error.
enum IndexRunStatus {
  noFoldersSelected,

  /// No local index on this platform (web).
  unsupported,

  /// The user declined photo access, so there is nothing to scan.
  permissionDenied,

  /// The CLIP image encoder has not been provisioned yet (M12 model manager).
  modelMissing,

  /// Encoder files are present but none could be loaded — e.g. fp16 without a
  /// compatible execution provider (KI-2) or an incompatible/corrupt artifact
  /// (KI-9).
  modelUnusable,

  /// The pipeline ran; [IndexRunResult.progress] carries the terminal phase.
  finished,
}

/// Outcome of one indexing pass.
class IndexRunResult {
  const IndexRunResult(
    this.status, {
    this.progress,
    this.message,
    this.modelUsed,
  });

  final IndexRunStatus status;

  /// Terminal progress when [status] is [IndexRunStatus.finished]; null otherwise.
  final IndexProgress? progress;

  /// Detail for the failure statuses (where the model was expected, or why each
  /// candidate failed to load).
  final String? message;

  /// Which artifact actually ran, e.g. `mobileclip_image.onnx (fp32, 86.6 MB)`.
  /// Null unless the pipeline ran.
  final String? modelUsed;
}

/// Runs one full indexing pass over the device gallery: permission → scan →
/// plan → index in batches, streaming [IndexProgress] to [onProgress] and
/// honouring [cancel].
///
/// This is a *wiring* seam only. It composes the unmodified M5 pipeline via
/// `buildDeviceIndexingService`; no indexing logic lives here.
Future<IndexRunResult> runDeviceIndexing({
  required AppDatabase db,
  required void Function(IndexProgress) onProgress,
  required IndexCancelToken cancel,
  required FolderSelection selection,
}) => impl.runDeviceIndexing(
  db: db,
  onProgress: onProgress,
  cancel: cancel,
  selection: selection,
);

Future<FolderCatalog> loadIndexFolders() => impl.loadIndexFolders();
