import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sample_data.dart';
import '../../state/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/photo_grid.dart';

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
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: q.length));
    ref.read(searchQueryProvider.notifier).state = q;
  }

  Future<void> _loadDevicePhotos() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      duration: Duration(milliseconds: 900),
      content: Text('Requesting photo access…'),
    ));
    final added =
        await ref.read(photoLibraryProvider.notifier).loadDevicePhotos();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(added > 0
          ? 'Added $added photos from your device.'
          : 'No device photos added (permission denied or none found).'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final deviceSupported =
        ref.read(photoLibraryProvider.notifier).deviceSupported;
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
                  Text('PixelSearch',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const Spacer(),
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
                  ? _EmptySearch(
                      onQueryTap: _runQuery,
                      onLoadDevice: deviceSupported ? _loadDevicePhotos : null,
                      total: ref.watch(photoLibraryProvider).length,
                    )
                  : results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No matches',
                          message:
                              'Try simpler words like “beach”, “dog”, or “night”.\n(Real CLIP search comes in the next milestone.)',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                              child: Text(
                                '${results.length} result${results.length == 1 ? '' : 's'} for “$query”',
                                style: TextStyle(color: scheme.onSurfaceVariant),
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
  final VoidCallback? onLoadDevice;
  final int total;
  const _EmptySearch({
    required this.onQueryTap,
    required this.onLoadDevice,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Try searching',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedQueries
              .map((q) => ActionChip(
                    label: Text(q),
                    onPressed: () => onQueryTap(q),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$total photos in library',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        onLoadDevice != null
                            ? 'Browsing a sample set. Add your real gallery to search it too.'
                            : 'Running on the bundled sample set (web demo).',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (onLoadDevice != null)
                  FilledButton.tonal(
                    onPressed: onLoadDevice,
                    child: const Text('Add mine'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
