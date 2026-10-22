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
    final policy = ref.watch(onlinePolicyProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Centre')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your photos.\nYour choice.',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Search stays on your device. You decide when optional features can go online.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: scheme.onPrimaryContainer,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !policy.loaded
                              ? 'Loading privacy settings…'
                              : policy.offline
                              ? 'Offline only is on'
                              : 'Online features are optional',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !policy.loaded
                              ? 'Online features stay unavailable until your settings load.'
                              : policy.offline
                              ? 'All online enhancements are paused. Your local photo search keeps working.'
                              : 'Only the features you allow below can connect. You can switch them off at any time.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _header(context, 'Your permissions'),
          const OnlineSettings(),
          _header(context, 'Your library'),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('$total photo${total == 1 ? '' : 's'} indexed'),
            subtitle: Text(
              total == 0
                  ? 'Add folders to start searching'
                  : 'Searchable on this device',
            ),
          ),
          if (indexingSupported)
            ListTile(
              leading: Icon(
                indexing.running
                    ? Icons.hourglass_top
                    : Icons.add_photo_alternate_outlined,
              ),
              title: Text(
                indexing.running
                    ? 'Indexing…'
                    : total == 0
                    ? 'Index my photos'
                    : 'Continue indexing',
              ),
              subtitle: const Text(
                'Choose folders. Only new and changed photos are processed on this device.',
              ),
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
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: IndexingStatus(state: indexing),
            ),
          _header(context, 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: LayoutBuilder(
              builder: (context, box) => SegmentedButton<ThemeMode>(
                direction:
                    box.maxWidth < 330 &&
                        MediaQuery.textScalerOf(context).scale(14) > 20
                    ? Axis.vertical
                    : Axis.horizontal,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).state = s.first,
              ),
            ),
          ),
          _header(context, 'About PixelSearch'),
          if (indexingSupported)
            ListTile(
              leading: const Icon(Icons.manage_search_outlined),
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
            subtitle: Text('On-device AI photo search\nVersion 0.1.0'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
