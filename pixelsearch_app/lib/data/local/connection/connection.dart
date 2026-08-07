// Chooses the database connection at compile time:
//   • native SQLite (Android / iOS / desktop) when `dart:io` is available,
//   • a web/unsupported stub otherwise.
// This mirrors the device_gallery conditional pattern and is why the web build
// still compiles even though there is no web DB backend yet (docs/KNOWN_ISSUES.md KI-3).
export 'connection_stub.dart' if (dart.library.io) 'connection_native.dart';
