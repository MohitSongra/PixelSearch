import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _file(String name) async {
  final support = await getApplicationSupportDirectory();
  final dir = Directory(p.join(support.path, 'search_evaluation'));
  await dir.create(recursive: true);
  return File(p.join(dir.path, name));
}

Future<String?> readEvaluationQueries() async {
  final file = await _file('queries.json');
  return await file.exists() ? file.readAsString() : null;
}

Future<String> _save(String name, String json) async {
  final file = await _file(name);
  final pending = File('${file.path}.pending');
  await pending.writeAsString(json, flush: true);
  await pending.rename(file.path);
  return file.path;
}

Future<String> saveEvaluationQueries(String json) =>
    _save('queries.json', json);
Future<String> saveEvaluationReport(String json) =>
    _save('latest_report.json', json);
