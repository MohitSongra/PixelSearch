import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_image.dart';
import '../../data/local/app_database.dart';
import '../../data/people_repository.dart';
import '../../domain/people/people_query.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';
import 'person_suggestions_screen.dart';

class FaceImage extends StatelessWidget {
  const FaceImage({super.key, required this.face});
  final PeopleFaceRecord? face;
  @override
  Widget build(BuildContext context) {
    final path = face?.cropPath;
    final provider = path == null ? null : fileImage(path);
    return AspectRatio(
      aspectRatio: 1,
      child: provider == null
          ? const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.person_outline),
            )
          : Image(
              image: provider,
              fit: BoxFit.cover,
              errorBuilder: (_, e, st) => const ColoredBox(
                color: Colors.black12,
                child: Icon(Icons.person_outline),
              ),
            ),
    );
  }
}

Future<bool> peopleAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  // Read before the await: the screen may be closed while the save runs, and
  // People must still refresh.
  final controller = ref.read(peopleControllerProvider);
  var succeeded = true;
  try {
    await action();
  } catch (e) {
    succeeded = false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
  controller.changed();
  return succeeded;
}

/// [currentSelf] is the person marked "This is me" now, if any; the dialog
/// says that saving moves it here (it belongs to one person only).
Future<({String name, List<String> aliases})?> editPersonName(
  BuildContext context, {
  PersonView? person,
  PersonView? currentSelf,
}) => showDialog<({String name, List<String> aliases})>(
  context: context,
  builder: (_) => _PersonNameDialog(person: person, currentSelf: currentSelf),
);

class _PersonNameDialog extends StatefulWidget {
  const _PersonNameDialog({this.person, this.currentSelf});
  final PersonView? person;
  final PersonView? currentSelf;
  @override
  State<_PersonNameDialog> createState() => _PersonNameDialogState();
}

class _PersonNameDialogState extends State<_PersonNameDialog> {
  final _form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.person?.record.name ?? '',
  );
  late final aliases = TextEditingController(
    text:
        widget.person?.aliases
            .where((alias) => !isSelfAlias(alias))
            .join(', ') ??
        '',
  );
  late bool _isMe = widget.person?.aliases.any(isSelfAlias) ?? false;
  late final String? _selfElsewhere =
      widget.currentSelf == null ||
          widget.currentSelf!.record.id == widget.person?.record.id
      ? null
      : widget.currentSelf!.label;

  void _save() {
    if (!_form.currentState!.validate()) return;
    final nicknames = aliases.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !isSelfAlias(s))
        .toSet();
    if (_isMe) nicknames.addAll(selfAliases);
    Navigator.pop(context, (
      name: name.text.trim(),
      aliases: nicknames.toList(),
    ));
  }

  @override
  void dispose() {
    name.dispose();
    aliases.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.person == null ? 'Name this person' : 'Edit name'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a name.'
                  : null,
            ),
            TextField(
              controller: aliases,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Nicknames'),
            ),
            CheckboxListTile(
              key: const ValueKey('person-is-me'),
              contentPadding: EdgeInsets.zero,
              title: const Text('This is me'),
              subtitle: _selfElsewhere == null
                  ? null
                  : Text(
                      _isMe
                          ? 'Currently $_selfElsewhere. Saving moves "me" here.'
                          : 'Currently $_selfElsewhere.',
                    ),
              value: _isMe,
              onChanged: (value) => setState(() => _isMe = value ?? false),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

Future<void> assignFaces(
  BuildContext context,
  WidgetRef ref,
  List<String> ids, {
  PersonView? unnamedPerson,
}) async {
  if (ids.isEmpty) return;
  final snapshot = await ref.read(peopleRepositoryProvider).load();
  if (!context.mounted) return;
  final faces = snapshot.faces.where((f) => ids.contains(f.id)).toList();
  if (faces.isEmpty) return;
  var filter = '';
  final namedPeople = snapshot.people
      .where(
        (p) =>
            p.record.id != unnamedPerson?.record.id &&
            p.record.name.trim().isNotEmpty,
      )
      .toList();
  bool matchesName(PersonView person) => [
    person.label,
    ...person.aliases,
  ].any((name) => name.toLowerCase().contains(filter));
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom) *
                0.7,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    faces.length == 1
                        ? 'Who is this?'
                        : 'Name ${faces.length} faces',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (faces.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'All ${faces.length} faces will be named as one person.',
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    key: const ValueKey('assign-person-filter'),
                    decoration: const InputDecoration(
                      labelText: 'Find an existing person',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setSheetState(
                      () => filter = value.trim().toLowerCase(),
                    ),
                  ),
                ),
                if (filter.isEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final face in faces.take(6))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 80,
                              child: FaceImage(face: face),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (faces.length == 1)
                    ListTile(
                      leading: const Icon(Icons.photo_outlined),
                      title: const Text('Open photo'),
                      onTap: () => Navigator.pop(context, '@photo'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: Text(
                      unnamedPerson == null ? 'New person' : 'Add a name',
                    ),
                    onTap: () => Navigator.pop(context, '@new'),
                  ),
                  if (faces.any((face) => face.personId != null))
                    ListTile(
                      leading: const Icon(Icons.person_remove_outlined),
                      title: const Text('Remove assignment'),
                      onTap: () => Navigator.pop(context, '@remove'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Not a face'),
                    onTap: () => Navigator.pop(context, '@dismiss'),
                  ),
                  const Divider(),
                ],
                if (filter.isNotEmpty && !namedPeople.any(matchesName))
                  const ListTile(title: Text('No matching people.')),
                for (final person in namedPeople.where(matchesName))
                  ListTile(
                    key: ValueKey('assign-person-${person.record.id}'),
                    leading: SizedBox(
                      width: 44,
                      child: ClipOval(child: FaceImage(face: person.cover)),
                    ),
                    title: Text(person.label),
                    subtitle: Text(
                      '${person.photoCount} photos${person.record.hidden ? ' | Hidden' : ''}',
                    ),
                    onTap: () => Navigator.pop(context, person.record.id),
                  ),
                if (filter.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: Text(
                      unnamedPerson == null ? 'New person' : 'Add a name',
                    ),
                    onTap: () => Navigator.pop(context, '@new'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == '@photo') {
    final photos = ref
        .read(photoLibraryProvider)
        .where((p) => p.id == faces.single.photoId)
        .toList();
    if (photos.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: 0),
        ),
      );
    }
    return;
  }
  if (action == '@new') {
    final name = await editPersonName(
      context,
      person: unnamedPerson,
      currentSelf: snapshot.self,
    );
    if (name == null || !context.mounted) return;
    String? personId = unnamedPerson?.record.id;
    final saved = await peopleAction(context, ref, () async {
      if (unnamedPerson != null) {
        final repo = ref.read(peopleRepositoryProvider);
        await repo.editPerson(
          unnamedPerson.record.id,
          name: name.name,
          aliases: name.aliases,
        );
        // The first face shown in the sheet is the one the user named: it
        // becomes confirmed, so the group's other automatic faces can be
        // checked against it ("Is this <name>?").
        final shown = faces.first;
        if (shown.assignment == 'automatic') {
          await repo.assign([shown.id], unnamedPerson.record.id);
        }
      } else {
        personId = await ref
            .read(peopleRepositoryProvider)
            .createPerson(ids, name: name.name, aliases: name.aliases);
      }
    });
    if (saved && personId != null && context.mounted) {
      _offerSimilar(context, faces, personId!, name.name);
    }
    return;
  }
  final target = action.startsWith('@') ? null : action;
  final saved = await peopleAction(
    context,
    ref,
    () => ref
        .read(peopleRepositoryProvider)
        .assign(ids, target, dismiss: action == '@dismiss'),
  );
  if (saved && target != null && context.mounted) {
    final person = namedPeople.where((p) => p.record.id == target).firstOrNull;
    _offerSimilar(context, faces, target, person?.label ?? 'this person');
  }
}

/// After the user names a detailed face, offer the confirm-only similar-faces
/// review. Small faces have no descriptor, so there is nothing to compare.
void _offerSimilar(
  BuildContext context,
  List<PeopleFaceRecord> faces,
  String personId,
  String name,
) {
  if (!faces.any((f) => f.quality == 'ready' && f.vector != null)) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // Do not hold later messages (errors, Undo offers) behind this one.
        persist: false,
        content: Text('Saved $name.'),
        action: SnackBarAction(
          label: 'Review similar',
          onPressed: () {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PersonSuggestionsScreen(personId: personId),
              ),
            );
          },
        ),
      ),
    );
}

class PhotoPeopleSection extends ConsumerWidget {
  const PhotoPeopleSection({super.key, required this.photoId});
  final String photoId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    if (snapshot == null || !snapshot.state.enabled) {
      return const SizedBox.shrink();
    }
    final faces = snapshot.faces
        .where((f) => f.photoId == photoId && !f.dismissed)
        .toList();
    if (faces.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('People'),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: faces.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final face = faces[i];
              final person = snapshot.people
                  .where((p) => p.record.id == face.personId)
                  .firstOrNull;
              return SizedBox(
                width: 76,
                child: InkWell(
                  onTap: () => assignFaces(context, ref, [face.id]),
                  child: Column(
                    children: [
                      SizedBox(height: 68, child: FaceImage(face: face)),
                      Text(
                        person?.label ?? 'Add name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Picks named, visible people for the search People filter. Returns the
/// chosen ids and whether any one of them (instead of all) must appear.
/// Hidden people are not offered, so a hidden selection is dropped here.
Future<({Set<String> ids, bool any})?> choosePeople(
  BuildContext context,
  List<PersonView> people, {
  Set<String> selected = const {},
  bool any = false,
}) {
  final choices =
      people
          .where((p) => p.record.name.trim().isNotEmpty && !p.record.hidden)
          .toList()
        ..sort((a, b) => b.photoCount.compareTo(a.photoCount));
  final picked = {
    for (final p in choices)
      if (selected.contains(p.record.id)) p.record.id,
  };
  var matchAny = any;
  var filter = '';
  return showModalBottomSheet<({Set<String> ids, bool any})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final visible = choices
            .where(
              (p) => [
                p.label,
                ...p.aliases.where((a) => !isSelfAlias(a)),
              ].any((name) => name.toLowerCase().contains(filter)),
            )
            .toList();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Everything but the buttons scrolls, so the sheet fits
                  // small screens with the keyboard open and large text.
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'Search by people',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Find a person',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) => setSheetState(
                              () => filter = value.trim().toLowerCase(),
                            ),
                          ),
                        ),
                        if (picked.length > 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('All of them'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Any of them'),
                                ),
                              ],
                              selected: {matchAny},
                              onSelectionChanged: (value) =>
                                  setSheetState(() => matchAny = value.single),
                            ),
                          ),
                        if (choices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Name people in People to search by them.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final person in visible)
                          CheckboxListTile(
                            key: ValueKey('people-filter-${person.record.id}'),
                            value: picked.contains(person.record.id),
                            onChanged: (value) => setSheetState(() {
                              if (value == true) {
                                picked.add(person.record.id);
                              } else {
                                picked.remove(person.record.id);
                              }
                            }),
                            secondary: SizedBox(
                              width: 44,
                              child: ClipOval(
                                child: FaceImage(face: person.cover),
                              ),
                            ),
                            title: Text(
                              person.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('${person.photoCount} photos'),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, (
                            ids: <String>{},
                            any: false,
                          )),
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        FilledButton(
                          key: const ValueKey('people-filter-done'),
                          onPressed: () => Navigator.pop(context, (
                            ids: picked,
                            any: matchAny && picked.length > 1,
                          )),
                          child: const Text('Show photos'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
