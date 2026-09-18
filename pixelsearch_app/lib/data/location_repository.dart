import 'dart:io';
import 'package:drift/drift.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'local/app_database.dart';

({double lat, double lng})? gpsFromTags(Map<String, IfdTag> tags) {
  double? coordinate(String key, String positive, String negative) {
    final values = tags['GPS GPS$key']?.values.toList();
    final direction = tags['GPS GPS${key}Ref']?.printable.trim();
    if (values == null ||
        values.length != 3 ||
        (direction != positive && direction != negative)) {
      return null;
    }
    double number(dynamic v) => switch (v) {
      Ratio() => v.toDouble(),
      num() => v.toDouble(),
      _ => double.nan,
    };
    final d = number(values[0]), m = number(values[1]), s = number(values[2]);
    if (![d, m, s].every((v) => v.isFinite && v >= 0) || m >= 60 || s >= 60) {
      return null;
    }
    return (d + m / 60 + s / 3600) * (direction == negative ? -1 : 1);
  }

  final lat = coordinate('Latitude', 'N', 'S'),
      lng = coordinate('Longitude', 'E', 'W');
  if (!_validCoordinates(lat, lng)) {
    return null;
  }
  return (lat: lat!, lng: lng!);
}

bool _validCoordinates(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat.isFinite &&
    lng.isFinite &&
    lat.abs() <= 90 &&
    lng.abs() <= 180;

Future<({double lat, double lng})?> _readGps(String path) async {
  final tags = await readExifFromFile(File(path));
  final gps = gpsFromTags(tags);
  if (gps == null &&
      const [
        'GPS GPSLatitude',
        'GPS GPSLatitudeRef',
        'GPS GPSLongitude',
        'GPS GPSLongitudeRef',
      ].any(tags.containsKey)) {
    throw const FormatException('Photo GPS tags are incomplete or invalid.');
  }
  return gps;
}

class LocationObservation {
  const LocationObservation({required this.accessible, this.lat, this.lng});
  final bool accessible;
  final double? lat, lng;
}

/// Current indexed revisions; invalid, stale and unscanned records are unchecked.
/// Missing means this reader found no GPS, not proof about the original photo.
class LocationSummary {
  const LocationSummary({
    required this.total,
    required this.located,
    required this.missing,
    required this.unchecked,
  });

  final int total, located, missing, unchecked;
}

/// Outcomes for a scan's starting revisions, including valid cached results.
/// The five outcome counts sum to total. Changed/deleted assets are unchecked.
class LocationScanResult extends LocationSummary {
  const LocationScanResult({
    required super.total,
    required super.located,
    required super.missing,
    required super.unchecked,
    required this.inaccessible,
    required this.failures,
    required this.cancelled,
  });

  final int inaccessible, failures;
  final bool cancelled;
}

const _photoPermissionOption = PermissionRequestOption(
  androidPermission: AndroidPermission(
    type: RequestType.image,
    mediaLocation: false,
  ),
);

Future<bool> _hasLocationAccess() async =>
    (await PhotoManager.getPermissionState(
      requestOption: _photoPermissionOption,
    )).hasAccess &&
    await Permission.accessMediaLocation.isGranted;

Future<void> _requestLocationAccess() async {
  final permission = await PhotoManager.getPermissionState(
    requestOption: _photoPermissionOption,
  );
  if (!permission.hasAccess) throw StateError('Photo access is required.');
  if (!await Permission.accessMediaLocation.request().isGranted) {
    throw StateError('Photo location access was not granted.');
  }
}

Future<LocationObservation> _lookupLocation(String id) async {
  final entity = await AssetEntity.fromId(id);
  final file = await entity?.originFile;
  if (file == null || !await file.exists()) {
    return const LocationObservation(accessible: false);
  }
  final gps = await compute(_readGps, file.path);
  return LocationObservation(accessible: true, lat: gps?.lat, lng: gps?.lng);
}

enum _LocationOutcome { located, missing, inaccessible, failure }

class LocationRepository {
  LocationRepository(
    this.db, {
    Future<void> Function()? requestAccess,
    Future<LocationObservation> Function(String)? lookup,
    Future<bool> Function()? stillAuthorized,
  }) : _requestAccess = requestAccess ?? _requestLocationAccess,
       _lookup = lookup ?? _lookupLocation,
       _stillAuthorized = stillAuthorized ?? _hasLocationAccess;
  final AppDatabase db;
  final Future<void> Function() _requestAccess;
  final Future<LocationObservation> Function(String) _lookup;
  final Future<bool> Function() _stillAuthorized;
  bool _cancelled = false;
  Future<LocationScanResult>? _activeScan;
  bool get running => _activeScan != null;
  void cancel() => _cancelled = true;

  Future<LocationSummary> summary() => db.transaction(() async {
    final revisions = {for (final p in await db.allPhotos()) p.id: p.mtimeMs};
    var located = 0, missing = 0;
    for (final row in await db.select(db.photoLocations).get()) {
      if (revisions[row.photoId] != row.revision) continue;
      if (row.status == 'located' &&
          _validCoordinates(row.latitude, row.longitude)) {
        located++;
      } else if (row.status == 'missing' &&
          row.latitude == null &&
          row.longitude == null) {
        missing++;
      }
    }
    return LocationSummary(
      total: revisions.length,
      located: located,
      missing: missing,
      unchecked: revisions.length - located - missing,
    );
  });

  Future<List<PhotoLocation>> located() async {
    final rows = await db.select(db.photoLocations).get();
    final revisions = {for (final p in await db.allPhotos()) p.id: p.mtimeMs};
    return rows
        .where(
          (r) =>
              r.status == 'located' &&
              revisions[r.photoId] == r.revision &&
              _validCoordinates(r.latitude, r.longitude),
        )
        .toList();
  }

  /// Repeated calls join the active pass; its callback and retry policy apply.
  Future<LocationScanResult> scan(
    void Function(int done, int total) progress, {
    bool retryMissing = false,
  }) {
    if (_activeScan != null) return _activeScan!;
    _cancelled = false;
    return _activeScan = _scan(
      progress,
      retryMissing: retryMissing,
    ).whenComplete(() => _activeScan = null);
  }

  Future<bool> _canContinue() async {
    if (_cancelled) return false;
    final authorized = await _stillAuthorized();
    if (_cancelled) return false;
    if (!authorized) throw StateError('Photo location access changed.');
    return true;
  }

  Future<LocationScanResult> _scan(
    void Function(int done, int total) progress, {
    required bool retryMissing,
  }) async {
    await _requestAccess();
    final photos = await db.allPhotos();
    final previous = {
      for (final r in await db.select(db.photoLocations).get()) r.photoId: r,
    };
    var done = 0, located = 0, missing = 0, inaccessible = 0, failures = 0;
    for (final p in photos) {
      if (!await _canContinue()) break;
      final old = previous[p.id];
      final cached =
          old != null &&
          old.revision == p.mtimeMs &&
          ((old.status == 'located' &&
                  _validCoordinates(old.latitude, old.longitude)) ||
              (!retryMissing &&
                  old.status == 'missing' &&
                  old.latitude == null &&
                  old.longitude == null));
      LocationObservation? gps;
      var lookupFailed = false;
      if (cached) {
        gps = LocationObservation(
          accessible: true,
          lat: old.latitude,
          lng: old.longitude,
        );
      } else {
        try {
          gps = await _lookup(p.id);
        } catch (_) {
          lookupFailed = true;
        }
      }
      if (!await _canContinue()) break;
      _LocationOutcome? outcome;
      try {
        // Keep the revision check and write atomic with respect to the indexer.
        outcome = await db.transaction(() async {
          final current = await (db.select(
            db.photoRows,
          )..where((r) => r.id.equals(p.id))).getSingleOrNull();
          if (!await _canContinue() || current?.mtimeMs != p.mtimeMs) {
            return null;
          }
          if (lookupFailed) return _LocationOutcome.failure;
          final observation = gps!;
          if (!observation.accessible) return _LocationOutcome.inaccessible;
          final absent = observation.lat == null && observation.lng == null;
          if (!absent && !_validCoordinates(observation.lat, observation.lng)) {
            return _LocationOutcome.failure;
          }
          if (!cached) {
            await db
                .into(db.photoLocations)
                .insertOnConflictUpdate(
                  PhotoLocationsCompanion.insert(
                    photoId: p.id,
                    revision: p.mtimeMs,
                    latitude: Value(observation.lat),
                    longitude: Value(observation.lng),
                    status: absent ? 'missing' : 'located',
                  ),
                );
          }
          return absent ? _LocationOutcome.missing : _LocationOutcome.located;
        });
      } on StateError {
        rethrow;
      } catch (_) {
        if (!await _canContinue()) break;
        outcome = _LocationOutcome.failure;
      }
      switch (outcome) {
        case _LocationOutcome.located:
          located++;
        case _LocationOutcome.missing:
          missing++;
        case _LocationOutcome.inaccessible:
          inaccessible++;
        case _LocationOutcome.failure:
          failures++;
        case null:
          break;
      }
      if (_cancelled) break;
      progress(++done, photos.length);
    }
    // Includes empty libraries and revocation during the final progress callback.
    await _canContinue();
    return LocationScanResult(
      total: photos.length,
      located: located,
      missing: missing,
      unchecked: photos.length - located - missing - inaccessible - failures,
      inaccessible: inaccessible,
      failures: failures,
      cancelled: _cancelled,
    );
  }
}
