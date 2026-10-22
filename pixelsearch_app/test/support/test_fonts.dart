import 'package:flutter/services.dart';

/// Loads real glyph metrics for widget tests on every host.
///
/// Without a real font, text renders in the wide FlutterTest font. Tests used
/// to load a Windows system font only when it existed, so layout tests passed
/// on Windows and failed on the Linux CI runner. The app's bundled Manrope
/// (OFL-1.1, `assets/fonts/`) is registered under its own name and as
/// Material's default 'Roboto', for tests that mount a bare `MaterialApp`.
Future<void> loadTestFonts() async {
  final manrope = rootBundle.load('assets/fonts/Manrope.ttf');
  for (final family in ['Manrope', 'Roboto']) {
    await (FontLoader(family)..addFont(manrope)).load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}
