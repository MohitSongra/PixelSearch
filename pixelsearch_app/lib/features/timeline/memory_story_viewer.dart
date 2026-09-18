import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../domain/timeline/memory_stories.dart';
import 'timeline_photo_image.dart';

class MemoryStoryViewer extends StatefulWidget {
  const MemoryStoryViewer({super.key, required this.story});
  final MemoryStory story;

  @override
  State<MemoryStoryViewer> createState() => _MemoryStoryViewerState();
}

class _MemoryStoryViewerState extends State<MemoryStoryViewer>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _playing = false;
  bool get _last => _index == widget.story.photos.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(MemoryStoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story != widget.story) {
      _timer?.cancel();
      _index = 0;
      _playing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _playing) _pause();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _schedule() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_last) {
        _pause();
        return;
      }
      setState(() {
        _index++;
        if (_last) _playing = false;
      });
      _schedule();
    });
  }

  void _move(int delta) {
    _timer?.cancel();
    setState(() {
      _index = (_index + delta).clamp(0, widget.story.photos.length - 1);
      _playing = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final photo = story.photos[_index];
    final controls = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              Dates.short(photo.date.toLocal()),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text('${_index + 1} of ${story.photos.length}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous photo',
                onPressed: _index == 0 ? null : () => _move(-1),
                icon: const Icon(Icons.skip_previous),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                tooltip: _playing ? 'Pause story' : 'Play story',
                onPressed: _playing
                    ? _pause
                    : _last
                    ? null
                    : () {
                        setState(() => _playing = true);
                        _schedule();
                      },
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Next photo',
                onPressed: _last ? null : () => _move(1),
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close story',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final image = ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SizedBox.expand(
                child: TimelinePhotoImage(
                  key: ValueKey(photo.id),
                  photo: photo,
                  fit: BoxFit.contain,
                ),
              ),
            );
            final progress = LinearProgressIndicator(
              value: (_index + 1) / story.photos.length,
              semanticsLabel:
                  'Story progress, photo ${_index + 1} of ${story.photos.length}',
            );
            // Short landscape viewports keep the image visible and controls scrollable.
            if (constraints.maxHeight < 360) {
              return Column(
                children: [
                  progress,
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: image),
                        Flexible(child: SingleChildScrollView(child: controls)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                progress,
                Expanded(child: image),
                Flexible(
                  flex: 0,
                  child: SingleChildScrollView(child: controls),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
