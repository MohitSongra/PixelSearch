import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/core/theme.dart';
import 'package:pixelsearch/features/search/search_screen.dart';
import 'package:pixelsearch/features/viewer/photo_viewer.dart';
import 'package:pixelsearch/state/providers.dart';

import 'support/test_fonts.dart';

import 'indexed_gallery_widgets_test.dart'
    show TestLibrary, fixtures, galleryPosition, scope;

final _homeScroll = find.byKey(const PageStorageKey('indexed-gallery-scroll'));

Future<void> _mountHome(
  WidgetTester tester,
  ProviderContainer container, {
  Size size = const Size(412, 915),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SearchScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectSearchVisible(WidgetTester tester) {
  final viewport = tester.getRect(_homeScroll);
  final search = tester.getRect(find.byType(TextField));
  expect(search.top, greaterThanOrEqualTo(viewport.top));
  expect(search.bottom, lessThanOrEqualTo(viewport.bottom));
  expect(find.byType(TextField).hitTestable(), findsOneWidget);
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('Home scrolls from its introduction, suggestions and photos', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(tester, container);

    final origins = <String, Finder>{
      'introduction': find.text('Find a moment.'),
      'supporting copy': find.text('Places, people, or the little details.'),
      'suggestion': find.byKey(const ValueKey('library-suggestion-flower')),
      'library summary': find.text('Your photos'),
      'photo': find.byKey(const ValueKey('indexed-photo-photo-0')),
    };
    for (final origin in origins.entries) {
      galleryPosition(tester).jumpTo(0);
      await tester.pumpAndSettle();
      expect(origin.value.hitTestable(), findsOneWidget, reason: origin.key);
      await tester.drag(origin.value, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(
        galleryPosition(tester).pixels,
        greaterThan(100),
        reason: 'A vertical drag on ${origin.key} should scroll Home.',
      );
      expect(find.text('Find a moment.').hitTestable(), findsNothing);
      _expectSearchVisible(tester);
    }

    final pinnedTop = tester.getTopLeft(find.byType(TextField)).dy;
    await tester.dragFrom(
      tester.getRect(_homeScroll).bottomCenter - const Offset(0, 100),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      closeTo(pinnedTop, .5),
    );
    _expectSearchVisible(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal suggestions leave the Home position unchanged', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(tester, container);
    await tester.drag(
      find.byKey(const ValueKey('library-suggestion-flower')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(galleryPosition(tester).pixels, 0);
    expect(container.read(searchQueryProvider), isEmpty);
    expect(find.text('Find a moment.').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date drag from expanded Home reaches the oldest photo', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(tester, container);
    final thumb = find.byKey(const ValueKey('gallery-date-scrubber'));
    final thumbBounds = tester.getRect(thumb);
    final viewport = tester.getRect(_homeScroll);
    expect(thumbBounds.size, const Size(48, 48));
    final gesture = await tester.startGesture(thumbBounds.center);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 4));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('indexed-photo-photo-119')).hitTestable(),
      findsOneWidget,
    );
    expect(
      galleryPosition(tester).pixels,
      closeTo(galleryPosition(tester).maxScrollExtent, 1),
    );
    _expectSearchVisible(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned search blocks photo taps and keeps focus while typing', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(tester, container, dark: true);
    await tester.drag(_homeScroll, const Offset(0, -700));
    await tester.pumpAndSettle();
    _expectSearchVisible(tester);

    final field = tester.getRect(find.byType(TextField));
    // A gallery tile spans x=12..viewportWidth-12 beneath the pinned header.
    // Its covered portion beside the search capsule must not receive this tap.
    await tester.tapAt(Offset(18, field.center.dy));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    tester.testTextInput.enterText('f');
    await tester.pumpAndSettle();
    expect(container.read(searchQueryProvider), 'f');
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(editable),
    );
    expect(editable.widget.focusNode.hasFocus, isTrue);
    tester.testTextInput.enterText('flower');
    await tester.pumpAndSettle();
    expect(container.read(searchQueryProvider), 'flower');
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and keyboard keep search and the gallery usable', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(
      tester,
      container,
      size: const Size(320, 740),
      textScale: 2,
    );
    expect(find.text('Find a moment.'), findsNothing);
    expect(
      find.byKey(const ValueKey('indexed-photo-photo-0')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    _expectSearchVisible(tester);
    await tester.dragFrom(
      tester.getRect(_homeScroll).bottomCenter - const Offset(0, 30),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(galleryPosition(tester).pixels, greaterThan(50));
    _expectSearchVisible(tester);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scrolled library can become empty and populate again', (
    tester,
  ) async {
    final container = scope(fixtures(120));
    addTearDown(container.dispose);
    await _mountHome(tester, container);
    galleryPosition(tester).jumpTo(galleryPosition(tester).maxScrollExtent);
    await tester.pumpAndSettle();

    final library =
        container.read(photoLibraryProvider.notifier) as TestLibrary;
    library.replace([]);
    await tester.pumpAndSettle();
    expect(find.text('Your memories start here'), findsOneWidget);
    expect(find.byTooltip('Index photos'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-date-scrubber')), findsNothing);
    expect(find.text('Try a search'), findsNothing);
    _expectSearchVisible(tester);
    expect(
      galleryPosition(tester).pixels,
      lessThanOrEqualTo(galleryPosition(tester).maxScrollExtent),
    );

    library.replace(fixtures(6));
    await tester.pumpAndSettle();
    galleryPosition(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Your memories start here'), findsNothing);
    expect(
      find.byKey(const ValueKey('indexed-photo-photo-0')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('6 photos indexed'), findsOneWidget);
    _expectSearchVisible(tester);
    expect(tester.takeException(), isNull);
  });
}
