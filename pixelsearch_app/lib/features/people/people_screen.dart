import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/people_repository.dart';
import '../../data/people/face_model_check.dart';
import '../../data/local/processing_lease.dart';
import '../../domain/gallery/indexed_gallery.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../search/indexed_gallery_view.dart';
import 'people_review_screen.dart';
import 'people_widgets.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key, this.showNewFaces = false});
  final bool showNewFaces;
  @override
  ConsumerState<PeopleScreen> createState() => _PeopleState();
}

class _PeopleState extends ConsumerState<PeopleScreen> {
  String _sort = 'photos';
  bool _hidden = false;
  late bool _unassigned = widget.showNewFaces;
  String _nameFilter = '';
  final _nameController = TextEditingController();
  bool _checkingModel = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkModel() async {
    final controller = ref.read(peopleControllerProvider);
    final paused = (await ref.read(peopleRepositoryProvider).state()).paused;
    if (!mounted) return;
    setState(() => _checkingModel = true);
    ProcessingLease? lease;
    try {
      await controller.suspend();
      lease = await ProcessingLease.acquire(
        ref.read(appDatabaseProvider),
        'face-model-check',
      );
      if (lease == null) throw StateError('Photo processing is busy.');
      final report = await checkFaceModel();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            report['passed'] == true
                ? 'Face model check passed'
                : 'Face model check failed',
          ),
          content: SingleChildScrollView(
            child: Text(
              (report['cases'] as List)
                  .map(
                    (row) =>
                        '${row['fixture']}: ${(row['cosine'] as double).toStringAsFixed(8)}',
                  )
                  .join('\n'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face model check could not complete.')),
        );
      }
    } finally {
      await lease?.release();
      if (mounted) setState(() => _checkingModel = false);
      if (!paused) unawaited(controller.kick());
    }
  }

  Future<void> _enable() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable offline People?'),
        content: const Text(
          'PixelSearch will process faces in your indexed photos. Face descriptors, names and groups stay on this device. Automatic assignment requires a reviewed validation sample.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      unawaited(
        peopleAction(
          context,
          ref,
          () => ref.read(peopleControllerProvider).enable(),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable and delete People data?'),
        content: const Text(
          'Names, face crops, descriptors, corrections and reviews will be removed. Original photos, the gallery index and semantic embeddings will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable and delete'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await peopleAction(
        context,
        ref,
        () => ref.read(peopleControllerProvider).disableAndDelete(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(peopleControllerProvider);
    final data = ref.watch(peopleSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            tooltip: 'Face grouping review',
            icon: const Icon(Icons.compare),
            onPressed: data.valueOrNull?.state.enabled == true
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PeopleReviewScreen(),
                    ),
                  )
                : null,
          ),
          PopupMenuButton<String>(
            tooltip: 'People options',
            onSelected: (value) {
              if (value == 'delete') {
                _delete();
              } else if (value == 'model') {
                _checkModel();
              } else if (value == 'hidden') {
                setState(() => _hidden = !_hidden);
              } else {
                setState(() => _sort = value);
              }
            },
            itemBuilder: (_) => [
              if (data.valueOrNull?.state.enabled == true)
                PopupMenuItem(
                  value: 'model',
                  enabled: !_checkingModel,
                  child: const Text('Check face model'),
                ),
              const PopupMenuItem(
                value: 'photos',
                child: Text('Sort by photo count'),
              ),
              const PopupMenuItem(value: 'name', child: Text('Sort by name')),
              const PopupMenuItem(
                value: 'latest',
                child: Text('Sort by latest photo'),
              ),
              CheckedPopupMenuItem(
                value: 'hidden',
                checked: _hidden,
                child: const Text('Show hidden people'),
              ),
              if (data.valueOrNull?.state.enabled == true)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Disable and delete People data'),
                ),
            ],
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, st) =>
            const Center(child: Text('People is unavailable on this device.')),
        data: (snapshot) {
          if (_checkingModel) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.state.enabled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 56),
                    const SizedBox(height: 16),
                    const Text('People grouping is off'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _enable,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Enable offline People'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!controller.hasPermission) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Photo access is required.'),
                  TextButton(
                    onPressed: controller.kick,
                    child: const Text('Check access'),
                  ),
                ],
              ),
            );
          }
          final people = snapshot.people
              .where(
                (p) =>
                    (_hidden || !p.record.hidden) &&
                    p.record.name.trim().isNotEmpty &&
                    [
                      p.label,
                      ...p.aliases,
                    ].any((name) => name.toLowerCase().contains(_nameFilter)),
              )
              .toList();
          people.sort((a, b) {
            final order = switch (_sort) {
              'name' => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              'latest' => b.latest.compareTo(a.latest),
              _ => b.photoCount.compareTo(a.photoCount),
            };
            return order != 0 ? order : a.record.id.compareTo(b.record.id);
          });
          final faces = snapshot.unassigned;
          final unnamedPeople = snapshot.unnamedPeople;
          return LayoutBuilder(
            builder: (context, box) {
              final large = MediaQuery.textScalerOf(context).scale(14) > 21;
              final columns = box.maxWidth < 500
                  ? 2
                  : box.maxWidth < 900
                  ? 3
                  : 5;
              final count = _unassigned
                  ? faces.length + unnamedPeople.length
                  : people.length;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${snapshot.processed} of ${snapshot.total} photos processed\n${snapshot.faces.length} faces | ${snapshot.people.length} groups',
                                ),
                              ),
                              IconButton(
                                tooltip: controller.running
                                    ? 'Pause people processing'
                                    : 'Continue people processing',
                                onPressed: () => unawaited(
                                  peopleAction(
                                    context,
                                    ref,
                                    controller.running
                                        ? controller.pause
                                        : controller.resume,
                                  ),
                                ),
                                icon: Icon(
                                  controller.running
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.running)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  value: controller.progress.total == 0
                                      ? null
                                      : controller.progress.checked /
                                            controller.progress.total,
                                ),
                                Text(
                                  '${controller.progress.checked}/${controller.progress.total} | ${controller.progress.phase}',
                                ),
                              ],
                            ),
                          ),
                        if (controller.error != null)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(controller.error!),
                          ),
                        if (snapshot.inaccessible + snapshot.failed > 0)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '${snapshot.inaccessible} unavailable | ${snapshot.failed} could not be processed',
                            ),
                          ),
                        if (snapshot.state.threshold == null)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.fact_check_outlined),
                            title: const Text(
                              'Automatic assignment awaits validation',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const PeopleReviewScreen(),
                              ),
                            ),
                          ),
                        if (!_unassigned && snapshot.facesToName > 0)
                          ListTile(
                            key: const ValueKey('new-faces-notice'),
                            leading: const Icon(
                              Icons.person_add_alt_1_outlined,
                            ),
                            title: const Text('New faces found'),
                            subtitle: Text(
                              '${snapshot.facesToName} faces to name',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => setState(() => _unassigned = true),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.people_outline),
                                label: Text('Named people'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.person_search_outlined),
                                label: Text('New faces'),
                              ),
                            ],
                            selected: {_unassigned},
                            onSelectionChanged: (values) =>
                                setState(() => _unassigned = values.single),
                          ),
                        ),
                        if (_unassigned)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${snapshot.facesToName} faces to name',
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: TextField(
                              key: const ValueKey('people-name-filter'),
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Find a person',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _nameFilter.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear person search',
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() {
                                          _nameController.clear();
                                          _nameFilter = '';
                                        }),
                                      ),
                              ),
                              onChanged: (value) => setState(
                                () => _nameFilter = value.trim().toLowerCase(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (count == 0)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _unassigned
                              ? 'No new faces to name.'
                              : _nameFilter.isNotEmpty
                              ? 'No matching people.'
                              : 'No named people yet.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: large ? 0.65 : 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final person = !_unassigned
                              ? people[i]
                              : i < unnamedPeople.length
                              ? unnamedPeople[i]
                              : null;
                          final face = person != null
                              ? person.cover
                              : faces[i - unnamedPeople.length];
                          return InkWell(
                            key: ValueKey(
                              _unassigned
                                  ? 'new-face-${face!.id}'
                                  : 'named-person-${person!.record.id}',
                            ),
                            onTap: () => _unassigned
                                ? assignFaces(
                                    context,
                                    ref,
                                    person?.faces.map((f) => f.id).toList() ??
                                        [face!.id],
                                    unnamedPerson: person,
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PersonScreen(
                                        personId: person!.record.id,
                                      ),
                                    ),
                                  ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FaceImage(face: face),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height:
                                      MediaQuery.textScalerOf(
                                        context,
                                      ).scale(14) *
                                      2.8,
                                  child: Text(
                                    _unassigned ? 'Add a name' : person!.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  person == null
                                      ? 'New face found'
                                      : '${person.photoCount} ${person.photoCount == 1 ? 'photo' : 'photos'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        }, childCount: count),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({super.key, required this.personId});
  final String personId;
  @override
  ConsumerState<PersonScreen> createState() => _PersonState();
}

class _PersonState extends ConsumerState<PersonScreen> {
  bool _facesMode = false;
  final _selected = <String>{};
  Future<void> _merge(PersonView person, List<PersonView> people) async {
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: [
          for (final p in people.where((p) => p.record.id != person.record.id))
            ListTile(
              leading: SizedBox(width: 48, child: FaceImage(face: p.cover)),
              title: Text(p.label),
              subtitle: Text('${p.photoCount} photos'),
              onTap: () => Navigator.pop(context, p.record.id),
            ),
        ],
      ),
    );
    if (target == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge these people?'),
        content: const Text(
          'Only merge groups you know are the same person. You can move individual faces afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await peopleAction(
      context,
      ref,
      () => ref.read(peopleRepositoryProvider).merge(person.record.id, target),
    );
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    final person = snapshot?.people
        .where((p) => p.record.id == widget.personId)
        .firstOrNull;
    final photos = ref
        .watch(photoLibraryProvider)
        .where((p) => person?.faces.any((f) => f.photoId == p.id) == true)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          person?.label ?? 'Person',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (person != null) ...[
            IconButton(
              tooltip: 'Edit name',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await editPersonName(context, person: person);
                if (result != null && context.mounted) {
                  await peopleAction(
                    context,
                    ref,
                    () => ref
                        .read(peopleRepositoryProvider)
                        .editPerson(
                          person.record.id,
                          name: result.name,
                          aliases: result.aliases,
                        ),
                  );
                }
              },
            ),
            PopupMenuButton<String>(
              tooltip: 'Person options',
              onSelected: (value) {
                if (value == 'merge') {
                  _merge(person, snapshot!.people);
                }
                if (value == 'hide') {
                  peopleAction(
                    context,
                    ref,
                    () => ref
                        .read(peopleRepositoryProvider)
                        .editPerson(
                          person.record.id,
                          hidden: !person.record.hidden,
                        ),
                  );
                }
                if (value == 'cover') {
                  setState(() {
                    _facesMode = true;
                    _selected.clear();
                  });
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'merge',
                  child: Text('Merge with another person'),
                ),
                PopupMenuItem(
                  value: 'hide',
                  child: Text(
                    person.record.hidden ? 'Unhide person' : 'Hide person',
                  ),
                ),
                const PopupMenuItem(
                  value: 'cover',
                  child: Text('Choose cover face'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: person == null
          ? const Center(child: Text('This person is no longer available.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Photos'),
                        icon: Icon(Icons.photo_library_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Faces'),
                        icon: Icon(Icons.face_outlined),
                      ),
                    ],
                    selected: {_facesMode},
                    onSelectionChanged: (v) => setState(() {
                      _facesMode = v.single;
                      _selected.clear();
                    }),
                  ),
                ),
                if (_facesMode && _selected.isNotEmpty)
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(child: Text('${_selected.length} selected')),
                      IconButton(
                        tooltip: 'Move selected faces',
                        icon: const Icon(Icons.drive_file_move_outline),
                        onPressed: () async {
                          await assignFaces(context, ref, _selected.toList());
                          if (mounted) setState(_selected.clear);
                        },
                      ),
                      IconButton(
                        tooltip: 'Use as cover',
                        icon: const Icon(Icons.account_circle_outlined),
                        onPressed: _selected.length != 1
                            ? null
                            : () async {
                                await peopleAction(
                                  context,
                                  ref,
                                  () => ref
                                      .read(peopleRepositoryProvider)
                                      .editPerson(
                                        person.record.id,
                                        coverFaceId: _selected.single,
                                      ),
                                );
                                if (mounted) setState(_selected.clear);
                              },
                      ),
                    ],
                  ),
                Expanded(
                  child: !_facesMode
                      ? IndexedGalleryView(gallery: IndexedGallery(photos))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: person.faces.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 140,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, i) {
                            final face = person.faces[i];
                            return InkWell(
                              onTap: () => setState(() {
                                if (!_selected.add(face.id)) {
                                  _selected.remove(face.id);
                                }
                              }),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FaceImage(face: face),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Icon(
                                      _selected.contains(face.id)
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: _selected.contains(face.id)
                                          ? Colors.lightGreenAccent
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
