String? _preferences;

Future<String?> readUserPreferences() async => _preferences;
Future<void> writeUserPreferences(String contents) async {
  _preferences = contents;
}
