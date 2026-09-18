import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/people_repository.dart';
import '../data/people/people_service.dart';
import '../domain/people/people_query.dart';
import 'providers.dart';

final peopleRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PeopleRepository(
    db,
    accessiblePhotoIds: () async {
      if (kIsWeb) return <String>{};
      final permission = await PhotoManager.getPermissionState(
        requestOption: peoplePhotoPermission,
      );
      if (permission.isAuth) return null;
      if (!permission.hasAccess) return <String>{};
      final accessible = <String>{};
      for (final photo in await db.allPhotos()) {
        if (await AssetEntity.fromId(photo.id) != null) {
          accessible.add(photo.id);
        }
      }
      return accessible;
    },
  );
});
final peopleSnapshotProvider = FutureProvider<PeopleSnapshot>(
  (ref) async => ref.watch(peopleRepositoryProvider).load(),
);
final peopleServiceProvider = Provider(
  (ref) => PeopleService(ref.watch(peopleRepositoryProvider)),
);
final peopleNameChoicesProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);
final peopleIgnoredNamesProvider = StateProvider<Set<String>>((ref) => {});
final peopleQueryProvider = FutureProvider<PeopleQuery>((ref) async {
  final query = await ref.watch(debouncedQueryProvider.future);
  final filters = ref.watch(searchFiltersProvider);
  final choices = ref.watch(peopleNameChoicesProvider);
  final ignored = ref.watch(peopleIgnoredNamesProvider);
  PeopleSnapshot? snapshot;
  if (!kIsWeb) {
    snapshot = await ref.watch(peopleSnapshotProvider.future);
  }
  return resolvePeopleQuery(
    query,
    [
      for (final p in snapshot?.people ?? <PersonView>[])
        NamedPerson(p.record.id, p.record.name, aliases: p.aliases),
    ],
    filters: filters,
    choices: choices,
    ignoredNames: ignored,
  );
});

final peopleControllerProvider = ChangeNotifierProvider<PeopleController>((
  ref,
) {
  final controller = PeopleController(
    ref,
    ref.watch(peopleRepositoryProvider),
    ref.watch(peopleServiceProvider),
  );
  ref.listen(indexingControllerProvider, (previous, next) {
    if (next.running) {
      controller.suspend();
    } else if (previous?.running == true) {
      controller.kick();
    }
  });
  return controller;
});

class PeopleController extends ChangeNotifier with WidgetsBindingObserver {
  PeopleController(this.ref, this.repository, this.service) {
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(kick);
  }
  final Ref ref;
  final PeopleRepository repository;
  final PeopleService service;
  bool running = false;
  bool hasPermission = true;
  bool _disposed = false;
  bool _foreground = true;
  String? error;
  PeopleProgress progress = const PeopleProgress();
  Future<void>? _task;
  Timer? _retry;
  Timer? _newPhotos;

  Future<void> _checkNewPhotos() async {
    if (kIsWeb || _disposed || !_foreground || running) return;
    try {
      if (await repository.hasPendingPhotos()) await kick();
    } catch (_) {
      // The next foreground pass can retry an unavailable database.
    }
  }

  void changed() {
    if (_disposed) return;
    ref.invalidate(peopleSnapshotProvider);
    notifyListeners();
  }

  Future<void> kick() async {
    if (kIsWeb ||
        _disposed ||
        !_foreground ||
        running ||
        ref.read(indexingControllerProvider).running) {
      return;
    }
    _retry?.cancel();
    final task = _run();
    _task = task;
    await task;
    if (_task == task) _task = null;
  }

  Future<void> _run() async {
    running = true;
    error = null;
    var resumeInterrupted = false;
    try {
      final state = await repository.state();
      if (!state.enabled || state.paused || _disposed || !_foreground) return;
      hasPermission = await hasPeoplePhotoAccess();
      if (!hasPermission) {
        error = 'Photo access is required for People.';
        return;
      }
      _newPhotos ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkNewPhotos(),
      );
      notifyListeners();
      var lastRefresh = 0;
      progress = await service.run((next) {
        if (_disposed) return;
        progress = next;
        if (next.checked - lastRefresh >= 20) {
          lastRefresh = next.checked;
          ref.invalidate(peopleSnapshotProvider);
        }
        notifyListeners();
      });
      if (progress.phase == 'error') {
        error =
            'The offline face model could not run. Retry after checking the app installation.';
      }
      if (progress.phase == 'paused') {
        final current = await repository.state();
        resumeInterrupted = current.enabled && !current.paused;
      }
    } catch (_) {
      error = 'People processing could not finish. Completed photos are saved.';
    } finally {
      running = false;
      if (!_disposed) changed();
      if (!_disposed &&
          _foreground &&
          (progress.phase == 'waiting for indexing' || resumeInterrupted)) {
        _retry = Timer(const Duration(seconds: 15), kick);
      }
    }
  }

  Future<void> enable() async {
    await repository.enable();
    changed();
    await kick();
  }

  Future<void> pause() async {
    _newPhotos?.cancel();
    _newPhotos = null;
    service.cancel();
    await repository.pause(true);
    changed();
  }

  Future<void> resume() async {
    await suspend();
    await repository.pause(false);
    changed();
    await kick();
  }

  Future<void> suspend() async {
    _retry?.cancel();
    service.cancel();
    await _task;
    _retry?.cancel();
  }

  Future<void> disableAndDelete() async {
    _newPhotos?.cancel();
    _newPhotos = null;
    service.cancel();
    final paths = await repository.disableAndDelete();
    await _task;
    _newPhotos?.cancel();
    _newPhotos = null;
    await service.deleteCrops(paths);
    progress = const PeopleProgress();
    changed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      kick();
    } else {
      service.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _newPhotos?.cancel();
    service.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
