import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pixelsearch/ai/text_embedder.dart';
import 'package:pixelsearch/core/model_locator.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/photo_repository.dart';
import 'package:pixelsearch/data/search/brute_force_vector_index.dart';
import 'package:pixelsearch/data/search/semantic_search_backend.dart';
import 'package:pixelsearch/evaluation/evaluation_runner.dart';
import 'package:pixelsearch/evaluation/evaluation_storage.dart';
import 'package:pixelsearch/evaluation/retrieval_evaluation.dart';
import 'package:pixelsearch/state/semantic_wiring_io.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real saved index: raw cosine, production replay, unchanged storage',
    (tester) async {
      final dbFile = File(
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'pixelsearch.sqlite',
        ),
      );
      expect(
        await dbFile.exists(),
        isTrue,
        reason:
            'Index photos in the app first; this test never creates a library.',
      );
      final db = AppDatabase(
        NativeDatabase(
          dbFile,
          setup: (raw) => raw.execute('PRAGMA query_only = ON'),
        ),
      );
      addTearDown(db.close);
      Future<String> storageDigest() async {
        final data = <String, Object>{};
        for (final (table, order) in [
          ('photo_rows', 'id'),
          ('embedding_rows', 'photo_id, model_id'),
          ('indexing_preferences_rows', 'id'),
          ('index_state_rows', 'id'),
        ]) {
          data[table] =
              (await db
                      .customSelect('SELECT * FROM $table ORDER BY $order')
                      .get())
                  .map((r) => r.data)
                  .toList();
        }
        return sha256.convert(utf8.encode(jsonEncode(data))).toString();
      }

      final before = await storageDigest();
      final repository = PhotoRepository(db);
      final corpus = await repository.loadPhotos();
      final vectors = await repository.loadEmbeddings();
      expect(corpus, isNotEmpty);
      expect(vectors, isNotEmpty);
      final index = BruteForceVectorIndex();
      for (final entry in vectors.entries) {
        index.upsert(entry.key, entry.value);
      }
      final backend = await buildSemanticBackend(index);
      expect(backend, isA<SemanticSearchBackend>());
      final semantic = backend as SemanticSearchBackend;
      addTearDown(semantic.embedder.dispose);
      final dataset = EvaluationDataset.parse(
        await readEvaluationQueries() ??
            await rootBundle.loadString('assets/evaluation/scene_queries.json'),
      );
      final report = await runSearchEvaluation(
        inspector: semantic,
        corpus: corpus,
        vectors: vectors,
        dataset: dataset,
        onProgress: (done, total) => debugPrint('EVALUATION $done/$total'),
      );
      final reports = report['queries'] as List;
      for (var i = 0; i < dataset.queries.length; i++) {
        final actual = await semantic.search(dataset.queries[i].query, corpus);
        final rows =
            reports[i]['trace']['rankings']['production']['ranking'] as List;
        expect(
          actual.take(200).map((p) => p.id).toList(),
          rows.map((r) => r['id']).toList(),
          reason:
              'Diagnostic production replay must match actual search for ${dataset.queries[i].id}',
        );
      }
      final textPath = (semantic.embedder as OnnxTextEmbedder).modelPath;
      final image = await const ModelLocator().resolveImage();
      report['device'] = {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
      };
      report['model_artifacts'] = {
        'text_path': textPath,
        'text_sha256': (await sha256.bind(File(textPath).openRead()).first)
            .toString(),
        'image_path': image?.path,
        'image_sha256': image == null
            ? null
            : (await sha256.bind(File(image.path).openRead()).first).toString(),
        'execution_provider': 'CPUExecutionProvider',
      };
      expect(
        await storageDigest(),
        before,
        reason:
            'Evaluation must not modify photos, embeddings, scope or checkpoints.',
      );
      report['verification'] = {
        'production_replay_matches': dataset.queries.length,
        'storage_unchanged': true,
        'storage_sha256_before_and_after': before,
      };
      final path = await saveEvaluationReport(jsonEncode(report));
      debugPrint('EVALUATION_REPORT $path');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
