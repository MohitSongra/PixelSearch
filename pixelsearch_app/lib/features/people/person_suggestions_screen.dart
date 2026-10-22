import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/people/face_suggestions.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';
import 'people_widgets.dart';

/// Unnamed faces ordered by similarity to faces the user confirmed for one
/// person. Ordering only: nothing is assigned until the user chooses Add, and
/// faces marked "Not (name)" are never suggested for that person again.
class PersonSuggestionsScreen extends ConsumerStatefulWidget {
  const PersonSuggestionsScreen({super.key, required this.personId});
  final String personId;
  @override
  ConsumerState<PersonSuggestionsScreen> createState() =>
      _PersonSuggestionsState();
}

class _PersonSuggestionsState extends ConsumerState<PersonSuggestionsScreen> {
  static const _page = 60;
  int _limit = _page;
  final _picked = <String>{};

  /// Last loaded page, shown while "Show more" loads so the grid (and the
  /// scroll position) stays in place.
  FaceSuggestionResult? _lastResult;

  Future<void> _decide({required bool add, required String name}) async {
    final ids = _picked.toList();
    final personId = widget.personId;
    final repo = ref.read(peopleRepositoryProvider);
    // Captured so Undo still works after this screen is closed.
    final controller = ref.read(peopleControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await peopleAction(
      context,
      ref,
      () => add
          ? repo.confirmSuggestions(personId, ids)
          : repo.rejectSuggestions(personId, ids),
    );
    if (!mounted) return;
    setState(_picked.clear);
    if (!saved) return;
    final faces = '${ids.length} face${ids.length == 1 ? '' : 's'}';
    // One Undo at a time: a newer decision replaces the older offer, so the
    // visible Undo always belongs to the last action.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(
            add
                ? 'Added $faces to $name.'
                : "$faces won't be suggested for $name again.",
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await repo.undoSuggestionDecisions(
                  personId,
                  confirmed: add ? ids : const [],
                  rejected: add ? const [] : ids,
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
              controller.changed();
            },
          ),
        ),
      );
  }

  void _openPhoto(PeopleFaceRecord face) {
    final photos = ref
        .read(photoLibraryProvider)
        .where((p) => p.id == face.photoId)
        .toList();
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    final person = snapshot?.people
        .where((p) => p.record.id == widget.personId)
        .firstOrNull;
    final suggestions = ref.watch(
      personSuggestionsProvider((personId: widget.personId, limit: _limit)),
    );
    final theme = Theme.of(context);
    if (snapshot == null || person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Similar faces')),
        body: Center(
          child: snapshot == null
              ? const CircularProgressIndicator()
              : const Text('This person is no longer available.'),
        ),
      );
    }
    final name = person.label;
    final faces = {for (final f in snapshot.faces) f.id: f};
    final references = person.faces
        .where(
          (f) =>
              f.assignment == 'manual' &&
              f.quality == 'ready' &&
              f.vector != null,
        )
        .toList();
    final tooSmall = snapshot.unassigned
        .where((f) => f.quality != 'ready' || f.vector == null)
        .length;
    final result = suggestions.valueOrNull ?? _lastResult;
    _lastResult = result;
    final items = result?.items ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Similar faces')),
      bottomNavigationBar: _picked.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  children: [
                    Text('${_picked.length} selected'),
                    OutlinedButton(
                      key: const ValueKey('suggestion-reject'),
                      onPressed: () => _decide(add: false, name: name),
                      child: Text(
                        'Not $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FilledButton(
                      key: const ValueKey('suggestion-confirm'),
                      onPressed: () => _decide(add: true, name: name),
                      child: Text(
                        'Add to $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.list(
              children: [
                if (references.isNotEmpty) ...[
                  Text(
                    'Confirmed faces of $name',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final face in references.take(4))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 64,
                                child: FaceImage(face: face),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'These unnamed faces look similar to faces you confirmed as '
                  '$name. Similar-looking people can appear here. This is not '
                  'recognition: nothing is added to $name until you choose Add.',
                  key: const ValueKey('suggestions-explanation'),
                ),
                if (snapshot.state.paused) ...[
                  const SizedBox(height: 8),
                  Text(
                    'People processing is paused (${snapshot.processed} of '
                    '${snapshot.total} photos). Only processed photos are compared.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (tooSmall > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$tooSmall unnamed faces are too small to compare. '
                    'Name them from New faces.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (items.isNotEmpty)
                  Text('Is this $name?', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          if (suggestions.isLoading && result == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (suggestions.hasError)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Suggestions are unavailable.')),
            )
          else if (result == null || result.references == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No clear face of $name yet. Suggestions need at least one '
                    'large, clear face you assigned to $name.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No more unnamed detailed faces to compare. Faces you '
                    'marked Not $name are not shown again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final face = faces[item.faceId];
                  final picked = _picked.contains(item.faceId);
                  return Semantics(
                    selected: picked,
                    label:
                        'Unnamed face ${i + 1}, ${picked ? 'selected' : 'not selected'}',
                    child: InkWell(
                      key: ValueKey('suggestion-${item.faceId}'),
                      onTap: () => setState(() {
                        if (!_picked.add(item.faceId)) {
                          _picked.remove(item.faceId);
                        }
                      }),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FaceImage(face: face),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Icon(
                              picked
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: picked
                                  ? Colors.lightGreenAccent
                                  : Colors.white,
                            ),
                          ),
                          if (face != null)
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: IconButton(
                                tooltip: 'Open photo',
                                iconSize: 20,
                                color: Colors.white,
                                icon: const Icon(Icons.open_in_full),
                                onPressed: () => _openPhoto(face),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${items.length} of ${result.eligible}',
                      ),
                    ),
                    if (result.eligible > items.length)
                      TextButton(
                        onPressed: () => setState(() => _limit += _page),
                        child: const Text('Show more'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
