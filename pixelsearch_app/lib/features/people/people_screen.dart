import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/people_repository.dart';
import '../../data/people/face_model_check.dart';
import '../../data/local/processing_lease.dart';
import '../../domain/gallery/indexed_gallery.dart';
import '../../domain/search/search_response.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../search/indexed_gallery_view.dart';
import 'people_review_screen.dart';
import 'people_widgets.dart';
import 'person_suggestions_screen.dart';
import 'same_person_screen.dart';

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
  bool _selecting = false;
  bool _showSmall = false;
  bool _grouping = false;
  final _pickedFaces = <String>{};

  void _endSelection() => setState(() {
    _selecting = false;
    _pickedFaces.clear();
  });

  Future<void> _nameSelected() async {
    final repo = ref.read(peopleRepositoryProvider);
    await assignFaces(context, ref, _pickedFaces.toList());
    if (!mounted) return;
    // Keep the selection if the sheet was cancelled or the save failed.
    final open = {for (final f in (await repo.load()).unassigned) f.id};
    if (!mounted) return;
    setState(() => _pickedFaces.retainWhere(open.contains));
    if (_pickedFaces.isEmpty) _endSelection();
  }

  Future<void> _dismissSelected() async {
    final repo = ref.read(peopleRepositoryProvider);
    final controller = ref.read(peopleControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Only faces that are still unnamed: dismissing an assigned face would
    // also record "not this person".
    final open = {for (final f in (await repo.load()).unassigned) f.id};
    final ids = _pickedFaces.where(open.contains).toList();
    if (!mounted) return;
    if (ids.isEmpty) {
      _endSelection();
      return;
    }
    final saved = await peopleAction(
      context,
      ref,
      () => repo.assign(ids, null, dismiss: true),
    );
    if (!mounted) return;
    _endSelection();
    if (!saved) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(
            '${ids.length} face${ids.length == 1 ? '' : 's'} marked Not a face.',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Restore only faces still dismissed and unassigned.
              final restore = [
                for (final f in (await repo.load()).dismissedFaces)
                  if (ids.contains(f.id) && f.personId == null) f.id,
              ];
              try {
                if (restore.isNotEmpty) await repo.assign(restore, null);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
              controller.changed();
            },
          ),
        ),
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Runs the validated automatic grouping once, at the user's request, while
  /// processing stays paused. Only faces large enough for a descriptor take
  /// part; mistakes are fixed by moving or removing faces.
  Future<void> _groupNow() async {
    if (_grouping) return;
    final calibration = await ref.read(peopleCalibrationProvider.future);
    if (!mounted) return;
    if (!calibration.passed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grouping needs a passed review first.')),
      );
      return;
    }
    final same = calibration.validationSame;
    final different = calibration.validationDifferent;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group similar faces?'),
        content: Text(
          'Faces that look alike are grouped automatically, using the cutoff '
          'from your review: in its test, $same same-person pairs were '
          'checked and all $different different-person pairs stayed apart. '
          'That is a small sample, not an accuracy guarantee. Faces can also be '
          'added to people you named; check them under "Same person?". Faces '
          'too small for a face model are not compared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Group faces'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _grouping = true);
    final repo = ref.read(peopleRepositoryProvider);
    final controller = ref.read(peopleControllerProvider);
    final database = ref.read(appDatabaseProvider);
    final paused = (await repo.state()).paused;
    final before = await repo.load();
    var grouped = 0;
    if (!mounted) return;
    final saved = await peopleAction(context, ref, () async {
      // Like the model check: stop any running pass and hold the lease so no
      // other grouping or processing writes at the same time.
      await controller.suspend();
      final lease = await ProcessingLease.acquire(database, 'people-group');
      if (lease == null) throw StateError('Photo processing is busy.');
      try {
        grouped = await repo.groupNow();
      } finally {
        await lease.release();
      }
    });
    if (!paused) unawaited(controller.kick());
    if (!mounted) return;
    setState(() => _grouping = false);
    if (!saved) return;
    final after = await repo.load();
    if (!mounted) return;
    int automaticInNamed(PeopleSnapshot s) => s.people
        .where((p) => p.record.name.trim().isNotEmpty)
        .fold(
          0,
          (n, p) =>
              n + p.faces.where((f) => f.assignment == 'automatic').length,
        );
    final intoNamed = automaticInNamed(after) - automaticInNamed(before);
    final newGroups = after.unnamedPeople.length - before.unnamedPeople.length;
    String faces(int n) => '$n face${n == 1 ? '' : 's'}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          grouped == 0
              ? 'No faces could be grouped right now.'
              : [
                  if (intoNamed > 0)
                    'Added ${faces(intoNamed)} to people you named '
                        '(check them in Same person?)',
                  if (newGroups > 0)
                    'made $newGroups new group${newGroups == 1 ? '' : 's'} '
                        'in New faces',
                  if (intoNamed <= 0 && newGroups <= 0)
                    'grouped ${faces(grouped)}',
                ].join('; '),
        ),
      ),
    );
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
    // Load the review result with the screen so the menu knows at once
    // whether grouping is allowed.
    ref.watch(peopleCalibrationProvider);
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
              } else if (value == 'group') {
                _groupNow();
              } else if (value == 'dismissed') {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const DismissedFacesScreen(),
                  ),
                );
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
              if (data.valueOrNull?.state.enabled == true)
                PopupMenuItem(
                  value: 'group',
                  enabled:
                      !_grouping &&
                      ref
                              .watch(peopleCalibrationProvider)
                              .valueOrNull
                              ?.passed ==
                          true,
                  child: const Text('Group similar faces'),
                ),
              if (data.valueOrNull?.state.enabled == true)
                const PopupMenuItem(
                  value: 'dismissed',
                  child: Text('Faces marked Not a face'),
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
          // Computed once per build and reused below.
          final faces = snapshot.namingQueue(includeSmall: _showSmall);
          final questions =
              ref.watch(samePersonQuestionsProvider).valueOrNull?.length ?? 0;
          final allGroups = snapshot.namingGroups(includeSmall: true);
          final allFaces = _showSmall
              ? faces
              : snapshot.namingQueue(includeSmall: true);
          // Largest look-alike groups first: usually the people seen most.
          final unnamedPeople = snapshot.namingGroups(includeSmall: _showSmall)
            ..sort((a, b) {
              final bySize = b.faces.length.compareTo(a.faces.length);
              return bySize != 0 ? bySize : a.record.id.compareTo(b.record.id);
            });
          final hiddenSmall =
              allFaces.length -
              snapshot.namingQueue().length +
              allGroups.length -
              snapshot.namingGroups().length;
          final toName = faces.length + unnamedPeople.length;
          // A face named or dismissed elsewhere leaves the selection.
          final open = {for (final f in faces) f.id};
          _pickedFaces.retainWhere(open.contains);
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
                                  '${snapshot.processed} of ${snapshot.total} photos processed${snapshot.state.paused ? ' | Paused' : ''}\n${snapshot.faces.length} faces | ${snapshot.people.length} groups',
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
                        if (questions > 0)
                          ListTile(
                            key: const ValueKey('same-person-entry'),
                            leading: const Icon(Icons.compare_outlined),
                            title: const Text('Same person?'),
                            subtitle: Text(
                              '$questions quick question${questions == 1 ? '' : 's'} '
                              'to make grouping more accurate',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const SamePersonScreen(),
                              ),
                            ),
                          ),
                        if (!_unassigned && snapshot.toName() > 0)
                          ListTile(
                            key: const ValueKey('new-faces-notice'),
                            leading: const Icon(
                              Icons.person_add_alt_1_outlined,
                            ),
                            title: const Text('New faces found'),
                            subtitle: Text('${snapshot.toName()} to name'),
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
                        if (_unassigned && _selecting)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Stop selecting',
                                  icon: const Icon(Icons.close),
                                  onPressed: _endSelection,
                                ),
                                Text('${_pickedFaces.length} selected'),
                                TextButton.icon(
                                  key: const ValueKey(
                                    'new-faces-name-selected',
                                  ),
                                  onPressed: _pickedFaces.isEmpty
                                      ? null
                                      : _nameSelected,
                                  icon: const Icon(Icons.person_add_outlined),
                                  label: const Text('Name selected faces'),
                                ),
                                TextButton.icon(
                                  key: const ValueKey(
                                    'new-faces-dismiss-selected',
                                  ),
                                  onPressed: _pickedFaces.isEmpty
                                      ? null
                                      : _dismissSelected,
                                  icon: const Icon(Icons.block),
                                  label: const Text('Not a face'),
                                ),
                              ],
                            ),
                          )
                        else if (_unassigned)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            // Wraps on narrow screens and with large text.
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text('$toName to name'),
                                if (hiddenSmall > 0 || _showSmall)
                                  TextButton(
                                    key: const ValueKey('new-faces-small'),
                                    onPressed: () => setState(
                                      () => _showSmall = !_showSmall,
                                    ),
                                    child: Text(
                                      _showSmall
                                          ? 'Hide small faces'
                                          : 'Show small faces ($hiddenSmall)',
                                    ),
                                  ),
                                if (faces.isNotEmpty)
                                  TextButton(
                                    key: const ValueKey('new-faces-select'),
                                    onPressed: () =>
                                        setState(() => _selecting = true),
                                    child: const Text('Select'),
                                  ),
                              ],
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
                          // Individual new faces can be multi-selected;
                          // unnamed groups are named as a whole.
                          final selectable = _unassigned && person == null;
                          final picked =
                              selectable && _pickedFaces.contains(face!.id);
                          void toggle() => setState(() {
                            _selecting = true;
                            if (!_pickedFaces.add(face!.id)) {
                              _pickedFaces.remove(face.id);
                            }
                          });
                          return Semantics(
                            selected: _selecting && selectable ? picked : null,
                            label: _selecting && selectable
                                ? 'New face, ${picked ? 'selected' : 'not selected'}'
                                : null,
                            child: InkWell(
                              key: ValueKey(
                                _unassigned
                                    ? 'new-face-${face!.id}'
                                    : 'named-person-${person!.record.id}',
                              ),
                              onLongPress: selectable ? toggle : null,
                              onTap: () => _unassigned && _selecting
                                  ? (selectable ? toggle() : null)
                                  : _unassigned
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
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: FaceImage(face: face),
                                          ),
                                          if (_selecting && selectable)
                                            Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Icon(
                                                picked
                                                    ? Icons.check_circle
                                                    : Icons
                                                          .radio_button_unchecked,
                                                color: picked
                                                    ? Colors.lightGreenAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                        ],
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
                                      _unassigned
                                          ? 'Add a name'
                                          : person!.label,
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
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
    if (!saved || !mounted) return;
    forgetPersonInSearch(ref, person.record.id);
    Navigator.pop(context);
  }

  Future<void> _deletePerson(PersonView person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${person.label}?'),
        content: Text(
          'The name and nicknames are removed. Its ${person.faces.length} '
          'faces go back to New faces. Photos are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete person'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await peopleAction(
      context,
      ref,
      () => ref.read(peopleRepositoryProvider).deletePerson(person.record.id),
    );
    if (!saved || !mounted) return;
    forgetPersonInSearch(ref, person.record.id);
    Navigator.pop(context);
  }

  /// Searches this person's photos (works for hidden people too, because the
  /// user chose them explicitly).
  void _searchPhotos(PersonView person) {
    ref.invalidate(peopleNameChoicesProvider);
    ref.invalidate(peopleIgnoredNamesProvider);
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchFiltersProvider.notifier).state = SearchFilters(
      personIds: {person.record.id},
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              key: const ValueKey('person-search-photos'),
              tooltip: 'Search photos of ${person.label}',
              icon: const Icon(Icons.image_search_outlined),
              onPressed: () => _searchPhotos(person),
            ),
            IconButton(
              tooltip: 'Edit name',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await editPersonName(
                  context,
                  person: person,
                  currentSelf: snapshot?.self,
                );
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
                if (value == 'delete') _deletePerson(person);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'merge',
                  child: Text('Merge with another person'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete person'),
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
                _SuggestionsEntry(person: person),
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

/// Entry to the confirm-only similar-faces review for one person.
class _SuggestionsEntry extends ConsumerWidget {
  const _SuggestionsEntry({required this.person});
  final PersonView person;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final references = person.faces
        .where(
          (f) =>
              f.assignment == 'manual' &&
              f.quality == 'ready' &&
              f.vector != null,
        )
        .length;
    final result = references == 0
        ? null
        : ref
              .watch(
                personSuggestionsProvider((
                  personId: person.record.id,
                  limit: 1,
                )),
              )
              .valueOrNull;
    final subtitle = references == 0
        ? 'Needs a clear, large face of ${person.label} first.'
        : result != null && result.eligible == 0
        ? 'No unnamed detailed faces to compare right now.'
        : 'Unnamed faces ordered by similarity to ${person.label}. '
              'Nothing is added until you confirm.';
    return ListTile(
      key: const ValueKey('person-suggestions-entry'),
      dense: true,
      visualDensity: VisualDensity.compact,
      enabled: references > 0,
      leading: const Icon(Icons.face_retouching_natural_outlined),
      title: Text(
        result == null || result.eligible == 0
            ? 'Review similar faces'
            : 'Review similar faces (${result.eligible})',
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PersonSuggestionsScreen(personId: person.record.id),
        ),
      ),
    );
  }
}

/// Faces the user marked "Not a face"; restoring returns them to New faces.
class DismissedFacesScreen extends ConsumerStatefulWidget {
  const DismissedFacesScreen({super.key});
  @override
  ConsumerState<DismissedFacesScreen> createState() => _DismissedState();
}

class _DismissedState extends ConsumerState<DismissedFacesScreen> {
  final _picked = <String>{};
  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    final faces = snapshot?.dismissedFaces ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Not a face')),
      bottomNavigationBar: _picked.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text('${_picked.length} selected')),
                    FilledButton(
                      key: const ValueKey('dismissed-restore'),
                      onPressed: () async {
                        final ids = _picked.toList();
                        await peopleAction(
                          context,
                          ref,
                          () => ref
                              .read(peopleRepositoryProvider)
                              .assign(ids, null),
                        );
                        if (mounted) setState(_picked.clear);
                      },
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              ),
            ),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Faces you marked Not a face are hidden from New faces. '
                    'Restore any that are real faces.',
                  ),
                ),
                Expanded(
                  child: faces.isEmpty
                      ? const Center(child: Text('No faces marked Not a face.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: faces.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 140,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, i) {
                            final face = faces[i];
                            final picked = _picked.contains(face.id);
                            return Semantics(
                              selected: picked,
                              label:
                                  'Face marked Not a face, ${picked ? 'selected' : 'not selected'}',
                              child: InkWell(
                                key: ValueKey('dismissed-${face.id}'),
                                onTap: () => setState(() {
                                  if (!_picked.add(face.id)) {
                                    _picked.remove(face.id);
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
                                        picked
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: picked
                                            ? Colors.lightGreenAccent
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
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

/// A deleted or merged person must not linger in the search filters, where
/// it would read as "No photos of Unnamed person".
void forgetPersonInSearch(WidgetRef ref, String personId) {
  final filters = ref.read(searchFiltersProvider);
  if (!{
    ...filters.personIds,
    ...filters.anyPersonIds,
    ...filters.excludedPersonIds,
  }.contains(personId)) {
    return;
  }
  ref.read(searchFiltersProvider.notifier).state = filters.withPeople(
    required: {...filters.personIds}..remove(personId),
    any: {...filters.anyPersonIds}..remove(personId),
    excluded: {...filters.excludedPersonIds}..remove(personId),
  );
}
