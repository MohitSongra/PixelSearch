import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import 'label_editor.dart';

/// Full-screen viewer with pinch-zoom, swipe between results, a details sheet,
/// and a consent-gated (mock) cloud caption — demonstrating the privacy model.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  final Map<String, String> _captions = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Photo get _current {
    final original = widget.photos[_index];
    final latest = ref
        .read(photoLibraryProvider)
        .where((p) => p.id == original.id);
    return ref
        .read(userPreferencesProvider)
        .applyLabelCorrection(latest.isEmpty ? original : latest.first);
  }

  Future<void> _editLabels() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LabelEditor(photo: _current),
    );
    if (saved != true || !mounted) return;
    await ref.read(photoLibraryProvider.notifier).refresh();
    if (mounted) setState(() {});
  }

  Future<void> _generateCaption() async {
    final privacyMode = ref.read(privacyModeProvider);
    if (privacyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Privacy mode is on — turn it off in Settings to use cloud features.',
          ),
        ),
      );
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ConsentSheet(photo: _current),
    );
    if (ok != true || !mounted) return;

    // Simulate an opt-in cloud round-trip (the real backend is Milestone M13).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 900),
        content: Text('Uploading 1 photo · generating caption…'),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _captions[_current.id] =
          '“${_current.caption}” — a bright, candid moment; likely ${_current.displayTags.take(3).join(', ')}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Share — wired to the OS share sheet next milestone.',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.photos.length,
              itemBuilder: (context, i) {
                final p = widget.photos[i];
                return Hero(
                  tag: p.id,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image(image: p.image, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),
          ),
          _DetailsPanel(
            photo: _current,
            caption: _captions[_current.id],
            onGenerateCaption: _generateCaption,
            onEditLabels: _editLabels,
            corrected: ref
                .read(userPreferencesProvider)
                .hasLabelCorrection(_current),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final Photo photo;
  final String? caption;
  final VoidCallback onGenerateCaption;
  final VoidCallback onEditLabels;
  final bool corrected;
  const _DetailsPanel({
    required this.photo,
    required this.caption,
    required this.onGenerateCaption,
    required this.onEditLabels,
    required this.corrected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photo.displayTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  Dates.short(photo.date),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (photo.place != null) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.place, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    photo.place!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(corrected ? 'Your labels' : 'Automatic labels'),
                ),
                IconButton(
                  tooltip: 'Edit labels',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEditLabels,
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: photo.labels
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            if (photo.labels.isEmpty) const Text('No labels'),
            if (photo.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [
                  for (final tag in photo.tags) Chip(label: Text(tag)),
                ],
              ),
            if (caption != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(caption!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onGenerateCaption,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate caption (cloud)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentSheet extends StatelessWidget {
  final Photo photo;
  const _ConsentSheet({required this.photo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: scheme.primary),
              const SizedBox(width: 10),
              Text(
                'Cloud caption',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To generate an AI caption, this ONE photo will be sent to the PixelSearch '
            'backend. Nothing else leaves your device, and the result is cached locally. '
            'Your gallery is never uploaded.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Allow for this photo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
