import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/people/face_grouping.dart';
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
  bool _restored = false;
  String? _roundKey;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _freshValidation() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check 20 new pairs?'),
        content: const Text(
          'Your saved ratings will calibrate the next cutoff. '
          'The next test uses previously unreviewed photos. '
          'Automatic grouping stays off until that separate test passes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Prepare pairs'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    final saved = await peopleAction(context, ref, () async {
      await ref.read(peopleRepositoryProvider).prepareFreshValidation();
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (saved) _restored = false;
    });
    if (saved && _scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _results(
    FaceCalibration result,
    List<PeopleReviewRecord> pairs,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Review results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(result.reason),
              const SizedBox(height: 16),
              Text(
                'Calibration: ${result.calibrationTrueJoins} of ${result.calibrationSame} same-person pairs matched.',
              ),
              Text(
                'Separate test: ${result.validationTrueJoins} of ${result.validationSame} same-person pairs matched.',
              ),
              Text(
                'Incorrect test joins: ${result.validationFalseJoins} of ${result.validationDifferent} different-person pairs.',
              ),
              if (result.candidateThreshold != null)
                Text(
                  'Tested cosine cutoff: ${result.candidateThreshold!.toStringAsFixed(4)}',
                ),
              if (!result.passed) ...[
                const SizedBox(height: 12),
                const Text(
                  'Your ratings are saved. Manual naming remains available.',
                ),
              ],
              for (var i = 0; i < pairs.length; i++)
                if (result.falseJoinPairIds.contains(
                  '${pairs[i].leftFaceId}|${pairs[i].rightFaceId}',
                ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Inspect pair ${i + 1}'),
                    subtitle: Text(
                      'Rated Different people; cosine ${pairs[i].cosine.toStringAsFixed(4)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, i),
                  ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _at = selected);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

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
    final result = ref.watch(peopleCalibrationProvider).valueOrNull;
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
          if (!_restored || _roundKey != pairs.first.id) {
            final pending = pairs.indexWhere((p) => p.judgment == 'pending');
            _at = pending < 0 ? 0 : pending;
            _restored = true;
            _roundKey = pairs.first.id;
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
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text('$complete of ${pairs.length} reviewed'),
              LinearProgressIndicator(value: complete / pairs.length),
              if (complete == pairs.length && result != null) ...[
                const SizedBox(height: 12),
                Text(result.reason),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => _results(result, pairs),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Review results'),
                  ),
                ),
              ],
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
              if (complete == pairs.length &&
                  result != null &&
                  !result.passed &&
                  result.candidateThreshold != null)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _freshValidation,
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Check 20 new pairs'),
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
                              'Previous judgments stay archived. The new review needs different photos. Automatic assignment stays off until it passes.',
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
