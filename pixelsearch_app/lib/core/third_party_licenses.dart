import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Adds the bundled non-package components to Flutter's licence page
/// (Settings > About PixelSearch > View licenses). Dart and Flutter packages
/// are collected automatically; these are assets or native libraries, so they are not.
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'SFace face recognition model (OpenCV Zoo)',
    ], await rootBundle.loadString('assets/models/SFACE_LICENSE.txt'));
    yield LicenseEntryWithLineBreaks(
      const ['CLIP tokenizer vocabulary (OpenAI CLIP, OpenCLIP)'],
      await rootBundle.loadString('assets/licenses/CLIP_TOKENIZER_LICENSE.txt'),
    );
    yield LicenseEntryWithLineBreaks(const [
      'Manrope font',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(
      const ['Material Icons font'],
      await rootBundle.loadString('assets/licenses/MATERIAL_ICONS_LICENSE.txt'),
    );
    yield LicenseEntryWithLineBreaks(const [
      'ONNX Runtime (native library)',
    ], await rootBundle.loadString('assets/licenses/ONNXRUNTIME_LICENSE.txt'));
  });
}
