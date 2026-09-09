import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sample_data.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/indexing_status.dart';
import '../../widgets/photo_grid.dart';
import '../indexing/folder_picker.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: q.length),
    );
    ref.read(searchQueryProvider.notifier).state = q;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.isLoading
        ? const <Photo>[]
        : resultsAsync.valueOrNull ?? const <Photo>[];
    final isSearching = resultsAsync.isLoading;
    final semantic =
        ref.watch(searchBackendProvider).valueOrNull?.isSemantic ?? false;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'PixelSearch',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  _ModeBadge(semantic: semantic),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'On-device · private',
                    child: Icon(Icons.shield_outlined, color: scheme.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SearchField(
                controller: _controller,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                onClear: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
            ),
            Expanded(
              child: query.trim().isEmpty
                  ? _EmptySearch(onQueryTap: _runQuery)
                  : results.isEmpty
                  ? (isSearching
                        ? const _Searching()
                        : resultsAsync.hasError
                        ? const EmptyState(
                            icon: Icons.error_outline,
                            title: 'Search unavailable',
                            message:
                                'Could not read the search index. Reopen the app to retry.',
                          )
                        : const EmptyState(
                            icon: Icons.search_off,
                            title: 'No close matches',
                            message:
                                'No photos met the search cutoff in your indexed folders.',
                          ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${results.length} result${results.length == 1 ? '' : 's'} for “$query”',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (isSearching)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(child: PhotoGrid(photos: results)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search your memories…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.mic_none)
            : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final ValueChanged<String> onQueryTap;
  const _EmptySearch({required this.onQueryTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Try searching',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedQueries
              .map(
                (q) =>
                    ActionChip(label: Text(q), onPressed: () => onQueryTap(q)),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const _IndexCard(),
      ],
    );
  }
}

/// Coverage + controls for the on-device index: how many photos are searchable,
/// and a button to build or refresh the index (with live progress and cancel).
class _IndexCard extends ConsumerWidget {
  const _IndexCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final total = ref.watch(photoLibraryProvider).length;
    final indexing = ref.watch(indexingControllerProvider);
    final controller = ref.read(indexingControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total photos indexed',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        !indexingSupported
                            ? 'Indexing needs a device gallery (not available on web).'
                            : total == 0
                            ? 'Index your gallery to search it — nothing leaves this device.'
                            : 'Re-indexing only picks up new and changed photos.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (indexingSupported) ...[
                  const SizedBox(width: 8),
                  indexing.running
                      ? OutlinedButton(
                          onPressed: controller.cancel,
                          child: const Text('Cancel'),
                        )
                      : FilledButton.tonal(
                          onPressed: () => chooseFoldersAndIndex(context, ref),
                          child: Text(total == 0 ? 'Index' : 'Re-index'),
                        ),
                ],
              ],
            ),
            if (statusLine(indexing) != null) ...[
              const SizedBox(height: 14),
              IndexingStatus(state: indexing),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact pill showing which search engine is live: real CLIP semantic search,
/// or the lexical fallback (web / model not yet provisioned).
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.semantic});
  final bool semantic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = semantic
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final fg = semantic ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Tooltip(
      message: semantic
          ? 'CLIP semantic search (on-device)'
          : 'Keyword search (semantic model not loaded)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              semantic ? Icons.auto_awesome : Icons.abc,
              size: 15,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              semantic ? 'Semantic' : 'Keyword',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the query is being embedded and ranked (first result set).
class _Searching extends StatelessWidget {
  const _Searching();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            'Searching your photos…',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
