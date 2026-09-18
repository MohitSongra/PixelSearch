import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../data/local/app_database.dart';
import '../../data/enhancements/caption_image.dart';
import '../../data/enhancements/enhancement_client.dart';
import '../../data/enhancements/online_policy.dart';
import '../../models/photo.dart';
import '../../state/providers.dart';

class CaptionScreen extends ConsumerStatefulWidget {
  const CaptionScreen({super.key, required this.photo});
  final Photo photo;
  @override
  ConsumerState<CaptionScreen> createState() => _CaptionState();
}

class _CaptionState extends ConsumerState<CaptionScreen> {
  final _text = TextEditingController();
  SavedCaption? _saved;
  String _base = '', _model = 'manual', _style = 'factual';
  String? _error;
  int _revision = 0, _generatedRevision = 0;
  bool _busy = true, _edited = false;
  RequestCancellation? _cancel;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final row = await (db.select(
        db.photoRows,
      )..where((p) => p.id.equals(widget.photo.id))).getSingleOrNull();
      final caption = await (db.select(
        db.savedCaptions,
      )..where((c) => c.photoId.equals(widget.photo.id))).getSingleOrNull();
      if (!mounted) return;
      _revision = row?.mtimeMs ?? 0;
      _generatedRevision = caption?.revision ?? _revision;
      _saved = caption;
      _base = caption?.baseCaption ?? '';
      _text.text = caption?.editedCaption ?? widget.photo.caption;
      _model = caption?.model ?? 'manual';
      _style = caption?.style ?? 'factual';
      _edited = caption?.manuallyEdited ?? false;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    _cancel = RequestCancellation();
    try {
      await action();
    } catch (e) {
      if (mounted) _error = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    final exists = await (db.select(
      db.photoRows,
    )..where((p) => p.id.equals(widget.photo.id))).getSingleOrNull();
    if (exists == null) throw StateError('Photo is no longer indexed.');
    await db
        .into(db.savedCaptions)
        .insertOnConflictUpdate(
          SavedCaptionsCompanion.insert(
            photoId: widget.photo.id,
            revision: _generatedRevision,
            baseCaption: _base,
            editedCaption: _text.text.trim(),
            model: _model,
            style: Value(_style),
            manuallyEdited: Value(_edited),
            provider: Value(_model == 'manual' ? 'user' : 'groq'),
            generatedMs:
                _saved?.generatedMs ?? DateTime.now().millisecondsSinceEpoch,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption saved on this device')),
      );
    }
  }

  Future<void> _generate() => _run(() async {
    if (!ref.read(onlinePolicyProvider).allows(OnlineFeature.captions)) {
      throw StateError('Enable online captions in Settings.');
    }
    final asset = await AssetEntity.fromId(widget.photo.id);
    final bytes = await asset?.originBytes;
    if (bytes == null) throw StateError('Original photo is unavailable.');
    final upload = await compute(prepareCaptionImage, bytes);
    if (!mounted || _cancel!.cancelled) return;
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send this photo to Groq?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 230,
                child: Image.memory(upload, fit: BoxFit.contain),
              ),
              const Text(
                'Only this resized copy is sent through your backend. Photo metadata is removed. The response replaces the current draft, not your saved caption.',
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
            child: const Text('Send photo'),
          ),
        ],
      ),
    );
    if (consent != true || !mounted || _cancel!.cancelled) return;
    final response = await ref
        .read(enhancementClientProvider)
        .request(
          OnlineFeature.captions,
          'caption',
          bytes: upload,
          cancellation: _cancel,
        );
    final caption = response['caption'], model = response['model'];
    if (caption is! String ||
        caption.isEmpty ||
        caption.length > 4000 ||
        model is! String) {
      throw const FormatException('Invalid caption response.');
    }
    if (!mounted || _cancel!.cancelled) return;
    _base = caption;
    _text.text = caption;
    _model = model;
    _style = 'factual';
    _generatedRevision = _revision;
    _saved = null;
    _edited = false;
  });
  Future<void> _rewrite(String style) => _run(() async {
    final response = await ref
        .read(enhancementClientProvider)
        .request(
          OnlineFeature.captions,
          'rewrite',
          json: {'text': _text.text, 'style': style},
          cancellation: _cancel,
        );
    final text = response['text'];
    if (text is! String || text.isEmpty || text.length > 4000) {
      throw const FormatException('Invalid rewrite response.');
    }
    if (!mounted || _cancel!.cancelled) return;
    _text.text = text;
    _style = style;
    _edited = false;
    _model = response['model'] as String? ?? _model;
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Caption'),
      actions: [
        IconButton(
          tooltip: 'Copy caption',
          icon: const Icon(Icons.copy),
          onPressed: () => Clipboard.setData(ClipboardData(text: _text.text)),
        ),
        IconButton(
          tooltip: 'Delete saved caption',
          icon: const Icon(Icons.delete_outline),
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final db = ref.read(appDatabaseProvider);
                  await (db.delete(
                    db.savedCaptions,
                  )..where((c) => c.photoId.equals(widget.photo.id))).go();
                  _text.clear();
                  _base = '';
                  _saved = null;
                  _model = 'manual';
                  _generatedRevision = _revision;
                }),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_generatedRevision != _revision)
          const Text('This caption was generated before the photo changed.'),
        if (_model != 'manual') Text('AI draft | $_model'),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        TextField(
          controller: _text,
          minLines: 4,
          maxLines: 12,
          maxLength: 4000,
          enabled: !_busy,
          onChanged: (_) => setState(() => _edited = true),
          decoration: const InputDecoration(labelText: 'Caption'),
        ),
        if (_base.isNotEmpty)
          ExpansionTile(
            title: const Text('Original AI description'),
            children: [Text(_base)],
          ),
        Wrap(
          spacing: 8,
          children: [
            for (final s in ['concise', 'social', 'formal'])
              OutlinedButton(
                onPressed: _busy || _text.text.trim().isEmpty
                    ? null
                    : () => _rewrite(s),
                child: Text(s),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _generate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate from photo'),
        ),
        TextButton.icon(
          onPressed: _busy ? null : () => _run(_save),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save caption'),
        ),
        if (_busy) ...[
          const LinearProgressIndicator(),
          TextButton(
            onPressed: () => _cancel?.cancel(),
            child: const Text('Cancel'),
          ),
        ],
      ],
    ),
  );
}
