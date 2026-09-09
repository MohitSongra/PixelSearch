import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _file() async => File(
  p.join(
    (await getApplicationSupportDirectory()).path,
    'user_preferences.json',
  ),
);

Future<String?> readUserPreferences() async {
  final file = await _file();
  return await file.exists() ? file.readAsString() : null;
}

Future<void> writeUserPreferences(String contents) async {
  final file = await _file();
  await file.parent.create(recursive: true);
  final pending = File('${file.path}.pending');
  await pending.writeAsString(contents, flush: true);
  await pending.rename(file.path);
}
