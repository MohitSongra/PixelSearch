import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixelsearch/app.dart';

void main() {
  testWidgets('App boots to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PixelSearchApp()));
    await tester.pumpAndSettle();

    // Onboarding headline is visible.
    expect(find.textContaining('Search your'), findsOneWidget);
    // At least one call-to-action button exists.
    expect(find.byType(OutlinedButton), findsWidgets);
  });
}
