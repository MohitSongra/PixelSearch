import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';
import '../../widgets/photo_grid.dart';

/// A time-based "event" cluster (Milestone M10, done on-device with classical
/// gap-based clustering — no cloud needed).
class _Event {
  final List<Photo> photos;
  _Event(this.photos);

  DateTime get start => photos.first.date;
  DateTime get end => photos.last.date;
  Photo get cover => photos.first;

  String get place {
    final counts = <String, int>{};
    for (final p in photos) {
      if (p.place != null) counts[p.place!] = (counts[p.place!] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'Moments';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String get title => '$place · ${Dates.monthYear(start)}';
}

List<_Event> _clusterEvents(List<Photo> photos) {
  if (photos.isEmpty) return [];
  final sorted = [...photos]..sort((a, b) => a.date.compareTo(b.date));
  final events = <_Event>[];
  var current = <Photo>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].date.difference(sorted[i - 1].date);
    if (gap.inHours > 48) {
      events.add(_Event(current));
      current = [];
    }
    current.add(sorted[i]);
  }
  if (current.isNotEmpty) events.add(_Event(current));
  // newest first
  return events.reversed.toList();
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoLibraryProvider);
    final events = _clusterEvents(photos);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, i) => _EventCard(event: events[i]),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strip = event.photos.take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(event.title)),
              body: PhotoGrid(photos: event.photos),
            ),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image(image: event.cover.image, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${Dates.short(event.start)}  ·  ${event.photos.length} photos',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: strip
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: Image(image: p.image, fit: BoxFit.cover),
                                  ),
                                ),
                              ))
                          .toList(),
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
