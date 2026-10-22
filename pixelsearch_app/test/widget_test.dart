import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixelsearch/app.dart';
import 'package:pixelsearch/state/providers.dart';

void main() {
  testWidgets('App boots to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [skipOnboardingProvider.overrideWith((ref) async => false)],
        child: const PixelSearchApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Onboarding headline is visible.
    expect(find.textContaining('Search your'), findsOneWidget);
    // At least one call-to-action button exists.
    expect(find.byType(OutlinedButton), findsWidgets);
    // Onboarding makes no unmeasured speed claim, and says how online
    // features change the "nothing is uploaded" promise.
    expect(find.textContaining('seconds'), findsNothing);
    expect(
      find.textContaining('unless you turn on an online feature'),
      findsOneWidget,
    );
  });
}
