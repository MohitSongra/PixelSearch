import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final privacy = ref.watch(privacyModeProvider);
    final total = ref.watch(photoLibraryProvider).length;
    final deviceLoaded = ref.watch(deviceLoadedProvider);
    final deviceSupported =
        ref.read(photoLibraryProvider.notifier).deviceSupported;

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
                    icon: Icon(Icons.brightness_auto)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),
          const Divider(),
          _header(context, 'Privacy'),
          SwitchListTile(
            title: const Text('Privacy mode'),
            subtitle: const Text(
                'Everything on-device. Cloud features (captions, assistant) are disabled.'),
            secondary: const Icon(Icons.shield_outlined),
            value: privacy,
            onChanged: (v) => ref.read(privacyModeProvider.notifier).state = v,
          ),
          const Divider(),
          _header(context, 'Library'),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('$total photos indexed'),
            subtitle: Text(deviceLoaded
                ? 'Sample set + your device photos'
                : 'Bundled sample set'),
          ),
          if (deviceSupported)
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('Add my device photos'),
              subtitle: const Text('Grant photo access and index them'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final added = await ref
                    .read(photoLibraryProvider.notifier)
                    .loadDevicePhotos();
                messenger.showSnackBar(SnackBar(
                  content: Text(added > 0
                      ? 'Added $added photos.'
                      : 'No photos added (permission denied or none found).'),
                ));
              },
            ),
          const Divider(),
          _header(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('PixelSearch (demo build)'),
            subtitle: Text(
                'Privacy-first semantic photo search.\nMilestones M0–M3 + mock search. CLIP indexing is next.'),
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
