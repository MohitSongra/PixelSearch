import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/indexing_status.dart';
import '../../widgets/photo_grid.dart';
import '../indexing/folder_picker.dart';
import 'conversation_sheet.dart';
import 'indexed_gallery_view.dart';
import '../people/people_screen.dart';
import '../people/people_widgets.dart';
import '../../state/people_providers.dart';
import '../../domain/search/search_response.dart';

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
    ref.listen(searchQueryProvider, (_, value) {
      ref.invalidate(peopleNameChoicesProvider);
      ref.invalidate(peopleIgnoredNamesProvider);
      if (_controller.text != value) {
        _controller.text = value;
        _controller.selection = TextSelection.collapsed(offset: value.length);
      }
    });
    final query = ref.watch(searchQueryProvider);
    ref.watch(peopleControllerProvider);
    final peopleQuery = ref.watch(peopleQueryProvider).valueOrNull;
    final newFaces =
        ref.watch(peopleSnapshotProvider).valueOrNull?.facesToName ?? 0;
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.isLoading
        ? const <Photo>[]
        : resultsAsync.valueOrNull ?? const <Photo>[];
    final isSearching = resultsAsync.isLoading;
    final semantic =
        ref.watch(searchBackendProvider).valueOrNull?.isSemantic ?? false;
    final scheme = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(22) > 30;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PixelSearch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'People',
                    icon: Badge(
                      isLabelVisible: newFaces > 0,
                      child: const Icon(Icons.people_outline),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PeopleScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Voice and conversation',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => const ConversationSheet(),
                    ),
                  ),
                  if (!largeText) ...[
                    _ModeBadge(semantic: semantic),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: ref.watch(privacyModeProvider)
                          ? 'Offline only'
                          : 'Local search; optional online enhancements',
                      child: Icon(Icons.shield_outlined, color: scheme.primary),
                    ),
                  ],
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
                onMic: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => const ConversationSheet(startListening: true),
                ),
              ),
            ),
            if (query.trim().isEmpty && newFaces > 0)
              ListTile(
                key: const ValueKey('search-new-faces'),
                dense: true,
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('New faces found'),
                subtitle: Text('$newFaces faces to name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PeopleScreen(showNewFaces: true),
                  ),
                ),
              ),
            if (!ref.watch(searchFiltersProvider).isEmpty)
              ListTile(
                dense: true,
                title: Text(
                  'Filters: ${ref.watch(searchFiltersProvider).toJson()}',
                ),
                trailing: IconButton(
                  tooltip: 'Clear filters',
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: () => ref.invalidate(searchFiltersProvider),
                ),
              ),
            if (peopleQuery != null &&
                (peopleQuery.matched.isNotEmpty || peopleQuery.needsChoice))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final match in peopleQuery.matched.entries)
                      InputChip(
                        label: Text(match.key),
                        avatar: const Icon(Icons.person_outline),
                        onDeleted: () {
                          ref
                              .read(peopleIgnoredNamesProvider.notifier)
                              .state = {
                            ...ref.read(peopleIgnoredNamesProvider),
                            match.key,
                          };
                          final filters = ref.read(searchFiltersProvider);
                          ref
                              .read(searchFiltersProvider.notifier)
                              .state = SearchFilters(
                            from: filters.from,
                            until: filters.until,
                            album: filters.album,
                            place: filters.place,
                            personIds: {...filters.personIds}
                              ..remove(match.value),
                          );
                        },
                      ),
                    for (final entry in peopleQuery.ambiguous.entries)
                      PopupMenuButton<String>(
                        tooltip: 'Choose ${entry.key}',
                        onSelected: (id) =>
                            ref
                                .read(peopleNameChoicesProvider.notifier)
                                .state = {
                              ...ref.read(peopleNameChoicesProvider),
                              entry.key: id,
                            },
                        itemBuilder: (_) => [
                          for (final p in entry.value)
                            PopupMenuItem(
                              value: p.id,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: FaceImage(
                                      face: ref
                                          .read(peopleSnapshotProvider)
                                          .valueOrNull
                                          ?.people
                                          .where(
                                            (person) =>
                                                person.record.id == p.id,
                                          )
                                          .firstOrNull
                                          ?.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(p.name)),
                                ],
                              ),
                            ),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.person_search),
                          label: Text('Choose ${entry.key}'),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child:
                  query.trim().isEmpty &&
                      ref.watch(searchFiltersProvider).isEmpty
                  ? _IndexedHome(onQueryTap: _runQuery)
                  : results.isEmpty
                  ? (peopleQuery?.needsChoice == true
                        ? const Center(
                            child: Text('Choose a person to see their photos.'),
                          )
                        : isSearching
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
                        Expanded(
                          child: PhotoGrid(
                            photos: results,
                            searchResponse: ref
                                .watch(searchResponseProvider)
                                .valueOrNull,
                          ),
                        ),
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
  final VoidCallback onMic;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onMic,
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
            ? IconButton(
                tooltip: 'Voice search',
                icon: const Icon(Icons.mic_none),
                onPressed: onMic,
              )
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
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

class _IndexedHome extends ConsumerWidget {
  final ValueChanged<String> onQueryTap;
  const _IndexedHome({required this.onQueryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(indexedGalleryProvider);
    final suggestions = ref.watch(librarySuggestionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IndexSummary(),
        if (suggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Text(
                  'Try searching',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  message:
                      'Based on labels in your indexed photos. Automatic labels can be incorrect.',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32 + MediaQuery.textScalerOf(context).scale(14) * 1.4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final suggestion = suggestions[i];
                final title =
                    '${suggestion.query[0].toUpperCase()}${suggestion.query.substring(1)}';
                return Center(
                  child: Tooltip(
                    message:
                        '${suggestion.photoCount} indexed photos labelled ${suggestion.query}',
                    child: ActionChip(
                      key: ValueKey('library-suggestion-${suggestion.query}'),
                      avatar: const Icon(Icons.search, size: 16),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onPressed: () => onQueryTap(suggestion.query),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        Expanded(
          child: gallery.photos.isEmpty
              ? const Center(child: Text('No indexed photos yet'))
              : IndexedGalleryView(gallery: gallery),
        ),
      ],
    );
  }
}

class _IndexSummary extends ConsumerWidget {
  const _IndexSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(photoLibraryProvider).length;
    final indexing = ref.watch(indexingControllerProvider);
    final controller = ref.read(indexingControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '$total photo${total == 1 ? '' : 's'} indexed',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (indexingSupported) ...[
                indexing.running
                    ? TextButton.icon(
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        onPressed: controller.cancel,
                        label: const Text('Cancel indexing'),
                      )
                    : TextButton.icon(
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        onPressed: () => chooseFoldersAndIndex(context, ref),
                        label: Text(
                          total == 0 ? 'Index photos' : 'Continue indexing',
                        ),
                      ),
              ],
            ],
          ),
          if (statusLine(indexing) != null) ...[
            const SizedBox(height: 4),
            IndexingStatus(state: indexing),
          ],
        ],
      ),
    );
  }
}

/// Compact indicator leaves room for the app title on narrow screens.
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.semantic});
  final bool semantic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: semantic
          ? 'CLIP semantic search (on-device)'
          : 'Keyword search (semantic model not loaded)',
      child: Icon(
        semantic ? Icons.auto_awesome : Icons.abc,
        semanticLabel: semantic ? 'Semantic search' : 'Keyword search',
        color: scheme.primary,
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
