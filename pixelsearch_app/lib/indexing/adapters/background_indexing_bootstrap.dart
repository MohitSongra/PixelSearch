import 'background_indexing_bootstrap_stub.dart'
    if (dart.library.io) 'background_indexing_bootstrap_io.dart'
    as impl;

/// Registers the Android WorkManager callback without making web builds import
/// device-only indexing adapters.
Future<void> initializeBackgroundIndexing() =>
    impl.initializeBackgroundIndexing();
