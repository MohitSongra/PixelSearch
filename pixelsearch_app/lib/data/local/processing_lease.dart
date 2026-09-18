import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Cross-isolate ownership of heavyweight photo processing. A crashed process
/// expires instead of leaving a permanent lock; search is never locked.
class ProcessingLease {
  ProcessingLease._(this.db, this.owner, this.onLost) {
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) => _renew());
  }
  final AppDatabase db;
  final String owner;
  final void Function()? onLost;
  Timer? _heartbeat;
  bool _released = false;
  static const ttlMs = 5 * 60 * 1000;

  static Future<ProcessingLease?> acquire(
    AppDatabase db,
    String kind, {
    void Function()? onLost,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final owner = '$kind:$now:${Random.secure().nextInt(1 << 32)}';
    await db.customUpdate(
      'INSERT INTO processing_leases(id, owner, expires_ms) VALUES (0, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET owner=excluded.owner, expires_ms=excluded.expires_ms '
      'WHERE processing_leases.expires_ms <= ?',
      variables: [Variable(owner), Variable(now + ttlMs), Variable(now)],
    );
    final row = await db
        .customSelect('SELECT owner FROM processing_leases WHERE id=0')
        .getSingle();
    return row.read<String>('owner') == owner
        ? ProcessingLease._(db, owner, onLost)
        : null;
  }

  Future<void> _renew() async {
    if (_released) return;
    try {
      final count = await db.customUpdate(
        'UPDATE processing_leases SET expires_ms=? WHERE id=0 AND owner=?',
        variables: [
          Variable(DateTime.now().millisecondsSinceEpoch + ttlMs),
          Variable(owner),
        ],
      );
      if (count == 0 && !_released) onLost?.call();
    } catch (_) {
      if (!_released) onLost?.call();
    }
  }

  Future<void> release() async {
    _released = true;
    _heartbeat?.cancel();
    await db.customUpdate(
      'DELETE FROM processing_leases WHERE id=0 AND owner=?',
      variables: [Variable(owner)],
    );
  }
}
