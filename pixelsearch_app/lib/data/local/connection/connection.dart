// Chooses the database connection at compile time:
//   • native SQLite (Android / iOS / desktop) when `dart:io` is available,
//   • a web/unsupported stub otherwise.
// The unsupported stub keeps native database APIs behind a platform boundary.
export 'connection_stub.dart' if (dart.library.io) 'connection_native.dart';
