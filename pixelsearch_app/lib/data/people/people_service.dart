import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../domain/people/face_contract.dart';
import '../local/app_database.dart';
import '../local/processing_lease.dart';
import '../people_repository.dart';
import 'face_processor.dart';

class PeopleProgress {
  const PeopleProgress({
    this.checked = 0,
    this.total = 0,
    this.faces = 0,
    this.failed = 0,
    this.inaccessible = 0,
    this.phase = 'idle',
    this.elapsedMs = 0,
  });
  final int checked, total, faces, failed, inaccessible, elapsedMs;
  final String phase;
}

const peoplePhotoPermission = PermissionRequestOption(
  androidPermission: AndroidPermission(
    type: RequestType.image,
    mediaLocation: false,
  ),
);

Future<bool> hasPeoplePhotoAccess() async =>
    (await PhotoManager.getPermissionState(
      requestOption: peoplePhotoPermission,
    )).hasAccess;

Future<String?> lookupPeoplePhoto(String id) async {
  final entity = await AssetEntity.fromId(id);
  final file = await entity?.originFile;
  return file != null && await file.exists() ? file.path : null;
}

class PeopleService {
  PeopleService(
    this.repository, {
    FaceProcessor Function()? processor,
    Future<String?> Function(String)? lookup,
    Future<bool> Function()? authorized,
    Future<Directory> Function()? cropDirectory,
  }) : _factory = processor ?? createFaceProcessor,
       _lookup = lookup ?? lookupPeoplePhoto,
       _authorized = authorized ?? hasPeoplePhotoAccess,
       _cropDirectory = cropDirectory ?? _defaultCropDirectory;
  final PeopleRepository repository;
  final FaceProcessor Function() _factory;
  final Future<String?> Function(String) _lookup;
  final Future<bool> Function() _authorized;
  final Future<Directory> Function() _cropDirectory;
  bool _cancelled = false;
  Future<PeopleProgress>? _active;
  void cancel() => _cancelled = true;
  Future<void> get stopped async {
    await _active;
  }

  static Future<Directory> _defaultCropDirectory() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'people_crops'),
  );

  Future<PeopleProgress> run(void Function(PeopleProgress) progress) {
    if (_active != null) return _active!;
    _cancelled = false;
    final run = _run(progress);
    _active = run;
    return run.whenComplete(() => _active = null);
  }

  Future<PeopleProgress> _run(void Function(PeopleProgress) progress) async {
    final lease = await ProcessingLease.acquire(
      repository.db,
      'people',
      onLost: cancel,
    );
    if (lease == null) {
      return const PeopleProgress(phase: 'waiting for indexing');
    }
    try {
      final result = await _processLibrary(progress);
      if ((await repository.state()).enabled) {
        final directory = await _cropDirectory();
        await directory.create(recursive: true);
        await File(p.join(directory.path, 'run_summary.json')).writeAsString(
          jsonEncode({
            'contract': FaceContract.id,
            'phase': result.phase,
            'checked': result.checked,
            'total': result.total,
            'faces': result.faces,
            'failed': result.failed,
            'inaccessible': result.inaccessible,
            'elapsed_ms': result.elapsedMs,
            'finished_at': DateTime.now().toUtc().toIso8601String(),
          }),
          flush: true,
        );
      }
      return result;
    } finally {
      await lease.release();
    }
  }

  Future<PeopleProgress> _processLibrary(
    void Function(PeopleProgress) progress,
  ) async {
    final initial = await repository.state();
    if (!initial.enabled || initial.paused || !await _authorized()) {
      return const PeopleProgress(phase: 'paused');
    }
    await repository.reconcile();
    await pruneCrops();
    final photos = await repository.db.allPhotos();
    photos.sort((a, b) {
      final af = a.facesJson != '[]', bf = b.facesJson != '[]';
      if (af != bf) return af ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    final scans = {
      for (final s
          in await repository.db.select(repository.db.peopleScans).get())
        s.photoId: s,
    };
    final directory = await _cropDirectory();
    await directory.create(recursive: true);
    final processor = _factory();
    var loaded = false, checked = 0, faces = 0, failed = 0, inaccessible = 0;
    final watch = Stopwatch()..start();
    PeopleProgress report(String phase) => PeopleProgress(
      checked: checked,
      total: photos.length,
      faces: faces,
      failed: failed,
      inaccessible: inaccessible,
      phase: phase,
      elapsedMs: watch.elapsedMilliseconds,
    );
    progress(report('preparing'));
    try {
      for (final photo in photos) {
        if (_cancelled || !await _authorized()) break;
        final current = await repository.state();
        if (!current.enabled || current.paused) break;
        final revision = peopleRevision(photo);
        final paths = <String>[];
        try {
          // Permission changes must also invalidate cached observations.
          final path = await _lookup(photo.id);
          if (_cancelled) break;
          if (path == null) {
            await repository.commitPhoto(
              photoId: photo.id,
              revision: revision,
              generation: current.generation,
              faces: [],
              status: 'inaccessible',
            );
            inaccessible++;
            checked++;
            progress(report('scanning'));
            continue;
          }
          final scan = scans[photo.id];
          if (scan?.status == 'done' &&
              scan?.revision == revision &&
              scan?.contract == FaceContract.id) {
            faces += scan!.faces;
            checked++;
            progress(report('scanning'));
            continue;
          }
          if (!loaded) {
            await processor.load();
            loaded = true;
          }
          final found = await processor.process(path);
          if (_cancelled ||
              !await _authorized() ||
              !await repository.isCurrent(
                photo.id,
                revision,
                current.generation,
              )) {
            break;
          }
          final rows = <PeopleFacesCompanion>[];
          for (var i = 0; i < found.length; i++) {
            final f = found[i];
            final id = sha256
                .convert(
                  utf8.encode('${photo.id}|$revision|${FaceContract.id}|$i'),
                )
                .toString();
            // Unique output paths never overwrite a previously committed crop.
            final file = File(
              p.join(
                directory.path,
                '${id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
              ),
            );
            await file.writeAsBytes(f.preview, flush: true);
            paths.add(file.path);
            rows.add(
              PeopleFacesCompanion.insert(
                id: id,
                photoId: photo.id,
                revision: revision,
                contract: FaceContract.id,
                x: f.x,
                y: f.y,
                w: f.w,
                h: f.h,
                quality: f.quality,
                cropPath: Value(file.path),
                landmarksJson: Value(
                  jsonEncode([
                    for (final point in f.landmarks) [point.$1, point.$2],
                  ]),
                ),
                vector: Value(
                  f.vector == null ? null : encodeFaceVector(f.vector!),
                ),
              ),
            );
          }
          if (_cancelled || !await _authorized()) break;
          final committed = await repository.commitPhoto(
            photoId: photo.id,
            revision: revision,
            generation: current.generation,
            faces: rows,
          );
          if (!committed) break;
          paths.clear();
          faces += found.length;
        } catch (_) {
          if (_cancelled) break;
          failed++;
          await repository.commitPhoto(
            photoId: photo.id,
            revision: revision,
            generation: current.generation,
            faces: [],
            status: 'failed',
          );
          if (!loaded) {
            progress(report('error'));
            return report('error');
          }
        } finally {
          for (final path in paths) {
            await _deleteOwned(path, directory);
          }
        }
        checked++;
        progress(report('scanning'));
      }
      if (!_cancelled && checked == photos.length) {
        progress(report('grouping'));
        await repository.applyGrouping();
      }
      return report(
        checked == photos.length && !_cancelled ? 'done' : 'paused',
      );
    } finally {
      await processor.dispose();
      await pruneCrops();
    }
  }

  Future<void> deleteCrops(List<String> paths) async {
    final directory = await _cropDirectory();
    for (final path in paths) {
      await _deleteOwned(path, directory);
    }
    await pruneCrops();
  }

  Future<void> pruneCrops() async {
    final directory = await _cropDirectory();
    if (!await directory.exists()) return;
    final keep = (await repository.db.select(repository.db.peopleFaces).get())
        .map((f) => f.cropPath)
        .whereType<String>()
        .map(p.normalize)
        .toSet();
    if ((await repository.state()).enabled) {
      keep.add(p.normalize(p.join(directory.path, 'run_summary.json')));
    }
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && !keep.contains(p.normalize(entity.path))) {
        await _deleteOwned(entity.path, directory);
      }
    }
  }

  Future<void> _deleteOwned(String path, Directory directory) async {
    if (!p.isWithin(
      p.normalize(directory.absolute.path),
      p.normalize(File(path).absolute.path),
    )) {
      return;
    }
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
