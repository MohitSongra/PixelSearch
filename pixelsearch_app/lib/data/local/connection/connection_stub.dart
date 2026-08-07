import 'package:drift/drift.dart';

/// Web / unsupported platforms: PixelSearch's local database is native-only for
/// now. Reading the database provider on such a platform throws; nothing in the
/// current (M2) code path does. See docs/KNOWN_ISSUES.md (KI-3) and ADR-007.
QueryExecutor openConnection() => throw UnsupportedError(
      'PixelSearch local database is native-only (Android/iOS/desktop) for now. '
      'Web has no persistence backend yet — see docs/KNOWN_ISSUES.md (KI-3).',
    );
