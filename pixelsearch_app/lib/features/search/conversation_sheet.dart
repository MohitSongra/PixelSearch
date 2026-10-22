import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../data/enhancements/enhancement_client.dart';
import '../../data/enhancements/online_policy.dart';
import '../../data/offline_speech.dart';
import '../../data/people_repository.dart';
import '../../domain/search/assistant_result.dart';
import '../../domain/people/people_query.dart';
import '../../state/people_providers.dart';
import '../../domain/search/query_text.dart';
import '../../domain/search/search_response.dart';
import '../../state/providers.dart';
import 'offline_speech_setup.dart';

final conversationHistoryProvider = StateProvider<List<SearchRequest>>(
  (ref) => [],
);

abstract interface class VoiceRecorder {
  Future<void> start(String path);
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class _DeviceVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();
  @override
  Future<void> start(String path) => _recorder.start(
    const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 16000,
      numChannels: 1,
    ),
    path: path,
  );
  @override
  Future<String?> stop() => _recorder.stop();
  @override
  Future<void> cancel() => _recorder.cancel();
  @override
  Future<void> dispose() => _recorder.dispose();
}

// Only device boundaries are replaceable; tests exercise the real sheet workflow.
class VoiceSearchServices {
  const VoiceSearchServices();
  static int _recordingId = 0;
  OfflineSpeechClient get speech => const OfflineSpeechClient();
  Future<PermissionStatus> requestPermission() =>
      Permission.microphone.request();
  VoiceRecorder createRecorder() => _DeviceVoiceRecorder();
  Future<String> recordingPath() async =>
      '${(await getTemporaryDirectory()).path}/pixelsearch_voice_'
      '${DateTime.now().microsecondsSinceEpoch}_${++_recordingId}.m4a';
  Future<Uint8List> readRecording(String path) => File(path).readAsBytes();
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

enum _VoicePhase {
  idle,
  permission,
  starting,
  listening,
  processing,
  recording,
  stopping,
  confirming,
  transcribing,
  refining,
}

class _VoiceCancelled implements Exception {}

class _VoiceOperation {
  _VoiceOperation({this.feature});
  final OnlineFeature? feature;
  final cancellation = RequestCancellation();
  final cancelled = Completer<void>();
  VoiceRecorder? recorder;
  String? path;
  bool native = false;
  Timer? timer;
  DialogRoute<bool>? dialog;
  Future<void>? cleanup;

  void cancel() {
    timer?.cancel();
    if (!cancelled.isCompleted) {
      cancellation.cancel();
      cancelled.complete();
    }
  }

  Future<T> wait<T>(Future<T> task, Duration timeout) => Future.any<T>([
    task,
    cancelled.future.then<T>((_) => throw _VoiceCancelled()),
  ]).timeout(timeout);
}

class ConversationSheet extends ConsumerStatefulWidget {
  const ConversationSheet({
    super.key,
    this.startListening = false,
    this.services = const VoiceSearchServices(),
    this.operationTimeout = const Duration(seconds: 110),
  });
  final bool startListening;
  final VoiceSearchServices services;
  final Duration operationTimeout;
  @override
  ConsumerState<ConversationSheet> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<ConversationSheet>
    with WidgetsBindingObserver {
  OfflineSpeechClient get _speech => widget.services.speech;
  final _message = TextEditingController();
  final _english = TextEditingController();
  String _language = 'English';
  String? _error;
  _VoicePhase _phase = _VoicePhase.idle;
  bool get _recording => _phase == _VoicePhase.recording;
  bool get _busy => _operation != null && !_recording;
  SearchRequest? _proposed;
  _VoiceOperation? _operation;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  Completer<void>? _resumed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    if (widget.startListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _listen();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      _resumed?.complete();
      _resumed = null;
      return;
    }
    _resumed ??= Completer<void>();
    // A permission dialog loses focus without putting the app in the background.
    if (state == AppLifecycleState.inactive &&
        _phase == _VoicePhase.permission) {
      return;
    }
    if (_operation != null) {
      _cancelAll();
      if (mounted) setState(() {});
    }
  }

  bool _active(_VoiceOperation op) =>
      mounted && identical(_operation, op) && !op.cancellation.cancelled;

  void _setPhase(_VoiceOperation op, _VoicePhase phase) {
    if (_active(op)) setState(() => _phase = phase);
  }

  Future<void> _run(
    Future<void> Function(_VoiceOperation op) action, {
    OnlineFeature? feature,
    _VoicePhase phase = _VoicePhase.permission,
  }) async {
    if (_operation != null) return;
    final op = _VoiceOperation(feature: feature);
    setState(() {
      _operation = op;
      _phase = phase;
      _error = null;
      _proposed = null;
      _english.clear();
    });
    await _execute(op, () => action(op));
  }

  Future<void> _execute(
    _VoiceOperation op,
    Future<void> Function() action,
  ) async {
    try {
      await op.wait(action(), widget.operationTimeout);
    } catch (e) {
      if (_active(op) && e is! _VoiceCancelled) _error = speechError(e);
    } finally {
      if (_active(op) && !_recording) {
        _cancelAll();
        setState(() {});
      } else if (!_active(op)) {
        unawaited(_cleanup(op));
      }
    }
  }

  Future<bool> _permission(_VoiceOperation op) async {
    final status = await widget.services.requestPermission();
    if (!_active(op)) return false;
    if (status.isPermanentlyDenied) {
      throw StateError(
        'Microphone access is blocked. Enable it in Android app settings.',
      );
    }
    if (!status.isGranted) {
      throw StateError('Microphone access was not granted.');
    }
    if (_lifecycle != AppLifecycleState.resumed) {
      _resumed ??= Completer<void>();
      await op.wait(_resumed!.future, const Duration(seconds: 10));
    }
    _setPhase(op, _VoicePhase.starting);
    return _active(op);
  }

  void _acceptTranscript(_VoiceOperation op, Object? text) {
    if (!_active(op)) return;
    if (text is! String || text.trim().isEmpty || text.length > 4000) {
      throw const FormatException(
        'No usable transcript was returned. Please try again.',
      );
    }
    _proposed = null;
    _english.clear();
    _message.text = text.trim();
  }

  Future<void> _listen() => _run((op) async {
    if (!await _permission(op)) return;
    final preferences = ref.read(userPreferencesProvider);
    await preferences.load();
    if (!_active(op)) return;
    _setPhase(op, _VoicePhase.starting);
    op.native = true;
    final text = await _speech.recognize(
      preferences.offlineSpeechLocale(_language),
      onState: (state) => _setPhase(
        op,
        state == 'listening' ? _VoicePhase.listening : _VoicePhase.processing,
      ),
    );
    _acceptTranscript(op, text);
  });

  Future<void> _stopListening() async {
    final op = _operation;
    if (op == null || _phase != _VoicePhase.listening) return;
    _setPhase(op, _VoicePhase.processing);
    try {
      await _speech.stop();
    } catch (e) {
      if (_active(op)) {
        _error = speechError(e);
        _cancelAll();
        setState(() {});
      }
    }
  }

  Future<void> _setupSpeech() async {
    try {
      final preferences = ref.read(userPreferencesProvider);
      await preferences.load();
      if (!mounted) return;
      final category = _language;
      final language = await showDialog<String>(
        context: context,
        builder: (_) => OfflineSpeechSetup(
          language: preferences.offlineSpeechLocale(category),
        ),
      );
      if (language != null && mounted) {
        await preferences.saveOfflineSpeechLocale(category, language);
        if (mounted) setState(() => _error = null);
      }
    } catch (e) {
      if (mounted) setState(() => _error = speechError(e));
    }
  }

  Future<void> _record() async {
    if (!ref.read(onlinePolicyProvider).allows(OnlineFeature.speech)) {
      setState(() => _error = 'Enable online transcription in Settings first.');
      return;
    }
    await _run((op) async {
      if (!await _permission(op)) return;
      final path = await widget.services.recordingPath();
      if (!_active(op)) return;
      op.path = path;
      final recorder = op.recorder = widget.services.createRecorder();
      _setPhase(op, _VoicePhase.starting);
      try {
        await recorder.start(path);
      } finally {
        // A plugin may finish starting after cancellation or its deadline.
        if (!_active(op)) unawaited(_cleanup(op, late: true));
      }
      if (!_active(op)) return;
      _setPhase(op, _VoicePhase.recording);
      op.timer = Timer(const Duration(seconds: 30), () {
        if (_active(op)) _stopRecording();
      });
    }, feature: OnlineFeature.speech);
  }

  Future<void> _stopRecording() async {
    final op = _operation;
    if (op == null || !_recording) return;
    op.timer?.cancel();
    _setPhase(op, _VoicePhase.stopping);
    await _execute(op, () async {
      String? path;
      try {
        path = await op.recorder!.stop();
      } finally {
        if (!_active(op)) unawaited(_cleanup(op, late: true));
      }
      if (!mounted || !_active(op)) return;
      if (path == null || path != op.path) {
        throw StateError('The recording could not be saved. Please try again.');
      }
      _setPhase(op, _VoicePhase.confirming);
      final route = op.dialog = DialogRoute<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transcribe this recording online?'),
          content: const Text(
            'This recording will be sent through your backend to Groq. The temporary audio is deleted after this request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send recording'),
            ),
          ],
        ),
      );
      final send = await Navigator.of(context, rootNavigator: true).push(route);
      op.dialog = null;
      if (send != true || !_active(op)) return;
      _setPhase(op, _VoicePhase.transcribing);
      final bytes = await widget.services.readRecording(path);
      if (!_active(op)) return;
      if (bytes.isEmpty) {
        throw StateError('The recording is empty. Please try again.');
      }
      final response = await ref
          .read(enhancementClientProvider)
          .request(
            OnlineFeature.speech,
            'transcribe',
            bytes: bytes,
            filename: 'speech.m4a',
            cancellation: op.cancellation,
          );
      _acceptTranscript(op, response['text']);
    });
  }

  Future<void> _refine() => _run(
    (op) async {
      if (_message.text.length > 2000) {
        throw StateError(
          'Shorten the transcript to 2000 characters before translating.',
        );
      }
      final filters = ref.read(searchFiltersProvider);
      final people = await ref.read(peopleRepositoryProvider).load();
      if (!_active(op)) return;
      // Hidden people are still private: the guard checks every saved name.
      final directory = peopleDirectory(people, includeHidden: true);
      final currentQuery = ref.read(searchQueryProvider);
      final references = [
        resolvePeopleQuery(_message.text, directory, filters: filters),
        resolvePeopleQuery(currentQuery, directory, filters: filters),
      ];
      if (filters.hasPeople ||
          references.any(
            (q) => q.hasPeople || q.needsChoice || q.mentions.isNotEmpty,
          )) {
        throw StateError('Named people searches stay on this device. Use Search locally with the editable English query.');
      }
      final data = await ref
          .read(enhancementClientProvider)
          .request(
            OnlineFeature.assistant,
            'assistant',
            cancellation: op.cancellation,
            json: {
              'message': _message.text,
              'query': ref.read(searchQueryProvider),
              'language': _language,
              'today': DateTime.now().toIso8601String().substring(0, 10),
              'filters': {
                ...filters.toJson(includePeople: false),
                if (filters.from != null)
                  'from': filters.from!.toIso8601String().substring(0, 10),
                if (filters.until != null)
                  'until': filters.until!.toIso8601String().substring(0, 10),
              },
            },
          );
      if (!_active(op)) return;
      _proposed = parseAssistantResult(data, ref.read(photoLibraryProvider));
      _english.text = _proposed!.query;
    },
    feature: OnlineFeature.assistant,
    phase: _VoicePhase.refining,
  );
  void _apply(SearchRequest request) {
    final history = ref.read(conversationHistoryProvider);
    ref.read(conversationHistoryProvider.notifier).state = [
      ...history,
      SearchRequest(
        ref.read(searchQueryProvider),
        filters: ref.read(searchFiltersProvider),
      ),
    ].takeLast(10);
    ref.read(searchFiltersProvider.notifier).state = request.filters;
    ref.read(searchQueryProvider.notifier).state = request.query;
    Navigator.pop(context);
  }

  void _cancelAll() {
    final op = _operation;
    _operation = null;
    _phase = _VoicePhase.idle;
    if (op == null) return;
    op.cancel();
    if (op.native) unawaited(_speech.cancel().catchError((Object _) {}));
    final dialog = op.dialog;
    if (dialog != null) {
      scheduleMicrotask(() {
        if (dialog.isActive) dialog.navigator?.removeRoute(dialog);
      });
    }
    unawaited(_cleanup(op));
  }

  Future<void> _cleanup(_VoiceOperation op, {bool late = false}) {
    Future<void> ignore(Future<void> Function() action) async {
      try {
        await action().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Cleanup must not revive a cancelled UI operation or leak async errors.
      }
    }

    Future<void> release() async {
      final recorder = op.recorder;
      if (recorder != null) {
        await ignore(recorder.cancel);
        await ignore(recorder.dispose);
      }
      final path = op.path;
      if (path != null) {
        await ignore(() => widget.services.deleteRecording(path));
      }
    }

    return late ? release() : op.cleanup ??= release();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAll();
    _message.dispose();
    _english.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onlinePolicyProvider, (_, policy) {
      final feature = _operation?.feature;
      if (feature != null && !policy.allows(feature)) {
        _cancelAll();
        if (mounted) setState(() {});
      }
    });
    final history = ref.watch(conversationHistoryProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search conversation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Undo last refinement',
                    icon: const Icon(Icons.undo),
                    onPressed: history.isEmpty || _busy || _recording
                        ? null
                        : () {
                            final previous = history.last;
                            ref
                                .read(conversationHistoryProvider.notifier)
                                .state = history
                                .take(history.length - 1)
                                .toList();
                            ref.read(searchQueryProvider.notifier).state =
                                previous.query;
                            ref.read(searchFiltersProvider.notifier).state =
                                previous.filters;
                          },
                  ),
                  IconButton(
                    tooltip: 'New conversation',
                    icon: const Icon(Icons.add_comment_outlined),
                    onPressed: () {
                      _cancelAll();
                      _message.clear();
                      _english.clear();
                      _proposed = null;
                      ref.read(conversationHistoryProvider.notifier).state = [];
                      ref.read(searchQueryProvider.notifier).state = '';
                      ref.read(searchFiltersProvider.notifier).state =
                          const SearchFilters();
                      setState(() {});
                    },
                  ),
                ],
              ),
              Text('Current: ${ref.watch(searchQueryProvider)}'),
              DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: [
                  for (final l in ['English', 'Hindi', 'Hinglish'])
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: _busy || _recording
                    ? null
                    : (l) => setState(() {
                        _language = l!;
                        _error = null;
                        _proposed = null;
                        _english.clear();
                      }),
              ),
              TextField(
                controller: _message,
                maxLength: 2000,
                minLines: 2,
                maxLines: 4,
                enabled: !_busy && !_recording,
                onChanged: (_) => setState(() {
                  _proposed = null;
                  _english.clear();
                }),
                decoration: const InputDecoration(
                  labelText: 'Query or follow-up',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: _phase == _VoicePhase.listening
                        ? 'Stop listening'
                        : 'Listen on-device',
                    icon: Icon(
                      _phase == _VoicePhase.listening ? Icons.stop : Icons.mic,
                    ),
                    onPressed: _phase == _VoicePhase.listening
                        ? _stopListening
                        : _busy || _recording
                        ? null
                        : _listen,
                  ),
                  IconButton(
                    tooltip: 'Offline speech setup',
                    icon: const Icon(Icons.settings_voice),
                    onPressed: _busy || _recording ? null : _setupSpeech,
                  ),
                  TextButton.icon(
                    icon: Icon(_recording ? Icons.stop : Icons.cloud_outlined),
                    label: Text(
                      _recording
                          ? 'Stop recording'
                          : 'Record for online transcription',
                    ),
                    onPressed: _busy
                        ? null
                        : _recording
                        ? _stopRecording
                        : _record,
                  ),
                  if (_language == 'English')
                    TextButton(
                      onPressed:
                          _busy || _recording || _message.text.trim().isEmpty
                          ? null
                          : () => _apply(
                              SearchRequest(
                                // Recognisers add sentence punctuation.
                                cleanSpokenQuery(_message.text),
                                filters: ref.read(searchFiltersProvider),
                              ),
                            ),
                      child: const Text('Search text locally'),
                    ),
                  FilledButton(
                    onPressed:
                        _busy || _recording || _message.text.trim().isEmpty
                        ? null
                        : _refine,
                    child: const Text('Refine / translate online'),
                  ),
                ],
              ),
              if (_proposed != null) ...[
                TextField(
                  controller: _english,
                  enabled: !_busy && !_recording,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'English query'),
                  maxLength: 2000,
                ),
                Text('Filters: ${_proposed!.filters.toJson()}'),
                FilledButton.icon(
                  onPressed: _busy || _recording || _english.text.trim().isEmpty
                      ? null
                      : () => _apply(
                          SearchRequest(
                            _english.text,
                            filters: _proposed!.filters,
                          ),
                        ),
                  icon: const Icon(Icons.search),
                  label: const Text('Apply local search'),
                ),
              ],
              if (_busy || _recording) ...[
                Text(switch (_phase) {
                  _VoicePhase.permission => 'Waiting for microphone permission',
                  _VoicePhase.starting => 'Preparing microphone',
                  _VoicePhase.listening => 'Listening on-device',
                  _VoicePhase.processing => 'Processing speech on-device',
                  _VoicePhase.recording => 'Recording audio',
                  _VoicePhase.stopping => 'Saving recording',
                  _VoicePhase.confirming => 'Awaiting recording approval',
                  _VoicePhase.transcribing => 'Transcribing online',
                  _VoicePhase.refining => 'Refining query online',
                  _VoicePhase.idle => '',
                }),
                const LinearProgressIndicator(),
                TextButton(
                  onPressed: () {
                    _cancelAll();
                    setState(() {});
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
