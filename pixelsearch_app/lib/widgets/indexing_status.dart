import 'package:flutter/material.dart';

import '../indexing/model/index_progress.dart';
import '../state/providers.dart';

/// Live status of the indexing pipeline: one status line plus a progress bar.
///
/// Shared by the search empty state and Settings → Library so both always report
/// the same numbers from the same [IndexingUiState]. Renders nothing before the
/// first run.
class IndexingStatus extends StatelessWidget {
  const IndexingStatus({super.key, required this.state});

  final IndexingUiState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = statusLine(state);
    if (line == null) return const SizedBox.shrink();

    final progress = state.progress;
    final determinate =
        state.running && progress.phase == IndexPhase.indexing && progress.total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        if (state.running) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              // Indeterminate while scanning/planning — the total isn't known yet.
              value: determinate ? progress.fraction : null,
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }
}

/// The status line for [state], or null when there is nothing to say yet.
/// Public so screens can render it without the bar.
String? statusLine(IndexingUiState state) {
  if (!state.running) return state.message;
  final p = state.progress;
  switch (p.phase) {
    case IndexPhase.scanning:
      return 'Scanning your gallery…';
    case IndexPhase.planning:
      return 'Working out what changed…';
    case IndexPhase.indexing:
      if (p.total == 0) return 'Nothing new to index.';
      final percent = (p.fraction * 100).round();
      return 'Indexing ${p.completed} of ${p.total}  ·  $percent%';
    default:
      return 'Finishing up…';
  }
}
