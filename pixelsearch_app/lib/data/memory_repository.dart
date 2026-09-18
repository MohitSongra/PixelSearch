import 'package:drift/drift.dart';
import '../domain/timeline/memory_grouping.dart';
import '../models/photo.dart';
import 'local/app_database.dart';

class MemoryRepository {
  MemoryRepository(this.db);
  final AppDatabase db;
  Future<void> _tail = Future.value();

  Future<List<MemoryGroup>> reconcile(List<Photo> photos) {
    final result = _tail.then(
      (_) => db.transaction(() async {
        final events = await db.select(db.memoryEvents).get();
        final members = await db.select(db.memoryMembers).get();
        final byId = {for (final photo in photos) photo.id: photo};
        final previous = [
          for (final e in events)
            MemoryGroup(
              id: e.id,
              title: e.title,
              coverId: e.coverId,
              photos: [
                for (final m in members)
                  if (m.eventId == e.id && byId.containsKey(m.photoId))
                    byId[m.photoId]!,
              ],
            ),
        ];
        final groups = reconcileMemories(photos, previous);
        final live = groups.map((e) => e.id).toSet();
        await (db.delete(
          db.memoryEvents,
        )..where((e) => e.id.isNotIn(live))).go();
        await db.delete(db.memoryMembers).go();
        await db.batch((b) {
          for (final g in groups) {
            b.insert(
              db.memoryEvents,
              MemoryEventsCompanion.insert(
                id: g.id,
                title: Value(g.title),
                coverId: g.cover.id,
                createdMs: g.start.millisecondsSinceEpoch,
              ),
              mode: InsertMode.insertOrReplace,
            );
            b.insertAll(db.memoryMembers, [
              for (final p in g.photos)
                MemoryMembersCompanion.insert(photoId: p.id, eventId: g.id),
            ]);
          }
        });
        return groups;
      }),
    );
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> edit(String id, {String? title, String? coverId}) {
    final result = _tail.then((_) async {
      await (db.update(db.memoryEvents)..where((e) => e.id.equals(id))).write(
        MemoryEventsCompanion(
          title: title == null ? const Value.absent() : Value(title.trim()),
          coverId: coverId == null ? const Value.absent() : Value(coverId),
        ),
      );
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
