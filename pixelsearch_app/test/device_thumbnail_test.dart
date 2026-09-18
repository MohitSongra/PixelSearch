import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixelsearch/core/platform_image_io.dart';

Future<ImageInfo> resolve(ImageProvider provider) {
  final done = Completer<ImageInfo>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      done.complete(info);
    },
    onError: (Object error, StackTrace? stack) {
      stream.removeListener(listener);
      done.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  return done.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 3)));
  for (final cache in ['valid', 'missing', 'corrupt', 'none']) {
    test(
      'device preview recovers $cache cache without changing storage',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'pixelsearch_thumbnail_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/preview.png');
        if (cache == 'valid') await file.writeAsBytes(png);
        if (cache == 'corrupt') await file.writeAsString('invalid image');
        var calls = 0;
        final provider = DeviceThumbnailImage(
          'asset',
          cache == 'none' ? null : file.path,
          galleryThumbnail: (id) async {
            expect(id, 'asset');
            calls++;
            return png;
          },
        );
        final image = await resolve(provider);
        expect(image.image.width, 4);
        expect(calls, cache == 'valid' ? 0 : 1);
        if (cache == 'missing' || cache == 'none') {
          expect(await file.exists(), isFalse);
        }
        await provider.evict();
        image.dispose();
      },
    );
  }
  test(
    'unavailable gallery asset renders a placeholder without image errors',
    () async {
      final provider = DeviceThumbnailImage(
        'denied',
        null,
        galleryThumbnail: (_) async => throw StateError('Access denied'),
      );
      final image = await resolve(provider);
      expect(image.image.width, 1);
      await provider.evict();
      image.dispose();
    },
  );
}
