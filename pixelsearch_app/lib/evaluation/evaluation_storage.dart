import 'evaluation_storage_stub.dart'
    if (dart.library.io) 'evaluation_storage_io.dart'
    as impl;

Future<String?> readEvaluationQueries() => impl.readEvaluationQueries();
Future<String> saveEvaluationQueries(String json) =>
    impl.saveEvaluationQueries(json);
Future<String> saveEvaluationReport(String json) =>
    impl.saveEvaluationReport(json);
