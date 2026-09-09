import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/search/search_diagnostics.dart';
import '../../evaluation/evaluation_runner.dart';
import '../../evaluation/evaluation_storage.dart';
import '../../evaluation/retrieval_evaluation.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';

final evaluationDatasetProvider = FutureProvider<EvaluationDataset>(
  (ref) async => EvaluationDataset.parse(
    await readEvaluationQueries() ??
        await rootBundle.loadString('assets/evaluation/scene_queries.json'),
  ),
);

class SearchDiagnosticsScreen extends ConsumerStatefulWidget {
  const SearchDiagnosticsScreen({super.key});
  @override
  ConsumerState<SearchDiagnosticsScreen> createState() =>
      _SearchDiagnosticsScreenState();
}

class _SearchDiagnosticsScreenState
    extends ConsumerState<SearchDiagnosticsScreen> {
  final _query = TextEditingController();
  EvaluationDataset? _dataset;
  SearchTrace? _trace;
  List<Photo> _corpus = [];
  Map<String, Object?>? _report;
  bool _busy = false;
  String? _status;
  String? _error;
  int _limit = 20;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run({bool batch = false}) async {
    if (_busy) return;
    if (ref.read(indexingControllerProvider).running) {
      setState(() {
        _error = 'Wait for indexing to finish or cancel it first.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _trace = null;
      _report = null;
      _status = 'Loading saved index...';
    });
    try {
      _dataset ??= await ref.read(evaluationDatasetProvider.future);
      if (!mounted) return;
      await ref.read(indexWarmupProvider.future);
      if (!mounted) return;
      final backend = await ref.read(searchBackendProvider.future);
      if (!mounted) return;
      if (backend is! SearchInspector) {
        throw StateError(
          'A semantic model is required. No keyword fallback is used for diagnostics.',
        );
      }
      final inspector = backend as SearchInspector;
      _corpus = await ref.read(photoRepositoryProvider).loadPhotos();
      if (!mounted) return;
      final vectors = await ref.read(photoRepositoryProvider).loadEmbeddings();
      if (batch) {
        _report = await runSearchEvaluation(
          inspector: inspector,
          corpus: _corpus,
          vectors: vectors,
          dataset: _dataset!,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _status = '$done / $total queries';
              });
            }
          },
        );
      } else {
        final snapshot = corpusSnapshot(_corpus, vectors);
        if ((snapshot['invalid_vector_ids'] as List).isNotEmpty) {
          throw StateError(
            'The saved index contains invalid image embeddings.',
          );
        }
        final trace = await inspector.inspect(_query.text, _corpus);
        if (!mounted) return;
        _trace = trace;
        final entry = _caseFor(trace.query);
        _dataset = _dataset!.replace(entry);
        await saveEvaluationQueries(jsonEncode(_dataset!.toJson()));
        if (!mounted) return;
        ref.invalidate(evaluationDatasetProvider);
        _report = {
          'schema_version': 1,
          'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
          'snapshot': snapshot,
          'dataset_id': _dataset!.id,
          'case': entry.toJson(),
          'trace': trace.toJson(),
          'comparison': rankingComparison(trace),
          'evaluation': evaluateTrace(trace, entry, _corpus),
        };
      }
      final path = await saveEvaluationReport(jsonEncode(_report));
      if (mounted) {
        setState(() {
          _status = 'Saved locally: $path';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  EvaluationQuery _caseFor(String query) => _dataset!.queries.firstWhere(
    (q) => q.query == query,
    orElse: () => EvaluationQuery(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      query: query,
    ),
  );

  Future<void> _judge(Photo photo, int? grade) async {
    if (_busy || _trace == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final previous = _caseFor(_trace!.query);
      final entry = EvaluationQuery(
        id: previous.id,
        query: previous.query,
        category: previous.category,
        exhaustive: previous.exhaustive,
        judgments: resolveJudgments(previous, _corpus),
      ).judge(photo.id, grade);
      final updated = _dataset!.replace(entry);
      await saveEvaluationQueries(jsonEncode(updated.toJson()));
      if (!mounted) return;
      ref.invalidate(evaluationDatasetProvider);
      setState(() {
        _dataset = updated;
        _report = null;
        _status = 'Judgment saved. Run again to refresh the report.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      if (!mounted) return;
      if (text == null) {
        throw const FormatException('Clipboard has no JSON dataset.');
      }
      final dataset = EvaluationDataset.parse(text);
      final corpus = await ref.read(photoRepositoryProvider).loadPhotos();
      for (final q in dataset.queries) {
        resolveJudgments(q, corpus);
      }
      await saveEvaluationQueries(jsonEncode(dataset.toJson()));
      if (mounted) {
        ref.invalidate(evaluationDatasetProvider);
        setState(() {
          _dataset = dataset;
          _trace = null;
          _report = null;
          _status = '${dataset.queries.length} queries imported';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = ref.watch(evaluationDatasetProvider);
    _dataset ??= loaded.valueOrNull;
    final selectedCase = _trace == null || _dataset == null
        ? null
        : _caseFor(_trace!.query);
    Map<String, int> judgments = {};
    if (selectedCase != null) {
      try {
        judgments = resolveJudgments(selectedCase, _corpus);
      } catch (_) {
        /* shown by run/import */
      }
    }
    final names = [
      'raw_semantic',
      'production',
      'legacy_mlkit_labels_experiment',
    ];
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search diagnostics'),
          actions: [
            IconButton(
              tooltip: 'Run evaluation set',
              icon: const Icon(Icons.playlist_play),
              onPressed: _busy || _dataset == null
                  ? null
                  : () => _run(batch: true),
            ),
            PopupMenuButton<String>(
              tooltip: 'Evaluation files',
              onSelected: (action) async {
                if (action == 'import') {
                  await _import();
                }
                if (action == 'report' && _report != null) {
                  await Clipboard.setData(
                    ClipboardData(
                      text: const JsonEncoder.withIndent('  ').convert(_report),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _status = 'Report copied';
                    });
                  }
                }
                if (action == 'queries' && _dataset != null) {
                  await Clipboard.setData(
                    ClipboardData(
                      text: const JsonEncoder.withIndent(
                        '  ',
                      ).convert(_dataset!.toJson()),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _status = 'Queries and judgments copied';
                    });
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'import',
                  enabled: !_busy,
                  child: const Text('Import judgments from clipboard'),
                ),
                PopupMenuItem(
                  value: 'report',
                  enabled: !_busy && _report != null,
                  child: const Text('Copy report'),
                ),
                PopupMenuItem(
                  value: 'queries',
                  enabled: !_busy && _dataset != null,
                  child: const Text('Copy queries and judgments'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !_busy,
                        controller: _query,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Scene query',
                        ),
                        onSubmitted: _busy ? null : (_) => _run(),
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: 'Evaluation queries',
                      icon: const Icon(Icons.list),
                      onSelected: (query) {
                        _query.text = query;
                      },
                      itemBuilder: (_) => [
                        for (final q
                            in _dataset?.queries ?? <EvaluationQuery>[])
                          PopupMenuItem(value: q.query, child: Text(q.query)),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Compare rankings',
                      icon: const Icon(Icons.search),
                      onPressed: _busy ? null : () => _run(),
                    ),
                  ],
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_trace != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Results for: ${_trace!.query}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (loaded.hasError || _error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error ?? '${loaded.error}'),
                ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _status!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        _trace == null
                            ? 'No comparison yet'
                            : '${_trace!.raw.length} vectors | ${judgments.length} judged',
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    value: _limit,
                    items: [
                      for (final n in [20, 50, 100, 200])
                        DropdownMenuItem(value: n, child: Text('Top $n')),
                    ],
                    onChanged: (n) => setState(() {
                      _limit = n!;
                    }),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Raw cosine'),
                  Tab(text: 'Final'),
                  Tab(text: 'Experiment'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final name in names)
                      _trace == null
                          ? const SizedBox.shrink()
                          : _ranking(
                              _trace!.rankings.firstWhere(
                                (r) => r.name == name,
                              ),
                              judgments,
                            ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ranking(
    DiagnosticRanking ranking,
    Map<String, int> judgments,
  ) => ListView.builder(
    itemCount: mathMin(_limit, ranking.photos.length),
    itemBuilder: (context, i) {
      final photo = ranking.photos[i];
      final row = ranking.rows[i];
      final cosine = row['cosine'] as double?;
      final score = row['score'] as double?;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 32, child: Text('${i + 1}')),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PhotoViewerScreen(
                        photos: ranking.photos,
                        initialIndex: i,
                      ),
                    ),
                  ),
                  child: Image(
                    image: photo.image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID ${photo.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'cos ${cosine?.toStringAsFixed(4) ?? 'missing'}${score == null ? '' : ' | score ${score.toStringAsFixed(4)}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Raw rank ${row['raw_rank'] ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Score breakdown',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Score breakdown'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(row),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: judgments[photo.id] ?? -1,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('Unjudged')),
                      DropdownMenuItem(value: 2, child: Text('Relevant')),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Partially relevant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(value: 0, child: Text('Irrelevant')),
                    ],
                    onChanged: _busy
                        ? null
                        : (grade) => _judge(photo, grade == -1 ? null : grade),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
          ],
        ),
      );
    },
  );
}

int mathMin(int a, int b) => a < b ? a : b;
