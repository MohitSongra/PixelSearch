import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../core/ai_contract.dart';
import '../models/photo.dart';
import 'local/app_database.dart';

/// Bridges the platform-free domain [Photo] to the drift store and owns
/// embedding persistence. M2 is additive: the running UI/search path does not
/// depend on this yet — M5 (indexer) and M6 (real search) do.
class PhotoRepository {
  PhotoRepository(this._db);
  final AppDatabase _db;

  /// Must equal the contract (INTERFACE_CONTRACT.md §0).
  static const String modelId = AiContract.modelId;
  static const String embeddingVersion = AiContract.embeddingVersion;

  // Photos ------------------------------------------------------------------
  Future<void> savePhotos(List<Photo> photos) =>
      _db.upsertPhotos(photos.map(photoToRow).toList());

  Future<List<Photo>> loadPhotos() async =>
      (await _db.allPhotos()).map(rowToPhoto).toList();

  Future<int> photoCount() => _db.photoCount();

  // Embeddings --------------------------------------------------------------
  Future<void> saveEmbedding(String photoId, Float32List vector,
          {String model = modelId, String version = embeddingVersion}) =>
      _db.upsertEmbedding(EmbeddingRowsCompanion.insert(
        photoId: photoId,
        modelId: model,
        embeddingVersion: Value(version),
        dim: vector.length,
        vector: encodeVector(vector),
        createdAtMs: Value(DateTime.now().millisecondsSinceEpoch),
      ));

  /// All current-version embeddings for [model], keyed by photo id (loaded into
  /// memory for the M6 cosine scan).
  Future<Map<String, Float32List>> loadEmbeddings(
      {String model = modelId, String version = embeddingVersion}) async {
    final rows = await _db.embeddingsFor(model, version);
    return {for (final r in rows) r.photoId: decodeVector(r.vector)};
  }

  /// Photo ids still awaiting a current-version embedding — the M5 work queue.
  Future<List<String>> photoIdsNeedingEmbedding(
          {String model = modelId, String version = embeddingVersion}) =>
      _db.photoIdsNeedingEmbedding(model, version);
}

// --- pure mapping + vector codec (unit-tested, no I/O) ----------------------

PhotoRowsCompanion photoToRow(Photo p) => PhotoRowsCompanion.insert(
      id: p.id,
      source: p.source.index,
      assetName: Value(p.assetName),
      title: Value(p.title),
      caption: Value(p.caption),
      tagsJson: Value(_encodeTags(p.tags)),
      dateMs: p.date.millisecondsSinceEpoch,
      lat: Value(p.lat),
      lng: Value(p.lng),
      place: Value(p.place),
      album: Value(p.album),
      thumbPath: Value(p.thumbPath),
      createdAtMs: Value(DateTime.now().millisecondsSinceEpoch),
    );

Photo rowToPhoto(PhotoRow r) => Photo(
      id: r.id,
      assetName: r.assetName,
      title: r.title,
      caption: r.caption,
      tags: _decodeTags(r.tagsJson),
      date: DateTime.fromMillisecondsSinceEpoch(r.dateMs),
      lat: r.lat,
      lng: r.lng,
      place: r.place,
      album: r.album,
      source: PhotoSource
          .values[r.source.clamp(0, PhotoSource.values.length - 1)],
      // Written by the M5 indexer, read-only here: the cached thumbnail the grid
      // renders, plus the M6 hybrid-ranking signals.
      thumbPath: r.thumbPath,
      labels: _decodeLabels(r.labelsJson),
      faceCount: _decodeCount(r.facesJson),
    );

String _encodeTags(List<String> tags) => jsonEncode(tags);

List<String> _decodeTags(String s) {
  try {
    final decoded = jsonDecode(s);
    return decoded is List ? decoded.map((e) => e.toString()).toList() : <String>[];
  } catch (_) {
    return <String>[];
  }
}

/// Tolerant decode of the M5 `labelsJson` column. Accepts either a plain list of
/// strings `["dog","beach"]` or a list of objects `[{"label":"dog",...}]`
/// (ML Kit shape), returning lower-cased label text. Never throws.
List<String> _decodeLabels(String s) {
  try {
    final decoded = jsonDecode(s);
    if (decoded is! List) return const [];
    final out = <String>[];
    for (final e in decoded) {
      if (e is String) {
        out.add(e.toLowerCase());
      } else if (e is Map) {
        final v = e['label'] ?? e['text'] ?? e['name'];
        if (v != null) out.add(v.toString().toLowerCase());
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Tolerant decode of the M5 `facesJson` column → face count (list length).
int _decodeCount(String s) {
  try {
    final decoded = jsonDecode(s);
    return decoded is List ? decoded.length : 0;
  } catch (_) {
    return 0;
  }
}

/// Encode a 512-d embedding as a little-endian float32 BLOB (INTERFACE_CONTRACT.md).
Uint8List encodeVector(Float32List v) {
  final bytes = ByteData(v.length * 4);
  for (var i = 0; i < v.length; i++) {
    bytes.setFloat32(i * 4, v[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// Decode a little-endian float32 BLOB back to a [Float32List].
Float32List decodeVector(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final out = Float32List(bytes.length ~/ 4);
  for (var i = 0; i < out.length; i++) {
    out[i] = data.getFloat32(i * 4, Endian.little);
  }
  return out;
}
