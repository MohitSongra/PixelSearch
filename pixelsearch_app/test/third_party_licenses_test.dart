import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/core/theme.dart';
import 'package:pixelsearch/core/third_party_licenses.dart';
import 'package:pixelsearch/features/settings/settings_screen.dart';

import 'indexed_gallery_widgets_test.dart' show fixtures, scope;

void main() {
  testWidgets('the bundled model, vocabulary and font are on the licence '
      'page', (tester) async {
    registerThirdPartyLicenses();
    final entries = (await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    ))!;
    String textOf(String package) => entries
        .firstWhere((e) => e.packages.contains(package))
        .paragraphs
        .map((p) => p.text)
        .join('\n');
    expect(
      textOf('SFace face recognition model (OpenCV Zoo)'),
      contains('Apache License'),
    );
    expect(
      textOf('CLIP tokenizer vocabulary (OpenAI CLIP, OpenCLIP)'),
      allOf(contains('Copyright (c) 2021 OpenAI'), contains('MIT License')),
    );
    expect(textOf('Manrope font'), contains('SIL OPEN FONT LICENSE'));
    expect(
      textOf('Material Icons font'),
      contains('Attribution 4.0 International'),
    );
    expect(
      textOf('ONNX Runtime (native library)'),
      contains('Copyright (c) Microsoft Corporation'),
    );
  });

  testWidgets('Settings tells users about ML Kit metrics, and About opens the '
      'licences', (tester) async {
    // Tall enough that the lazily built Settings list includes its last tile.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = scope(fixtures(3));
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ML Kit sends metrics about its performance and use'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('about-pixelsearch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('All rights reserved'), findsOneWidget);
    expect(find.text('View licenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
