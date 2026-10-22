import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../state/people_providers.dart';
import '../../domain/people/people_query.dart';
import '../../domain/people/people_search_state.dart';
import '../../domain/search/search_response.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/indexing_status.dart';
import '../../widgets/photo_grid.dart';
import '../indexing/folder_picker.dart';
import '../people/people_screen.dart';
import '../people/people_widgets.dart';
import '../people/same_person_screen.dart';
import 'conversation_sheet.dart';
import 'indexed_gallery_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _searchFieldKey = GlobalKey();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    ref.read(searchQueryProvider.notifier).state = q;
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _runQuery('');
    ref.invalidate(searchFiltersProvider);
    ref.invalidate(peopleNameChoicesProvider);
    ref.invalidate(peopleIgnoredNamesProvider);
  }

  void _openPeople({bool newFaces = false}) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PeopleScreen(showNewFaces: newFaces),
    ),
  );

  /// Shows every photo of the people in [query], dropping the scene words (and,
  /// when [keepDates] is false, the date/album/place filters too).
  void _showAllOfPeople(PeopleQuery query, {required bool keepDates}) {
    final people = query.filters;
    ref.read(searchFiltersProvider.notifier).state = keepDates
        ? people
        : const SearchFilters().withPeople(
            required: people.personIds,
            any: people.anyPersonIds,
            excluded: people.excludedPersonIds,
          );
    _runQuery('');
  }

  Widget _peopleEmptyView(PeopleEmptyState state, PeopleQuery query) {
    final names = joinNames(state.names);
    // Exclusion-only searches ("beach without X") name nobody to include.
    final ofNames = names.isEmpty ? '' : ' of $names';
    final photos = '${state.count} photo${state.count == 1 ? '' : 's'}';
    const key = ValueKey('person-search-empty');
    return switch (state.kind) {
      PeopleEmptyKind.selfMissing => EmptyState(
        key: key,
        icon: Icons.person_search_outlined,
        title: 'Which person is you?',
        message:
            'Open your person in People, tap Edit name and turn on This is me. '
            'Nothing was searched yet.',
        actionLabel: 'Open People',
        actionIcon: Icons.people_outline,
        onAction: _openPeople,
        secondaryLabel: 'Search without "me"',
        onSecondary: () => ref.read(peopleIgnoredNamesProvider.notifier).state =
            {...ref.read(peopleIgnoredNamesProvider), selfKey},
      ),
      PeopleEmptyKind.peopleOff => EmptyState(
        key: key,
        icon: Icons.people_outline,
        title: 'People is off',
        message: 'Turn on People to search by name.',
        actionLabel: 'Open People',
        actionIcon: Icons.people_outline,
        onAction: _openPeople,
        secondaryLabel: 'Clear person filter',
        onSecondary: () => ref.read(searchFiltersProvider.notifier).state = ref
            .read(searchFiltersProvider)
            .withoutPeople(),
      ),
      PeopleEmptyKind.noAssignedPhotos => EmptyState(
        key: key,
        icon: Icons.person_search_outlined,
        title: 'No photos of $names yet',
        message:
            'People search uses faces you assigned to a person on this device. '
            'Name more faces in New faces.',
        actionLabel: 'Review new faces',
        onAction: () => _openPeople(newFaces: true),
      ),
      PeopleEmptyKind.notTogether => EmptyState(
        key: key,
        icon: Icons.group_outlined,
        title: 'No photos of $names together',
        message:
            'Each has assigned photos, but none include all of them. Faces '
            'that are not assigned yet cannot be matched.',
        actionLabel: 'Review new faces',
        onAction: () => _openPeople(newFaces: true),
      ),
      PeopleEmptyKind.allExcluded => EmptyState(
        key: key,
        icon: Icons.person_off_outlined,
        title: 'Every photo$ofNames includes an excluded person',
        message:
            'Excluding only removes photos where that person’s face is assigned.',
      ),
      PeopleEmptyKind.noneInFilters => EmptyState(
        key: key,
        icon: Icons.filter_alt_off_outlined,
        title: '$photos$ofNames, none with these filters',
        message: 'Remove a date, album or place filter to see them.',
        actionLabel: 'Show all $photos',
        actionIcon: Icons.photo_library_outlined,
        onAction: () => _showAllOfPeople(query, keepDates: false),
      ),
      PeopleEmptyKind.noSceneMatch => EmptyState(
        key: key,
        icon: Icons.image_search_outlined,
        title: '$photos$ofNames, none match "${state.remainder}"',
        message: 'Try other words, or show all of these photos.',
        actionLabel: 'Show all $photos',
        actionIcon: Icons.photo_library_outlined,
        onAction: () => _showAllOfPeople(query, keepDates: true),
      ),
    };
  }

  static String _chipLabel(PersonMention mention) {
    final name = mention.isSelf ? 'You' : mention.label ?? mention.text;
    return switch (mention.role) {
      PersonRole.required => name,
      PersonRole.any => 'either $name',
      PersonRole.excluded => 'not $name',
    };
  }

  void _conversation({bool listen = false}) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ConversationSheet(startListening: listen),
  );
  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, value) {
      // Keep person choices and dismissed chips while their names remain.
      final choices = ref.read(peopleNameChoicesProvider);
      final ignored = ref.read(peopleIgnoredNamesProvider);
      final kept = prunePeopleSelections(value, choices, ignored);
      if (kept.choices.length != choices.length) {
        ref.read(peopleNameChoicesProvider.notifier).state = kept.choices;
      }
      if (kept.ignored.length != ignored.length) {
        ref.read(peopleIgnoredNamesProvider.notifier).state = kept.ignored;
      }
      if (_controller.text != value) {
        _controller.text = value;
        _controller.selection = TextSelection.collapsed(offset: value.length);
      }
    });
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(searchFiltersProvider);
    final home = query.trim().isEmpty && filters.isEmpty;
    ref.watch(peopleControllerProvider);
    final peopleQuery = ref.watch(peopleQueryProvider).valueOrNull;
    final peopleSnapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    final newFaces = peopleSnapshot?.toName() ?? 0;
    final response = ref.watch(searchResponseProvider).valueOrNull;
    final peopleEmpty = peopleQuery == null || response == null
        ? null
        : explainEmptyPeopleSearch(peopleQuery, response);
    final personChips = <PersonMention>[];
    for (final mention in peopleQuery?.mentions ?? const <PersonMention>[]) {
      if (mention.personId != null &&
          !personChips.any(
            (c) => c.personId == mention.personId && c.role == mention.role,
          )) {
        personChips.add(mention);
      }
    }
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.isLoading
        ? const <Photo>[]
        : resultsAsync.valueOrNull ?? const <Photo>[];
    final semantic =
        ref.watch(searchBackendProvider).valueOrNull?.isSemantic ?? false;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 23;
    final roomy = MediaQuery.sizeOf(context).height > 720 && !largeText;
    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: TextField(
        key: _searchFieldKey,
        controller: _controller,
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Describe a photo…',
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? IconButton(
                  tooltip: 'Voice search',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => _conversation(listen: true),
                )
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () => _runQuery(''),
                ),
          filled: true,
          fillColor: scheme.primaryContainer.withValues(alpha: .65),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
    return PopScope(
      canPop: home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clear();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          leading: home ? null : BackButton(onPressed: _clear),
          title: home
              ? Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Pixel'),
                      TextSpan(
                        text: 'Search',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ],
                  ),
                  style: theme.textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('Search results'),
          actions: [
            IconButton(
              tooltip: 'People',
              icon: Badge(
                isLabelVisible: newFaces > 0,
                child: const Icon(Icons.people_outline),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PeopleScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Voice and conversation',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _conversation,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: home
              ? _IndexedHome(
                  onQueryTap: _runQuery,
                  introduction: roomy
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LocalSearchNote(semantic: semantic),
                              const SizedBox(height: 6),
                              Text(
                                'Find a moment.',
                                style: theme.textTheme.headlineLarge,
                              ),
                            ],
                          ),
                        )
                      : null,
                  searchField: searchField,
                  supportingContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (roomy)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                          child: Text(
                            'Places, people, or the little details.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (newFaces > 0)
                        ListTile(
                          key: const ValueKey('search-new-faces'),
                          dense: true,
                          leading: const Icon(Icons.person_add_alt_1_outlined),
                          title: const Text('New faces found'),
                          subtitle: Text('$newFaces to name'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const PeopleScreen(showNewFaces: true),
                            ),
                          ),
                        ),
                      // Asked each time the app opens, like Google Photos'
                      // "Same or different person?" prompts.
                      if (!kIsWeb) const SamePersonPrompt(),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const _SearchFiltersBar(),
                    if (peopleQuery != null &&
                        (personChips.isNotEmpty || peopleQuery.needsChoice))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final mention in personChips)
                              InputChip(
                                key: ValueKey(
                                  mention.role == PersonRole.required
                                      ? 'person-chip-${mention.key}'
                                      : 'person-chip-${mention.key}-${mention.role.name}',
                                ),
                                label: Text(_chipLabel(mention)),
                                tooltip: mention.role == PersonRole.excluded
                                    ? 'Hides photos where this face is assigned'
                                    : null,
                                avatar: Icon(
                                  mention.role == PersonRole.excluded
                                      ? Icons.person_off_outlined
                                      : Icons.person_outline,
                                ),
                                // Dismissing a chip searches the words as text.
                                onDeleted: () =>
                                    ref
                                        .read(
                                          peopleIgnoredNamesProvider.notifier,
                                        )
                                        .state = {
                                      ...ref.read(peopleIgnoredNamesProvider),
                                      mention.key,
                                    },
                              ),
                            for (final entry in peopleQuery.ambiguous.entries)
                              PopupMenuButton<String>(
                                tooltip: entry.key == selfKey
                                    ? 'Choose which person is you'
                                    : 'Choose ${entry.key}',
                                onSelected: (id) =>
                                    ref
                                        .read(
                                          peopleNameChoicesProvider.notifier,
                                        )
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
                                                        person.record.id ==
                                                        p.id,
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
                                  label: Text(
                                    entry.key == selfKey
                                        ? 'Which one is you?'
                                        : 'Choose ${entry.key}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    resultsAsync.isLoading
                                        ? 'Finding your photos…'
                                        : '${results.length} result${results.length == 1 ? '' : 's'}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Tooltip(
                                  // A name-only query lists the person's
                                  // photos without the text model.
                                  message: response?.mode == 'people'
                                      ? 'Matched by assigned faces'
                                      : semantic
                                      ? 'Matched by on-device semantic search'
                                      : 'Matched by labels and photo details',
                                  child: Icon(
                                    Icons.phonelink_lock_outlined,
                                    size: 20,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: resultsAsync.isLoading
                                ? const _Searching()
                                : peopleQuery?.needsChoice == true &&
                                      results.isEmpty
                                ? const EmptyState(
                                    icon: Icons.person_search_outlined,
                                    title: 'Which person?',
                                    message:
                                        'Choose a person above to see their photos.',
                                  )
                                : resultsAsync.hasError
                                ? const EmptyState(
                                    icon: Icons.error_outline,
                                    title: 'Search unavailable',
                                    message:
                                        'Could not read the search index. Reopen the app to retry.',
                                  )
                                : peopleEmpty != null && results.isEmpty
                                ? LayoutBuilder(
                                    // Two actions and long names must not be
                                    // clipped on small phones or large text.
                                    builder: (context, box) =>
                                        SingleChildScrollView(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: box.maxHeight,
                                            ),
                                            child: _peopleEmptyView(
                                              peopleEmpty,
                                              peopleQuery!,
                                            ),
                                          ),
                                        ),
                                  )
                                : results.isEmpty
                                ? const EmptyState(
                                    icon: Icons.search_off,
                                    title: 'No close matches',
                                    message:
                                        'Try a simpler description or remove a filter. Only indexed photos are searched.',
                                  )
                                : PhotoGrid(
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
      ),
    );
  }
}

class _LocalSearchNote extends StatelessWidget {
  const _LocalSearchNote({required this.semantic});
  final bool semantic;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: semantic
          ? 'AI search runs on your device'
          : 'Searching labels and photo details on your device',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'On-device search',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexedHome extends ConsumerWidget {
  const _IndexedHome({
    required this.onQueryTap,
    required this.searchField,
    required this.supportingContent,
    this.introduction,
  });
  final ValueChanged<String> onQueryTap;
  final Widget searchField;
  final Widget supportingContent;
  final Widget? introduction;
  void _allSuggestions(BuildContext context, WidgetRef ref) {
    final suggestions = ref.read(librarySuggestionsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Try a search',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final suggestion in suggestions)
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion.query),
                subtitle: Text(
                  '${suggestion.photoCount} photos with this label',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onQueryTap(suggestion.query);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(indexedGalleryProvider);
    final suggestions = ref.watch(librarySuggestionsProvider);
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showCovers =
            constraints.maxHeight > 400 &&
            MediaQuery.textScalerOf(context).scale(14) < 21;
        return IndexedGalleryView(
          gallery: gallery,
          introduction: introduction,
          pinnedHeader: searchField,
          headerBuilder: (chooseMonth, month) =>
              _IndexSummary(onChooseMonth: chooseMonth, month: month),
          emptyContent: const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Your memories start here',
            message:
                'Add folders from your phone to make your photos searchable. Indexing happens on this device.',
          ),
          beforeGallery: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              supportingContent,
              if (suggestions.isNotEmpty) ...[
                if (MediaQuery.textScalerOf(context).scale(14) < 21)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Try a search',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _allSuggestions(context, ref),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: showCovers
                      ? 112
                      : MediaQuery.textScalerOf(context).scale(14) + 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: showCovers
                        ? suggestions.length.clamp(0, 4)
                        : suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final suggestion = suggestions[i];
                      final title =
                          '${suggestion.query[0].toUpperCase()}${suggestion.query.substring(1)}';
                      final cover = gallery.photos
                          .where(
                            (photo) => photo.labels.any(
                              (label) =>
                                  label.trim().toLowerCase().replaceAll(
                                    RegExp(r'\s+'),
                                    ' ',
                                  ) ==
                                  suggestion.query,
                            ),
                          )
                          .firstOrNull;
                      if (!showCovers || cover == null) {
                        return Center(
                          child: ActionChip(
                            key: ValueKey(
                              'library-suggestion-${suggestion.query}',
                            ),
                            avatar: const Icon(Icons.search, size: 18),
                            label: Text(title),
                            onPressed: () => onQueryTap(suggestion.query),
                          ),
                        );
                      }
                      return Semantics(
                        button: true,
                        label:
                            'Search $title, ${suggestion.photoCount} labelled photos',
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          color: theme.colorScheme.surfaceContainer,
                          child: InkWell(
                            key: ValueKey(
                              'library-suggestion-${suggestion.query}',
                            ),
                            onTap: () => onQueryTap(suggestion.query),
                            child: SizedBox(
                              width: ((constraints.maxWidth - 56) / 2).clamp(
                                138,
                                240,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image(
                                    image: cover.image,
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xB3001612),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    right: 12,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _IndexSummary extends ConsumerWidget {
  const _IndexSummary({this.onChooseMonth, this.month});
  final VoidCallback? onChooseMonth;
  final DateTime? month;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(photoLibraryProvider).length;
    final indexing = ref.watch(indexingControllerProvider);
    final controller = ref.read(indexingControllerProvider.notifier);
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
    final actions = <Widget>[
      if (onChooseMonth != null)
        IconButton(
          key: const ValueKey('gallery-month-picker'),
          onPressed: onChooseMonth,
          tooltip: 'Jump to date · ${Dates.monthYear(month!)}',
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      if (indexingSupported)
        Tooltip(
          message: indexing.running
              ? 'Cancel indexing'
              : total == 0
              ? 'Index photos'
              : 'Continue indexing',
          child:
              MediaQuery.sizeOf(context).width >= 410 &&
                  !indexing.running &&
                  !largeText
              ? TextButton.icon(
                  onPressed: () => chooseFoldersAndIndex(context, ref),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos'),
                )
              : IconButton(
                  icon: Icon(
                    indexing.running
                        ? Icons.stop_circle_outlined
                        : Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: indexing.running
                      ? controller.cancel
                      : () => chooseFoldersAndIndex(context, ref),
                ),
        ),
    ];
    final title = Text('Your photos', style: theme.textTheme.titleLarge);
    final count = Semantics(
      label: '$total photo${total == 1 ? '' : 's'} indexed',
      excludeSemantics: true,
      child: Text(
        largeText
            ? '$total indexed'
            : '$total photo${total == 1 ? '' : 's'} indexed',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (largeText) ...[
            title,
            Row(
              children: [
                Expanded(child: count),
                ...actions,
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, count],
                  ),
                ),
                ...actions,
              ],
            ),
          if (statusLine(indexing) != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: IndexingStatus(state: indexing),
            ),
        ],
      ),
    );
  }
}

class _SearchFiltersBar extends ConsumerWidget {
  const _SearchFiltersBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final photos = ref.watch(photoLibraryProvider);
    final people = kIsWeb
        ? null
        : ref.watch(peopleSnapshotProvider).valueOrNull;
    // Copy-with helpers keep every person field when one filter changes.
    void save({
      DateTime? from,
      DateTime? until,
      String? album,
      String? place,
      String? clear,
    }) {
      var next = filters;
      if (clear == 'date') {
        next = next.withDate(null, null);
      } else if (from != null || until != null) {
        next = next.withDate(from ?? filters.from, until ?? filters.until);
      }
      if (clear == 'album') {
        next = next.withAlbum(null);
      } else if (album != null) {
        next = next.withAlbum(album);
      }
      if (clear == 'place') {
        next = next.withPlace(null);
      } else if (place != null) {
        next = next.withPlace(place);
      }
      ref.read(searchFiltersProvider.notifier).state = next;
    }

    final chosen = {...filters.personIds, ...filters.anyPersonIds};
    String personLabel(String id) =>
        people?.people.where((p) => p.record.id == id).firstOrNull?.label ??
        'Person';
    final peopleLabel = chosen.isEmpty
        ? filters.excludedPersonIds.isEmpty
              ? 'People'
              : 'Not ${personLabel(filters.excludedPersonIds.first)}'
        : chosen.length == 1
        ? personLabel(chosen.single)
        : '${personLabel(chosen.first)} +${chosen.length - 1}';
    final showPeople =
        people != null &&
        people.state.enabled &&
        (filters.hasPeople ||
            people.people.any(
              (p) => p.record.name.trim().isNotEmpty && !p.record.hidden,
            ));

    Future<void> pick(
      String label,
      List<String> values,
      ValueChanged<String> selected,
    ) async {
      final value = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final item in values)
                ListTile(
                  title: Text(item),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      );
      if (value != null) selected(value);
    }

    final albums =
        photos.map((p) => p.album).where((s) => s.isNotEmpty).toSet().toList()
          ..sort();
    final places =
        photos
            .map((p) => p.place)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (showPeople) ...[
            Center(
              child: FilterChip(
                key: const ValueKey('people-filter-chip'),
                label: Text(
                  peopleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                avatar: const Icon(Icons.people_outline, size: 16),
                selected: filters.hasPeople,
                onSelected: (_) async {
                  final picked = await choosePeople(
                    context,
                    people.people,
                    selected: chosen,
                    any: filters.anyPersonIds.isNotEmpty,
                  );
                  if (picked == null) return;
                  final current = ref.read(searchFiltersProvider);
                  // Clear removes every person constraint, exclusions too.
                  ref
                      .read(searchFiltersProvider.notifier)
                      .state = picked.ids.isEmpty
                      ? current.withoutPeople()
                      : current.withPeople(
                          required: picked.any ? const {} : picked.ids,
                          any: picked.any ? picked.ids : const {},
                          excluded: current.excludedPersonIds,
                        );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Center(
            child: FilterChip(
              label: Text(
                filters.from == null ? 'Date' : Dates.short(filters.from!),
              ),
              avatar: const Icon(Icons.calendar_today_outlined, size: 16),
              selected: filters.from != null || filters.until != null,
              onSelected: (_) async {
                if (filters.from != null || filters.until != null) {
                  save(clear: 'date');
                  return;
                }
                final dates = photos.map((p) => p.date.toLocal()).toList()
                  ..sort();
                final last = dates.isEmpty ? DateTime.now() : dates.last;
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: dates.isEmpty ? DateTime(1900) : dates.first,
                  lastDate: DateTime(last.year, last.month, last.day),
                  helpText: 'Filter by date',
                );
                if (range != null) {
                  save(
                    from: range.start,
                    until: DateTime(
                      range.end.year,
                      range.end.month,
                      range.end.day + 1,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: FilterChip(
              label: Text(filters.album ?? 'Album'),
              selected: filters.album != null,
              avatar: const Icon(Icons.photo_album_outlined, size: 16),
              onSelected: albums.isEmpty && filters.album == null
                  ? null
                  : (_) {
                      if (filters.album != null) {
                        save(clear: 'album');
                      } else {
                        pick(
                          'Choose an album',
                          albums,
                          (value) => save(album: value),
                        );
                      }
                    },
            ),
          ),
          if (places.isNotEmpty || filters.place != null) ...[
            const SizedBox(width: 8),
            Center(
              child: FilterChip(
                label: Text(filters.place ?? 'Place'),
                selected: filters.place != null,
                avatar: const Icon(Icons.place_outlined, size: 16),
                onSelected: (_) {
                  if (filters.place != null) {
                    save(clear: 'place');
                  } else {
                    pick(
                      'Choose a place',
                      places,
                      (value) => save(place: value),
                    );
                  }
                },
              ),
            ),
          ],
          if (!filters.isEmpty) ...[
            const SizedBox(width: 8),
            Center(
              child: IconButton(
                tooltip: 'Clear filters',
                onPressed: () => ref.invalidate(searchFiltersProvider),
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Searching your photos',
    liveRegion: true,
    child: Column(
      children: [
        const LinearProgressIndicator(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 15,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemBuilder: (_, _) => DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
