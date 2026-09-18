import 'package:flutter/foundation.dart';
import '../user_preferences.dart';

enum OnlineFeature { captions, assistant, speech, maps }

class OnlinePolicy extends ChangeNotifier {
  OnlinePolicy(this.preferences);
  final UserPreferences preferences;
  bool offline = true;
  bool loaded = false;
  String baseUrl = '';
  Set<OnlineFeature> enabled = {};
  Map<String, dynamic> _desired = {};
  Future<void> _writes = Future.value();
  int _generation = 0;
  int get generation => _generation;
  bool allows(OnlineFeature feature) =>
      loaded && !offline && enabled.contains(feature);

  Future<void> load() async {
    await preferences.load();
    _desired = preferences.onlineSettings;
    _publish(_desired);
    loaded = true;
    notifyListeners();
  }

  void _publish(Map<String, dynamic> data) {
    offline = data['offline'] != false;
    baseUrl = data['base_url'] as String? ?? '';
    enabled = OnlineFeature.values.where((f) => data[f.name] == true).toSet();
  }

  Future<void> update({
    bool? offline,
    OnlineFeature? feature,
    bool? allow,
    String? baseUrl,
  }) {
    if (!loaded) {
      return Future.error(StateError('Privacy settings are still loading.'));
    }
    final next = Map<String, dynamic>.from(_desired);
    if (offline != null) next['offline'] = offline;
    if (feature != null) next[feature.name] = allow == true;
    if (baseUrl != null) {
      final value = baseUrl.trim();
      final uri = Uri.tryParse(value);
      if (value.isNotEmpty &&
          (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty ||
              uri.hasQuery ||
              uri.hasFragment)) {
        return Future.error(
          ArgumentError(
            'Use an HTTPS backend URL without credentials or query parameters.',
          ),
        );
      }
      next['base_url'] = value;
    }
    _desired = next;
    final ticket = ++_generation;
    // Revocation takes effect before disk I/O, and cancels in-flight requests.
    if (offline == true) this.offline = true;
    if (feature != null && allow == false) enabled.remove(feature);
    notifyListeners();
    final operation = _writes.then((_) async {
      await preferences.saveOnlineSettings(next);
      // A superseded write must never re-enable a just-revoked capability.
      if (ticket == _generation) {
        _publish(next);
        notifyListeners();
      }
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
