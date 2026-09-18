import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// New RGB image deliberately drops EXIF, XMP and filename metadata.
Uint8List prepareCaptionImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image format.');
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1280 || oriented.height > 1280
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1280 : null,
          height: oriented.height > oriented.width ? 1280 : null,
        )
      : oriented;
  final clean = img.Image.fromBytes(
    width: resized.width,
    height: resized.height,
    bytes: resized.getBytes(order: img.ChannelOrder.rgb).buffer,
    numChannels: 3,
  );
  return Uint8List.fromList(img.encodeJpg(clean, quality: 85));
}
