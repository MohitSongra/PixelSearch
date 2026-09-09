import 'dart:convert';

import 'package:drift/drift.dart';

import '../indexing/model/folder_selection.dart';
import 'local/app_database.dart';

class IndexingPreferencesRepository {
  const IndexingPreferencesRepository(this.db);
  final AppDatabase db;

  Future<FolderSelection> load() async {
    final row = await (db.select(
      db.indexingPreferencesRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return FolderSelection();
    final ids = (jsonDecode(row.folderIdsJson) as List).cast<String>();
    return FolderSelection(allFolders: row.allFolders, folderIds: ids.toSet());
  }

  Future<void> save(FolderSelection selection) async {
    await db
        .into(db.indexingPreferencesRows)
        .insertOnConflictUpdate(
          IndexingPreferencesRowsCompanion(
            id: const Value(0),
            allFolders: Value(selection.allFolders),
            folderIdsJson: Value(
              jsonEncode(selection.folderIds.toList()..sort()),
            ),
          ),
        );
  }
}
