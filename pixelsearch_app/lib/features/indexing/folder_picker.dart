import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../indexing/model/folder_selection.dart';
import '../../state/providers.dart';

/// Every foreground entry point confirms its scope before starting any AI work.
Future<bool> chooseFoldersAndIndex(BuildContext context, WidgetRef ref) async {
  if (ref.read(indexingControllerProvider).running) return false;
  final selection = await Navigator.of(context).push<FolderSelection>(
    MaterialPageRoute(builder: (_) => const FolderPickerScreen()),
  );
  if (selection == null || !context.mounted) return false;
  unawaited(
    ref.read(indexingControllerProvider.notifier).start(selection: selection),
  );
  return true;
}

class FolderPickerScreen extends ConsumerStatefulWidget {
  const FolderPickerScreen({super.key});

  @override
  ConsumerState<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends ConsumerState<FolderPickerScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _all = false;
  Set<String> _ids = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    try {
      final saved = await ref.read(indexingPreferencesProvider).load();
      if (!mounted) return;
      setState(() {
        _all = saved.allFolders;
        _ids = {...saved.folderIds};
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load saved folders.';
        });
      }
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final selection = FolderSelection(allFolders: _all, folderIds: _ids);
    try {
      await ref.read(indexingPreferencesProvider).save(selection);
      if (mounted) Navigator.of(context).pop(selection);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save folders. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(indexFoldersProvider);
    final folders = catalog.valueOrNull?.folders ?? const <GalleryFolder>[];
    final available = folders.map((f) => f.id).toSet();
    final missing = _ids.difference(available);
    final folderCount = _all ? folders.length : _ids.length;
    final count = folders
        .where((f) => _all || _ids.contains(f.id))
        .fold<int>(0, (n, f) => n + f.count);
    final ready =
        !_loading &&
        !_saving &&
        !catalog.isLoading &&
        !catalog.hasError &&
        folders.isNotEmpty &&
        (_all || (_ids.isNotEmpty && missing.isEmpty));

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose folders')),
        body: SafeArea(
          child: Column(
            children: [
              if (_error != null)
                ListTile(
                  title: Text(_error!),
                  trailing: IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.refresh),
                    onPressed: _loading ? _loadSelection : null,
                  ),
                ),
              if (_loading && _error == null) const LinearProgressIndicator(),
              Expanded(
                child: catalog.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_off_outlined, size: 40),
                          const SizedBox(height: 12),
                          Text('$error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.invalidate(indexFoldersProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) => folders.isEmpty
                      ? const Center(
                          child: Text('No accessible photo folders.'),
                        )
                      : ListView(
                          children: [
                            if (data.limited)
                              const ListTile(
                                leading: Icon(Icons.lock_outline),
                                title: Text('Limited photo access'),
                                subtitle: Text(
                                  'Only photos allowed by Android are available.',
                                ),
                              ),
                            SwitchListTile(
                              secondary: const Icon(
                                Icons.photo_library_outlined,
                              ),
                              title: const Text('All folders'),
                              value: _all,
                              onChanged: _loading || _saving
                                  ? null
                                  : (v) => setState(() {
                                      _all = v;
                                    }),
                            ),
                            const Divider(height: 1),
                            for (final folder in folders)
                              CheckboxListTile(
                                key: ValueKey(folder.id),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                secondary: const Icon(Icons.folder_outlined),
                                title: Text(folder.name),
                                subtitle: Text(
                                  folder.relativePath == null
                                      ? '${folder.count} photos'
                                      : '${folder.count} photos\n${folder.relativePath}',
                                ),
                                isThreeLine: folder.relativePath != null,
                                value: _all || _ids.contains(folder.id),
                                onChanged: _loading || _saving
                                    ? null
                                    : (v) => setState(() {
                                        if (_all) {
                                          _ids = {...available};
                                          _all = false;
                                        }
                                        if (v == true) {
                                          _ids.add(folder.id);
                                        } else {
                                          _ids.remove(folder.id);
                                        }
                                      }),
                              ),
                            if (!_all)
                              for (final id in missing)
                                CheckboxListTile(
                                  value: true,
                                  title: const Text('Unavailable folder'),
                                  subtitle: Text(id),
                                  onChanged: _saving
                                      ? null
                                      : (_) => setState(() {
                                          _ids.remove(id);
                                        }),
                                ),
                          ],
                        ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$count photos in $folderCount ${folderCount == 1 ? 'folder' : 'folders'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: ready ? _confirm : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        _saving ? 'Saving...' : 'Index selected folders',
                      ),
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
