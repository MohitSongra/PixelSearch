import '../models/photo.dart';

/// Web / unsupported-platform stub. Device gallery access needs native APIs,
/// so on the web the app simply runs on the bundled sample photos.
class DeviceGallery {
  /// Whether real device-gallery access is available on this platform.
  static bool get isSupported => false;

  /// Returns an empty list on unsupported platforms.
  static Future<List<Photo>> load({int limit = 80}) async => <Photo>[];
}
