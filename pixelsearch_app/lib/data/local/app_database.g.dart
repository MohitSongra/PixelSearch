// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PhotoRowsTable extends PhotoRows
    with TableInfo<$PhotoRowsTable, PhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetNameMeta = const VerificationMeta(
    'assetName',
  );
  @override
  late final GeneratedColumn<String> assetName = GeneratedColumn<String>(
    'asset_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _dateMsMeta = const VerificationMeta('dateMs');
  @override
  late final GeneratedColumn<int> dateMs = GeneratedColumn<int>(
    'date_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mtimeMsMeta = const VerificationMeta(
    'mtimeMs',
  );
  @override
  late final GeneratedColumn<int> mtimeMs = GeneratedColumn<int>(
    'mtime_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelsJsonMeta = const VerificationMeta(
    'labelsJson',
  );
  @override
  late final GeneratedColumn<String> labelsJson = GeneratedColumn<String>(
    'labels_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _facesJsonMeta = const VerificationMeta(
    'facesJson',
  );
  @override
  late final GeneratedColumn<String> facesJson = GeneratedColumn<String>(
    'faces_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _indexedAtMsMeta = const VerificationMeta(
    'indexedAtMs',
  );
  @override
  late final GeneratedColumn<int> indexedAtMs = GeneratedColumn<int>(
    'indexed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    assetName,
    title,
    caption,
    tagsJson,
    dateMs,
    lat,
    lng,
    place,
    album,
    createdAtMs,
    mtimeMs,
    byteSize,
    width,
    height,
    thumbPath,
    labelsJson,
    facesJson,
    indexedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('asset_name')) {
      context.handle(
        _assetNameMeta,
        assetName.isAcceptableOrUnknown(data['asset_name']!, _assetNameMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('date_ms')) {
      context.handle(
        _dateMsMeta,
        dateMs.isAcceptableOrUnknown(data['date_ms']!, _dateMsMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    }
    if (data.containsKey('mtime_ms')) {
      context.handle(
        _mtimeMsMeta,
        mtimeMs.isAcceptableOrUnknown(data['mtime_ms']!, _mtimeMsMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    }
    if (data.containsKey('labels_json')) {
      context.handle(
        _labelsJsonMeta,
        labelsJson.isAcceptableOrUnknown(data['labels_json']!, _labelsJsonMeta),
      );
    }
    if (data.containsKey('faces_json')) {
      context.handle(
        _facesJsonMeta,
        facesJson.isAcceptableOrUnknown(data['faces_json']!, _facesJsonMeta),
      );
    }
    if (data.containsKey('indexed_at_ms')) {
      context.handle(
        _indexedAtMsMeta,
        indexedAtMs.isAcceptableOrUnknown(
          data['indexed_at_ms']!,
          _indexedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
      assetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_name'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      dateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_ms'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      mtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mtime_ms'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      ),
      labelsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}labels_json'],
      )!,
      facesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}faces_json'],
      )!,
      indexedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at_ms'],
      )!,
    );
  }

  @override
  $PhotoRowsTable createAlias(String alias) {
    return $PhotoRowsTable(attachedDatabase, alias);
  }
}

class PhotoRow extends DataClass implements Insertable<PhotoRow> {
  final String id;
  final int source;
  final String? assetName;
  final String title;
  final String caption;
  final String tagsJson;
  final int dateMs;
  final double? lat;
  final double? lng;
  final String? place;
  final String album;
  final int createdAtMs;
  final int mtimeMs;
  final int byteSize;
  final int width;
  final int height;
  final String? thumbPath;
  final String labelsJson;
  final String facesJson;
  final int indexedAtMs;
  const PhotoRow({
    required this.id,
    required this.source,
    this.assetName,
    required this.title,
    required this.caption,
    required this.tagsJson,
    required this.dateMs,
    this.lat,
    this.lng,
    this.place,
    required this.album,
    required this.createdAtMs,
    required this.mtimeMs,
    required this.byteSize,
    required this.width,
    required this.height,
    this.thumbPath,
    required this.labelsJson,
    required this.facesJson,
    required this.indexedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<int>(source);
    if (!nullToAbsent || assetName != null) {
      map['asset_name'] = Variable<String>(assetName);
    }
    map['title'] = Variable<String>(title);
    map['caption'] = Variable<String>(caption);
    map['tags_json'] = Variable<String>(tagsJson);
    map['date_ms'] = Variable<int>(dateMs);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    map['album'] = Variable<String>(album);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['mtime_ms'] = Variable<int>(mtimeMs);
    map['byte_size'] = Variable<int>(byteSize);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    map['labels_json'] = Variable<String>(labelsJson);
    map['faces_json'] = Variable<String>(facesJson);
    map['indexed_at_ms'] = Variable<int>(indexedAtMs);
    return map;
  }

  PhotoRowsCompanion toCompanion(bool nullToAbsent) {
    return PhotoRowsCompanion(
      id: Value(id),
      source: Value(source),
      assetName: assetName == null && nullToAbsent
          ? const Value.absent()
          : Value(assetName),
      title: Value(title),
      caption: Value(caption),
      tagsJson: Value(tagsJson),
      dateMs: Value(dateMs),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      album: Value(album),
      createdAtMs: Value(createdAtMs),
      mtimeMs: Value(mtimeMs),
      byteSize: Value(byteSize),
      width: Value(width),
      height: Value(height),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      labelsJson: Value(labelsJson),
      facesJson: Value(facesJson),
      indexedAtMs: Value(indexedAtMs),
    );
  }

  factory PhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoRow(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<int>(json['source']),
      assetName: serializer.fromJson<String?>(json['assetName']),
      title: serializer.fromJson<String>(json['title']),
      caption: serializer.fromJson<String>(json['caption']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      dateMs: serializer.fromJson<int>(json['dateMs']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      place: serializer.fromJson<String?>(json['place']),
      album: serializer.fromJson<String>(json['album']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      mtimeMs: serializer.fromJson<int>(json['mtimeMs']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      labelsJson: serializer.fromJson<String>(json['labelsJson']),
      facesJson: serializer.fromJson<String>(json['facesJson']),
      indexedAtMs: serializer.fromJson<int>(json['indexedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<int>(source),
      'assetName': serializer.toJson<String?>(assetName),
      'title': serializer.toJson<String>(title),
      'caption': serializer.toJson<String>(caption),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'dateMs': serializer.toJson<int>(dateMs),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'place': serializer.toJson<String?>(place),
      'album': serializer.toJson<String>(album),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'mtimeMs': serializer.toJson<int>(mtimeMs),
      'byteSize': serializer.toJson<int>(byteSize),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'labelsJson': serializer.toJson<String>(labelsJson),
      'facesJson': serializer.toJson<String>(facesJson),
      'indexedAtMs': serializer.toJson<int>(indexedAtMs),
    };
  }

  PhotoRow copyWith({
    String? id,
    int? source,
    Value<String?> assetName = const Value.absent(),
    String? title,
    String? caption,
    String? tagsJson,
    int? dateMs,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> place = const Value.absent(),
    String? album,
    int? createdAtMs,
    int? mtimeMs,
    int? byteSize,
    int? width,
    int? height,
    Value<String?> thumbPath = const Value.absent(),
    String? labelsJson,
    String? facesJson,
    int? indexedAtMs,
  }) => PhotoRow(
    id: id ?? this.id,
    source: source ?? this.source,
    assetName: assetName.present ? assetName.value : this.assetName,
    title: title ?? this.title,
    caption: caption ?? this.caption,
    tagsJson: tagsJson ?? this.tagsJson,
    dateMs: dateMs ?? this.dateMs,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    place: place.present ? place.value : this.place,
    album: album ?? this.album,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    mtimeMs: mtimeMs ?? this.mtimeMs,
    byteSize: byteSize ?? this.byteSize,
    width: width ?? this.width,
    height: height ?? this.height,
    thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
    labelsJson: labelsJson ?? this.labelsJson,
    facesJson: facesJson ?? this.facesJson,
    indexedAtMs: indexedAtMs ?? this.indexedAtMs,
  );
  PhotoRow copyWithCompanion(PhotoRowsCompanion data) {
    return PhotoRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      assetName: data.assetName.present ? data.assetName.value : this.assetName,
      title: data.title.present ? data.title.value : this.title,
      caption: data.caption.present ? data.caption.value : this.caption,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      dateMs: data.dateMs.present ? data.dateMs.value : this.dateMs,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      place: data.place.present ? data.place.value : this.place,
      album: data.album.present ? data.album.value : this.album,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      mtimeMs: data.mtimeMs.present ? data.mtimeMs.value : this.mtimeMs,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      labelsJson: data.labelsJson.present
          ? data.labelsJson.value
          : this.labelsJson,
      facesJson: data.facesJson.present ? data.facesJson.value : this.facesJson,
      indexedAtMs: data.indexedAtMs.present
          ? data.indexedAtMs.value
          : this.indexedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('assetName: $assetName, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('dateMs: $dateMs, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('place: $place, ')
          ..write('album: $album, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('labelsJson: $labelsJson, ')
          ..write('facesJson: $facesJson, ')
          ..write('indexedAtMs: $indexedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    assetName,
    title,
    caption,
    tagsJson,
    dateMs,
    lat,
    lng,
    place,
    album,
    createdAtMs,
    mtimeMs,
    byteSize,
    width,
    height,
    thumbPath,
    labelsJson,
    facesJson,
    indexedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.assetName == this.assetName &&
          other.title == this.title &&
          other.caption == this.caption &&
          other.tagsJson == this.tagsJson &&
          other.dateMs == this.dateMs &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.place == this.place &&
          other.album == this.album &&
          other.createdAtMs == this.createdAtMs &&
          other.mtimeMs == this.mtimeMs &&
          other.byteSize == this.byteSize &&
          other.width == this.width &&
          other.height == this.height &&
          other.thumbPath == this.thumbPath &&
          other.labelsJson == this.labelsJson &&
          other.facesJson == this.facesJson &&
          other.indexedAtMs == this.indexedAtMs);
}

class PhotoRowsCompanion extends UpdateCompanion<PhotoRow> {
  final Value<String> id;
  final Value<int> source;
  final Value<String?> assetName;
  final Value<String> title;
  final Value<String> caption;
  final Value<String> tagsJson;
  final Value<int> dateMs;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> place;
  final Value<String> album;
  final Value<int> createdAtMs;
  final Value<int> mtimeMs;
  final Value<int> byteSize;
  final Value<int> width;
  final Value<int> height;
  final Value<String?> thumbPath;
  final Value<String> labelsJson;
  final Value<String> facesJson;
  final Value<int> indexedAtMs;
  final Value<int> rowid;
  const PhotoRowsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.assetName = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.dateMs = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.place = const Value.absent(),
    this.album = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.mtimeMs = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.labelsJson = const Value.absent(),
    this.facesJson = const Value.absent(),
    this.indexedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoRowsCompanion.insert({
    required String id,
    required int source,
    this.assetName = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required int dateMs,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.place = const Value.absent(),
    this.album = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.mtimeMs = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.labelsJson = const Value.absent(),
    this.facesJson = const Value.absent(),
    this.indexedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       dateMs = Value(dateMs);
  static Insertable<PhotoRow> custom({
    Expression<String>? id,
    Expression<int>? source,
    Expression<String>? assetName,
    Expression<String>? title,
    Expression<String>? caption,
    Expression<String>? tagsJson,
    Expression<int>? dateMs,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? place,
    Expression<String>? album,
    Expression<int>? createdAtMs,
    Expression<int>? mtimeMs,
    Expression<int>? byteSize,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? thumbPath,
    Expression<String>? labelsJson,
    Expression<String>? facesJson,
    Expression<int>? indexedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (assetName != null) 'asset_name': assetName,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (dateMs != null) 'date_ms': dateMs,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (place != null) 'place': place,
      if (album != null) 'album': album,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (mtimeMs != null) 'mtime_ms': mtimeMs,
      if (byteSize != null) 'byte_size': byteSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (labelsJson != null) 'labels_json': labelsJson,
      if (facesJson != null) 'faces_json': facesJson,
      if (indexedAtMs != null) 'indexed_at_ms': indexedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoRowsCompanion copyWith({
    Value<String>? id,
    Value<int>? source,
    Value<String?>? assetName,
    Value<String>? title,
    Value<String>? caption,
    Value<String>? tagsJson,
    Value<int>? dateMs,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? place,
    Value<String>? album,
    Value<int>? createdAtMs,
    Value<int>? mtimeMs,
    Value<int>? byteSize,
    Value<int>? width,
    Value<int>? height,
    Value<String?>? thumbPath,
    Value<String>? labelsJson,
    Value<String>? facesJson,
    Value<int>? indexedAtMs,
    Value<int>? rowid,
  }) {
    return PhotoRowsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      assetName: assetName ?? this.assetName,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      tagsJson: tagsJson ?? this.tagsJson,
      dateMs: dateMs ?? this.dateMs,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      place: place ?? this.place,
      album: album ?? this.album,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      mtimeMs: mtimeMs ?? this.mtimeMs,
      byteSize: byteSize ?? this.byteSize,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbPath: thumbPath ?? this.thumbPath,
      labelsJson: labelsJson ?? this.labelsJson,
      facesJson: facesJson ?? this.facesJson,
      indexedAtMs: indexedAtMs ?? this.indexedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (assetName.present) {
      map['asset_name'] = Variable<String>(assetName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (dateMs.present) {
      map['date_ms'] = Variable<int>(dateMs.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (mtimeMs.present) {
      map['mtime_ms'] = Variable<int>(mtimeMs.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (labelsJson.present) {
      map['labels_json'] = Variable<String>(labelsJson.value);
    }
    if (facesJson.present) {
      map['faces_json'] = Variable<String>(facesJson.value);
    }
    if (indexedAtMs.present) {
      map['indexed_at_ms'] = Variable<int>(indexedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRowsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('assetName: $assetName, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('dateMs: $dateMs, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('place: $place, ')
          ..write('album: $album, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('labelsJson: $labelsJson, ')
          ..write('facesJson: $facesJson, ')
          ..write('indexedAtMs: $indexedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmbeddingRowsTable extends EmbeddingRows
    with TableInfo<$EmbeddingRowsTable, EmbeddingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmbeddingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingVersionMeta = const VerificationMeta(
    'embeddingVersion',
  );
  @override
  late final GeneratedColumn<String> embeddingVersion = GeneratedColumn<String>(
    'embedding_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1'),
  );
  static const VerificationMeta _dimMeta = const VerificationMeta('dim');
  @override
  late final GeneratedColumn<int> dim = GeneratedColumn<int>(
    'dim',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
    'vector',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    modelId,
    embeddingVersion,
    dim,
    vector,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'embedding_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmbeddingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('embedding_version')) {
      context.handle(
        _embeddingVersionMeta,
        embeddingVersion.isAcceptableOrUnknown(
          data['embedding_version']!,
          _embeddingVersionMeta,
        ),
      );
    }
    if (data.containsKey('dim')) {
      context.handle(
        _dimMeta,
        dim.isAcceptableOrUnknown(data['dim']!, _dimMeta),
      );
    } else if (isInserting) {
      context.missing(_dimMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(
        _vectorMeta,
        vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta),
      );
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId, modelId};
  @override
  EmbeddingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmbeddingRow(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      embeddingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_version'],
      )!,
      dim: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim'],
      )!,
      vector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vector'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $EmbeddingRowsTable createAlias(String alias) {
    return $EmbeddingRowsTable(attachedDatabase, alias);
  }
}

class EmbeddingRow extends DataClass implements Insertable<EmbeddingRow> {
  final String photoId;
  final String modelId;
  final String embeddingVersion;
  final int dim;
  final Uint8List vector;
  final int createdAtMs;
  const EmbeddingRow({
    required this.photoId,
    required this.modelId,
    required this.embeddingVersion,
    required this.dim,
    required this.vector,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['model_id'] = Variable<String>(modelId);
    map['embedding_version'] = Variable<String>(embeddingVersion);
    map['dim'] = Variable<int>(dim);
    map['vector'] = Variable<Uint8List>(vector);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  EmbeddingRowsCompanion toCompanion(bool nullToAbsent) {
    return EmbeddingRowsCompanion(
      photoId: Value(photoId),
      modelId: Value(modelId),
      embeddingVersion: Value(embeddingVersion),
      dim: Value(dim),
      vector: Value(vector),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory EmbeddingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmbeddingRow(
      photoId: serializer.fromJson<String>(json['photoId']),
      modelId: serializer.fromJson<String>(json['modelId']),
      embeddingVersion: serializer.fromJson<String>(json['embeddingVersion']),
      dim: serializer.fromJson<int>(json['dim']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'modelId': serializer.toJson<String>(modelId),
      'embeddingVersion': serializer.toJson<String>(embeddingVersion),
      'dim': serializer.toJson<int>(dim),
      'vector': serializer.toJson<Uint8List>(vector),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  EmbeddingRow copyWith({
    String? photoId,
    String? modelId,
    String? embeddingVersion,
    int? dim,
    Uint8List? vector,
    int? createdAtMs,
  }) => EmbeddingRow(
    photoId: photoId ?? this.photoId,
    modelId: modelId ?? this.modelId,
    embeddingVersion: embeddingVersion ?? this.embeddingVersion,
    dim: dim ?? this.dim,
    vector: vector ?? this.vector,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  EmbeddingRow copyWithCompanion(EmbeddingRowsCompanion data) {
    return EmbeddingRow(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      embeddingVersion: data.embeddingVersion.present
          ? data.embeddingVersion.value
          : this.embeddingVersion,
      dim: data.dim.present ? data.dim.value : this.dim,
      vector: data.vector.present ? data.vector.value : this.vector,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingRow(')
          ..write('photoId: $photoId, ')
          ..write('modelId: $modelId, ')
          ..write('embeddingVersion: $embeddingVersion, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    photoId,
    modelId,
    embeddingVersion,
    dim,
    $driftBlobEquality.hash(vector),
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmbeddingRow &&
          other.photoId == this.photoId &&
          other.modelId == this.modelId &&
          other.embeddingVersion == this.embeddingVersion &&
          other.dim == this.dim &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.createdAtMs == this.createdAtMs);
}

class EmbeddingRowsCompanion extends UpdateCompanion<EmbeddingRow> {
  final Value<String> photoId;
  final Value<String> modelId;
  final Value<String> embeddingVersion;
  final Value<int> dim;
  final Value<Uint8List> vector;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const EmbeddingRowsCompanion({
    this.photoId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.embeddingVersion = const Value.absent(),
    this.dim = const Value.absent(),
    this.vector = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmbeddingRowsCompanion.insert({
    required String photoId,
    required String modelId,
    this.embeddingVersion = const Value.absent(),
    required int dim,
    required Uint8List vector,
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       modelId = Value(modelId),
       dim = Value(dim),
       vector = Value(vector);
  static Insertable<EmbeddingRow> custom({
    Expression<String>? photoId,
    Expression<String>? modelId,
    Expression<String>? embeddingVersion,
    Expression<int>? dim,
    Expression<Uint8List>? vector,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (modelId != null) 'model_id': modelId,
      if (embeddingVersion != null) 'embedding_version': embeddingVersion,
      if (dim != null) 'dim': dim,
      if (vector != null) 'vector': vector,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmbeddingRowsCompanion copyWith({
    Value<String>? photoId,
    Value<String>? modelId,
    Value<String>? embeddingVersion,
    Value<int>? dim,
    Value<Uint8List>? vector,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return EmbeddingRowsCompanion(
      photoId: photoId ?? this.photoId,
      modelId: modelId ?? this.modelId,
      embeddingVersion: embeddingVersion ?? this.embeddingVersion,
      dim: dim ?? this.dim,
      vector: vector ?? this.vector,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (embeddingVersion.present) {
      map['embedding_version'] = Variable<String>(embeddingVersion.value);
    }
    if (dim.present) {
      map['dim'] = Variable<int>(dim.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingRowsCompanion(')
          ..write('photoId: $photoId, ')
          ..write('modelId: $modelId, ')
          ..write('embeddingVersion: $embeddingVersion, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IndexStateRowsTable extends IndexStateRows
    with TableInfo<$IndexStateRowsTable, IndexStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexStateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalPhotosMeta = const VerificationMeta(
    'totalPhotos',
  );
  @override
  late final GeneratedColumn<int> totalPhotos = GeneratedColumn<int>(
    'total_photos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _embeddedCountMeta = const VerificationMeta(
    'embeddedCount',
  );
  @override
  late final GeneratedColumn<int> embeddedCount = GeneratedColumn<int>(
    'embedded_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRunMsMeta = const VerificationMeta(
    'lastRunMs',
  );
  @override
  late final GeneratedColumn<int> lastRunMs = GeneratedColumn<int>(
    'last_run_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _modelReadyMeta = const VerificationMeta(
    'modelReady',
  );
  @override
  late final GeneratedColumn<bool> modelReady = GeneratedColumn<bool>(
    'model_ready',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("model_ready" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    modelId,
    totalPhotos,
    embeddedCount,
    lastRunMs,
    modelReady,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'index_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('total_photos')) {
      context.handle(
        _totalPhotosMeta,
        totalPhotos.isAcceptableOrUnknown(
          data['total_photos']!,
          _totalPhotosMeta,
        ),
      );
    }
    if (data.containsKey('embedded_count')) {
      context.handle(
        _embeddedCountMeta,
        embeddedCount.isAcceptableOrUnknown(
          data['embedded_count']!,
          _embeddedCountMeta,
        ),
      );
    }
    if (data.containsKey('last_run_ms')) {
      context.handle(
        _lastRunMsMeta,
        lastRunMs.isAcceptableOrUnknown(data['last_run_ms']!, _lastRunMsMeta),
      );
    }
    if (data.containsKey('model_ready')) {
      context.handle(
        _modelReadyMeta,
        modelReady.isAcceptableOrUnknown(data['model_ready']!, _modelReadyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndexStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      totalPhotos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_photos'],
      )!,
      embeddedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embedded_count'],
      )!,
      lastRunMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_run_ms'],
      )!,
      modelReady: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}model_ready'],
      )!,
    );
  }

  @override
  $IndexStateRowsTable createAlias(String alias) {
    return $IndexStateRowsTable(attachedDatabase, alias);
  }
}

class IndexStateRow extends DataClass implements Insertable<IndexStateRow> {
  final int id;
  final String modelId;
  final int totalPhotos;
  final int embeddedCount;
  final int lastRunMs;
  final bool modelReady;
  const IndexStateRow({
    required this.id,
    required this.modelId,
    required this.totalPhotos,
    required this.embeddedCount,
    required this.lastRunMs,
    required this.modelReady,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model_id'] = Variable<String>(modelId);
    map['total_photos'] = Variable<int>(totalPhotos);
    map['embedded_count'] = Variable<int>(embeddedCount);
    map['last_run_ms'] = Variable<int>(lastRunMs);
    map['model_ready'] = Variable<bool>(modelReady);
    return map;
  }

  IndexStateRowsCompanion toCompanion(bool nullToAbsent) {
    return IndexStateRowsCompanion(
      id: Value(id),
      modelId: Value(modelId),
      totalPhotos: Value(totalPhotos),
      embeddedCount: Value(embeddedCount),
      lastRunMs: Value(lastRunMs),
      modelReady: Value(modelReady),
    );
  }

  factory IndexStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexStateRow(
      id: serializer.fromJson<int>(json['id']),
      modelId: serializer.fromJson<String>(json['modelId']),
      totalPhotos: serializer.fromJson<int>(json['totalPhotos']),
      embeddedCount: serializer.fromJson<int>(json['embeddedCount']),
      lastRunMs: serializer.fromJson<int>(json['lastRunMs']),
      modelReady: serializer.fromJson<bool>(json['modelReady']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'modelId': serializer.toJson<String>(modelId),
      'totalPhotos': serializer.toJson<int>(totalPhotos),
      'embeddedCount': serializer.toJson<int>(embeddedCount),
      'lastRunMs': serializer.toJson<int>(lastRunMs),
      'modelReady': serializer.toJson<bool>(modelReady),
    };
  }

  IndexStateRow copyWith({
    int? id,
    String? modelId,
    int? totalPhotos,
    int? embeddedCount,
    int? lastRunMs,
    bool? modelReady,
  }) => IndexStateRow(
    id: id ?? this.id,
    modelId: modelId ?? this.modelId,
    totalPhotos: totalPhotos ?? this.totalPhotos,
    embeddedCount: embeddedCount ?? this.embeddedCount,
    lastRunMs: lastRunMs ?? this.lastRunMs,
    modelReady: modelReady ?? this.modelReady,
  );
  IndexStateRow copyWithCompanion(IndexStateRowsCompanion data) {
    return IndexStateRow(
      id: data.id.present ? data.id.value : this.id,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      totalPhotos: data.totalPhotos.present
          ? data.totalPhotos.value
          : this.totalPhotos,
      embeddedCount: data.embeddedCount.present
          ? data.embeddedCount.value
          : this.embeddedCount,
      lastRunMs: data.lastRunMs.present ? data.lastRunMs.value : this.lastRunMs,
      modelReady: data.modelReady.present
          ? data.modelReady.value
          : this.modelReady,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexStateRow(')
          ..write('id: $id, ')
          ..write('modelId: $modelId, ')
          ..write('totalPhotos: $totalPhotos, ')
          ..write('embeddedCount: $embeddedCount, ')
          ..write('lastRunMs: $lastRunMs, ')
          ..write('modelReady: $modelReady')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    modelId,
    totalPhotos,
    embeddedCount,
    lastRunMs,
    modelReady,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexStateRow &&
          other.id == this.id &&
          other.modelId == this.modelId &&
          other.totalPhotos == this.totalPhotos &&
          other.embeddedCount == this.embeddedCount &&
          other.lastRunMs == this.lastRunMs &&
          other.modelReady == this.modelReady);
}

class IndexStateRowsCompanion extends UpdateCompanion<IndexStateRow> {
  final Value<int> id;
  final Value<String> modelId;
  final Value<int> totalPhotos;
  final Value<int> embeddedCount;
  final Value<int> lastRunMs;
  final Value<bool> modelReady;
  const IndexStateRowsCompanion({
    this.id = const Value.absent(),
    this.modelId = const Value.absent(),
    this.totalPhotos = const Value.absent(),
    this.embeddedCount = const Value.absent(),
    this.lastRunMs = const Value.absent(),
    this.modelReady = const Value.absent(),
  });
  IndexStateRowsCompanion.insert({
    this.id = const Value.absent(),
    this.modelId = const Value.absent(),
    this.totalPhotos = const Value.absent(),
    this.embeddedCount = const Value.absent(),
    this.lastRunMs = const Value.absent(),
    this.modelReady = const Value.absent(),
  });
  static Insertable<IndexStateRow> custom({
    Expression<int>? id,
    Expression<String>? modelId,
    Expression<int>? totalPhotos,
    Expression<int>? embeddedCount,
    Expression<int>? lastRunMs,
    Expression<bool>? modelReady,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modelId != null) 'model_id': modelId,
      if (totalPhotos != null) 'total_photos': totalPhotos,
      if (embeddedCount != null) 'embedded_count': embeddedCount,
      if (lastRunMs != null) 'last_run_ms': lastRunMs,
      if (modelReady != null) 'model_ready': modelReady,
    });
  }

  IndexStateRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? modelId,
    Value<int>? totalPhotos,
    Value<int>? embeddedCount,
    Value<int>? lastRunMs,
    Value<bool>? modelReady,
  }) {
    return IndexStateRowsCompanion(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      embeddedCount: embeddedCount ?? this.embeddedCount,
      lastRunMs: lastRunMs ?? this.lastRunMs,
      modelReady: modelReady ?? this.modelReady,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (totalPhotos.present) {
      map['total_photos'] = Variable<int>(totalPhotos.value);
    }
    if (embeddedCount.present) {
      map['embedded_count'] = Variable<int>(embeddedCount.value);
    }
    if (lastRunMs.present) {
      map['last_run_ms'] = Variable<int>(lastRunMs.value);
    }
    if (modelReady.present) {
      map['model_ready'] = Variable<bool>(modelReady.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexStateRowsCompanion(')
          ..write('id: $id, ')
          ..write('modelId: $modelId, ')
          ..write('totalPhotos: $totalPhotos, ')
          ..write('embeddedCount: $embeddedCount, ')
          ..write('lastRunMs: $lastRunMs, ')
          ..write('modelReady: $modelReady')
          ..write(')'))
        .toString();
  }
}

class $IndexingPreferencesRowsTable extends IndexingPreferencesRows
    with TableInfo<$IndexingPreferencesRowsTable, IndexingPreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexingPreferencesRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allFoldersMeta = const VerificationMeta(
    'allFolders',
  );
  @override
  late final GeneratedColumn<bool> allFolders = GeneratedColumn<bool>(
    'all_folders',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_folders" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _folderIdsJsonMeta = const VerificationMeta(
    'folderIdsJson',
  );
  @override
  late final GeneratedColumn<String> folderIdsJson = GeneratedColumn<String>(
    'folder_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, allFolders, folderIdsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indexing_preferences_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexingPreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('all_folders')) {
      context.handle(
        _allFoldersMeta,
        allFolders.isAcceptableOrUnknown(data['all_folders']!, _allFoldersMeta),
      );
    }
    if (data.containsKey('folder_ids_json')) {
      context.handle(
        _folderIdsJsonMeta,
        folderIdsJson.isAcceptableOrUnknown(
          data['folder_ids_json']!,
          _folderIdsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndexingPreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexingPreferencesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      allFolders: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_folders'],
      )!,
      folderIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_ids_json'],
      )!,
    );
  }

  @override
  $IndexingPreferencesRowsTable createAlias(String alias) {
    return $IndexingPreferencesRowsTable(attachedDatabase, alias);
  }
}

class IndexingPreferencesRow extends DataClass
    implements Insertable<IndexingPreferencesRow> {
  final int id;
  final bool allFolders;
  final String folderIdsJson;
  const IndexingPreferencesRow({
    required this.id,
    required this.allFolders,
    required this.folderIdsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['all_folders'] = Variable<bool>(allFolders);
    map['folder_ids_json'] = Variable<String>(folderIdsJson);
    return map;
  }

  IndexingPreferencesRowsCompanion toCompanion(bool nullToAbsent) {
    return IndexingPreferencesRowsCompanion(
      id: Value(id),
      allFolders: Value(allFolders),
      folderIdsJson: Value(folderIdsJson),
    );
  }

  factory IndexingPreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexingPreferencesRow(
      id: serializer.fromJson<int>(json['id']),
      allFolders: serializer.fromJson<bool>(json['allFolders']),
      folderIdsJson: serializer.fromJson<String>(json['folderIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'allFolders': serializer.toJson<bool>(allFolders),
      'folderIdsJson': serializer.toJson<String>(folderIdsJson),
    };
  }

  IndexingPreferencesRow copyWith({
    int? id,
    bool? allFolders,
    String? folderIdsJson,
  }) => IndexingPreferencesRow(
    id: id ?? this.id,
    allFolders: allFolders ?? this.allFolders,
    folderIdsJson: folderIdsJson ?? this.folderIdsJson,
  );
  IndexingPreferencesRow copyWithCompanion(
    IndexingPreferencesRowsCompanion data,
  ) {
    return IndexingPreferencesRow(
      id: data.id.present ? data.id.value : this.id,
      allFolders: data.allFolders.present
          ? data.allFolders.value
          : this.allFolders,
      folderIdsJson: data.folderIdsJson.present
          ? data.folderIdsJson.value
          : this.folderIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexingPreferencesRow(')
          ..write('id: $id, ')
          ..write('allFolders: $allFolders, ')
          ..write('folderIdsJson: $folderIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, allFolders, folderIdsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexingPreferencesRow &&
          other.id == this.id &&
          other.allFolders == this.allFolders &&
          other.folderIdsJson == this.folderIdsJson);
}

class IndexingPreferencesRowsCompanion
    extends UpdateCompanion<IndexingPreferencesRow> {
  final Value<int> id;
  final Value<bool> allFolders;
  final Value<String> folderIdsJson;
  const IndexingPreferencesRowsCompanion({
    this.id = const Value.absent(),
    this.allFolders = const Value.absent(),
    this.folderIdsJson = const Value.absent(),
  });
  IndexingPreferencesRowsCompanion.insert({
    this.id = const Value.absent(),
    this.allFolders = const Value.absent(),
    this.folderIdsJson = const Value.absent(),
  });
  static Insertable<IndexingPreferencesRow> custom({
    Expression<int>? id,
    Expression<bool>? allFolders,
    Expression<String>? folderIdsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (allFolders != null) 'all_folders': allFolders,
      if (folderIdsJson != null) 'folder_ids_json': folderIdsJson,
    });
  }

  IndexingPreferencesRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? allFolders,
    Value<String>? folderIdsJson,
  }) {
    return IndexingPreferencesRowsCompanion(
      id: id ?? this.id,
      allFolders: allFolders ?? this.allFolders,
      folderIdsJson: folderIdsJson ?? this.folderIdsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (allFolders.present) {
      map['all_folders'] = Variable<bool>(allFolders.value);
    }
    if (folderIdsJson.present) {
      map['folder_ids_json'] = Variable<String>(folderIdsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexingPreferencesRowsCompanion(')
          ..write('id: $id, ')
          ..write('allFolders: $allFolders, ')
          ..write('folderIdsJson: $folderIdsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PhotoRowsTable photoRows = $PhotoRowsTable(this);
  late final $EmbeddingRowsTable embeddingRows = $EmbeddingRowsTable(this);
  late final $IndexStateRowsTable indexStateRows = $IndexStateRowsTable(this);
  late final $IndexingPreferencesRowsTable indexingPreferencesRows =
      $IndexingPreferencesRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    photoRows,
    embeddingRows,
    indexStateRows,
    indexingPreferencesRows,
  ];
}

typedef $$PhotoRowsTableCreateCompanionBuilder =
    PhotoRowsCompanion Function({
      required String id,
      required int source,
      Value<String?> assetName,
      Value<String> title,
      Value<String> caption,
      Value<String> tagsJson,
      required int dateMs,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> place,
      Value<String> album,
      Value<int> createdAtMs,
      Value<int> mtimeMs,
      Value<int> byteSize,
      Value<int> width,
      Value<int> height,
      Value<String?> thumbPath,
      Value<String> labelsJson,
      Value<String> facesJson,
      Value<int> indexedAtMs,
      Value<int> rowid,
    });
typedef $$PhotoRowsTableUpdateCompanionBuilder =
    PhotoRowsCompanion Function({
      Value<String> id,
      Value<int> source,
      Value<String?> assetName,
      Value<String> title,
      Value<String> caption,
      Value<String> tagsJson,
      Value<int> dateMs,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> place,
      Value<String> album,
      Value<int> createdAtMs,
      Value<int> mtimeMs,
      Value<int> byteSize,
      Value<int> width,
      Value<int> height,
      Value<String?> thumbPath,
      Value<String> labelsJson,
      Value<String> facesJson,
      Value<int> indexedAtMs,
      Value<int> rowid,
    });

class $$PhotoRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoRowsTable> {
  $$PhotoRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateMs => $composableBuilder(
    column: $table.dateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelsJson => $composableBuilder(
    column: $table.labelsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facesJson => $composableBuilder(
    column: $table.facesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotoRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoRowsTable> {
  $$PhotoRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateMs => $composableBuilder(
    column: $table.dateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelsJson => $composableBuilder(
    column: $table.labelsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facesJson => $composableBuilder(
    column: $table.facesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotoRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoRowsTable> {
  $$PhotoRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get assetName =>
      $composableBuilder(column: $table.assetName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get dateMs =>
      $composableBuilder(column: $table.dateMs, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mtimeMs =>
      $composableBuilder(column: $table.mtimeMs, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get labelsJson => $composableBuilder(
    column: $table.labelsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get facesJson =>
      $composableBuilder(column: $table.facesJson, builder: (column) => column);

  GeneratedColumn<int> get indexedAtMs => $composableBuilder(
    column: $table.indexedAtMs,
    builder: (column) => column,
  );
}

class $$PhotoRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotoRowsTable,
          PhotoRow,
          $$PhotoRowsTableFilterComposer,
          $$PhotoRowsTableOrderingComposer,
          $$PhotoRowsTableAnnotationComposer,
          $$PhotoRowsTableCreateCompanionBuilder,
          $$PhotoRowsTableUpdateCompanionBuilder,
          (PhotoRow, BaseReferences<_$AppDatabase, $PhotoRowsTable, PhotoRow>),
          PhotoRow,
          PrefetchHooks Function()
        > {
  $$PhotoRowsTableTableManager(_$AppDatabase db, $PhotoRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<String?> assetName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<int> dateMs = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> mtimeMs = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String> labelsJson = const Value.absent(),
                Value<String> facesJson = const Value.absent(),
                Value<int> indexedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoRowsCompanion(
                id: id,
                source: source,
                assetName: assetName,
                title: title,
                caption: caption,
                tagsJson: tagsJson,
                dateMs: dateMs,
                lat: lat,
                lng: lng,
                place: place,
                album: album,
                createdAtMs: createdAtMs,
                mtimeMs: mtimeMs,
                byteSize: byteSize,
                width: width,
                height: height,
                thumbPath: thumbPath,
                labelsJson: labelsJson,
                facesJson: facesJson,
                indexedAtMs: indexedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int source,
                Value<String?> assetName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required int dateMs,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> mtimeMs = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String> labelsJson = const Value.absent(),
                Value<String> facesJson = const Value.absent(),
                Value<int> indexedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoRowsCompanion.insert(
                id: id,
                source: source,
                assetName: assetName,
                title: title,
                caption: caption,
                tagsJson: tagsJson,
                dateMs: dateMs,
                lat: lat,
                lng: lng,
                place: place,
                album: album,
                createdAtMs: createdAtMs,
                mtimeMs: mtimeMs,
                byteSize: byteSize,
                width: width,
                height: height,
                thumbPath: thumbPath,
                labelsJson: labelsJson,
                facesJson: facesJson,
                indexedAtMs: indexedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotoRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotoRowsTable,
      PhotoRow,
      $$PhotoRowsTableFilterComposer,
      $$PhotoRowsTableOrderingComposer,
      $$PhotoRowsTableAnnotationComposer,
      $$PhotoRowsTableCreateCompanionBuilder,
      $$PhotoRowsTableUpdateCompanionBuilder,
      (PhotoRow, BaseReferences<_$AppDatabase, $PhotoRowsTable, PhotoRow>),
      PhotoRow,
      PrefetchHooks Function()
    >;
typedef $$EmbeddingRowsTableCreateCompanionBuilder =
    EmbeddingRowsCompanion Function({
      required String photoId,
      required String modelId,
      Value<String> embeddingVersion,
      required int dim,
      required Uint8List vector,
      Value<int> createdAtMs,
      Value<int> rowid,
    });
typedef $$EmbeddingRowsTableUpdateCompanionBuilder =
    EmbeddingRowsCompanion Function({
      Value<String> photoId,
      Value<String> modelId,
      Value<String> embeddingVersion,
      Value<int> dim,
      Value<Uint8List> vector,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$EmbeddingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $EmbeddingRowsTable> {
  $$EmbeddingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingVersion => $composableBuilder(
    column: $table.embeddingVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmbeddingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmbeddingRowsTable> {
  $$EmbeddingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingVersion => $composableBuilder(
    column: $table.embeddingVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmbeddingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmbeddingRowsTable> {
  $$EmbeddingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get embeddingVersion => $composableBuilder(
    column: $table.embeddingVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dim =>
      $composableBuilder(column: $table.dim, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$EmbeddingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmbeddingRowsTable,
          EmbeddingRow,
          $$EmbeddingRowsTableFilterComposer,
          $$EmbeddingRowsTableOrderingComposer,
          $$EmbeddingRowsTableAnnotationComposer,
          $$EmbeddingRowsTableCreateCompanionBuilder,
          $$EmbeddingRowsTableUpdateCompanionBuilder,
          (
            EmbeddingRow,
            BaseReferences<_$AppDatabase, $EmbeddingRowsTable, EmbeddingRow>,
          ),
          EmbeddingRow,
          PrefetchHooks Function()
        > {
  $$EmbeddingRowsTableTableManager(_$AppDatabase db, $EmbeddingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmbeddingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmbeddingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmbeddingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> embeddingVersion = const Value.absent(),
                Value<int> dim = const Value.absent(),
                Value<Uint8List> vector = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmbeddingRowsCompanion(
                photoId: photoId,
                modelId: modelId,
                embeddingVersion: embeddingVersion,
                dim: dim,
                vector: vector,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required String modelId,
                Value<String> embeddingVersion = const Value.absent(),
                required int dim,
                required Uint8List vector,
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmbeddingRowsCompanion.insert(
                photoId: photoId,
                modelId: modelId,
                embeddingVersion: embeddingVersion,
                dim: dim,
                vector: vector,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmbeddingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmbeddingRowsTable,
      EmbeddingRow,
      $$EmbeddingRowsTableFilterComposer,
      $$EmbeddingRowsTableOrderingComposer,
      $$EmbeddingRowsTableAnnotationComposer,
      $$EmbeddingRowsTableCreateCompanionBuilder,
      $$EmbeddingRowsTableUpdateCompanionBuilder,
      (
        EmbeddingRow,
        BaseReferences<_$AppDatabase, $EmbeddingRowsTable, EmbeddingRow>,
      ),
      EmbeddingRow,
      PrefetchHooks Function()
    >;
typedef $$IndexStateRowsTableCreateCompanionBuilder =
    IndexStateRowsCompanion Function({
      Value<int> id,
      Value<String> modelId,
      Value<int> totalPhotos,
      Value<int> embeddedCount,
      Value<int> lastRunMs,
      Value<bool> modelReady,
    });
typedef $$IndexStateRowsTableUpdateCompanionBuilder =
    IndexStateRowsCompanion Function({
      Value<int> id,
      Value<String> modelId,
      Value<int> totalPhotos,
      Value<int> embeddedCount,
      Value<int> lastRunMs,
      Value<bool> modelReady,
    });

class $$IndexStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $IndexStateRowsTable> {
  $$IndexStateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPhotos => $composableBuilder(
    column: $table.totalPhotos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get embeddedCount => $composableBuilder(
    column: $table.embeddedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRunMs => $composableBuilder(
    column: $table.lastRunMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get modelReady => $composableBuilder(
    column: $table.modelReady,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndexStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexStateRowsTable> {
  $$IndexStateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPhotos => $composableBuilder(
    column: $table.totalPhotos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embeddedCount => $composableBuilder(
    column: $table.embeddedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRunMs => $composableBuilder(
    column: $table.lastRunMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get modelReady => $composableBuilder(
    column: $table.modelReady,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndexStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexStateRowsTable> {
  $$IndexStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get totalPhotos => $composableBuilder(
    column: $table.totalPhotos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get embeddedCount => $composableBuilder(
    column: $table.embeddedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRunMs =>
      $composableBuilder(column: $table.lastRunMs, builder: (column) => column);

  GeneratedColumn<bool> get modelReady => $composableBuilder(
    column: $table.modelReady,
    builder: (column) => column,
  );
}

class $$IndexStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndexStateRowsTable,
          IndexStateRow,
          $$IndexStateRowsTableFilterComposer,
          $$IndexStateRowsTableOrderingComposer,
          $$IndexStateRowsTableAnnotationComposer,
          $$IndexStateRowsTableCreateCompanionBuilder,
          $$IndexStateRowsTableUpdateCompanionBuilder,
          (
            IndexStateRow,
            BaseReferences<_$AppDatabase, $IndexStateRowsTable, IndexStateRow>,
          ),
          IndexStateRow,
          PrefetchHooks Function()
        > {
  $$IndexStateRowsTableTableManager(
    _$AppDatabase db,
    $IndexStateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<int> totalPhotos = const Value.absent(),
                Value<int> embeddedCount = const Value.absent(),
                Value<int> lastRunMs = const Value.absent(),
                Value<bool> modelReady = const Value.absent(),
              }) => IndexStateRowsCompanion(
                id: id,
                modelId: modelId,
                totalPhotos: totalPhotos,
                embeddedCount: embeddedCount,
                lastRunMs: lastRunMs,
                modelReady: modelReady,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<int> totalPhotos = const Value.absent(),
                Value<int> embeddedCount = const Value.absent(),
                Value<int> lastRunMs = const Value.absent(),
                Value<bool> modelReady = const Value.absent(),
              }) => IndexStateRowsCompanion.insert(
                id: id,
                modelId: modelId,
                totalPhotos: totalPhotos,
                embeddedCount: embeddedCount,
                lastRunMs: lastRunMs,
                modelReady: modelReady,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndexStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndexStateRowsTable,
      IndexStateRow,
      $$IndexStateRowsTableFilterComposer,
      $$IndexStateRowsTableOrderingComposer,
      $$IndexStateRowsTableAnnotationComposer,
      $$IndexStateRowsTableCreateCompanionBuilder,
      $$IndexStateRowsTableUpdateCompanionBuilder,
      (
        IndexStateRow,
        BaseReferences<_$AppDatabase, $IndexStateRowsTable, IndexStateRow>,
      ),
      IndexStateRow,
      PrefetchHooks Function()
    >;
typedef $$IndexingPreferencesRowsTableCreateCompanionBuilder =
    IndexingPreferencesRowsCompanion Function({
      Value<int> id,
      Value<bool> allFolders,
      Value<String> folderIdsJson,
    });
typedef $$IndexingPreferencesRowsTableUpdateCompanionBuilder =
    IndexingPreferencesRowsCompanion Function({
      Value<int> id,
      Value<bool> allFolders,
      Value<String> folderIdsJson,
    });

class $$IndexingPreferencesRowsTableFilterComposer
    extends Composer<_$AppDatabase, $IndexingPreferencesRowsTable> {
  $$IndexingPreferencesRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allFolders => $composableBuilder(
    column: $table.allFolders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderIdsJson => $composableBuilder(
    column: $table.folderIdsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndexingPreferencesRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexingPreferencesRowsTable> {
  $$IndexingPreferencesRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allFolders => $composableBuilder(
    column: $table.allFolders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderIdsJson => $composableBuilder(
    column: $table.folderIdsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndexingPreferencesRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexingPreferencesRowsTable> {
  $$IndexingPreferencesRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get allFolders => $composableBuilder(
    column: $table.allFolders,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderIdsJson => $composableBuilder(
    column: $table.folderIdsJson,
    builder: (column) => column,
  );
}

class $$IndexingPreferencesRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndexingPreferencesRowsTable,
          IndexingPreferencesRow,
          $$IndexingPreferencesRowsTableFilterComposer,
          $$IndexingPreferencesRowsTableOrderingComposer,
          $$IndexingPreferencesRowsTableAnnotationComposer,
          $$IndexingPreferencesRowsTableCreateCompanionBuilder,
          $$IndexingPreferencesRowsTableUpdateCompanionBuilder,
          (
            IndexingPreferencesRow,
            BaseReferences<
              _$AppDatabase,
              $IndexingPreferencesRowsTable,
              IndexingPreferencesRow
            >,
          ),
          IndexingPreferencesRow,
          PrefetchHooks Function()
        > {
  $$IndexingPreferencesRowsTableTableManager(
    _$AppDatabase db,
    $IndexingPreferencesRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexingPreferencesRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IndexingPreferencesRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IndexingPreferencesRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> allFolders = const Value.absent(),
                Value<String> folderIdsJson = const Value.absent(),
              }) => IndexingPreferencesRowsCompanion(
                id: id,
                allFolders: allFolders,
                folderIdsJson: folderIdsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> allFolders = const Value.absent(),
                Value<String> folderIdsJson = const Value.absent(),
              }) => IndexingPreferencesRowsCompanion.insert(
                id: id,
                allFolders: allFolders,
                folderIdsJson: folderIdsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndexingPreferencesRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndexingPreferencesRowsTable,
      IndexingPreferencesRow,
      $$IndexingPreferencesRowsTableFilterComposer,
      $$IndexingPreferencesRowsTableOrderingComposer,
      $$IndexingPreferencesRowsTableAnnotationComposer,
      $$IndexingPreferencesRowsTableCreateCompanionBuilder,
      $$IndexingPreferencesRowsTableUpdateCompanionBuilder,
      (
        IndexingPreferencesRow,
        BaseReferences<
          _$AppDatabase,
          $IndexingPreferencesRowsTable,
          IndexingPreferencesRow
        >,
      ),
      IndexingPreferencesRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PhotoRowsTableTableManager get photoRows =>
      $$PhotoRowsTableTableManager(_db, _db.photoRows);
  $$EmbeddingRowsTableTableManager get embeddingRows =>
      $$EmbeddingRowsTableTableManager(_db, _db.embeddingRows);
  $$IndexStateRowsTableTableManager get indexStateRows =>
      $$IndexStateRowsTableTableManager(_db, _db.indexStateRows);
  $$IndexingPreferencesRowsTableTableManager get indexingPreferencesRows =>
      $$IndexingPreferencesRowsTableTableManager(
        _db,
        _db.indexingPreferencesRows,
      );
}
