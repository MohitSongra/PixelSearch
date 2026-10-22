import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../domain/search/search_response.dart';
import '../../state/providers.dart';
import 'label_editor.dart';
import 'original_photo.dart';
import 'search_explanation.dart';
import 'caption_screen.dart';
import '../people/people_widgets.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.searchResponse,
  });
  final List<Photo> photos;
  final int initialIndex;
  final SearchResponse? searchResponse;
  @override
  ConsumerState<PhotoViewerScreen> createState() => _ViewerState();
}

class _ViewerState extends ConsumerState<PhotoViewerScreen> {
  late int _index = widget.initialIndex;
  late final _pages = PageController(initialPage: _index);
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Photo get current {
    final original = widget.photos[_index];
    return ref
            .watch(photoLibraryProvider)
            .where((p) => p.id == original.id)
            .firstOrNull ??
        original;
  }

  Future<void> _editLabels(Photo photo) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => LabelEditor(photo: photo),
    );
    if (saved == true && mounted) {
      await ref.read(photoLibraryProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = current;
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              title: Text(
                Dates.short(photo.date.toLocal()),
                style: theme.textTheme.titleMedium,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Center(
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: widget.photos.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        child: Center(
                          child: HeroMode(
                            enabled: !MediaQuery.disableAnimationsOf(context),
                            child: Hero(
                              tag: widget.photos[i].id,
                              child: OriginalPhoto(
                                key: ValueKey(widget.photos[i].id),
                                photo: widget.photos[i],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              photo.album,
                              if (photo.place?.isNotEmpty == true) photo.place!,
                            ].join(' · '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Details'),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => _PhotoDetails(
                              sourcePhoto: photo,
                              response: widget.searchResponse,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Labels'),
                          onPressed: () => _editLabels(photo),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.notes_outlined),
                          label: const Text('Caption'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => CaptionScreen(photo: photo),
                            ),
                          ),
                        ),
                        if (widget.searchResponse != null)
                          TextButton.icon(
                            icon: const Icon(Icons.manage_search_outlined),
                            label: const Text('Why this matched'),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => SearchExplanation(
                                response: widget.searchResponse!,
                                photoId: photo.id,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoDetails extends ConsumerWidget {
  const _PhotoDetails({required this.sourcePhoto, this.response});
  final Photo sourcePhoto;
  final SearchResponse? response;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo =
        ref
            .watch(photoLibraryProvider)
            .where((p) => p.id == sourcePhoto.id)
            .firstOrNull ??
        sourcePhoto;
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .65,
      minChildSize: .35,
      maxChildSize: .92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          Text('Photo details', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          Text(photo.displayTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(Dates.short(photo.date.toLocal())),
            subtitle: Text(photo.album),
          ),
          if (photo.place?.isNotEmpty == true || photo.hasLocation)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(photo.place ?? 'Recorded location'),
              subtitle: photo.hasLocation
                  ? Text(
                      '${photo.lat!.toStringAsFixed(4)}, ${photo.lng!.toStringAsFixed(4)}',
                    )
                  : null,
            ),
          const SizedBox(height: 16),
          PhotoPeopleSection(photoId: photo.id),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  ref.watch(userPreferencesProvider).hasLabelCorrection(photo)
                      ? 'Your labels'
                      : 'Automatic labels',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Edit labels',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => LabelEditor(photo: photo),
                  );
                  if (saved == true) {
                    await ref.read(photoLibraryProvider.notifier).refresh();
                  }
                },
              ),
            ],
          ),
          Text(
            'Labels help you find this photo. You can correct them.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (photo.labels.isEmpty)
            const Text('No labels')
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final label in photo.labels) Chip(label: Text(label)),
              ],
            ),
        ],
      ),
    );
  }
}
