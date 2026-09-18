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

class $MemoryEventsTable extends MemoryEvents
    with TableInfo<$MemoryEventsTable, MemoryEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _coverIdMeta = const VerificationMeta(
    'coverId',
  );
  @override
  late final GeneratedColumn<String> coverId = GeneratedColumn<String>(
    'cover_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMsMeta = const VerificationMeta(
    'createdMs',
  );
  @override
  late final GeneratedColumn<int> createdMs = GeneratedColumn<int>(
    'created_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, coverId, createdMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('cover_id')) {
      context.handle(
        _coverIdMeta,
        coverId.isAcceptableOrUnknown(data['cover_id']!, _coverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coverIdMeta);
    }
    if (data.containsKey('created_ms')) {
      context.handle(
        _createdMsMeta,
        createdMs.isAcceptableOrUnknown(data['created_ms']!, _createdMsMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_id'],
      )!,
      createdMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_ms'],
      )!,
    );
  }

  @override
  $MemoryEventsTable createAlias(String alias) {
    return $MemoryEventsTable(attachedDatabase, alias);
  }
}

class MemoryEvent extends DataClass implements Insertable<MemoryEvent> {
  final String id;
  final String title;
  final String coverId;
  final int createdMs;
  const MemoryEvent({
    required this.id,
    required this.title,
    required this.coverId,
    required this.createdMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['cover_id'] = Variable<String>(coverId);
    map['created_ms'] = Variable<int>(createdMs);
    return map;
  }

  MemoryEventsCompanion toCompanion(bool nullToAbsent) {
    return MemoryEventsCompanion(
      id: Value(id),
      title: Value(title),
      coverId: Value(coverId),
      createdMs: Value(createdMs),
    );
  }

  factory MemoryEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      coverId: serializer.fromJson<String>(json['coverId']),
      createdMs: serializer.fromJson<int>(json['createdMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'coverId': serializer.toJson<String>(coverId),
      'createdMs': serializer.toJson<int>(createdMs),
    };
  }

  MemoryEvent copyWith({
    String? id,
    String? title,
    String? coverId,
    int? createdMs,
  }) => MemoryEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    coverId: coverId ?? this.coverId,
    createdMs: createdMs ?? this.createdMs,
  );
  MemoryEvent copyWithCompanion(MemoryEventsCompanion data) {
    return MemoryEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      coverId: data.coverId.present ? data.coverId.value : this.coverId,
      createdMs: data.createdMs.present ? data.createdMs.value : this.createdMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverId: $coverId, ')
          ..write('createdMs: $createdMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, coverId, createdMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.coverId == this.coverId &&
          other.createdMs == this.createdMs);
}

class MemoryEventsCompanion extends UpdateCompanion<MemoryEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> coverId;
  final Value<int> createdMs;
  final Value<int> rowid;
  const MemoryEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.coverId = const Value.absent(),
    this.createdMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryEventsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required String coverId,
    required int createdMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       coverId = Value(coverId),
       createdMs = Value(createdMs);
  static Insertable<MemoryEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? coverId,
    Expression<int>? createdMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (coverId != null) 'cover_id': coverId,
      if (createdMs != null) 'created_ms': createdMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? coverId,
    Value<int>? createdMs,
    Value<int>? rowid,
  }) {
    return MemoryEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      coverId: coverId ?? this.coverId,
      createdMs: createdMs ?? this.createdMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverId.present) {
      map['cover_id'] = Variable<String>(coverId.value);
    }
    if (createdMs.present) {
      map['created_ms'] = Variable<int>(createdMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverId: $coverId, ')
          ..write('createdMs: $createdMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryMembersTable extends MemoryMembers
    with TableInfo<$MemoryMembersTable, MemoryMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryMembersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [photoId, eventId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryMember> instance, {
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
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  MemoryMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryMember(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
    );
  }

  @override
  $MemoryMembersTable createAlias(String alias) {
    return $MemoryMembersTable(attachedDatabase, alias);
  }
}

class MemoryMember extends DataClass implements Insertable<MemoryMember> {
  final String photoId;
  final String eventId;
  const MemoryMember({required this.photoId, required this.eventId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['event_id'] = Variable<String>(eventId);
    return map;
  }

  MemoryMembersCompanion toCompanion(bool nullToAbsent) {
    return MemoryMembersCompanion(
      photoId: Value(photoId),
      eventId: Value(eventId),
    );
  }

  factory MemoryMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryMember(
      photoId: serializer.fromJson<String>(json['photoId']),
      eventId: serializer.fromJson<String>(json['eventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'eventId': serializer.toJson<String>(eventId),
    };
  }

  MemoryMember copyWith({String? photoId, String? eventId}) => MemoryMember(
    photoId: photoId ?? this.photoId,
    eventId: eventId ?? this.eventId,
  );
  MemoryMember copyWithCompanion(MemoryMembersCompanion data) {
    return MemoryMember(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryMember(')
          ..write('photoId: $photoId, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(photoId, eventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryMember &&
          other.photoId == this.photoId &&
          other.eventId == this.eventId);
}

class MemoryMembersCompanion extends UpdateCompanion<MemoryMember> {
  final Value<String> photoId;
  final Value<String> eventId;
  final Value<int> rowid;
  const MemoryMembersCompanion({
    this.photoId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryMembersCompanion.insert({
    required String photoId,
    required String eventId,
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       eventId = Value(eventId);
  static Insertable<MemoryMember> custom({
    Expression<String>? photoId,
    Expression<String>? eventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (eventId != null) 'event_id': eventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryMembersCompanion copyWith({
    Value<String>? photoId,
    Value<String>? eventId,
    Value<int>? rowid,
  }) {
    return MemoryMembersCompanion(
      photoId: photoId ?? this.photoId,
      eventId: eventId ?? this.eventId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryMembersCompanion(')
          ..write('photoId: $photoId, ')
          ..write('eventId: $eventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedCaptionsTable extends SavedCaptions
    with TableInfo<$SavedCaptionsTable, SavedCaption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedCaptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCaptionMeta = const VerificationMeta(
    'baseCaption',
  );
  @override
  late final GeneratedColumn<String> baseCaption = GeneratedColumn<String>(
    'base_caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedCaptionMeta = const VerificationMeta(
    'editedCaption',
  );
  @override
  late final GeneratedColumn<String> editedCaption = GeneratedColumn<String>(
    'edited_caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('groq'),
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('factual'),
  );
  static const VerificationMeta _manuallyEditedMeta = const VerificationMeta(
    'manuallyEdited',
  );
  @override
  late final GeneratedColumn<bool> manuallyEdited = GeneratedColumn<bool>(
    'manually_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manually_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _generatedMsMeta = const VerificationMeta(
    'generatedMs',
  );
  @override
  late final GeneratedColumn<int> generatedMs = GeneratedColumn<int>(
    'generated_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    revision,
    baseCaption,
    editedCaption,
    model,
    provider,
    style,
    manuallyEdited,
    generatedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_captions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedCaption> instance, {
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('base_caption')) {
      context.handle(
        _baseCaptionMeta,
        baseCaption.isAcceptableOrUnknown(
          data['base_caption']!,
          _baseCaptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCaptionMeta);
    }
    if (data.containsKey('edited_caption')) {
      context.handle(
        _editedCaptionMeta,
        editedCaption.isAcceptableOrUnknown(
          data['edited_caption']!,
          _editedCaptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_editedCaptionMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('manually_edited')) {
      context.handle(
        _manuallyEditedMeta,
        manuallyEdited.isAcceptableOrUnknown(
          data['manually_edited']!,
          _manuallyEditedMeta,
        ),
      );
    }
    if (data.containsKey('generated_ms')) {
      context.handle(
        _generatedMsMeta,
        generatedMs.isAcceptableOrUnknown(
          data['generated_ms']!,
          _generatedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  SavedCaption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedCaption(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      baseCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_caption'],
      )!,
      editedCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edited_caption'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      manuallyEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manually_edited'],
      )!,
      generatedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generated_ms'],
      )!,
    );
  }

  @override
  $SavedCaptionsTable createAlias(String alias) {
    return $SavedCaptionsTable(attachedDatabase, alias);
  }
}

class SavedCaption extends DataClass implements Insertable<SavedCaption> {
  final String photoId;
  final int revision;
  final String baseCaption;
  final String editedCaption;
  final String model;
  final String provider;
  final String style;
  final bool manuallyEdited;
  final int generatedMs;
  const SavedCaption({
    required this.photoId,
    required this.revision,
    required this.baseCaption,
    required this.editedCaption,
    required this.model,
    required this.provider,
    required this.style,
    required this.manuallyEdited,
    required this.generatedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['revision'] = Variable<int>(revision);
    map['base_caption'] = Variable<String>(baseCaption);
    map['edited_caption'] = Variable<String>(editedCaption);
    map['model'] = Variable<String>(model);
    map['provider'] = Variable<String>(provider);
    map['style'] = Variable<String>(style);
    map['manually_edited'] = Variable<bool>(manuallyEdited);
    map['generated_ms'] = Variable<int>(generatedMs);
    return map;
  }

  SavedCaptionsCompanion toCompanion(bool nullToAbsent) {
    return SavedCaptionsCompanion(
      photoId: Value(photoId),
      revision: Value(revision),
      baseCaption: Value(baseCaption),
      editedCaption: Value(editedCaption),
      model: Value(model),
      provider: Value(provider),
      style: Value(style),
      manuallyEdited: Value(manuallyEdited),
      generatedMs: Value(generatedMs),
    );
  }

  factory SavedCaption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedCaption(
      photoId: serializer.fromJson<String>(json['photoId']),
      revision: serializer.fromJson<int>(json['revision']),
      baseCaption: serializer.fromJson<String>(json['baseCaption']),
      editedCaption: serializer.fromJson<String>(json['editedCaption']),
      model: serializer.fromJson<String>(json['model']),
      provider: serializer.fromJson<String>(json['provider']),
      style: serializer.fromJson<String>(json['style']),
      manuallyEdited: serializer.fromJson<bool>(json['manuallyEdited']),
      generatedMs: serializer.fromJson<int>(json['generatedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'revision': serializer.toJson<int>(revision),
      'baseCaption': serializer.toJson<String>(baseCaption),
      'editedCaption': serializer.toJson<String>(editedCaption),
      'model': serializer.toJson<String>(model),
      'provider': serializer.toJson<String>(provider),
      'style': serializer.toJson<String>(style),
      'manuallyEdited': serializer.toJson<bool>(manuallyEdited),
      'generatedMs': serializer.toJson<int>(generatedMs),
    };
  }

  SavedCaption copyWith({
    String? photoId,
    int? revision,
    String? baseCaption,
    String? editedCaption,
    String? model,
    String? provider,
    String? style,
    bool? manuallyEdited,
    int? generatedMs,
  }) => SavedCaption(
    photoId: photoId ?? this.photoId,
    revision: revision ?? this.revision,
    baseCaption: baseCaption ?? this.baseCaption,
    editedCaption: editedCaption ?? this.editedCaption,
    model: model ?? this.model,
    provider: provider ?? this.provider,
    style: style ?? this.style,
    manuallyEdited: manuallyEdited ?? this.manuallyEdited,
    generatedMs: generatedMs ?? this.generatedMs,
  );
  SavedCaption copyWithCompanion(SavedCaptionsCompanion data) {
    return SavedCaption(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      revision: data.revision.present ? data.revision.value : this.revision,
      baseCaption: data.baseCaption.present
          ? data.baseCaption.value
          : this.baseCaption,
      editedCaption: data.editedCaption.present
          ? data.editedCaption.value
          : this.editedCaption,
      model: data.model.present ? data.model.value : this.model,
      provider: data.provider.present ? data.provider.value : this.provider,
      style: data.style.present ? data.style.value : this.style,
      manuallyEdited: data.manuallyEdited.present
          ? data.manuallyEdited.value
          : this.manuallyEdited,
      generatedMs: data.generatedMs.present
          ? data.generatedMs.value
          : this.generatedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedCaption(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('baseCaption: $baseCaption, ')
          ..write('editedCaption: $editedCaption, ')
          ..write('model: $model, ')
          ..write('provider: $provider, ')
          ..write('style: $style, ')
          ..write('manuallyEdited: $manuallyEdited, ')
          ..write('generatedMs: $generatedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    photoId,
    revision,
    baseCaption,
    editedCaption,
    model,
    provider,
    style,
    manuallyEdited,
    generatedMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedCaption &&
          other.photoId == this.photoId &&
          other.revision == this.revision &&
          other.baseCaption == this.baseCaption &&
          other.editedCaption == this.editedCaption &&
          other.model == this.model &&
          other.provider == this.provider &&
          other.style == this.style &&
          other.manuallyEdited == this.manuallyEdited &&
          other.generatedMs == this.generatedMs);
}

class SavedCaptionsCompanion extends UpdateCompanion<SavedCaption> {
  final Value<String> photoId;
  final Value<int> revision;
  final Value<String> baseCaption;
  final Value<String> editedCaption;
  final Value<String> model;
  final Value<String> provider;
  final Value<String> style;
  final Value<bool> manuallyEdited;
  final Value<int> generatedMs;
  final Value<int> rowid;
  const SavedCaptionsCompanion({
    this.photoId = const Value.absent(),
    this.revision = const Value.absent(),
    this.baseCaption = const Value.absent(),
    this.editedCaption = const Value.absent(),
    this.model = const Value.absent(),
    this.provider = const Value.absent(),
    this.style = const Value.absent(),
    this.manuallyEdited = const Value.absent(),
    this.generatedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedCaptionsCompanion.insert({
    required String photoId,
    required int revision,
    required String baseCaption,
    required String editedCaption,
    required String model,
    this.provider = const Value.absent(),
    this.style = const Value.absent(),
    this.manuallyEdited = const Value.absent(),
    required int generatedMs,
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       revision = Value(revision),
       baseCaption = Value(baseCaption),
       editedCaption = Value(editedCaption),
       model = Value(model),
       generatedMs = Value(generatedMs);
  static Insertable<SavedCaption> custom({
    Expression<String>? photoId,
    Expression<int>? revision,
    Expression<String>? baseCaption,
    Expression<String>? editedCaption,
    Expression<String>? model,
    Expression<String>? provider,
    Expression<String>? style,
    Expression<bool>? manuallyEdited,
    Expression<int>? generatedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (revision != null) 'revision': revision,
      if (baseCaption != null) 'base_caption': baseCaption,
      if (editedCaption != null) 'edited_caption': editedCaption,
      if (model != null) 'model': model,
      if (provider != null) 'provider': provider,
      if (style != null) 'style': style,
      if (manuallyEdited != null) 'manually_edited': manuallyEdited,
      if (generatedMs != null) 'generated_ms': generatedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedCaptionsCompanion copyWith({
    Value<String>? photoId,
    Value<int>? revision,
    Value<String>? baseCaption,
    Value<String>? editedCaption,
    Value<String>? model,
    Value<String>? provider,
    Value<String>? style,
    Value<bool>? manuallyEdited,
    Value<int>? generatedMs,
    Value<int>? rowid,
  }) {
    return SavedCaptionsCompanion(
      photoId: photoId ?? this.photoId,
      revision: revision ?? this.revision,
      baseCaption: baseCaption ?? this.baseCaption,
      editedCaption: editedCaption ?? this.editedCaption,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      style: style ?? this.style,
      manuallyEdited: manuallyEdited ?? this.manuallyEdited,
      generatedMs: generatedMs ?? this.generatedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (baseCaption.present) {
      map['base_caption'] = Variable<String>(baseCaption.value);
    }
    if (editedCaption.present) {
      map['edited_caption'] = Variable<String>(editedCaption.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (manuallyEdited.present) {
      map['manually_edited'] = Variable<bool>(manuallyEdited.value);
    }
    if (generatedMs.present) {
      map['generated_ms'] = Variable<int>(generatedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedCaptionsCompanion(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('baseCaption: $baseCaption, ')
          ..write('editedCaption: $editedCaption, ')
          ..write('model: $model, ')
          ..write('provider: $provider, ')
          ..write('style: $style, ')
          ..write('manuallyEdited: $manuallyEdited, ')
          ..write('generatedMs: $generatedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoLocationsTable extends PhotoLocations
    with TableInfo<$PhotoLocationsTable, PhotoLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoLocationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EXIF GPS'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    revision,
    latitude,
    longitude,
    status,
    provenance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoLocation> instance, {
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  PhotoLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoLocation(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
    );
  }

  @override
  $PhotoLocationsTable createAlias(String alias) {
    return $PhotoLocationsTable(attachedDatabase, alias);
  }
}

class PhotoLocation extends DataClass implements Insertable<PhotoLocation> {
  final String photoId;
  final int revision;
  final double? latitude;
  final double? longitude;
  final String status;
  final String provenance;
  const PhotoLocation({
    required this.photoId,
    required this.revision,
    this.latitude,
    this.longitude,
    required this.status,
    required this.provenance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['status'] = Variable<String>(status);
    map['provenance'] = Variable<String>(provenance);
    return map;
  }

  PhotoLocationsCompanion toCompanion(bool nullToAbsent) {
    return PhotoLocationsCompanion(
      photoId: Value(photoId),
      revision: Value(revision),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      status: Value(status),
      provenance: Value(provenance),
    );
  }

  factory PhotoLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoLocation(
      photoId: serializer.fromJson<String>(json['photoId']),
      revision: serializer.fromJson<int>(json['revision']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      status: serializer.fromJson<String>(json['status']),
      provenance: serializer.fromJson<String>(json['provenance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'revision': serializer.toJson<int>(revision),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'status': serializer.toJson<String>(status),
      'provenance': serializer.toJson<String>(provenance),
    };
  }

  PhotoLocation copyWith({
    String? photoId,
    int? revision,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    String? status,
    String? provenance,
  }) => PhotoLocation(
    photoId: photoId ?? this.photoId,
    revision: revision ?? this.revision,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    status: status ?? this.status,
    provenance: provenance ?? this.provenance,
  );
  PhotoLocation copyWithCompanion(PhotoLocationsCompanion data) {
    return PhotoLocation(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      revision: data.revision.present ? data.revision.value : this.revision,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      status: data.status.present ? data.status.value : this.status,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoLocation(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('status: $status, ')
          ..write('provenance: $provenance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(photoId, revision, latitude, longitude, status, provenance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoLocation &&
          other.photoId == this.photoId &&
          other.revision == this.revision &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.status == this.status &&
          other.provenance == this.provenance);
}

class PhotoLocationsCompanion extends UpdateCompanion<PhotoLocation> {
  final Value<String> photoId;
  final Value<int> revision;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String> status;
  final Value<String> provenance;
  final Value<int> rowid;
  const PhotoLocationsCompanion({
    this.photoId = const Value.absent(),
    this.revision = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.status = const Value.absent(),
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoLocationsCompanion.insert({
    required String photoId,
    required int revision,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required String status,
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       revision = Value(revision),
       status = Value(status);
  static Insertable<PhotoLocation> custom({
    Expression<String>? photoId,
    Expression<int>? revision,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? status,
    Expression<String>? provenance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (revision != null) 'revision': revision,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (status != null) 'status': status,
      if (provenance != null) 'provenance': provenance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoLocationsCompanion copyWith({
    Value<String>? photoId,
    Value<int>? revision,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String>? status,
    Value<String>? provenance,
    Value<int>? rowid,
  }) {
    return PhotoLocationsCompanion(
      photoId: photoId ?? this.photoId,
      revision: revision ?? this.revision,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      provenance: provenance ?? this.provenance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoLocationsCompanion(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('status: $status, ')
          ..write('provenance: $provenance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeoplePersonsTable extends PeoplePersons
    with TableInfo<$PeoplePersonsTable, PersonRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeoplePersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _aliasesJsonMeta = const VerificationMeta(
    'aliasesJson',
  );
  @override
  late final GeneratedColumn<String> aliasesJson = GeneratedColumn<String>(
    'aliases_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _coverFaceIdMeta = const VerificationMeta(
    'coverFaceId',
  );
  @override
  late final GeneratedColumn<String> coverFaceId = GeneratedColumn<String>(
    'cover_face_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdMsMeta = const VerificationMeta(
    'createdMs',
  );
  @override
  late final GeneratedColumn<int> createdMs = GeneratedColumn<int>(
    'created_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    aliasesJson,
    coverFaceId,
    hidden,
    createdMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('aliases_json')) {
      context.handle(
        _aliasesJsonMeta,
        aliasesJson.isAcceptableOrUnknown(
          data['aliases_json']!,
          _aliasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('cover_face_id')) {
      context.handle(
        _coverFaceIdMeta,
        coverFaceId.isAcceptableOrUnknown(
          data['cover_face_id']!,
          _coverFaceIdMeta,
        ),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('created_ms')) {
      context.handle(
        _createdMsMeta,
        createdMs.isAcceptableOrUnknown(data['created_ms']!, _createdMsMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      aliasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases_json'],
      )!,
      coverFaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_face_id'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      createdMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_ms'],
      )!,
    );
  }

  @override
  $PeoplePersonsTable createAlias(String alias) {
    return $PeoplePersonsTable(attachedDatabase, alias);
  }
}

class PersonRecord extends DataClass implements Insertable<PersonRecord> {
  final String id;
  final String name;
  final String aliasesJson;
  final String? coverFaceId;
  final bool hidden;
  final int createdMs;
  const PersonRecord({
    required this.id,
    required this.name,
    required this.aliasesJson,
    this.coverFaceId,
    required this.hidden,
    required this.createdMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['aliases_json'] = Variable<String>(aliasesJson);
    if (!nullToAbsent || coverFaceId != null) {
      map['cover_face_id'] = Variable<String>(coverFaceId);
    }
    map['hidden'] = Variable<bool>(hidden);
    map['created_ms'] = Variable<int>(createdMs);
    return map;
  }

  PeoplePersonsCompanion toCompanion(bool nullToAbsent) {
    return PeoplePersonsCompanion(
      id: Value(id),
      name: Value(name),
      aliasesJson: Value(aliasesJson),
      coverFaceId: coverFaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverFaceId),
      hidden: Value(hidden),
      createdMs: Value(createdMs),
    );
  }

  factory PersonRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      aliasesJson: serializer.fromJson<String>(json['aliasesJson']),
      coverFaceId: serializer.fromJson<String?>(json['coverFaceId']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      createdMs: serializer.fromJson<int>(json['createdMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'aliasesJson': serializer.toJson<String>(aliasesJson),
      'coverFaceId': serializer.toJson<String?>(coverFaceId),
      'hidden': serializer.toJson<bool>(hidden),
      'createdMs': serializer.toJson<int>(createdMs),
    };
  }

  PersonRecord copyWith({
    String? id,
    String? name,
    String? aliasesJson,
    Value<String?> coverFaceId = const Value.absent(),
    bool? hidden,
    int? createdMs,
  }) => PersonRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    aliasesJson: aliasesJson ?? this.aliasesJson,
    coverFaceId: coverFaceId.present ? coverFaceId.value : this.coverFaceId,
    hidden: hidden ?? this.hidden,
    createdMs: createdMs ?? this.createdMs,
  );
  PersonRecord copyWithCompanion(PeoplePersonsCompanion data) {
    return PersonRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      aliasesJson: data.aliasesJson.present
          ? data.aliasesJson.value
          : this.aliasesJson,
      coverFaceId: data.coverFaceId.present
          ? data.coverFaceId.value
          : this.coverFaceId,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      createdMs: data.createdMs.present ? data.createdMs.value : this.createdMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('coverFaceId: $coverFaceId, ')
          ..write('hidden: $hidden, ')
          ..write('createdMs: $createdMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, aliasesJson, coverFaceId, hidden, createdMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.aliasesJson == this.aliasesJson &&
          other.coverFaceId == this.coverFaceId &&
          other.hidden == this.hidden &&
          other.createdMs == this.createdMs);
}

class PeoplePersonsCompanion extends UpdateCompanion<PersonRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> aliasesJson;
  final Value<String?> coverFaceId;
  final Value<bool> hidden;
  final Value<int> createdMs;
  final Value<int> rowid;
  const PeoplePersonsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.coverFaceId = const Value.absent(),
    this.hidden = const Value.absent(),
    this.createdMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeoplePersonsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.coverFaceId = const Value.absent(),
    this.hidden = const Value.absent(),
    required int createdMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdMs = Value(createdMs);
  static Insertable<PersonRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? aliasesJson,
    Expression<String>? coverFaceId,
    Expression<bool>? hidden,
    Expression<int>? createdMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (aliasesJson != null) 'aliases_json': aliasesJson,
      if (coverFaceId != null) 'cover_face_id': coverFaceId,
      if (hidden != null) 'hidden': hidden,
      if (createdMs != null) 'created_ms': createdMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeoplePersonsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? aliasesJson,
    Value<String?>? coverFaceId,
    Value<bool>? hidden,
    Value<int>? createdMs,
    Value<int>? rowid,
  }) {
    return PeoplePersonsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      aliasesJson: aliasesJson ?? this.aliasesJson,
      coverFaceId: coverFaceId ?? this.coverFaceId,
      hidden: hidden ?? this.hidden,
      createdMs: createdMs ?? this.createdMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aliasesJson.present) {
      map['aliases_json'] = Variable<String>(aliasesJson.value);
    }
    if (coverFaceId.present) {
      map['cover_face_id'] = Variable<String>(coverFaceId.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (createdMs.present) {
      map['created_ms'] = Variable<int>(createdMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeoplePersonsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('coverFaceId: $coverFaceId, ')
          ..write('hidden: $hidden, ')
          ..write('createdMs: $createdMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleFacesTable extends PeopleFaces
    with TableInfo<$PeopleFacesTable, PeopleFaceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleFacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractMeta = const VerificationMeta(
    'contract',
  );
  @override
  late final GeneratedColumn<String> contract = GeneratedColumn<String>(
    'contract',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wMeta = const VerificationMeta('w');
  @override
  late final GeneratedColumn<double> w = GeneratedColumn<double>(
    'w',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hMeta = const VerificationMeta('h');
  @override
  late final GeneratedColumn<double> h = GeneratedColumn<double>(
    'h',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landmarksJsonMeta = const VerificationMeta(
    'landmarksJson',
  );
  @override
  late final GeneratedColumn<String> landmarksJson = GeneratedColumn<String>(
    'landmarks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
    'vector',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropPathMeta = const VerificationMeta(
    'cropPath',
  );
  @override
  late final GeneratedColumn<String> cropPath = GeneratedColumn<String>(
    'crop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignmentMeta = const VerificationMeta(
    'assignment',
  );
  @override
  late final GeneratedColumn<String> assignment = GeneratedColumn<String>(
    'assignment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unassigned'),
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta(
    'dismissed',
  );
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dismissed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    photoId,
    revision,
    contract,
    x,
    y,
    w,
    h,
    landmarksJson,
    vector,
    quality,
    cropPath,
    personId,
    assignment,
    dismissed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_faces';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleFaceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('contract')) {
      context.handle(
        _contractMeta,
        contract.isAcceptableOrUnknown(data['contract']!, _contractMeta),
      );
    } else if (isInserting) {
      context.missing(_contractMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('w')) {
      context.handle(_wMeta, w.isAcceptableOrUnknown(data['w']!, _wMeta));
    } else if (isInserting) {
      context.missing(_wMeta);
    }
    if (data.containsKey('h')) {
      context.handle(_hMeta, h.isAcceptableOrUnknown(data['h']!, _hMeta));
    } else if (isInserting) {
      context.missing(_hMeta);
    }
    if (data.containsKey('landmarks_json')) {
      context.handle(
        _landmarksJsonMeta,
        landmarksJson.isAcceptableOrUnknown(
          data['landmarks_json']!,
          _landmarksJsonMeta,
        ),
      );
    }
    if (data.containsKey('vector')) {
      context.handle(
        _vectorMeta,
        vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('crop_path')) {
      context.handle(
        _cropPathMeta,
        cropPath.isAcceptableOrUnknown(data['crop_path']!, _cropPathMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('assignment')) {
      context.handle(
        _assignmentMeta,
        assignment.isAcceptableOrUnknown(data['assignment']!, _assignmentMeta),
      );
    }
    if (data.containsKey('dismissed')) {
      context.handle(
        _dismissedMeta,
        dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleFaceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleFaceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      contract: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      w: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}w'],
      )!,
      h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}h'],
      )!,
      landmarksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landmarks_json'],
      )!,
      vector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vector'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      cropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_path'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      assignment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignment'],
      )!,
      dismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dismissed'],
      )!,
    );
  }

  @override
  $PeopleFacesTable createAlias(String alias) {
    return $PeopleFacesTable(attachedDatabase, alias);
  }
}

class PeopleFaceRecord extends DataClass
    implements Insertable<PeopleFaceRecord> {
  final String id;
  final String photoId;
  final String revision;
  final String contract;
  final double x;
  final double y;
  final double w;
  final double h;
  final String landmarksJson;
  final Uint8List? vector;
  final String quality;
  final String? cropPath;
  final String? personId;
  final String assignment;
  final bool dismissed;
  const PeopleFaceRecord({
    required this.id,
    required this.photoId,
    required this.revision,
    required this.contract,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.landmarksJson,
    this.vector,
    required this.quality,
    this.cropPath,
    this.personId,
    required this.assignment,
    required this.dismissed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['photo_id'] = Variable<String>(photoId);
    map['revision'] = Variable<String>(revision);
    map['contract'] = Variable<String>(contract);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['w'] = Variable<double>(w);
    map['h'] = Variable<double>(h);
    map['landmarks_json'] = Variable<String>(landmarksJson);
    if (!nullToAbsent || vector != null) {
      map['vector'] = Variable<Uint8List>(vector);
    }
    map['quality'] = Variable<String>(quality);
    if (!nullToAbsent || cropPath != null) {
      map['crop_path'] = Variable<String>(cropPath);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['assignment'] = Variable<String>(assignment);
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  PeopleFacesCompanion toCompanion(bool nullToAbsent) {
    return PeopleFacesCompanion(
      id: Value(id),
      photoId: Value(photoId),
      revision: Value(revision),
      contract: Value(contract),
      x: Value(x),
      y: Value(y),
      w: Value(w),
      h: Value(h),
      landmarksJson: Value(landmarksJson),
      vector: vector == null && nullToAbsent
          ? const Value.absent()
          : Value(vector),
      quality: Value(quality),
      cropPath: cropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cropPath),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      assignment: Value(assignment),
      dismissed: Value(dismissed),
    );
  }

  factory PeopleFaceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleFaceRecord(
      id: serializer.fromJson<String>(json['id']),
      photoId: serializer.fromJson<String>(json['photoId']),
      revision: serializer.fromJson<String>(json['revision']),
      contract: serializer.fromJson<String>(json['contract']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      w: serializer.fromJson<double>(json['w']),
      h: serializer.fromJson<double>(json['h']),
      landmarksJson: serializer.fromJson<String>(json['landmarksJson']),
      vector: serializer.fromJson<Uint8List?>(json['vector']),
      quality: serializer.fromJson<String>(json['quality']),
      cropPath: serializer.fromJson<String?>(json['cropPath']),
      personId: serializer.fromJson<String?>(json['personId']),
      assignment: serializer.fromJson<String>(json['assignment']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'photoId': serializer.toJson<String>(photoId),
      'revision': serializer.toJson<String>(revision),
      'contract': serializer.toJson<String>(contract),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'w': serializer.toJson<double>(w),
      'h': serializer.toJson<double>(h),
      'landmarksJson': serializer.toJson<String>(landmarksJson),
      'vector': serializer.toJson<Uint8List?>(vector),
      'quality': serializer.toJson<String>(quality),
      'cropPath': serializer.toJson<String?>(cropPath),
      'personId': serializer.toJson<String?>(personId),
      'assignment': serializer.toJson<String>(assignment),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  PeopleFaceRecord copyWith({
    String? id,
    String? photoId,
    String? revision,
    String? contract,
    double? x,
    double? y,
    double? w,
    double? h,
    String? landmarksJson,
    Value<Uint8List?> vector = const Value.absent(),
    String? quality,
    Value<String?> cropPath = const Value.absent(),
    Value<String?> personId = const Value.absent(),
    String? assignment,
    bool? dismissed,
  }) => PeopleFaceRecord(
    id: id ?? this.id,
    photoId: photoId ?? this.photoId,
    revision: revision ?? this.revision,
    contract: contract ?? this.contract,
    x: x ?? this.x,
    y: y ?? this.y,
    w: w ?? this.w,
    h: h ?? this.h,
    landmarksJson: landmarksJson ?? this.landmarksJson,
    vector: vector.present ? vector.value : this.vector,
    quality: quality ?? this.quality,
    cropPath: cropPath.present ? cropPath.value : this.cropPath,
    personId: personId.present ? personId.value : this.personId,
    assignment: assignment ?? this.assignment,
    dismissed: dismissed ?? this.dismissed,
  );
  PeopleFaceRecord copyWithCompanion(PeopleFacesCompanion data) {
    return PeopleFaceRecord(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      revision: data.revision.present ? data.revision.value : this.revision,
      contract: data.contract.present ? data.contract.value : this.contract,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      w: data.w.present ? data.w.value : this.w,
      h: data.h.present ? data.h.value : this.h,
      landmarksJson: data.landmarksJson.present
          ? data.landmarksJson.value
          : this.landmarksJson,
      vector: data.vector.present ? data.vector.value : this.vector,
      quality: data.quality.present ? data.quality.value : this.quality,
      cropPath: data.cropPath.present ? data.cropPath.value : this.cropPath,
      personId: data.personId.present ? data.personId.value : this.personId,
      assignment: data.assignment.present
          ? data.assignment.value
          : this.assignment,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleFaceRecord(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('contract: $contract, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('landmarksJson: $landmarksJson, ')
          ..write('vector: $vector, ')
          ..write('quality: $quality, ')
          ..write('cropPath: $cropPath, ')
          ..write('personId: $personId, ')
          ..write('assignment: $assignment, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    photoId,
    revision,
    contract,
    x,
    y,
    w,
    h,
    landmarksJson,
    $driftBlobEquality.hash(vector),
    quality,
    cropPath,
    personId,
    assignment,
    dismissed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleFaceRecord &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.revision == this.revision &&
          other.contract == this.contract &&
          other.x == this.x &&
          other.y == this.y &&
          other.w == this.w &&
          other.h == this.h &&
          other.landmarksJson == this.landmarksJson &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.quality == this.quality &&
          other.cropPath == this.cropPath &&
          other.personId == this.personId &&
          other.assignment == this.assignment &&
          other.dismissed == this.dismissed);
}

class PeopleFacesCompanion extends UpdateCompanion<PeopleFaceRecord> {
  final Value<String> id;
  final Value<String> photoId;
  final Value<String> revision;
  final Value<String> contract;
  final Value<double> x;
  final Value<double> y;
  final Value<double> w;
  final Value<double> h;
  final Value<String> landmarksJson;
  final Value<Uint8List?> vector;
  final Value<String> quality;
  final Value<String?> cropPath;
  final Value<String?> personId;
  final Value<String> assignment;
  final Value<bool> dismissed;
  final Value<int> rowid;
  const PeopleFacesCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.revision = const Value.absent(),
    this.contract = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.w = const Value.absent(),
    this.h = const Value.absent(),
    this.landmarksJson = const Value.absent(),
    this.vector = const Value.absent(),
    this.quality = const Value.absent(),
    this.cropPath = const Value.absent(),
    this.personId = const Value.absent(),
    this.assignment = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleFacesCompanion.insert({
    required String id,
    required String photoId,
    required String revision,
    required String contract,
    required double x,
    required double y,
    required double w,
    required double h,
    this.landmarksJson = const Value.absent(),
    this.vector = const Value.absent(),
    required String quality,
    this.cropPath = const Value.absent(),
    this.personId = const Value.absent(),
    this.assignment = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       photoId = Value(photoId),
       revision = Value(revision),
       contract = Value(contract),
       x = Value(x),
       y = Value(y),
       w = Value(w),
       h = Value(h),
       quality = Value(quality);
  static Insertable<PeopleFaceRecord> custom({
    Expression<String>? id,
    Expression<String>? photoId,
    Expression<String>? revision,
    Expression<String>? contract,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? w,
    Expression<double>? h,
    Expression<String>? landmarksJson,
    Expression<Uint8List>? vector,
    Expression<String>? quality,
    Expression<String>? cropPath,
    Expression<String>? personId,
    Expression<String>? assignment,
    Expression<bool>? dismissed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (revision != null) 'revision': revision,
      if (contract != null) 'contract': contract,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (w != null) 'w': w,
      if (h != null) 'h': h,
      if (landmarksJson != null) 'landmarks_json': landmarksJson,
      if (vector != null) 'vector': vector,
      if (quality != null) 'quality': quality,
      if (cropPath != null) 'crop_path': cropPath,
      if (personId != null) 'person_id': personId,
      if (assignment != null) 'assignment': assignment,
      if (dismissed != null) 'dismissed': dismissed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleFacesCompanion copyWith({
    Value<String>? id,
    Value<String>? photoId,
    Value<String>? revision,
    Value<String>? contract,
    Value<double>? x,
    Value<double>? y,
    Value<double>? w,
    Value<double>? h,
    Value<String>? landmarksJson,
    Value<Uint8List?>? vector,
    Value<String>? quality,
    Value<String?>? cropPath,
    Value<String?>? personId,
    Value<String>? assignment,
    Value<bool>? dismissed,
    Value<int>? rowid,
  }) {
    return PeopleFacesCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      revision: revision ?? this.revision,
      contract: contract ?? this.contract,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      landmarksJson: landmarksJson ?? this.landmarksJson,
      vector: vector ?? this.vector,
      quality: quality ?? this.quality,
      cropPath: cropPath ?? this.cropPath,
      personId: personId ?? this.personId,
      assignment: assignment ?? this.assignment,
      dismissed: dismissed ?? this.dismissed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (contract.present) {
      map['contract'] = Variable<String>(contract.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (w.present) {
      map['w'] = Variable<double>(w.value);
    }
    if (h.present) {
      map['h'] = Variable<double>(h.value);
    }
    if (landmarksJson.present) {
      map['landmarks_json'] = Variable<String>(landmarksJson.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (cropPath.present) {
      map['crop_path'] = Variable<String>(cropPath.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (assignment.present) {
      map['assignment'] = Variable<String>(assignment.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleFacesCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('contract: $contract, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('landmarksJson: $landmarksJson, ')
          ..write('vector: $vector, ')
          ..write('quality: $quality, ')
          ..write('cropPath: $cropPath, ')
          ..write('personId: $personId, ')
          ..write('assignment: $assignment, ')
          ..write('dismissed: $dismissed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleScansTable extends PeopleScans
    with TableInfo<$PeopleScansTable, PeopleScanRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleScansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contractMeta = const VerificationMeta(
    'contract',
  );
  @override
  late final GeneratedColumn<String> contract = GeneratedColumn<String>(
    'contract',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _facesMeta = const VerificationMeta('faces');
  @override
  late final GeneratedColumn<int> faces = GeneratedColumn<int>(
    'faces',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMsMeta = const VerificationMeta(
    'completedMs',
  );
  @override
  late final GeneratedColumn<int> completedMs = GeneratedColumn<int>(
    'completed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    revision,
    contract,
    status,
    faces,
    completedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleScanRecord> instance, {
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('contract')) {
      context.handle(
        _contractMeta,
        contract.isAcceptableOrUnknown(data['contract']!, _contractMeta),
      );
    } else if (isInserting) {
      context.missing(_contractMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('faces')) {
      context.handle(
        _facesMeta,
        faces.isAcceptableOrUnknown(data['faces']!, _facesMeta),
      );
    }
    if (data.containsKey('completed_ms')) {
      context.handle(
        _completedMsMeta,
        completedMs.isAcceptableOrUnknown(
          data['completed_ms']!,
          _completedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  PeopleScanRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleScanRecord(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      contract: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      faces: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}faces'],
      )!,
      completedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_ms'],
      )!,
    );
  }

  @override
  $PeopleScansTable createAlias(String alias) {
    return $PeopleScansTable(attachedDatabase, alias);
  }
}

class PeopleScanRecord extends DataClass
    implements Insertable<PeopleScanRecord> {
  final String photoId;
  final String revision;
  final String contract;
  final String status;
  final int faces;
  final int completedMs;
  const PeopleScanRecord({
    required this.photoId,
    required this.revision,
    required this.contract,
    required this.status,
    required this.faces,
    required this.completedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['revision'] = Variable<String>(revision);
    map['contract'] = Variable<String>(contract);
    map['status'] = Variable<String>(status);
    map['faces'] = Variable<int>(faces);
    map['completed_ms'] = Variable<int>(completedMs);
    return map;
  }

  PeopleScansCompanion toCompanion(bool nullToAbsent) {
    return PeopleScansCompanion(
      photoId: Value(photoId),
      revision: Value(revision),
      contract: Value(contract),
      status: Value(status),
      faces: Value(faces),
      completedMs: Value(completedMs),
    );
  }

  factory PeopleScanRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleScanRecord(
      photoId: serializer.fromJson<String>(json['photoId']),
      revision: serializer.fromJson<String>(json['revision']),
      contract: serializer.fromJson<String>(json['contract']),
      status: serializer.fromJson<String>(json['status']),
      faces: serializer.fromJson<int>(json['faces']),
      completedMs: serializer.fromJson<int>(json['completedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'revision': serializer.toJson<String>(revision),
      'contract': serializer.toJson<String>(contract),
      'status': serializer.toJson<String>(status),
      'faces': serializer.toJson<int>(faces),
      'completedMs': serializer.toJson<int>(completedMs),
    };
  }

  PeopleScanRecord copyWith({
    String? photoId,
    String? revision,
    String? contract,
    String? status,
    int? faces,
    int? completedMs,
  }) => PeopleScanRecord(
    photoId: photoId ?? this.photoId,
    revision: revision ?? this.revision,
    contract: contract ?? this.contract,
    status: status ?? this.status,
    faces: faces ?? this.faces,
    completedMs: completedMs ?? this.completedMs,
  );
  PeopleScanRecord copyWithCompanion(PeopleScansCompanion data) {
    return PeopleScanRecord(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      revision: data.revision.present ? data.revision.value : this.revision,
      contract: data.contract.present ? data.contract.value : this.contract,
      status: data.status.present ? data.status.value : this.status,
      faces: data.faces.present ? data.faces.value : this.faces,
      completedMs: data.completedMs.present
          ? data.completedMs.value
          : this.completedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleScanRecord(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('contract: $contract, ')
          ..write('status: $status, ')
          ..write('faces: $faces, ')
          ..write('completedMs: $completedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(photoId, revision, contract, status, faces, completedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleScanRecord &&
          other.photoId == this.photoId &&
          other.revision == this.revision &&
          other.contract == this.contract &&
          other.status == this.status &&
          other.faces == this.faces &&
          other.completedMs == this.completedMs);
}

class PeopleScansCompanion extends UpdateCompanion<PeopleScanRecord> {
  final Value<String> photoId;
  final Value<String> revision;
  final Value<String> contract;
  final Value<String> status;
  final Value<int> faces;
  final Value<int> completedMs;
  final Value<int> rowid;
  const PeopleScansCompanion({
    this.photoId = const Value.absent(),
    this.revision = const Value.absent(),
    this.contract = const Value.absent(),
    this.status = const Value.absent(),
    this.faces = const Value.absent(),
    this.completedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleScansCompanion.insert({
    required String photoId,
    required String revision,
    required String contract,
    required String status,
    this.faces = const Value.absent(),
    required int completedMs,
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       revision = Value(revision),
       contract = Value(contract),
       status = Value(status),
       completedMs = Value(completedMs);
  static Insertable<PeopleScanRecord> custom({
    Expression<String>? photoId,
    Expression<String>? revision,
    Expression<String>? contract,
    Expression<String>? status,
    Expression<int>? faces,
    Expression<int>? completedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (revision != null) 'revision': revision,
      if (contract != null) 'contract': contract,
      if (status != null) 'status': status,
      if (faces != null) 'faces': faces,
      if (completedMs != null) 'completed_ms': completedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleScansCompanion copyWith({
    Value<String>? photoId,
    Value<String>? revision,
    Value<String>? contract,
    Value<String>? status,
    Value<int>? faces,
    Value<int>? completedMs,
    Value<int>? rowid,
  }) {
    return PeopleScansCompanion(
      photoId: photoId ?? this.photoId,
      revision: revision ?? this.revision,
      contract: contract ?? this.contract,
      status: status ?? this.status,
      faces: faces ?? this.faces,
      completedMs: completedMs ?? this.completedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (contract.present) {
      map['contract'] = Variable<String>(contract.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (faces.present) {
      map['faces'] = Variable<int>(faces.value);
    }
    if (completedMs.present) {
      map['completed_ms'] = Variable<int>(completedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleScansCompanion(')
          ..write('photoId: $photoId, ')
          ..write('revision: $revision, ')
          ..write('contract: $contract, ')
          ..write('status: $status, ')
          ..write('faces: $faces, ')
          ..write('completedMs: $completedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleDecisionsTable extends PeopleDecisions
    with TableInfo<$PeopleDecisionsTable, PeopleDecisionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleDecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _faceIdMeta = const VerificationMeta('faceId');
  @override
  late final GeneratedColumn<String> faceId = GeneratedColumn<String>(
    'face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
    'decision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [faceId, personId, decision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleDecisionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('face_id')) {
      context.handle(
        _faceIdMeta,
        faceId.isAcceptableOrUnknown(data['face_id']!, _faceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    } else if (isInserting) {
      context.missing(_decisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {faceId, personId};
  @override
  PeopleDecisionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleDecisionRecord(
      faceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision'],
      )!,
    );
  }

  @override
  $PeopleDecisionsTable createAlias(String alias) {
    return $PeopleDecisionsTable(attachedDatabase, alias);
  }
}

class PeopleDecisionRecord extends DataClass
    implements Insertable<PeopleDecisionRecord> {
  final String faceId;
  final String personId;
  final String decision;
  const PeopleDecisionRecord({
    required this.faceId,
    required this.personId,
    required this.decision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['face_id'] = Variable<String>(faceId);
    map['person_id'] = Variable<String>(personId);
    map['decision'] = Variable<String>(decision);
    return map;
  }

  PeopleDecisionsCompanion toCompanion(bool nullToAbsent) {
    return PeopleDecisionsCompanion(
      faceId: Value(faceId),
      personId: Value(personId),
      decision: Value(decision),
    );
  }

  factory PeopleDecisionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleDecisionRecord(
      faceId: serializer.fromJson<String>(json['faceId']),
      personId: serializer.fromJson<String>(json['personId']),
      decision: serializer.fromJson<String>(json['decision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'faceId': serializer.toJson<String>(faceId),
      'personId': serializer.toJson<String>(personId),
      'decision': serializer.toJson<String>(decision),
    };
  }

  PeopleDecisionRecord copyWith({
    String? faceId,
    String? personId,
    String? decision,
  }) => PeopleDecisionRecord(
    faceId: faceId ?? this.faceId,
    personId: personId ?? this.personId,
    decision: decision ?? this.decision,
  );
  PeopleDecisionRecord copyWithCompanion(PeopleDecisionsCompanion data) {
    return PeopleDecisionRecord(
      faceId: data.faceId.present ? data.faceId.value : this.faceId,
      personId: data.personId.present ? data.personId.value : this.personId,
      decision: data.decision.present ? data.decision.value : this.decision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleDecisionRecord(')
          ..write('faceId: $faceId, ')
          ..write('personId: $personId, ')
          ..write('decision: $decision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(faceId, personId, decision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleDecisionRecord &&
          other.faceId == this.faceId &&
          other.personId == this.personId &&
          other.decision == this.decision);
}

class PeopleDecisionsCompanion extends UpdateCompanion<PeopleDecisionRecord> {
  final Value<String> faceId;
  final Value<String> personId;
  final Value<String> decision;
  final Value<int> rowid;
  const PeopleDecisionsCompanion({
    this.faceId = const Value.absent(),
    this.personId = const Value.absent(),
    this.decision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleDecisionsCompanion.insert({
    required String faceId,
    required String personId,
    required String decision,
    this.rowid = const Value.absent(),
  }) : faceId = Value(faceId),
       personId = Value(personId),
       decision = Value(decision);
  static Insertable<PeopleDecisionRecord> custom({
    Expression<String>? faceId,
    Expression<String>? personId,
    Expression<String>? decision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (faceId != null) 'face_id': faceId,
      if (personId != null) 'person_id': personId,
      if (decision != null) 'decision': decision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleDecisionsCompanion copyWith({
    Value<String>? faceId,
    Value<String>? personId,
    Value<String>? decision,
    Value<int>? rowid,
  }) {
    return PeopleDecisionsCompanion(
      faceId: faceId ?? this.faceId,
      personId: personId ?? this.personId,
      decision: decision ?? this.decision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (faceId.present) {
      map['face_id'] = Variable<String>(faceId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleDecisionsCompanion(')
          ..write('faceId: $faceId, ')
          ..write('personId: $personId, ')
          ..write('decision: $decision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleReviewsTable extends PeopleReviews
    with TableInfo<$PeopleReviewsTable, PeopleReviewRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftFaceIdMeta = const VerificationMeta(
    'leftFaceId',
  );
  @override
  late final GeneratedColumn<String> leftFaceId = GeneratedColumn<String>(
    'left_face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightFaceIdMeta = const VerificationMeta(
    'rightFaceId',
  );
  @override
  late final GeneratedColumn<String> rightFaceId = GeneratedColumn<String>(
    'right_face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subsetMeta = const VerificationMeta('subset');
  @override
  late final GeneratedColumn<String> subset = GeneratedColumn<String>(
    'subset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cosineMeta = const VerificationMeta('cosine');
  @override
  late final GeneratedColumn<double> cosine = GeneratedColumn<double>(
    'cosine',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _judgmentMeta = const VerificationMeta(
    'judgment',
  );
  @override
  late final GeneratedColumn<String> judgment = GeneratedColumn<String>(
    'judgment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _contractMeta = const VerificationMeta(
    'contract',
  );
  @override
  late final GeneratedColumn<String> contract = GeneratedColumn<String>(
    'contract',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    leftFaceId,
    rightFaceId,
    subset,
    cosine,
    judgment,
    contract,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleReviewRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('left_face_id')) {
      context.handle(
        _leftFaceIdMeta,
        leftFaceId.isAcceptableOrUnknown(
          data['left_face_id']!,
          _leftFaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_leftFaceIdMeta);
    }
    if (data.containsKey('right_face_id')) {
      context.handle(
        _rightFaceIdMeta,
        rightFaceId.isAcceptableOrUnknown(
          data['right_face_id']!,
          _rightFaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rightFaceIdMeta);
    }
    if (data.containsKey('subset')) {
      context.handle(
        _subsetMeta,
        subset.isAcceptableOrUnknown(data['subset']!, _subsetMeta),
      );
    } else if (isInserting) {
      context.missing(_subsetMeta);
    }
    if (data.containsKey('cosine')) {
      context.handle(
        _cosineMeta,
        cosine.isAcceptableOrUnknown(data['cosine']!, _cosineMeta),
      );
    } else if (isInserting) {
      context.missing(_cosineMeta);
    }
    if (data.containsKey('judgment')) {
      context.handle(
        _judgmentMeta,
        judgment.isAcceptableOrUnknown(data['judgment']!, _judgmentMeta),
      );
    }
    if (data.containsKey('contract')) {
      context.handle(
        _contractMeta,
        contract.isAcceptableOrUnknown(data['contract']!, _contractMeta),
      );
    } else if (isInserting) {
      context.missing(_contractMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleReviewRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleReviewRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      leftFaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}left_face_id'],
      )!,
      rightFaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}right_face_id'],
      )!,
      subset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subset'],
      )!,
      cosine: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cosine'],
      )!,
      judgment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}judgment'],
      )!,
      contract: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract'],
      )!,
    );
  }

  @override
  $PeopleReviewsTable createAlias(String alias) {
    return $PeopleReviewsTable(attachedDatabase, alias);
  }
}

class PeopleReviewRecord extends DataClass
    implements Insertable<PeopleReviewRecord> {
  final String id;
  final String leftFaceId;
  final String rightFaceId;
  final String subset;
  final double cosine;
  final String judgment;
  final String contract;
  const PeopleReviewRecord({
    required this.id,
    required this.leftFaceId,
    required this.rightFaceId,
    required this.subset,
    required this.cosine,
    required this.judgment,
    required this.contract,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['left_face_id'] = Variable<String>(leftFaceId);
    map['right_face_id'] = Variable<String>(rightFaceId);
    map['subset'] = Variable<String>(subset);
    map['cosine'] = Variable<double>(cosine);
    map['judgment'] = Variable<String>(judgment);
    map['contract'] = Variable<String>(contract);
    return map;
  }

  PeopleReviewsCompanion toCompanion(bool nullToAbsent) {
    return PeopleReviewsCompanion(
      id: Value(id),
      leftFaceId: Value(leftFaceId),
      rightFaceId: Value(rightFaceId),
      subset: Value(subset),
      cosine: Value(cosine),
      judgment: Value(judgment),
      contract: Value(contract),
    );
  }

  factory PeopleReviewRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleReviewRecord(
      id: serializer.fromJson<String>(json['id']),
      leftFaceId: serializer.fromJson<String>(json['leftFaceId']),
      rightFaceId: serializer.fromJson<String>(json['rightFaceId']),
      subset: serializer.fromJson<String>(json['subset']),
      cosine: serializer.fromJson<double>(json['cosine']),
      judgment: serializer.fromJson<String>(json['judgment']),
      contract: serializer.fromJson<String>(json['contract']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'leftFaceId': serializer.toJson<String>(leftFaceId),
      'rightFaceId': serializer.toJson<String>(rightFaceId),
      'subset': serializer.toJson<String>(subset),
      'cosine': serializer.toJson<double>(cosine),
      'judgment': serializer.toJson<String>(judgment),
      'contract': serializer.toJson<String>(contract),
    };
  }

  PeopleReviewRecord copyWith({
    String? id,
    String? leftFaceId,
    String? rightFaceId,
    String? subset,
    double? cosine,
    String? judgment,
    String? contract,
  }) => PeopleReviewRecord(
    id: id ?? this.id,
    leftFaceId: leftFaceId ?? this.leftFaceId,
    rightFaceId: rightFaceId ?? this.rightFaceId,
    subset: subset ?? this.subset,
    cosine: cosine ?? this.cosine,
    judgment: judgment ?? this.judgment,
    contract: contract ?? this.contract,
  );
  PeopleReviewRecord copyWithCompanion(PeopleReviewsCompanion data) {
    return PeopleReviewRecord(
      id: data.id.present ? data.id.value : this.id,
      leftFaceId: data.leftFaceId.present
          ? data.leftFaceId.value
          : this.leftFaceId,
      rightFaceId: data.rightFaceId.present
          ? data.rightFaceId.value
          : this.rightFaceId,
      subset: data.subset.present ? data.subset.value : this.subset,
      cosine: data.cosine.present ? data.cosine.value : this.cosine,
      judgment: data.judgment.present ? data.judgment.value : this.judgment,
      contract: data.contract.present ? data.contract.value : this.contract,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleReviewRecord(')
          ..write('id: $id, ')
          ..write('leftFaceId: $leftFaceId, ')
          ..write('rightFaceId: $rightFaceId, ')
          ..write('subset: $subset, ')
          ..write('cosine: $cosine, ')
          ..write('judgment: $judgment, ')
          ..write('contract: $contract')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    leftFaceId,
    rightFaceId,
    subset,
    cosine,
    judgment,
    contract,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleReviewRecord &&
          other.id == this.id &&
          other.leftFaceId == this.leftFaceId &&
          other.rightFaceId == this.rightFaceId &&
          other.subset == this.subset &&
          other.cosine == this.cosine &&
          other.judgment == this.judgment &&
          other.contract == this.contract);
}

class PeopleReviewsCompanion extends UpdateCompanion<PeopleReviewRecord> {
  final Value<String> id;
  final Value<String> leftFaceId;
  final Value<String> rightFaceId;
  final Value<String> subset;
  final Value<double> cosine;
  final Value<String> judgment;
  final Value<String> contract;
  final Value<int> rowid;
  const PeopleReviewsCompanion({
    this.id = const Value.absent(),
    this.leftFaceId = const Value.absent(),
    this.rightFaceId = const Value.absent(),
    this.subset = const Value.absent(),
    this.cosine = const Value.absent(),
    this.judgment = const Value.absent(),
    this.contract = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleReviewsCompanion.insert({
    required String id,
    required String leftFaceId,
    required String rightFaceId,
    required String subset,
    required double cosine,
    this.judgment = const Value.absent(),
    required String contract,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       leftFaceId = Value(leftFaceId),
       rightFaceId = Value(rightFaceId),
       subset = Value(subset),
       cosine = Value(cosine),
       contract = Value(contract);
  static Insertable<PeopleReviewRecord> custom({
    Expression<String>? id,
    Expression<String>? leftFaceId,
    Expression<String>? rightFaceId,
    Expression<String>? subset,
    Expression<double>? cosine,
    Expression<String>? judgment,
    Expression<String>? contract,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leftFaceId != null) 'left_face_id': leftFaceId,
      if (rightFaceId != null) 'right_face_id': rightFaceId,
      if (subset != null) 'subset': subset,
      if (cosine != null) 'cosine': cosine,
      if (judgment != null) 'judgment': judgment,
      if (contract != null) 'contract': contract,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? leftFaceId,
    Value<String>? rightFaceId,
    Value<String>? subset,
    Value<double>? cosine,
    Value<String>? judgment,
    Value<String>? contract,
    Value<int>? rowid,
  }) {
    return PeopleReviewsCompanion(
      id: id ?? this.id,
      leftFaceId: leftFaceId ?? this.leftFaceId,
      rightFaceId: rightFaceId ?? this.rightFaceId,
      subset: subset ?? this.subset,
      cosine: cosine ?? this.cosine,
      judgment: judgment ?? this.judgment,
      contract: contract ?? this.contract,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (leftFaceId.present) {
      map['left_face_id'] = Variable<String>(leftFaceId.value);
    }
    if (rightFaceId.present) {
      map['right_face_id'] = Variable<String>(rightFaceId.value);
    }
    if (subset.present) {
      map['subset'] = Variable<String>(subset.value);
    }
    if (cosine.present) {
      map['cosine'] = Variable<double>(cosine.value);
    }
    if (judgment.present) {
      map['judgment'] = Variable<String>(judgment.value);
    }
    if (contract.present) {
      map['contract'] = Variable<String>(contract.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleReviewsCompanion(')
          ..write('id: $id, ')
          ..write('leftFaceId: $leftFaceId, ')
          ..write('rightFaceId: $rightFaceId, ')
          ..write('subset: $subset, ')
          ..write('cosine: $cosine, ')
          ..write('judgment: $judgment, ')
          ..write('contract: $contract, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleStateTable extends PeopleState
    with TableInfo<$PeopleStateTable, PeopleStateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleStateTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _thresholdMeta = const VerificationMeta(
    'threshold',
  );
  @override
  late final GeneratedColumn<double> threshold = GeneratedColumn<double>(
    'threshold',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calibrationJsonMeta = const VerificationMeta(
    'calibrationJson',
  );
  @override
  late final GeneratedColumn<String> calibrationJson = GeneratedColumn<String>(
    'calibration_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    paused,
    generation,
    threshold,
    calibrationJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    }
    if (data.containsKey('threshold')) {
      context.handle(
        _thresholdMeta,
        threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta),
      );
    }
    if (data.containsKey('calibration_json')) {
      context.handle(
        _calibrationJsonMeta,
        calibrationJson.isAcceptableOrUnknown(
          data['calibration_json']!,
          _calibrationJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleStateRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleStateRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      threshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}threshold'],
      ),
      calibrationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibration_json'],
      )!,
    );
  }

  @override
  $PeopleStateTable createAlias(String alias) {
    return $PeopleStateTable(attachedDatabase, alias);
  }
}

class PeopleStateRecord extends DataClass
    implements Insertable<PeopleStateRecord> {
  final int id;
  final bool enabled;
  final bool paused;
  final int generation;
  final double? threshold;
  final String calibrationJson;
  const PeopleStateRecord({
    required this.id,
    required this.enabled,
    required this.paused,
    required this.generation,
    this.threshold,
    required this.calibrationJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['paused'] = Variable<bool>(paused);
    map['generation'] = Variable<int>(generation);
    if (!nullToAbsent || threshold != null) {
      map['threshold'] = Variable<double>(threshold);
    }
    map['calibration_json'] = Variable<String>(calibrationJson);
    return map;
  }

  PeopleStateCompanion toCompanion(bool nullToAbsent) {
    return PeopleStateCompanion(
      id: Value(id),
      enabled: Value(enabled),
      paused: Value(paused),
      generation: Value(generation),
      threshold: threshold == null && nullToAbsent
          ? const Value.absent()
          : Value(threshold),
      calibrationJson: Value(calibrationJson),
    );
  }

  factory PeopleStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleStateRecord(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      paused: serializer.fromJson<bool>(json['paused']),
      generation: serializer.fromJson<int>(json['generation']),
      threshold: serializer.fromJson<double?>(json['threshold']),
      calibrationJson: serializer.fromJson<String>(json['calibrationJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'paused': serializer.toJson<bool>(paused),
      'generation': serializer.toJson<int>(generation),
      'threshold': serializer.toJson<double?>(threshold),
      'calibrationJson': serializer.toJson<String>(calibrationJson),
    };
  }

  PeopleStateRecord copyWith({
    int? id,
    bool? enabled,
    bool? paused,
    int? generation,
    Value<double?> threshold = const Value.absent(),
    String? calibrationJson,
  }) => PeopleStateRecord(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    paused: paused ?? this.paused,
    generation: generation ?? this.generation,
    threshold: threshold.present ? threshold.value : this.threshold,
    calibrationJson: calibrationJson ?? this.calibrationJson,
  );
  PeopleStateRecord copyWithCompanion(PeopleStateCompanion data) {
    return PeopleStateRecord(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      paused: data.paused.present ? data.paused.value : this.paused,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      threshold: data.threshold.present ? data.threshold.value : this.threshold,
      calibrationJson: data.calibrationJson.present
          ? data.calibrationJson.value
          : this.calibrationJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleStateRecord(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('paused: $paused, ')
          ..write('generation: $generation, ')
          ..write('threshold: $threshold, ')
          ..write('calibrationJson: $calibrationJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, enabled, paused, generation, threshold, calibrationJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleStateRecord &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.paused == this.paused &&
          other.generation == this.generation &&
          other.threshold == this.threshold &&
          other.calibrationJson == this.calibrationJson);
}

class PeopleStateCompanion extends UpdateCompanion<PeopleStateRecord> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<bool> paused;
  final Value<int> generation;
  final Value<double?> threshold;
  final Value<String> calibrationJson;
  const PeopleStateCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.paused = const Value.absent(),
    this.generation = const Value.absent(),
    this.threshold = const Value.absent(),
    this.calibrationJson = const Value.absent(),
  });
  PeopleStateCompanion.insert({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.paused = const Value.absent(),
    this.generation = const Value.absent(),
    this.threshold = const Value.absent(),
    this.calibrationJson = const Value.absent(),
  });
  static Insertable<PeopleStateRecord> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<bool>? paused,
    Expression<int>? generation,
    Expression<double>? threshold,
    Expression<String>? calibrationJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (paused != null) 'paused': paused,
      if (generation != null) 'generation': generation,
      if (threshold != null) 'threshold': threshold,
      if (calibrationJson != null) 'calibration_json': calibrationJson,
    });
  }

  PeopleStateCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<bool>? paused,
    Value<int>? generation,
    Value<double?>? threshold,
    Value<String>? calibrationJson,
  }) {
    return PeopleStateCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      paused: paused ?? this.paused,
      generation: generation ?? this.generation,
      threshold: threshold ?? this.threshold,
      calibrationJson: calibrationJson ?? this.calibrationJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (threshold.present) {
      map['threshold'] = Variable<double>(threshold.value);
    }
    if (calibrationJson.present) {
      map['calibration_json'] = Variable<String>(calibrationJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleStateCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('paused: $paused, ')
          ..write('generation: $generation, ')
          ..write('threshold: $threshold, ')
          ..write('calibrationJson: $calibrationJson')
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
  late final $MemoryEventsTable memoryEvents = $MemoryEventsTable(this);
  late final $MemoryMembersTable memoryMembers = $MemoryMembersTable(this);
  late final $SavedCaptionsTable savedCaptions = $SavedCaptionsTable(this);
  late final $PhotoLocationsTable photoLocations = $PhotoLocationsTable(this);
  late final $PeoplePersonsTable peoplePersons = $PeoplePersonsTable(this);
  late final $PeopleFacesTable peopleFaces = $PeopleFacesTable(this);
  late final $PeopleScansTable peopleScans = $PeopleScansTable(this);
  late final $PeopleDecisionsTable peopleDecisions = $PeopleDecisionsTable(
    this,
  );
  late final $PeopleReviewsTable peopleReviews = $PeopleReviewsTable(this);
  late final $PeopleStateTable peopleState = $PeopleStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    photoRows,
    embeddingRows,
    indexStateRows,
    indexingPreferencesRows,
    memoryEvents,
    memoryMembers,
    savedCaptions,
    photoLocations,
    peoplePersons,
    peopleFaces,
    peopleScans,
    peopleDecisions,
    peopleReviews,
    peopleState,
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
typedef $$MemoryEventsTableCreateCompanionBuilder =
    MemoryEventsCompanion Function({
      required String id,
      Value<String> title,
      required String coverId,
      required int createdMs,
      Value<int> rowid,
    });
typedef $$MemoryEventsTableUpdateCompanionBuilder =
    MemoryEventsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> coverId,
      Value<int> createdMs,
      Value<int> rowid,
    });

class $$MemoryEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryEventsTable> {
  $$MemoryEventsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverId => $composableBuilder(
    column: $table.coverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdMs => $composableBuilder(
    column: $table.createdMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryEventsTable> {
  $$MemoryEventsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverId => $composableBuilder(
    column: $table.coverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdMs => $composableBuilder(
    column: $table.createdMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryEventsTable> {
  $$MemoryEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverId =>
      $composableBuilder(column: $table.coverId, builder: (column) => column);

  GeneratedColumn<int> get createdMs =>
      $composableBuilder(column: $table.createdMs, builder: (column) => column);
}

class $$MemoryEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryEventsTable,
          MemoryEvent,
          $$MemoryEventsTableFilterComposer,
          $$MemoryEventsTableOrderingComposer,
          $$MemoryEventsTableAnnotationComposer,
          $$MemoryEventsTableCreateCompanionBuilder,
          $$MemoryEventsTableUpdateCompanionBuilder,
          (
            MemoryEvent,
            BaseReferences<_$AppDatabase, $MemoryEventsTable, MemoryEvent>,
          ),
          MemoryEvent,
          PrefetchHooks Function()
        > {
  $$MemoryEventsTableTableManager(_$AppDatabase db, $MemoryEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverId = const Value.absent(),
                Value<int> createdMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryEventsCompanion(
                id: id,
                title: title,
                coverId: coverId,
                createdMs: createdMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                required String coverId,
                required int createdMs,
                Value<int> rowid = const Value.absent(),
              }) => MemoryEventsCompanion.insert(
                id: id,
                title: title,
                coverId: coverId,
                createdMs: createdMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryEventsTable,
      MemoryEvent,
      $$MemoryEventsTableFilterComposer,
      $$MemoryEventsTableOrderingComposer,
      $$MemoryEventsTableAnnotationComposer,
      $$MemoryEventsTableCreateCompanionBuilder,
      $$MemoryEventsTableUpdateCompanionBuilder,
      (
        MemoryEvent,
        BaseReferences<_$AppDatabase, $MemoryEventsTable, MemoryEvent>,
      ),
      MemoryEvent,
      PrefetchHooks Function()
    >;
typedef $$MemoryMembersTableCreateCompanionBuilder =
    MemoryMembersCompanion Function({
      required String photoId,
      required String eventId,
      Value<int> rowid,
    });
typedef $$MemoryMembersTableUpdateCompanionBuilder =
    MemoryMembersCompanion Function({
      Value<String> photoId,
      Value<String> eventId,
      Value<int> rowid,
    });

class $$MemoryMembersTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryMembersTable> {
  $$MemoryMembersTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryMembersTable> {
  $$MemoryMembersTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryMembersTable> {
  $$MemoryMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);
}

class $$MemoryMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryMembersTable,
          MemoryMember,
          $$MemoryMembersTableFilterComposer,
          $$MemoryMembersTableOrderingComposer,
          $$MemoryMembersTableAnnotationComposer,
          $$MemoryMembersTableCreateCompanionBuilder,
          $$MemoryMembersTableUpdateCompanionBuilder,
          (
            MemoryMember,
            BaseReferences<_$AppDatabase, $MemoryMembersTable, MemoryMember>,
          ),
          MemoryMember,
          PrefetchHooks Function()
        > {
  $$MemoryMembersTableTableManager(_$AppDatabase db, $MemoryMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryMembersCompanion(
                photoId: photoId,
                eventId: eventId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required String eventId,
                Value<int> rowid = const Value.absent(),
              }) => MemoryMembersCompanion.insert(
                photoId: photoId,
                eventId: eventId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryMembersTable,
      MemoryMember,
      $$MemoryMembersTableFilterComposer,
      $$MemoryMembersTableOrderingComposer,
      $$MemoryMembersTableAnnotationComposer,
      $$MemoryMembersTableCreateCompanionBuilder,
      $$MemoryMembersTableUpdateCompanionBuilder,
      (
        MemoryMember,
        BaseReferences<_$AppDatabase, $MemoryMembersTable, MemoryMember>,
      ),
      MemoryMember,
      PrefetchHooks Function()
    >;
typedef $$SavedCaptionsTableCreateCompanionBuilder =
    SavedCaptionsCompanion Function({
      required String photoId,
      required int revision,
      required String baseCaption,
      required String editedCaption,
      required String model,
      Value<String> provider,
      Value<String> style,
      Value<bool> manuallyEdited,
      required int generatedMs,
      Value<int> rowid,
    });
typedef $$SavedCaptionsTableUpdateCompanionBuilder =
    SavedCaptionsCompanion Function({
      Value<String> photoId,
      Value<int> revision,
      Value<String> baseCaption,
      Value<String> editedCaption,
      Value<String> model,
      Value<String> provider,
      Value<String> style,
      Value<bool> manuallyEdited,
      Value<int> generatedMs,
      Value<int> rowid,
    });

class $$SavedCaptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedCaptionsTable> {
  $$SavedCaptionsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCaption => $composableBuilder(
    column: $table.baseCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editedCaption => $composableBuilder(
    column: $table.editedCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manuallyEdited => $composableBuilder(
    column: $table.manuallyEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generatedMs => $composableBuilder(
    column: $table.generatedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedCaptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedCaptionsTable> {
  $$SavedCaptionsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCaption => $composableBuilder(
    column: $table.baseCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editedCaption => $composableBuilder(
    column: $table.editedCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manuallyEdited => $composableBuilder(
    column: $table.manuallyEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generatedMs => $composableBuilder(
    column: $table.generatedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedCaptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedCaptionsTable> {
  $$SavedCaptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get baseCaption => $composableBuilder(
    column: $table.baseCaption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get editedCaption => $composableBuilder(
    column: $table.editedCaption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<bool> get manuallyEdited => $composableBuilder(
    column: $table.manuallyEdited,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generatedMs => $composableBuilder(
    column: $table.generatedMs,
    builder: (column) => column,
  );
}

class $$SavedCaptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedCaptionsTable,
          SavedCaption,
          $$SavedCaptionsTableFilterComposer,
          $$SavedCaptionsTableOrderingComposer,
          $$SavedCaptionsTableAnnotationComposer,
          $$SavedCaptionsTableCreateCompanionBuilder,
          $$SavedCaptionsTableUpdateCompanionBuilder,
          (
            SavedCaption,
            BaseReferences<_$AppDatabase, $SavedCaptionsTable, SavedCaption>,
          ),
          SavedCaption,
          PrefetchHooks Function()
        > {
  $$SavedCaptionsTableTableManager(_$AppDatabase db, $SavedCaptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedCaptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedCaptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedCaptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> baseCaption = const Value.absent(),
                Value<String> editedCaption = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<bool> manuallyEdited = const Value.absent(),
                Value<int> generatedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedCaptionsCompanion(
                photoId: photoId,
                revision: revision,
                baseCaption: baseCaption,
                editedCaption: editedCaption,
                model: model,
                provider: provider,
                style: style,
                manuallyEdited: manuallyEdited,
                generatedMs: generatedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required int revision,
                required String baseCaption,
                required String editedCaption,
                required String model,
                Value<String> provider = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<bool> manuallyEdited = const Value.absent(),
                required int generatedMs,
                Value<int> rowid = const Value.absent(),
              }) => SavedCaptionsCompanion.insert(
                photoId: photoId,
                revision: revision,
                baseCaption: baseCaption,
                editedCaption: editedCaption,
                model: model,
                provider: provider,
                style: style,
                manuallyEdited: manuallyEdited,
                generatedMs: generatedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedCaptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedCaptionsTable,
      SavedCaption,
      $$SavedCaptionsTableFilterComposer,
      $$SavedCaptionsTableOrderingComposer,
      $$SavedCaptionsTableAnnotationComposer,
      $$SavedCaptionsTableCreateCompanionBuilder,
      $$SavedCaptionsTableUpdateCompanionBuilder,
      (
        SavedCaption,
        BaseReferences<_$AppDatabase, $SavedCaptionsTable, SavedCaption>,
      ),
      SavedCaption,
      PrefetchHooks Function()
    >;
typedef $$PhotoLocationsTableCreateCompanionBuilder =
    PhotoLocationsCompanion Function({
      required String photoId,
      required int revision,
      Value<double?> latitude,
      Value<double?> longitude,
      required String status,
      Value<String> provenance,
      Value<int> rowid,
    });
typedef $$PhotoLocationsTableUpdateCompanionBuilder =
    PhotoLocationsCompanion Function({
      Value<String> photoId,
      Value<int> revision,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String> status,
      Value<String> provenance,
      Value<int> rowid,
    });

class $$PhotoLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoLocationsTable> {
  $$PhotoLocationsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotoLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoLocationsTable> {
  $$PhotoLocationsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotoLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoLocationsTable> {
  $$PhotoLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );
}

class $$PhotoLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotoLocationsTable,
          PhotoLocation,
          $$PhotoLocationsTableFilterComposer,
          $$PhotoLocationsTableOrderingComposer,
          $$PhotoLocationsTableAnnotationComposer,
          $$PhotoLocationsTableCreateCompanionBuilder,
          $$PhotoLocationsTableUpdateCompanionBuilder,
          (
            PhotoLocation,
            BaseReferences<_$AppDatabase, $PhotoLocationsTable, PhotoLocation>,
          ),
          PhotoLocation,
          PrefetchHooks Function()
        > {
  $$PhotoLocationsTableTableManager(
    _$AppDatabase db,
    $PhotoLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoLocationsCompanion(
                photoId: photoId,
                revision: revision,
                latitude: latitude,
                longitude: longitude,
                status: status,
                provenance: provenance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required int revision,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required String status,
                Value<String> provenance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoLocationsCompanion.insert(
                photoId: photoId,
                revision: revision,
                latitude: latitude,
                longitude: longitude,
                status: status,
                provenance: provenance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotoLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotoLocationsTable,
      PhotoLocation,
      $$PhotoLocationsTableFilterComposer,
      $$PhotoLocationsTableOrderingComposer,
      $$PhotoLocationsTableAnnotationComposer,
      $$PhotoLocationsTableCreateCompanionBuilder,
      $$PhotoLocationsTableUpdateCompanionBuilder,
      (
        PhotoLocation,
        BaseReferences<_$AppDatabase, $PhotoLocationsTable, PhotoLocation>,
      ),
      PhotoLocation,
      PrefetchHooks Function()
    >;
typedef $$PeoplePersonsTableCreateCompanionBuilder =
    PeoplePersonsCompanion Function({
      required String id,
      Value<String> name,
      Value<String> aliasesJson,
      Value<String?> coverFaceId,
      Value<bool> hidden,
      required int createdMs,
      Value<int> rowid,
    });
typedef $$PeoplePersonsTableUpdateCompanionBuilder =
    PeoplePersonsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> aliasesJson,
      Value<String?> coverFaceId,
      Value<bool> hidden,
      Value<int> createdMs,
      Value<int> rowid,
    });

class $$PeoplePersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PeoplePersonsTable> {
  $$PeoplePersonsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverFaceId => $composableBuilder(
    column: $table.coverFaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdMs => $composableBuilder(
    column: $table.createdMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeoplePersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeoplePersonsTable> {
  $$PeoplePersonsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverFaceId => $composableBuilder(
    column: $table.coverFaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdMs => $composableBuilder(
    column: $table.createdMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeoplePersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeoplePersonsTable> {
  $$PeoplePersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverFaceId => $composableBuilder(
    column: $table.coverFaceId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<int> get createdMs =>
      $composableBuilder(column: $table.createdMs, builder: (column) => column);
}

class $$PeoplePersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeoplePersonsTable,
          PersonRecord,
          $$PeoplePersonsTableFilterComposer,
          $$PeoplePersonsTableOrderingComposer,
          $$PeoplePersonsTableAnnotationComposer,
          $$PeoplePersonsTableCreateCompanionBuilder,
          $$PeoplePersonsTableUpdateCompanionBuilder,
          (
            PersonRecord,
            BaseReferences<_$AppDatabase, $PeoplePersonsTable, PersonRecord>,
          ),
          PersonRecord,
          PrefetchHooks Function()
        > {
  $$PeoplePersonsTableTableManager(_$AppDatabase db, $PeoplePersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeoplePersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeoplePersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeoplePersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> aliasesJson = const Value.absent(),
                Value<String?> coverFaceId = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> createdMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeoplePersonsCompanion(
                id: id,
                name: name,
                aliasesJson: aliasesJson,
                coverFaceId: coverFaceId,
                hidden: hidden,
                createdMs: createdMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String> aliasesJson = const Value.absent(),
                Value<String?> coverFaceId = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                required int createdMs,
                Value<int> rowid = const Value.absent(),
              }) => PeoplePersonsCompanion.insert(
                id: id,
                name: name,
                aliasesJson: aliasesJson,
                coverFaceId: coverFaceId,
                hidden: hidden,
                createdMs: createdMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeoplePersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeoplePersonsTable,
      PersonRecord,
      $$PeoplePersonsTableFilterComposer,
      $$PeoplePersonsTableOrderingComposer,
      $$PeoplePersonsTableAnnotationComposer,
      $$PeoplePersonsTableCreateCompanionBuilder,
      $$PeoplePersonsTableUpdateCompanionBuilder,
      (
        PersonRecord,
        BaseReferences<_$AppDatabase, $PeoplePersonsTable, PersonRecord>,
      ),
      PersonRecord,
      PrefetchHooks Function()
    >;
typedef $$PeopleFacesTableCreateCompanionBuilder =
    PeopleFacesCompanion Function({
      required String id,
      required String photoId,
      required String revision,
      required String contract,
      required double x,
      required double y,
      required double w,
      required double h,
      Value<String> landmarksJson,
      Value<Uint8List?> vector,
      required String quality,
      Value<String?> cropPath,
      Value<String?> personId,
      Value<String> assignment,
      Value<bool> dismissed,
      Value<int> rowid,
    });
typedef $$PeopleFacesTableUpdateCompanionBuilder =
    PeopleFacesCompanion Function({
      Value<String> id,
      Value<String> photoId,
      Value<String> revision,
      Value<String> contract,
      Value<double> x,
      Value<double> y,
      Value<double> w,
      Value<double> h,
      Value<String> landmarksJson,
      Value<Uint8List?> vector,
      Value<String> quality,
      Value<String?> cropPath,
      Value<String?> personId,
      Value<String> assignment,
      Value<bool> dismissed,
      Value<int> rowid,
    });

class $$PeopleFacesTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleFacesTable> {
  $$PeopleFacesTableFilterComposer({
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

  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get w => $composableBuilder(
    column: $table.w,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get h => $composableBuilder(
    column: $table.h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get landmarksJson => $composableBuilder(
    column: $table.landmarksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropPath => $composableBuilder(
    column: $table.cropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignment => $composableBuilder(
    column: $table.assignment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleFacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleFacesTable> {
  $$PeopleFacesTableOrderingComposer({
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

  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get w => $composableBuilder(
    column: $table.w,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get h => $composableBuilder(
    column: $table.h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get landmarksJson => $composableBuilder(
    column: $table.landmarksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropPath => $composableBuilder(
    column: $table.cropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignment => $composableBuilder(
    column: $table.assignment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleFacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleFacesTable> {
  $$PeopleFacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get contract =>
      $composableBuilder(column: $table.contract, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get w =>
      $composableBuilder(column: $table.w, builder: (column) => column);

  GeneratedColumn<double> get h =>
      $composableBuilder(column: $table.h, builder: (column) => column);

  GeneratedColumn<String> get landmarksJson => $composableBuilder(
    column: $table.landmarksJson,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get cropPath =>
      $composableBuilder(column: $table.cropPath, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get assignment => $composableBuilder(
    column: $table.assignment,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);
}

class $$PeopleFacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleFacesTable,
          PeopleFaceRecord,
          $$PeopleFacesTableFilterComposer,
          $$PeopleFacesTableOrderingComposer,
          $$PeopleFacesTableAnnotationComposer,
          $$PeopleFacesTableCreateCompanionBuilder,
          $$PeopleFacesTableUpdateCompanionBuilder,
          (
            PeopleFaceRecord,
            BaseReferences<_$AppDatabase, $PeopleFacesTable, PeopleFaceRecord>,
          ),
          PeopleFaceRecord,
          PrefetchHooks Function()
        > {
  $$PeopleFacesTableTableManager(_$AppDatabase db, $PeopleFacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleFacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleFacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleFacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<String> contract = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> w = const Value.absent(),
                Value<double> h = const Value.absent(),
                Value<String> landmarksJson = const Value.absent(),
                Value<Uint8List?> vector = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<String?> cropPath = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> assignment = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleFacesCompanion(
                id: id,
                photoId: photoId,
                revision: revision,
                contract: contract,
                x: x,
                y: y,
                w: w,
                h: h,
                landmarksJson: landmarksJson,
                vector: vector,
                quality: quality,
                cropPath: cropPath,
                personId: personId,
                assignment: assignment,
                dismissed: dismissed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String photoId,
                required String revision,
                required String contract,
                required double x,
                required double y,
                required double w,
                required double h,
                Value<String> landmarksJson = const Value.absent(),
                Value<Uint8List?> vector = const Value.absent(),
                required String quality,
                Value<String?> cropPath = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> assignment = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleFacesCompanion.insert(
                id: id,
                photoId: photoId,
                revision: revision,
                contract: contract,
                x: x,
                y: y,
                w: w,
                h: h,
                landmarksJson: landmarksJson,
                vector: vector,
                quality: quality,
                cropPath: cropPath,
                personId: personId,
                assignment: assignment,
                dismissed: dismissed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleFacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleFacesTable,
      PeopleFaceRecord,
      $$PeopleFacesTableFilterComposer,
      $$PeopleFacesTableOrderingComposer,
      $$PeopleFacesTableAnnotationComposer,
      $$PeopleFacesTableCreateCompanionBuilder,
      $$PeopleFacesTableUpdateCompanionBuilder,
      (
        PeopleFaceRecord,
        BaseReferences<_$AppDatabase, $PeopleFacesTable, PeopleFaceRecord>,
      ),
      PeopleFaceRecord,
      PrefetchHooks Function()
    >;
typedef $$PeopleScansTableCreateCompanionBuilder =
    PeopleScansCompanion Function({
      required String photoId,
      required String revision,
      required String contract,
      required String status,
      Value<int> faces,
      required int completedMs,
      Value<int> rowid,
    });
typedef $$PeopleScansTableUpdateCompanionBuilder =
    PeopleScansCompanion Function({
      Value<String> photoId,
      Value<String> revision,
      Value<String> contract,
      Value<String> status,
      Value<int> faces,
      Value<int> completedMs,
      Value<int> rowid,
    });

class $$PeopleScansTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleScansTable> {
  $$PeopleScansTableFilterComposer({
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

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faces => $composableBuilder(
    column: $table.faces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedMs => $composableBuilder(
    column: $table.completedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleScansTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleScansTable> {
  $$PeopleScansTableOrderingComposer({
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

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faces => $composableBuilder(
    column: $table.faces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedMs => $composableBuilder(
    column: $table.completedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleScansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleScansTable> {
  $$PeopleScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get contract =>
      $composableBuilder(column: $table.contract, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get faces =>
      $composableBuilder(column: $table.faces, builder: (column) => column);

  GeneratedColumn<int> get completedMs => $composableBuilder(
    column: $table.completedMs,
    builder: (column) => column,
  );
}

class $$PeopleScansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleScansTable,
          PeopleScanRecord,
          $$PeopleScansTableFilterComposer,
          $$PeopleScansTableOrderingComposer,
          $$PeopleScansTableAnnotationComposer,
          $$PeopleScansTableCreateCompanionBuilder,
          $$PeopleScansTableUpdateCompanionBuilder,
          (
            PeopleScanRecord,
            BaseReferences<_$AppDatabase, $PeopleScansTable, PeopleScanRecord>,
          ),
          PeopleScanRecord,
          PrefetchHooks Function()
        > {
  $$PeopleScansTableTableManager(_$AppDatabase db, $PeopleScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<String> contract = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> faces = const Value.absent(),
                Value<int> completedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleScansCompanion(
                photoId: photoId,
                revision: revision,
                contract: contract,
                status: status,
                faces: faces,
                completedMs: completedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required String revision,
                required String contract,
                required String status,
                Value<int> faces = const Value.absent(),
                required int completedMs,
                Value<int> rowid = const Value.absent(),
              }) => PeopleScansCompanion.insert(
                photoId: photoId,
                revision: revision,
                contract: contract,
                status: status,
                faces: faces,
                completedMs: completedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleScansTable,
      PeopleScanRecord,
      $$PeopleScansTableFilterComposer,
      $$PeopleScansTableOrderingComposer,
      $$PeopleScansTableAnnotationComposer,
      $$PeopleScansTableCreateCompanionBuilder,
      $$PeopleScansTableUpdateCompanionBuilder,
      (
        PeopleScanRecord,
        BaseReferences<_$AppDatabase, $PeopleScansTable, PeopleScanRecord>,
      ),
      PeopleScanRecord,
      PrefetchHooks Function()
    >;
typedef $$PeopleDecisionsTableCreateCompanionBuilder =
    PeopleDecisionsCompanion Function({
      required String faceId,
      required String personId,
      required String decision,
      Value<int> rowid,
    });
typedef $$PeopleDecisionsTableUpdateCompanionBuilder =
    PeopleDecisionsCompanion Function({
      Value<String> faceId,
      Value<String> personId,
      Value<String> decision,
      Value<int> rowid,
    });

class $$PeopleDecisionsTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleDecisionsTable> {
  $$PeopleDecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleDecisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleDecisionsTable> {
  $$PeopleDecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleDecisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleDecisionsTable> {
  $$PeopleDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get faceId =>
      $composableBuilder(column: $table.faceId, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);
}

class $$PeopleDecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleDecisionsTable,
          PeopleDecisionRecord,
          $$PeopleDecisionsTableFilterComposer,
          $$PeopleDecisionsTableOrderingComposer,
          $$PeopleDecisionsTableAnnotationComposer,
          $$PeopleDecisionsTableCreateCompanionBuilder,
          $$PeopleDecisionsTableUpdateCompanionBuilder,
          (
            PeopleDecisionRecord,
            BaseReferences<
              _$AppDatabase,
              $PeopleDecisionsTable,
              PeopleDecisionRecord
            >,
          ),
          PeopleDecisionRecord,
          PrefetchHooks Function()
        > {
  $$PeopleDecisionsTableTableManager(
    _$AppDatabase db,
    $PeopleDecisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> faceId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleDecisionsCompanion(
                faceId: faceId,
                personId: personId,
                decision: decision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String faceId,
                required String personId,
                required String decision,
                Value<int> rowid = const Value.absent(),
              }) => PeopleDecisionsCompanion.insert(
                faceId: faceId,
                personId: personId,
                decision: decision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleDecisionsTable,
      PeopleDecisionRecord,
      $$PeopleDecisionsTableFilterComposer,
      $$PeopleDecisionsTableOrderingComposer,
      $$PeopleDecisionsTableAnnotationComposer,
      $$PeopleDecisionsTableCreateCompanionBuilder,
      $$PeopleDecisionsTableUpdateCompanionBuilder,
      (
        PeopleDecisionRecord,
        BaseReferences<
          _$AppDatabase,
          $PeopleDecisionsTable,
          PeopleDecisionRecord
        >,
      ),
      PeopleDecisionRecord,
      PrefetchHooks Function()
    >;
typedef $$PeopleReviewsTableCreateCompanionBuilder =
    PeopleReviewsCompanion Function({
      required String id,
      required String leftFaceId,
      required String rightFaceId,
      required String subset,
      required double cosine,
      Value<String> judgment,
      required String contract,
      Value<int> rowid,
    });
typedef $$PeopleReviewsTableUpdateCompanionBuilder =
    PeopleReviewsCompanion Function({
      Value<String> id,
      Value<String> leftFaceId,
      Value<String> rightFaceId,
      Value<String> subset,
      Value<double> cosine,
      Value<String> judgment,
      Value<String> contract,
      Value<int> rowid,
    });

class $$PeopleReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleReviewsTable> {
  $$PeopleReviewsTableFilterComposer({
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

  ColumnFilters<String> get leftFaceId => $composableBuilder(
    column: $table.leftFaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rightFaceId => $composableBuilder(
    column: $table.rightFaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subset => $composableBuilder(
    column: $table.subset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cosine => $composableBuilder(
    column: $table.cosine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get judgment => $composableBuilder(
    column: $table.judgment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleReviewsTable> {
  $$PeopleReviewsTableOrderingComposer({
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

  ColumnOrderings<String> get leftFaceId => $composableBuilder(
    column: $table.leftFaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rightFaceId => $composableBuilder(
    column: $table.rightFaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subset => $composableBuilder(
    column: $table.subset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cosine => $composableBuilder(
    column: $table.cosine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get judgment => $composableBuilder(
    column: $table.judgment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contract => $composableBuilder(
    column: $table.contract,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleReviewsTable> {
  $$PeopleReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get leftFaceId => $composableBuilder(
    column: $table.leftFaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rightFaceId => $composableBuilder(
    column: $table.rightFaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subset =>
      $composableBuilder(column: $table.subset, builder: (column) => column);

  GeneratedColumn<double> get cosine =>
      $composableBuilder(column: $table.cosine, builder: (column) => column);

  GeneratedColumn<String> get judgment =>
      $composableBuilder(column: $table.judgment, builder: (column) => column);

  GeneratedColumn<String> get contract =>
      $composableBuilder(column: $table.contract, builder: (column) => column);
}

class $$PeopleReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleReviewsTable,
          PeopleReviewRecord,
          $$PeopleReviewsTableFilterComposer,
          $$PeopleReviewsTableOrderingComposer,
          $$PeopleReviewsTableAnnotationComposer,
          $$PeopleReviewsTableCreateCompanionBuilder,
          $$PeopleReviewsTableUpdateCompanionBuilder,
          (
            PeopleReviewRecord,
            BaseReferences<
              _$AppDatabase,
              $PeopleReviewsTable,
              PeopleReviewRecord
            >,
          ),
          PeopleReviewRecord,
          PrefetchHooks Function()
        > {
  $$PeopleReviewsTableTableManager(_$AppDatabase db, $PeopleReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> leftFaceId = const Value.absent(),
                Value<String> rightFaceId = const Value.absent(),
                Value<String> subset = const Value.absent(),
                Value<double> cosine = const Value.absent(),
                Value<String> judgment = const Value.absent(),
                Value<String> contract = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleReviewsCompanion(
                id: id,
                leftFaceId: leftFaceId,
                rightFaceId: rightFaceId,
                subset: subset,
                cosine: cosine,
                judgment: judgment,
                contract: contract,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String leftFaceId,
                required String rightFaceId,
                required String subset,
                required double cosine,
                Value<String> judgment = const Value.absent(),
                required String contract,
                Value<int> rowid = const Value.absent(),
              }) => PeopleReviewsCompanion.insert(
                id: id,
                leftFaceId: leftFaceId,
                rightFaceId: rightFaceId,
                subset: subset,
                cosine: cosine,
                judgment: judgment,
                contract: contract,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleReviewsTable,
      PeopleReviewRecord,
      $$PeopleReviewsTableFilterComposer,
      $$PeopleReviewsTableOrderingComposer,
      $$PeopleReviewsTableAnnotationComposer,
      $$PeopleReviewsTableCreateCompanionBuilder,
      $$PeopleReviewsTableUpdateCompanionBuilder,
      (
        PeopleReviewRecord,
        BaseReferences<_$AppDatabase, $PeopleReviewsTable, PeopleReviewRecord>,
      ),
      PeopleReviewRecord,
      PrefetchHooks Function()
    >;
typedef $$PeopleStateTableCreateCompanionBuilder =
    PeopleStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<bool> paused,
      Value<int> generation,
      Value<double?> threshold,
      Value<String> calibrationJson,
    });
typedef $$PeopleStateTableUpdateCompanionBuilder =
    PeopleStateCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<bool> paused,
      Value<int> generation,
      Value<double?> threshold,
      Value<String> calibrationJson,
    });

class $$PeopleStateTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleStateTable> {
  $$PeopleStateTableFilterComposer({
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

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibrationJson => $composableBuilder(
    column: $table.calibrationJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleStateTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleStateTable> {
  $$PeopleStateTableOrderingComposer({
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

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibrationJson => $composableBuilder(
    column: $table.calibrationJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleStateTable> {
  $$PeopleStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => column);

  GeneratedColumn<String> get calibrationJson => $composableBuilder(
    column: $table.calibrationJson,
    builder: (column) => column,
  );
}

class $$PeopleStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleStateTable,
          PeopleStateRecord,
          $$PeopleStateTableFilterComposer,
          $$PeopleStateTableOrderingComposer,
          $$PeopleStateTableAnnotationComposer,
          $$PeopleStateTableCreateCompanionBuilder,
          $$PeopleStateTableUpdateCompanionBuilder,
          (
            PeopleStateRecord,
            BaseReferences<_$AppDatabase, $PeopleStateTable, PeopleStateRecord>,
          ),
          PeopleStateRecord,
          PrefetchHooks Function()
        > {
  $$PeopleStateTableTableManager(_$AppDatabase db, $PeopleStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<double?> threshold = const Value.absent(),
                Value<String> calibrationJson = const Value.absent(),
              }) => PeopleStateCompanion(
                id: id,
                enabled: enabled,
                paused: paused,
                generation: generation,
                threshold: threshold,
                calibrationJson: calibrationJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<double?> threshold = const Value.absent(),
                Value<String> calibrationJson = const Value.absent(),
              }) => PeopleStateCompanion.insert(
                id: id,
                enabled: enabled,
                paused: paused,
                generation: generation,
                threshold: threshold,
                calibrationJson: calibrationJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleStateTable,
      PeopleStateRecord,
      $$PeopleStateTableFilterComposer,
      $$PeopleStateTableOrderingComposer,
      $$PeopleStateTableAnnotationComposer,
      $$PeopleStateTableCreateCompanionBuilder,
      $$PeopleStateTableUpdateCompanionBuilder,
      (
        PeopleStateRecord,
        BaseReferences<_$AppDatabase, $PeopleStateTable, PeopleStateRecord>,
      ),
      PeopleStateRecord,
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
  $$MemoryEventsTableTableManager get memoryEvents =>
      $$MemoryEventsTableTableManager(_db, _db.memoryEvents);
  $$MemoryMembersTableTableManager get memoryMembers =>
      $$MemoryMembersTableTableManager(_db, _db.memoryMembers);
  $$SavedCaptionsTableTableManager get savedCaptions =>
      $$SavedCaptionsTableTableManager(_db, _db.savedCaptions);
  $$PhotoLocationsTableTableManager get photoLocations =>
      $$PhotoLocationsTableTableManager(_db, _db.photoLocations);
  $$PeoplePersonsTableTableManager get peoplePersons =>
      $$PeoplePersonsTableTableManager(_db, _db.peoplePersons);
  $$PeopleFacesTableTableManager get peopleFaces =>
      $$PeopleFacesTableTableManager(_db, _db.peopleFaces);
  $$PeopleScansTableTableManager get peopleScans =>
      $$PeopleScansTableTableManager(_db, _db.peopleScans);
  $$PeopleDecisionsTableTableManager get peopleDecisions =>
      $$PeopleDecisionsTableTableManager(_db, _db.peopleDecisions);
  $$PeopleReviewsTableTableManager get peopleReviews =>
      $$PeopleReviewsTableTableManager(_db, _db.peopleReviews);
  $$PeopleStateTableTableManager get peopleState =>
      $$PeopleStateTableTableManager(_db, _db.peopleState);
}
