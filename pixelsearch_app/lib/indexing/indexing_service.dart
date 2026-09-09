import 'dart:async';

import '../ai/ai_logger.dart';
import 'asset_processor.dart';
import 'index_planner.dart';
import 'index_store.dart';
import 'model/index_config.dart';
import 'model/index_progress.dart';
import 'model/indexed_item.dart';
import 'model_version_manager.dart';
import 'ports/gallery_source.dart';

/// The indexing orchestrator (IndexScheduler): scan → plan → delete → index in
/// batched transactions, with checkpoints, progress streaming, cancellation, and
/// automatic resume. It is deliberately independent of *how* it is triggered
/// (foreground call or WorkManager), so the whole flow is unit-testable.
///
/// Resume & crash-recovery are structural: `run()` re-reconciles every time, and
/// each committed batch makes those assets "up to date", so an interrupted or
/// crashed run simply continues where it left off on the next call — no bespoke
/// resume state to corrupt.
class IndexingService {
  IndexingService({
    required this.gallery,
    required this.processor,
    required this.store,
    required this.versionManager,
    this.planner = const IndexPlanner(),
    this.config = IndexConfig.defaults,
    this.log = const AiLog('Indexing'),
    int Function()? nowMs,
    this.onDispose,
  }) : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final GallerySource gallery;
  final AssetProcessor processor;
  final IndexStore store;
  final ModelVersionManager versionManager;
  final IndexPlanner planner;
  final IndexConfig config;
  final AiLog log;
  final int Function() _nowMs;

  /// Composition-root hook for device resources the core does not own directly,
  /// such as ML Kit detectors and ONNX sessions.
  final Future<void> Function()? onDispose;

  final StreamController<IndexProgress> _progress =
      StreamController<IndexProgress>.broadcast();
  Stream<IndexProgress> get progress => _progress.stream;
  IndexProgress get state => _state;
  IndexProgress _state = IndexProgress.idle;

  bool _cancelRequested = false;
  bool _running = false;
  bool _disposed = false;
  bool get isRunning => _running;

  /// Wall-clock of the current run, reported in the completion log line.
  final Stopwatch _runWatch = Stopwatch();

  void cancel() => _cancelRequested = true;

  Future<IndexProgress> run() async {
    if (_running) return _state;
    _running = true;
    _cancelRequested = false;
    _runWatch
      ..reset()
      ..start();
    try {
      _emit(const IndexProgress(phase: IndexPhase.scanning));
      final snapshot = await gallery.listAssets();
      final assets = snapshot.assets;
      log.info('scan: ${assets.length} gallery assets discovered');

      if (_cancelRequested) return _finish(IndexPhase.cancelled, 0, 0, 0, 0);

      _emit(const IndexProgress(phase: IndexPhase.planning));
      final indexed = await store.indexedRecords();
      final plan = planner.reconcile(
        gallery: assets,
        indexed: indexed,
        currentEmbeddingVersion: versionManager.currentVersion,
        existingAssetIds: snapshot.existingAssetIds,
        canDeleteMissing: snapshot.canDeleteMissing,
      );
      log.info(
        'plan: ${plan.toIndex.length} to index, ${plan.toDelete.length} '
        'to delete, ${assets.length - plan.toIndex.length} already up to date '
        '(${indexed.length} rows already in the store)',
      );

      if (plan.toDelete.isNotEmpty) {
        await store.deleteAssets(plan.toDelete);
      }

      final total = plan.toIndex.length;
      var completed = 0;
      var failed = 0;
      final buffer = <IndexedItem>[];
      _emit(
        IndexProgress(
          phase: IndexPhase.indexing,
          total: total,
          deleted: plan.toDelete.length,
        ),
      );

      Future<void> flush(String? currentId) async {
        if (buffer.isEmpty) return;
        await store.commitBatch(buffer, nowMs: _nowMs());
        completed += buffer.length;
        buffer.clear();
        await store.saveCheckpoint(
          total: total,
          embedded: completed,
          nowMs: _nowMs(),
        );
        _emit(
          IndexProgress(
            phase: IndexPhase.indexing,
            total: total,
            completed: completed,
            failed: failed,
            deleted: plan.toDelete.length,
            currentId: currentId,
          ),
        );
      }

      for (final item in plan.toIndex) {
        if (_cancelRequested) {
          await flush(item.asset.id); // persist what we have before stopping
          return _finish(
            IndexPhase.cancelled,
            total,
            completed,
            failed,
            plan.toDelete.length,
          );
        }
        try {
          buffer.add(await processor.process(item.asset, config));
        } catch (e, st) {
          failed++; // isolate per-asset failures; a bad photo never aborts the run
          log.error('asset ${item.asset.id} failed', e, st);
        }
        if (buffer.length >= config.batchSize) {
          await flush(item.asset.id);
        }
        // Each asset includes synchronous decode/preprocess/ONNX work. Yielding
        // here lets Flutter handle input and paint before the next one begins.
        // It does not change the indexing order, model input, or persistence.
        if (config.yieldBetweenAssets) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      await flush(null);
      return _finish(
        IndexPhase.done,
        total,
        completed,
        failed,
        plan.toDelete.length,
      );
    } catch (e, st) {
      log.error('indexing run failed', e, st);
      return _finish(
        IndexPhase.error,
        _state.total,
        _state.completed,
        _state.failed,
        _state.deleted,
      );
    } finally {
      _running = false;
    }
  }

  IndexProgress _finish(
    IndexPhase phase,
    int total,
    int completed,
    int failed,
    int deleted,
  ) {
    final p = IndexProgress(
      phase: phase,
      total: total,
      completed: completed,
      failed: failed,
      deleted: deleted,
    );
    _runWatch.stop();
    log.info(
      'run ${phase.name}: sent=$total embedded=$completed failed=$failed '
      'deleted=$deleted in ${_runWatch.elapsedMilliseconds}ms',
    );
    _emit(p);
    return p;
  }

  void _emit(IndexProgress p) {
    _state = p;
    if (!_progress.isClosed) _progress.add(p);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await onDispose?.call();
    } finally {
      if (!_progress.isClosed) await _progress.close();
    }
  }
}
