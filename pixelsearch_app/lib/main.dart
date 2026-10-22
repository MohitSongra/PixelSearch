import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/third_party_licenses.dart';
import 'indexing/adapters/background_indexing_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerThirdPartyLicenses();
  await initializeBackgroundIndexing();
  runApp(const ProviderScope(child: PixelSearchApp()));
}
