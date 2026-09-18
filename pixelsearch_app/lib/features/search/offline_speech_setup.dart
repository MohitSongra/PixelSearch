import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offline_speech.dart';
import '../../state/providers.dart';

class OfflineSpeechSetup extends ConsumerStatefulWidget {
  const OfflineSpeechSetup({super.key, required this.language});
  final String language;
  @override
  ConsumerState<OfflineSpeechSetup> createState() => _OfflineSpeechSetupState();
}

class _OfflineSpeechSetupState extends ConsumerState<OfflineSpeechSetup> {
  final _client = const OfflineSpeechClient();
  late String _language = widget.language;
  OfflineSpeechSupport? _support;
  String? _status;
  bool _busy = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _status = null;
      _support = null;
    });
    try {
      final support = await _client.support(_language);
      if (mounted && generation == _generation) {
        setState(() => _support = support);
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _status = speechError(e));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $_language for offline speech?'),
        content: const Text(
          'Android will contact its speech provider to download language files. No photo or recording is sent. Android controls the download and may continue it after this screen closes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final status = await _client.download(
        _language,
        ref.read(onlinePolicyProvider),
        confirmed: true,
      );
      if (!mounted) return;
      await _refresh();
      if (mounted && !(_support?.ready ?? false)) {
        setState(
          () => _status = status == 'installed'
              ? 'Download finished. Refresh to check availability.'
              : 'Download requested. Refresh after Android finishes.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = speechError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    ++_generation;
    _client.cancel().catchError((Object _) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(onlinePolicyProvider);
    final support = _support;
    return AlertDialog(
      title: const Text('Offline speech'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy) const LinearProgressIndicator(),
              DropdownButton<String>(
                isExpanded: true,
                value: _language,
                items: [
                  for (final language in support?.choices ?? [_language])
                    DropdownMenuItem(value: language, child: Text(language)),
                ],
                onChanged: _busy
                    ? null
                    : (language) {
                        _language = language!;
                        _refresh();
                      },
              ),
              if (support != null) ...[
                Text(
                  support.ready
                      ? 'Ready on this phone'
                      : support.scheduled
                      ? 'Download pending'
                      : support.canDownload
                      ? 'Download available'
                      : 'Not offered by this phone',
                ),
                const SizedBox(height: 12),
                Text(
                  'Installed languages: ${support.installed.isEmpty ? "None reported" : support.installed.join(", ")}',
                ),
                if (!support.ready && policy.offline)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Offline only is on. Downloads are disabled.'),
                  ),
              ],
              if (_status != null) Text(_status!),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh language status',
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
        if (support?.canDownload ?? false)
          TextButton.icon(
            onPressed: _busy || !policy.loaded || policy.offline
                ? null
                : _download,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (support?.ready ?? false)
          FilledButton(
            onPressed: _busy ? null : () => Navigator.pop(context, _language),
            child: const Text('Use language'),
          ),
      ],
    );
  }
}
