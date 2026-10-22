import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/memory_repository.dart';
import '../../domain/timeline/memory_grouping.dart';
import '../../domain/timeline/memory_stories.dart';
import '../../state/providers.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/empty_state.dart';
import 'memory_story_viewer.dart';
import 'timeline_photo_image.dart';

final memoryRepositoryProvider = Provider(
  (ref) => MemoryRepository(ref.watch(appDatabaseProvider)),
);
final memoriesProvider = FutureProvider<List<MemoryGroup>>((ref) async {
  ref.watch(photoLibraryProvider);
  if (!indexingSupported) return [];
  // Avoid reconciling the initial empty UI state against durable events.
  final photos = await ref.read(photoRepositoryProvider).loadPhotos();
  return ref.read(memoryRepositoryProvider).reconcile(photos);
});

final memoryTimelineProvider = Provider<AsyncValue<MemoryTimeline>>(
  (ref) => ref.watch(memoriesProvider).whenData(MemoryTimeline.new),
);

String _photoCount(int count) => '$count photo${count == 1 ? '' : 's'}';

String _dateRange(DateTime start, DateTime end) {
  final first = Dates.short(start.toLocal());
  final last = Dates.short(end.toLocal());
  return first == last ? first : '$first - $last';
}

String _memoryTitle(MemoryGroup event) =>
    event.title.isEmpty ? _photoCount(event.photos.length) : event.title;

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});
  @override
  ConsumerState<TimelineScreen> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<TimelineScreen> {
  int? _year;
  int? _month;
  bool _peopleOnly = false;

  Widget _navigation(MemoryTimeline timeline, int year, int? month) {
    final yearPicker = DropdownButtonFormField<int>(
      key: ValueKey('timeline-year-$year'),
      isExpanded: true,
      itemHeight: null,
      initialValue: year,
      decoration: const InputDecoration(labelText: 'Year'),
      items: [
        for (final value in timeline.years)
          DropdownMenuItem(value: value, child: Text('$value')),
      ],
      onChanged: (value) => setState(() {
        _year = value;
        _month = null;
        _peopleOnly = false;
      }),
    );
    final monthPicker = DropdownButtonFormField<int>(
      key: ValueKey('timeline-month-$year-$month'),
      isExpanded: true,
      itemHeight: null,
      initialValue: month ?? 0,
      decoration: const InputDecoration(labelText: 'Month'),
      items: [
        const DropdownMenuItem(value: 0, child: Text('All months')),
        for (final value in timeline.monthsIn(year))
          DropdownMenuItem(
            value: value,
            child: Text(Dates.monthYear(DateTime(year, value))),
          ),
      ],
      onChanged: (value) => setState(() => _month = value == 0 ? null : value),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(16) > 24) {
          return Column(
            children: [yearPicker, const SizedBox(height: 12), monthPicker],
          );
        }
        return Row(
          children: [
            Expanded(child: yearPicker),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: monthPicker),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Timeline')),
    body: ref
        .watch(memoryTimelineProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Timeline unavailable: $e')),
          data: (timeline) {
            if (timeline.years.isEmpty) {
              return const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'Memories, ready to rediscover',
                message:
                    'Index your photos to see them grouped into moments and yearly highlights.',
              );
            }
            final year = timeline.years.contains(_year)
                ? _year!
                : timeline.years.first;
            final month = timeline.monthsIn(year).contains(_month)
                ? _month
                : null;
            final highlights = timeline.story(year)!;
            final people = timeline.story(year, peopleOnly: true);
            final peopleOnly = _peopleOnly && people != null;
            final story = peopleOnly ? people : highlights;
            final sections = timeline.sections(year, month: month);
            return CustomScrollView(
              key: ValueKey('timeline-$year-$month'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MediaQuery.textScalerOf(context).scale(16) <=
                            24) ...[
                          Text(
                            'Moments, rediscovered.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The days worth another look.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _navigation(timeline, year, month),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            direction:
                                MediaQuery.textScalerOf(context).scale(14) > 21
                                ? Axis.vertical
                                : Axis.horizontal,
                            segments: [
                              const ButtonSegment(
                                value: false,
                                icon: Icon(Icons.auto_awesome_outlined),
                                label: Text('Highlights'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: const Icon(Icons.people_outline),
                                label: const Text('People'),
                                enabled: people != null,
                              ),
                            ],
                            selected: {peopleOnly},
                            showSelectedIcon: false,
                            onSelectionChanged: (value) =>
                                setState(() => _peopleOnly = value.single),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StoryCard(story: story),
                      ],
                    ),
                  ),
                ),
                for (final section in sections) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          Dates.monthYear(section.date),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList.builder(
                      itemCount: section.memories.length,
                      itemBuilder: (context, i) {
                        final memory = section.memories[i];
                        final event = memory.event;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Material(
                            key: ValueKey('memory-${event.id}'),
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      MemoryDetail(eventId: event.id),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 104,
                                        height: 104,
                                        child: TimelinePhotoImage(
                                          photo: event.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _memoryTitle(event),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _dateRange(
                                              memory.start,
                                              memory.end,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          if (event.title.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                _photoCount(
                                                  event.photos.length,
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 20),
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
  );
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final MemoryStory story;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        key: const ValueKey('open-memory-story'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MemoryStoryViewer(story: story),
          ),
        ),
        child: SizedBox(
          height: large ? 300 : 248,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TimelinePhotoImage(photo: story.photos.first),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDB001B16)],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _photoCount(story.photos.length),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.play_circle_outline,
                      semanticLabel: 'Open story',
                      color: Colors.white,
                      size: 40,
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

class MemoryDetail extends ConsumerWidget {
  const MemoryDetail({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(memoriesProvider).valueOrNull ?? [];
    final matches = events.where((e) => e.id == eventId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Memory unavailable')),
      );
    }
    final event = matches.first;
    Future<void> save({String? title, String? cover}) async {
      try {
        await ref
            .read(memoryRepositoryProvider)
            .edit(eventId, title: title, coverId: cover);
        ref.invalidate(memoriesProvider);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save memory')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _memoryTitle(event),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Rename memory',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              var draft = event.title;
              final title = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Memory name'),
                  content: TextFormField(
                    initialValue: draft,
                    onChanged: (v) => draft = v,
                    maxLength: 100,
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, draft),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (title != null) await save(title: title);
            },
          ),
          IconButton(
            tooltip: 'Choose cover',
            icon: const Icon(Icons.image_outlined),
            onPressed: () async {
              final id = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (context) => GridView.builder(
                  itemCount: event.photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemBuilder: (_, i) => Semantics(
                    label: 'Use photo ${i + 1} as cover',
                    button: true,
                    selected: event.photos[i].id == event.cover.id,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, event.photos[i].id),
                      child: TimelinePhotoImage(photo: event.photos[i]),
                    ),
                  ),
                ),
              );
              if (id != null) await save(cover: id);
            },
          ),
        ],
      ),
      body: PhotoGrid(photos: event.photos),
    );
  }
}
