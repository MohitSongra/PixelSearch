import 'dart:io';

import 'package:workmanager/workmanager.dart';

import 'indexing_wiring.dart';

/// WorkManager requires the top-level callback to be registered before any task
/// is scheduled. Keep desktop tests and non-Android builds free of this plugin
/// call; PixelSearch is Android-first today.
Future<void> initializeBackgroundIndexing() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(indexCallbackDispatcher);
}
