import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_image.dart';
import '../../data/local/app_database.dart';
import '../../data/people_repository.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';

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
  var succeeded = true;
  try {
    await action();
  } catch (e) {
    succeeded = false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
  if (context.mounted) ref.read(peopleControllerProvider).changed();
  return succeeded;
}

Future<({String name, List<String> aliases})?> editPersonName(
  BuildContext context, {
  PersonView? person,
}) => showDialog<({String name, List<String> aliases})>(
  context: context,
  builder: (_) => _PersonNameDialog(person: person),
);

class _PersonNameDialog extends StatefulWidget {
  const _PersonNameDialog({this.person});
  final PersonView? person;
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
            .where((alias) => !_selfAliases.contains(alias.toLowerCase()))
            .join(', ') ??
        '',
  );
  static const _selfAliases = {'me', 'myself'};
  late bool _isMe =
      widget.person?.aliases.any(
        (alias) => _selfAliases.contains(alias.toLowerCase()),
      ) ??
      false;

  void _save() {
    if (!_form.currentState!.validate()) return;
    final nicknames = aliases.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (_isMe) nicknames.addAll(_selfAliases);
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
              contentPadding: EdgeInsets.zero,
              title: const Text('This is me'),
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
    final name = await editPersonName(context, person: unnamedPerson);
    if (name == null || !context.mounted) return;
    await peopleAction(context, ref, () async {
      if (unnamedPerson != null) {
        await ref
            .read(peopleRepositoryProvider)
            .editPerson(
              unnamedPerson.record.id,
              name: name.name,
              aliases: name.aliases,
            );
      } else {
        await ref
            .read(peopleRepositoryProvider)
            .createPerson(ids, name: name.name, aliases: name.aliases);
      }
    });
    return;
  }
  await peopleAction(
    context,
    ref,
    () => ref
        .read(peopleRepositoryProvider)
        .assign(
          ids,
          action.startsWith('@') ? null : action,
          dismiss: action == '@dismiss',
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
