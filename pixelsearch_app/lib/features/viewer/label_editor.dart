import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo.dart';
import '../../state/providers.dart';

class LabelEditor extends ConsumerStatefulWidget {
  const LabelEditor({super.key, required this.photo});
  final Photo photo;

  @override
  ConsumerState<LabelEditor> createState() => _LabelEditorState();
}

class _LabelEditorState extends ConsumerState<LabelEditor> {
  late final List<String> _labels = [...widget.photo.labels];
  final _input = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = _input.text.trim().toLowerCase();
    if (value.isEmpty) return;
    setState(() {
      if (!_labels.contains(value)) _labels.add(value);
      _input.clear();
    });
  }

  Future<void> _save({bool reset = false}) async {
    _add();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final store = ref.read(userPreferencesProvider);
      if (reset) {
        await store.resetLabels(widget.photo);
      } else {
        await store.correctLabels(widget.photo, _labels);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save labels. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Edit labels'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final label in _labels)
                    InputChip(
                      label: Text(label),
                      deleteButtonTooltipMessage: 'Remove $label',
                      onDeleted: _saving
                          ? null
                          : () => setState(() => _labels.remove(label)),
                    ),
                ],
              ),
              TextField(
                controller: _input,
                enabled: !_saving,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: 'Label',
                  suffixIcon: IconButton(
                    tooltip: 'Add label',
                    onPressed: _saving ? null : _add,
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
              if (ref
                  .read(userPreferencesProvider)
                  .hasLabelCorrection(widget.photo))
                TextButton.icon(
                  onPressed: _saving ? null : () => _save(reset: true),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore automatic labels'),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
  );
}
