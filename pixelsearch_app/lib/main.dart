import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'indexing/adapters/background_indexing_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundIndexing();
  runApp(const ProviderScope(child: PixelSearchApp()));
}
