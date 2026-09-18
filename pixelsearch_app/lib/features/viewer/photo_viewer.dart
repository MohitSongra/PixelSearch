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
    final updated = ref
        .watch(photoLibraryProvider)
        .where((p) => p.id == original.id);
    return updated.isEmpty ? original : updated.first;
  }

  @override
  Widget build(BuildContext context) {
    final photo = current;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          photo.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
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
                  child: OriginalPhoto(
                    key: ValueKey(widget.photos[i].id),
                    photo: widget.photos[i],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${Dates.short(photo.date)} | ${photo.album}'),
                  PhotoPeopleSection(photoId: photo.id),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ref
                                  .read(userPreferencesProvider)
                                  .hasLabelCorrection(photo)
                              ? 'Your labels'
                              : 'Automatic labels',
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
                          if (saved == true && mounted) {
                            await ref
                                .read(photoLibraryProvider.notifier)
                                .refresh();
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    photo.labels.isEmpty
                        ? 'No labels'
                        : photo.labels.join(', '),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.notes),
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
                          icon: const Icon(Icons.info_outline),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
