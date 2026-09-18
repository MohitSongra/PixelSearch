import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:exif/exif.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelsearch/data/local/app_database.dart';
import 'package:pixelsearch/data/location_repository.dart';

const _located = LocationObservation(accessible: true, lat: 18, lng: 73);
const _missing = LocationObservation(accessible: true);
const _inaccessible = LocationObservation(accessible: false);

void _progress(int done, int total) {}

IfdTag _direction(String value) =>
    IfdTag(tag: 0, tagType: 'ASCII', printable: value, values: const IfdNone());

IfdTag _coordinate(List<Ratio> values) =>
    IfdTag(tag: 0, tagType: 'Ratio', printable: '', values: IfdRatios(values));

Map<String, IfdTag> _tags() => {
  'GPS GPSLatitudeRef': _direction('S'),
  'GPS GPSLongitudeRef': _direction('W'),
  'GPS GPSLatitude': _coordinate([Ratio(31, 1), Ratio(30, 1), Ratio(1, 2)]),
  'GPS GPSLongitude': _coordinate([Ratio(70, 1), Ratio(15, 1), Ratio(3, 2)]),
};

void _expectCounts(
  LocationSummary summary, {
  required int total,
  int located = 0,
  int missing = 0,
  int unchecked = 0,
  int inaccessible = 0,
  int failures = 0,
  bool cancelled = false,
}) {
  expect(summary.total, total);
  expect(summary.located, located);
  expect(summary.missing, missing);
  expect(summary.unchecked, unchecked);
  if (summary is LocationScanResult) {
    expect(summary.inaccessible, inaccessible);
    expect(summary.failures, failures);
    expect(summary.cancelled, cancelled);
    expect(
      summary.located +
          summary.missing +
          summary.unchecked +
          summary.inaccessible +
          summary.failures,
      total,
    );
  } else {
    expect(summary.located + summary.missing + summary.unchecked, total);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedPhotos(List<String> ids) => db.upsertPhotos([
    for (var i = 0; i < ids.length; i++)
      PhotoRowsCompanion.insert(
        id: ids[i],
        source: 1,
        dateMs: ids.length - i,
        mtimeMs: const Value(10),
      ),
  ]);

  Future<void> seedLocation(
    String id, {
    int revision = 10,
    String status = 'located',
    double? lat = 18,
    double? lng = 73,
  }) => db
      .into(db.photoLocations)
      .insertOnConflictUpdate(
        PhotoLocationsCompanion.insert(
          photoId: id,
          revision: revision,
          status: status,
          latitude: Value(lat),
          longitude: Value(lng),
        ),
      );

  LocationRepository repository({
    Future<LocationObservation> Function(String)? lookup,
    Future<bool> Function()? authorized,
    Future<void> Function()? request,
  }) => LocationRepository(
    db,
    requestAccess: request ?? () async {},
    stillAuthorized: authorized ?? () async => true,
    lookup: lookup ?? (_) async => _located,
  );

  test(
    'summary and located exclude stale, orphaned and invalid coordinates',
    () async {
      await seedPhotos([
        'valid',
        'zero',
        'missing',
        'unscanned',
        'stale',
        'partial',
        'nan',
        'infinity',
        'lat-range',
        'lng-range',
        'bad-missing',
        'unknown-status',
      ]);
      await seedLocation('valid');
      await seedLocation('zero', lat: 0, lng: 0);
      await seedLocation('missing', status: 'missing', lat: null, lng: null);
      await seedLocation('stale', revision: 9);
      await seedLocation('partial', lng: null);
      await seedLocation('nan', lat: double.nan);
      await seedLocation('infinity', lng: double.infinity);
      await seedLocation('lat-range', lat: 90.1);
      await seedLocation('lng-range', lng: -180.1);
      await seedLocation('bad-missing', status: 'missing');
      await seedLocation('unknown-status', status: 'unknown');
      await seedLocation('orphan');
      final repo = repository(
        request: () async => fail('Summary must not request permissions'),
      );
      _expectCounts(
        await repo.summary(),
        total: 12,
        located: 2,
        missing: 1,
        unchecked: 9,
      );
      expect((await repo.located()).map((r) => r.photoId).toSet(), {
        'valid',
        'zero',
      });
    },
  );

  test(
    'scan counts cached, new, inaccessible and failed observations separately',
    () async {
      await seedPhotos(['cached', 'absent', 'fresh', 'unavailable', 'broken']);
      await seedLocation('cached');
      await seedLocation('absent', status: 'missing', lat: null, lng: null);
      final reads = <String>[];
      final progress = <(int, int)>[];
      final repo = repository(
        lookup: (id) async {
          reads.add(id);
          if (id == 'unavailable') return _inaccessible;
          if (id == 'broken') throw const FormatException('fixture failure');
          return _located;
        },
      );
      _expectCounts(
        await repo.scan((done, total) => progress.add((done, total))),
        total: 5,
        located: 2,
        missing: 1,
        inaccessible: 1,
        failures: 1,
      );
      expect(reads, ['fresh', 'unavailable', 'broken']);
      expect(progress, [(1, 5), (2, 5), (3, 5), (4, 5), (5, 5)]);
      _expectCounts(
        await repo.summary(),
        total: 5,
        located: 2,
        missing: 1,
        unchecked: 2,
      );
      expect((await db.select(db.photoLocations).get()).length, 3);
    },
  );

  test(
    'retryMissing is opt-in and always skips unchanged valid locations',
    () async {
      await seedPhotos(['located', 'missing']);
      await seedLocation('located');
      await seedLocation('missing', status: 'missing', lat: null, lng: null);
      final reads = <String>[];
      var observation = _missing;
      final repo = repository(
        lookup: (id) async {
          reads.add(id);
          return observation;
        },
      );
      _expectCounts(
        await repo.scan(_progress),
        total: 2,
        located: 1,
        missing: 1,
      );
      expect(reads, isEmpty);
      _expectCounts(
        await repo.scan(_progress, retryMissing: true),
        total: 2,
        located: 1,
        missing: 1,
      );
      expect(reads, ['missing']);
      observation = _located;
      _expectCounts(
        await repo.scan(_progress, retryMissing: true),
        total: 2,
        located: 2,
      );
      await repo.scan(_progress, retryMissing: true);
      expect(reads, ['missing', 'missing']);
    },
  );

  test(
    'retrying missing does not manufacture GPS when new reads fail',
    () async {
      await seedPhotos(['missing']);
      await seedLocation('missing', status: 'missing', lat: null, lng: null);
      final before = await db.select(db.photoLocations).get();
      final repo = repository(
        lookup: (_) async => throw StateError('reader failure'),
      );
      _expectCounts(
        await repo.scan(_progress, retryMissing: true),
        total: 1,
        failures: 1,
      );
      expect(await db.select(db.photoLocations).get(), before);
      expect(await repo.located(), isEmpty);
    },
  );

  test(
    'stale and invalid located rows are re-read without retryMissing',
    () async {
      await seedPhotos(['stale', 'invalid', 'missing']);
      await seedLocation('stale', revision: 9);
      await seedLocation('invalid', lat: double.infinity);
      await seedLocation(
        'missing',
        status: 'missing',
        lat: null,
        lng: null,
        revision: 9,
      );
      var reads = 0;
      final repo = repository(
        lookup: (_) async {
          reads++;
          return _located;
        },
      );
      _expectCounts(await repo.scan(_progress), total: 3, located: 3);
      expect(reads, 3);
      expect((await repo.located()).every((r) => r.revision == 10), isTrue);
    },
  );

  final invalidCoordinates = <(double?, double?)>[
    (double.nan, 1),
    (1, double.nan),
    (double.infinity, 1),
    (1, double.negativeInfinity),
    (90.1, 1),
    (-90.1, 1),
    (1, 180.1),
    (1, -180.1),
    (null, 1),
    (1, null),
  ];
  for (var i = 0; i < invalidCoordinates.length; i++) {
    test(
      'invalid observation $i remains retryable and never becomes missing',
      () async {
        await seedPhotos(['a']);
        final (lat, lng) = invalidCoordinates[i];
        var reads = 0;
        final repo = repository(
          lookup: (_) async {
            reads++;
            return LocationObservation(accessible: true, lat: lat, lng: lng);
          },
        );
        _expectCounts(await repo.scan(_progress), total: 1, failures: 1);
        _expectCounts(await repo.scan(_progress), total: 1, failures: 1);
        expect(reads, 2);
        expect(await db.select(db.photoLocations).get(), isEmpty);
      },
    );
  }

  test(
    'explicit zero and finite boundary coordinates retain EXIF provenance',
    () async {
      await seedPhotos(['zero', 'north-east', 'south-west']);
      final repo = repository(
        lookup: (id) async => switch (id) {
          'zero' => const LocationObservation(accessible: true, lat: 0, lng: 0),
          'north-east' => const LocationObservation(
            accessible: true,
            lat: 90,
            lng: 180,
          ),
          _ => const LocationObservation(accessible: true, lat: -90, lng: -180),
        },
      );
      _expectCounts(await repo.scan(_progress), total: 3, located: 3);
      expect(
        (await repo.located()).every((r) => r.provenance == 'EXIF GPS'),
        isTrue,
      );
    },
  );

  test(
    'cancel and resume include cached results without repeating reads',
    () async {
      await seedPhotos(['a', 'b', 'c']);
      final reads = <String>[];
      final repo = repository(
        lookup: (id) async {
          reads.add(id);
          return _located;
        },
      );
      _expectCounts(
        await repo.scan((done, _) {
          if (done == 1) repo.cancel();
        }),
        total: 3,
        located: 1,
        unchecked: 2,
        cancelled: true,
      );
      expect(repo.running, isFalse);
      _expectCounts(await repo.scan(_progress), total: 3, located: 3);
      expect(reads, ['a', 'b', 'c']);
    },
  );

  test(
    'cancel during lookup leaves the in-flight asset unchecked without a write',
    () async {
      await seedPhotos(['a', 'b']);
      final started = Completer<void>();
      final finish = Completer<LocationObservation>();
      final repo = repository(
        lookup: (_) {
          started.complete();
          return finish.future;
        },
      );
      final pending = repo.scan(_progress);
      await started.future;
      repo.cancel();
      finish.complete(_located);
      _expectCounts(await pending, total: 2, unchecked: 2, cancelled: true);
      expect(await db.select(db.photoLocations).get(), isEmpty);
    },
  );

  test(
    'cancel during the final pre-write authorization check prevents a write',
    () async {
      await seedPhotos(['a']);
      late LocationRepository repo;
      var checks = 0;
      repo = repository(
        authorized: () async {
          if (++checks == 3) repo.cancel();
          return true;
        },
      );
      _expectCounts(
        await repo.scan(_progress),
        total: 1,
        unchecked: 1,
        cancelled: true,
      );
      expect(await db.select(db.photoLocations).get(), isEmpty);
    },
  );

  for (final delete in [false, true]) {
    test(
      '${delete ? 'deleted' : 'edited'} photo during lookup stays unchecked',
      () async {
        await seedPhotos(['a']);
        final repo = repository(
          lookup: (_) async {
            if (delete) {
              await db.deleteAssets(['a']);
            } else {
              await (db.update(db.photoRows)..where((r) => r.id.equals('a')))
                  .write(const PhotoRowsCompanion(mtimeMs: Value(11)));
            }
            return _located;
          },
        );
        _expectCounts(await repo.scan(_progress), total: 1, unchecked: 1);
        expect(await db.select(db.photoLocations).get(), isEmpty);
        _expectCounts(
          await repo.summary(),
          total: delete ? 0 : 1,
          unchecked: delete ? 0 : 1,
        );
      },
    );
  }

  test(
    'cached row edited while scan starts is not counted as current',
    () async {
      await seedPhotos(['a']);
      await seedLocation('a');
      var checks = 0;
      final repo = repository(
        authorized: () async {
          if (++checks == 1) {
            await (db.update(db.photoRows)..where((r) => r.id.equals('a')))
                .write(const PhotoRowsCompanion(mtimeMs: Value(11)));
          }
          return true;
        },
        lookup: (_) async => fail('Cached revision does not need another read'),
      );
      _expectCounts(await repo.scan(_progress), total: 1, unchecked: 1);
      expect(await repo.located(), isEmpty);
    },
  );

  test(
    'empty and all-cached scans still reject revoked authorization',
    () async {
      final repo = repository(
        authorized: () async => false,
        lookup: (_) async => fail('Unauthorized lookup'),
      );
      await expectLater(repo.scan(_progress), throwsStateError);
      expect(repo.running, isFalse);
      await seedPhotos(['a']);
      await seedLocation('a');
      await expectLater(repo.scan(_progress), throwsStateError);
      expect(repo.running, isFalse);
    },
  );

  for (final afterDone in [1, 2]) {
    test('revocation after cached progress $afterDone is detected', () async {
      await seedPhotos(['a', 'b']);
      await seedLocation('a');
      await seedLocation('b', status: 'missing', lat: null, lng: null);
      var authorized = true;
      final repo = repository(
        authorized: () async => authorized,
        lookup: (_) async => fail('Should skip cached rows'),
      );
      await expectLater(
        repo.scan((done, _) {
          if (done == afterDone) authorized = false;
        }),
        throwsStateError,
      );
      expect(repo.running, isFalse);
    });
  }

  for (final outcome in ['located', 'inaccessible', 'failure']) {
    test('authorization is rechecked after $outcome lookup', () async {
      await seedPhotos(['a']);
      var authorized = true;
      final repo = repository(
        authorized: () async => authorized,
        lookup: (_) async {
          authorized = false;
          if (outcome == 'failure') throw const FormatException('fixture');
          return outcome == 'inaccessible' ? _inaccessible : _located;
        },
      );
      await expectLater(repo.scan(_progress), throwsStateError);
      expect(repo.running, isFalse);
      expect(await db.select(db.photoLocations).get(), isEmpty);
    });
  }

  test(
    'permission loss at the final write guard prevents persistence',
    () async {
      await seedPhotos(['a']);
      var checks = 0;
      final repo = repository(authorized: () async => ++checks < 3);
      await expectLater(repo.scan(_progress), throwsStateError);
      expect(await db.select(db.photoLocations).get(), isEmpty);
    },
  );

  test(
    'initial access denial resets running and a later scan can succeed',
    () async {
      await seedPhotos(['a']);
      var denied = true;
      final repo = repository(
        request: () async {
          if (denied) throw StateError('denied');
        },
      );
      await expectLater(repo.scan(_progress), throwsStateError);
      expect(repo.running, isFalse);
      denied = false;
      _expectCounts(await repo.scan(_progress), total: 1, located: 1);
    },
  );

  test('overlapping scans share one pass and one result', () async {
    await seedPhotos(['a']);
    final started = Completer<void>();
    final finish = Completer<LocationObservation>();
    var reads = 0;
    final repo = repository(
      lookup: (_) {
        reads++;
        started.complete();
        return finish.future;
      },
    );
    final first = repo.scan(_progress);
    await started.future;
    final second = repo.scan(_progress, retryMissing: true);
    expect(identical(first, second), isTrue);
    expect(repo.running, isTrue);
    finish.complete(_located);
    _expectCounts(await first, total: 1, located: 1);
    expect(await second, same(await first));
    expect(reads, 1);
    expect(repo.running, isFalse);
  });

  test(
    'default authorization rechecks photo and media-location permissions on cached rows',
    () async {
      await seedPhotos(['a']);
      await seedLocation('a');
      const photosChannel = MethodChannel('com.fluttercandies/photo_manager');
      const permissionChannel = MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var galleryAccess = PermissionState.authorized;
      var mediaAccess = true;
      messenger.setMockMethodCallHandler(photosChannel, (call) async {
        expect(call.method, 'getPermissionState');
        return galleryAccess.index;
      });
      messenger.setMockMethodCallHandler(permissionChannel, (call) async {
        expect(call.method, 'checkPermissionStatus');
        return mediaAccess ? 1 : 0;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(photosChannel, null);
        messenger.setMockMethodCallHandler(permissionChannel, null);
      });
      final repo = LocationRepository(
        db,
        requestAccess: () async {},
        lookup: (_) async => fail('Cached rows should not be read'),
      );
      _expectCounts(await repo.scan(_progress), total: 1, located: 1);
      galleryAccess = PermissionState.denied;
      await expectLater(repo.scan(_progress), throwsStateError);
      galleryAccess = PermissionState.authorized;
      mediaAccess = false;
      await expectLater(repo.scan(_progress), throwsStateError);
    },
  );

  test(
    'scan and retry preserve the current schema, photos, embeddings and folder preferences',
    () async {
      await seedPhotos(['a', 'b']);
      await db
          .into(db.embeddingRows)
          .insert(
            EmbeddingRowsCompanion.insert(
              photoId: 'a',
              modelId: 'fixture',
              dim: 512,
              vector: Uint8List(2048),
            ),
          );
      await db
          .into(db.indexingPreferencesRows)
          .insert(
            const IndexingPreferencesRowsCompanion(
              folderIdsJson: Value('["fixture-folder"]'),
            ),
          );
      await db
          .into(db.indexStateRows)
          .insert(
            const IndexStateRowsCompanion(
              embeddedCount: Value(1),
              totalPhotos: Value(2),
            ),
          );
      Future<List<Object?>> snapshot() async => [
        for (final table in [
          'photo_rows',
          'embedding_rows',
          'indexing_preferences_rows',
          'index_state_rows',
        ])
          (await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
              .map((r) => r.data)
              .toList(),
        (await db.customSelect('PRAGMA user_version').getSingle()).data,
      ];
      final before = await snapshot();
      final repo = repository(
        lookup: (id) async => id == 'a' ? _located : _missing,
      );
      await repo.scan(_progress);
      await repo.scan(_progress, retryMissing: true);
      expect(await snapshot(), before);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        db.schemaVersion,
      );
    },
  );

  group('EXIF coordinate validation', () {
    for (final zero in [false, true]) {
      test(
        'synthetic JPEG decodes ${zero ? 'explicit zero' : 'nonzero GPS'} tags',
        () async {
          final image = img.Image(width: 2, height: 2);
          final gps = image.exif.gpsIfd;
          gps[0x0001] = img.IfdValueAscii('S');
          gps[0x0003] = img.IfdValueAscii('W');
          gps[0x0002] = img.IfdValueRational.list([
            for (final value in [zero ? 0 : 31, zero ? 0 : 30, 0])
              img.IfdValueRational(value, 1).value.single,
          ]);
          gps[0x0004] = img.IfdValueRational.list([
            for (final value in [zero ? 0 : 70, zero ? 0 : 15, 0])
              img.IfdValueRational(value, 1).value.single,
          ]);
          final tags = await readExifFromBytes(img.encodeJpg(image));
          expect(
            gpsFromTags(tags),
            zero ? (lat: 0.0, lng: 0.0) : (lat: -31.5, lng: -70.25),
          );
        },
      );
    }

    test(
      'synthetic JPEG with no GPS does not invent zero coordinates',
      () async {
        final tags = await readExifFromBytes(
          img.encodeJpg(img.Image(width: 2, height: 2)),
        );
        expect(gpsFromTags(tags), isNull);
      },
    );

    test('fractional DMS preserves southern and western hemispheres', () {
      final gps = gpsFromTags(_tags())!;
      expect(gps.lat, closeTo(-(31 + .5 + .5 / 3600), 1e-10));
      expect(gps.lng, closeTo(-(70 + .25 + 1.5 / 3600), 1e-10));
    });

    test('zero requires actual coordinate and hemisphere tags', () {
      expect(gpsFromTags({}), isNull);
      final tags = _tags();
      tags['GPS GPSLatitude'] = _coordinate([
        Ratio(0, 1),
        Ratio(0, 1),
        Ratio(0, 1),
      ]);
      tags['GPS GPSLongitude'] = _coordinate([
        Ratio(0, 1),
        Ratio(0, 1),
        Ratio(0, 1),
      ]);
      expect(gpsFromTags(tags), (lat: 0.0, lng: 0.0));
      tags.remove('GPS GPSLongitudeRef');
      expect(gpsFromTags(tags), isNull);
    });

    for (final key in ['Latitude', 'Longitude']) {
      test('$key rejects missing, invalid and nonfinite DMS values', () {
        for (final values in <List<Ratio>>[
          [],
          [Ratio(1, 1)],
          [Ratio(0, 0), Ratio(0, 1), Ratio(0, 1)],
          [Ratio(1, 0), Ratio(0, 1), Ratio(0, 1)],
          [Ratio(-1, 1), Ratio(0, 1), Ratio(0, 1)],
          [Ratio(0, 1), Ratio(60, 1), Ratio(0, 1)],
          [Ratio(0, 1), Ratio(0, 1), Ratio(60, 1)],
          [Ratio(key == 'Latitude' ? 91 : 181, 1), Ratio(0, 1), Ratio(0, 1)],
          [Ratio(key == 'Latitude' ? 90 : 180, 1), Ratio(0, 1), Ratio(1, 1)],
        ]) {
          final tags = _tags()..['GPS GPS$key'] = _coordinate(values);
          expect(gpsFromTags(tags), isNull);
        }
        final tags = _tags()..['GPS GPS${key}Ref'] = _direction('?');
        expect(gpsFromTags(tags), isNull);
      });
    }
  });
}
