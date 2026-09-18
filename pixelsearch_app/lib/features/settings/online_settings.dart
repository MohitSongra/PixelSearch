import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/enhancements/online_policy.dart';
import '../../state/providers.dart';

class OnlineSettings extends ConsumerWidget {
  const OnlineSettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(onlinePolicyProvider);
    Future<void> update(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Offline only'),
          value: policy.offline,
          secondary: const Icon(Icons.shield_outlined),
          onChanged: !policy.loaded
              ? null
              : (v) => update(() => policy.update(offline: v)),
        ),
        for (final f in OnlineFeature.values)
          SwitchListTile(
            title: Text(switch (f) {
              OnlineFeature.captions => 'Online captions',
              OnlineFeature.assistant => 'Search assistant',
              OnlineFeature.speech => 'Online transcription',
              OnlineFeature.maps => 'Online map tiles',
            }),
            value: policy.enabled.contains(f),
            onChanged: policy.offline
                ? null
                : (v) async {
                    if (v) {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Allow online processing?'),
                          content: Text(switch (f) {
                            OnlineFeature.captions =>
                              'Only a photo you approve is sent to your backend and Groq. Rewrites send caption text. Provider processing occurs off-device.',
                            OnlineFeature.assistant =>
                              'Your query, conversation context and active filters are sent to your backend and Groq. No photos or gallery inventory are sent.',
                            OnlineFeature.speech =>
                              'Recordings you approve are sent to your backend and Groq for transcription.',
                            OnlineFeature.maps =>
                              'OpenStreetMap receives your IP address and requested map areas. No photos are sent.',
                          }),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Allow'),
                            ),
                          ],
                        ),
                      );
                      if (yes != true) return;
                    }
                    await update(() => policy.update(feature: f, allow: v));
                  },
          ),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: const Text('Enhancement backend'),
          subtitle: Text(
            policy.baseUrl.isEmpty ? 'Not configured' : policy.baseUrl,
          ),
          onTap: () async {
            var url = policy.baseUrl, token = '';
            final save = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Backend connection'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: url,
                        onChanged: (v) => url = v,
                        decoration: const InputDecoration(
                          labelText: 'HTTPS URL',
                        ),
                      ),
                      TextField(
                        onChanged: (v) => token = v,
                        obscureText: true,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Per-install access token',
                          helperText: 'Blank keeps the saved token',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
            if (save == true) {
              await update(() async {
                await policy.update(baseUrl: url);
                if (token.isNotEmpty) {
                  await const FlutterSecureStorage().write(
                    key: 'backend_install_token',
                    value: token.trim(),
                  );
                }
              });
            }
          },
        ),
      ],
    );
  }
}
