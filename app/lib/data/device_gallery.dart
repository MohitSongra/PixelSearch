// Conditional export: on mobile/desktop (dart:io) use the photo_manager
// implementation; on web fall back to a stub so the app still compiles and
// runs with the bundled sample photos.
export 'device_gallery_stub.dart'
    if (dart.library.io) 'device_gallery_io.dart';
