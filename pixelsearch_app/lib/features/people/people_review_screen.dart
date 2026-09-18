import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';
import 'people_widgets.dart';

class PeopleReviewScreen extends ConsumerStatefulWidget {
  const PeopleReviewScreen({super.key});
  @override
  ConsumerState<PeopleReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<PeopleReviewScreen> {
  int _at = 0;
  bool _busy = false;
  String? _summary;
  bool _restored = false;
  Future<void> _prepare() async {
    setState(() => _busy = true);
    await peopleAction(context, ref, () async {
      await ref.read(peopleRepositoryProvider).prepareReview();
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _judge(PeopleReviewRecord pair, String value, int total) async {
    setState(() => _busy = true);
    final saved = await peopleAction(context, ref, () async {
      final repository = ref.read(peopleRepositoryProvider);
      await repository.judge(pair.id, value);
      final result = await repository.calibration();
      _summary = result.reason;
      if (result.passed) await repository.applyGrouping();
    });
    if (mounted) {
      setState(() {
        _busy = false;
        if (saved && _at + 1 < total) _at++;
      });
    }
  }

  void _open(PeopleFaceRecord face) {
    final photos = ref
        .read(photoLibraryProvider)
        .where((p) => p.id == face.photoId)
        .toList();
    if (photos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(peopleSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Face grouping review')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, st) => const Center(child: Text('Review unavailable.')),
        data: (snapshot) {
          if (!snapshot.state.enabled) {
            return const Center(child: Text('People grouping is off.'));
          }
          final pairs = snapshot.reviews;
          if (pairs.isEmpty) {
            return Center(
              child: _busy
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed:
                          snapshot.faces.where((f) => f.vector != null).length <
                              4
                          ? null
                          : _prepare,
                      icon: const Icon(Icons.compare),
                      label: const Text('Prepare local review'),
                    ),
            );
          }
          if (!_restored) {
            final pending = pairs.indexWhere((p) => p.judgment == 'pending');
            _at = pending < 0 ? 0 : pending;
            _restored = true;
          }
          final pair = pairs[_at.clamp(0, pairs.length - 1)];
          final left = snapshot.faces
              .where((f) => f.id == pair.leftFaceId)
              .firstOrNull;
          final right = snapshot.faces
              .where((f) => f.id == pair.rightFaceId)
              .firstOrNull;
          final complete = pairs.where((p) => p.judgment != 'pending').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('$complete of ${pairs.length} reviewed'),
              LinearProgressIndicator(value: complete / pairs.length),
              const SizedBox(height: 16),
              Text(
                'Same person?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final face in [left, right])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: InkWell(
                          onTap: face == null ? null : () => _open(face),
                          child: FaceImage(face: face),
                        ),
                      ),
                    ),
                ],
              ),
              if (left == null || right == null)
                const Text(
                  'A photo is no longer available. Start a new review.',
                ),
              const SizedBox(height: 12),
              for (final option in [
                ('same', 'Same person', Icons.check),
                ('different', 'Different people', Icons.close),
                ('unsure', 'Unsure', Icons.help_outline),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: OutlinedButton.icon(
                    onPressed: _busy || left == null || right == null
                        ? null
                        : () => _judge(pair, option.$1, pairs.length),
                    icon: Icon(option.$3),
                    label: Text(option.$2),
                    style: pair.judgment == option.$1
                        ? OutlinedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                          )
                        : null,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous pair',
                    onPressed: _busy || _at == 0
                        ? null
                        : () => setState(() => _at--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Pair ${_at + 1} of ${pairs.length}'),
                  IconButton(
                    tooltip: 'Next pair',
                    onPressed: _busy || _at + 1 >= pairs.length
                        ? null
                        : () => setState(() => _at++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_summary != null) Text(_summary!),
              if (complete == pairs.length && _summary == null)
                Text(
                  (jsonDecode(snapshot.state.calibrationJson) as Map)['reason']
                          as String? ??
                      'Review saved.',
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Start a new review?'),
                            content: const Text(
                              'Previous judgments stay archived. Automatic assignment is paused until the new review passes.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('New review'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        await peopleAction(
                          context,
                          ref,
                          () => ref
                              .read(peopleRepositoryProvider)
                              .archiveReview(),
                        );
                        if (mounted) {
                          setState(() {
                            _at = 0;
                            _summary = null;
                            _restored = false;
                          });
                        }
                      },
                icon: const Icon(Icons.restart_alt),
                label: const Text('New review'),
              ),
            ],
          );
        },
      ),
    );
  }
}
