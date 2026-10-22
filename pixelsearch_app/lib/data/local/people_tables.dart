import 'package:drift/drift.dart';

@DataClassName('PersonRecord')
class PeoplePersons extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get aliasesJson => text().withDefault(const Constant('[]'))();
  TextColumn get coverFaceId => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  IntColumn get createdMs => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeopleFaceRecord')
class PeopleFaces extends Table {
  TextColumn get id => text()();
  TextColumn get photoId => text()();
  TextColumn get revision => text()();
  TextColumn get contract => text()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get w => real()();
  RealColumn get h => real()();
  TextColumn get landmarksJson => text().withDefault(const Constant('[]'))();
  BlobColumn get vector => blob().nullable()();
  TextColumn get quality => text()();
  TextColumn get cropPath => text().nullable()();
  TextColumn get personId => text().nullable()();
  TextColumn get assignment =>
      text().withDefault(const Constant('unassigned'))();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeopleScanRecord')
class PeopleScans extends Table {
  TextColumn get photoId => text()();
  TextColumn get revision => text()();
  TextColumn get contract => text()();
  TextColumn get status => text()();
  IntColumn get faces => integer().withDefault(const Constant(0))();
  IntColumn get completedMs => integer()();
  @override
  Set<Column> get primaryKey => {photoId};
}

@DataClassName('PeopleDecisionRecord')
class PeopleDecisions extends Table {
  TextColumn get faceId => text()();
  TextColumn get personId => text()();
  TextColumn get decision => text()();
  @override
  Set<Column> get primaryKey => {faceId, personId};
}

@DataClassName('PeopleReviewRecord')
class PeopleReviews extends Table {
  TextColumn get id => text()();
  TextColumn get leftFaceId => text()();
  TextColumn get rightFaceId => text()();
  TextColumn get subset => text()();
  RealColumn get cosine => real()();
  TextColumn get judgment => text().withDefault(const Constant('pending'))();
  TextColumn get contract => text()();

  /// The reviewed photos (v7). Face ids include the photo revision, so after
  /// an edit only these still identify a reviewed photo. Null for review rows
  /// whose faces were already gone when the column was added.
  TextColumn get leftPhotoId => text().nullable()();
  TextColumn get rightPhotoId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PeopleStateRecord')
class PeopleState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  BoolColumn get paused => boolean().withDefault(const Constant(false))();
  IntColumn get generation => integer().withDefault(const Constant(0))();
  RealColumn get threshold => real().nullable()();
  TextColumn get calibrationJson => text().withDefault(const Constant('{}'))();
  @override
  Set<Column> get primaryKey => {id};
}
