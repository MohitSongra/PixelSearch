import 'dart:convert';

import '../models/photo.dart';
import 'user_preferences_storage.dart';

/// User decisions are separate from indexer-owned metadata, so a re-index
/// cannot overwrite a correction. No gallery files or embeddings are changed.
class UserPreferences {
  UserPreferences({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
  }) : _read = read ?? readUserPreferences,
       _write = write ?? writeUserPreferences;

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  Map<String, dynamic> _data = {};
  Future<void>? _loaded;
  Future<void> _writes = Future<void>.value();

  Future<void> load() => _loaded ??= _load();

  Future<void> _load() async {
    try {
      final contents = await _read();
      if (contents != null) {
        _data = jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (_) {
      _loaded = null;
      rethrow;
    }
  }

  bool get onboardingComplete => _data['onboarding_complete'] == true;
  Map<String, dynamic> get onlineSettings =>
      Map<String, dynamic>.from(_data['online_settings'] as Map? ?? {});
  Future<void> saveOnlineSettings(Map<String, dynamic> settings) =>
      _update((next) => next['online_settings'] = settings);

  String offlineSpeechLocale(String language) {
    final fallback = language == 'English' ? 'en-IN' : 'hi-IN';
    final saved = (_data['offline_speech_locales'] as Map?)?[language];
    return saved is String && _validSpeechLocale(language, saved)
        ? saved
        : fallback;
  }

  bool _validSpeechLocale(String language, String locale) =>
      const ['English', 'Hindi', 'Hinglish'].contains(language) &&
      RegExp(r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$').hasMatch(locale) &&
      locale.split('-').first.toLowerCase() ==
          (language == 'English' ? 'en' : 'hi');

  Future<void> saveOfflineSpeechLocale(String language, String locale) {
    if (!_validSpeechLocale(language, locale)) {
      throw ArgumentError('Choose a matching offline speech language.');
    }
    return _update((next) {
      final locales = Map<String, dynamic>.from(
        next['offline_speech_locales'] as Map? ?? {},
      );
      locales[language] = locale;
      next['offline_speech_locales'] = locales;
    });
  }

  Future<bool> shouldSkipOnboarding(Future<int> Function() photoCount) async {
    await load();
    if (onboardingComplete) return true;
    if (await photoCount() == 0) return false;
    // Upgrade existing installs without asking them to index again.
    await completeOnboarding();
    return true;
  }

  Future<void> completeOnboarding() =>
      _update((next) => next['onboarding_complete'] = true);

  String _key(Photo photo) => '${photo.id}|${photo.assetName ?? ''}';

  bool hasLabelCorrection(Photo photo) =>
      (_data['label_corrections'] as Map?)?.containsKey(_key(photo)) ?? false;

  Photo applyLabelCorrection(Photo photo) {
    final labels = (_data['label_corrections'] as Map?)?[_key(photo)];
    return labels is List
        ? photo.withLabels(List<String>.unmodifiable(labels.cast<String>()))
        : photo;
  }

  Future<void> correctLabels(Photo photo, List<String> labels) =>
      _update((next) {
        final corrections = Map<String, dynamic>.from(
          next['label_corrections'] as Map? ?? {},
        );
        corrections[_key(photo)] = labels
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        next['label_corrections'] = corrections;
      });

  Future<void> resetLabels(Photo photo) => _update((next) {
    final corrections = Map<String, dynamic>.from(
      next['label_corrections'] as Map? ?? {},
    )..remove(_key(photo));
    next['label_corrections'] = corrections;
  });

  Future<void> _update(void Function(Map<String, dynamic>) edit) {
    final operation = _writes.then((_) async {
      await load();
      final next = Map<String, dynamic>.from(_data);
      edit(next);
      await _write(jsonEncode(next));
      _data = next;
    });
    // A failed save must surface to its caller without blocking future saves.
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
