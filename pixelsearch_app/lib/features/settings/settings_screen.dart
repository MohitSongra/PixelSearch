import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/indexing_status.dart';
import '../indexing/folder_picker.dart';
import '../search/search_diagnostics_screen.dart';
import 'online_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final total = ref.watch(photoLibraryProvider).length;
    final indexing = ref.watch(indexingControllerProvider);
    final controller = ref.read(indexingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _header(context, 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),
          const Divider(),
          _header(context, 'Privacy'),
          const OnlineSettings(),
          const Divider(),
          _header(context, 'Library'),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('$total photo${total == 1 ? '' : 's'} indexed'),
            subtitle: Text(
              total == 0 ? 'Nothing indexed yet' : 'Searchable on this device',
            ),
          ),
          if (indexingSupported)
            ListTile(
              leading: Icon(
                indexing.running ? Icons.hourglass_top : Icons.refresh_outlined,
              ),
              title: Text(
                indexing.running
                    ? 'Indexing…'
                    : total == 0
                    ? 'Index my photos'
                    : 'Continue indexing',
              ),
              subtitle: const Text(
                'Labels and embeddings are computed on-device. Only new and '
                'changed photos are processed.',
              ),
              isThreeLine: true,
              trailing: indexing.running
                  ? TextButton(
                      onPressed: controller.cancel,
                      child: const Text('Cancel'),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: indexing.running
                  ? null
                  : () => chooseFoldersAndIndex(context, ref),
            ),
          if (statusLine(indexing) != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: IndexingStatus(state: indexing),
            ),
          const Divider(),
          _header(context, 'About'),
          if (indexingSupported)
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Search diagnostics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SearchDiagnosticsScreen(),
                ),
              ),
            ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('PixelSearch'),
            subtitle: Text(
              'Privacy-first semantic photo search.\nOn-device indexing (ML Kit + CLIP) and semantic search.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.tag),
            title: Text('Version'),
            subtitle: Text('0.1.0 · Flutter demo'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1,
      ),
    ),
  );
}
