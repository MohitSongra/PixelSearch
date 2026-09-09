import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../integration_test/support/modelkit_paths.dart';

void main() {
  group('ModelKitPaths', () {
    test('uses an explicit location before the sibling checkout default', () {
      final paths = ModelKitPaths.resolve(
        environmentValue: r'C:\models\pixelsearch',
        workingDirectory: r'C:\work\pixelsearch_app',
      );

      expect(paths.root, p.normalize(r'C:\models\pixelsearch'));
      expect(
        paths.imageModel,
        p.join(
          p.normalize(r'C:\models\pixelsearch'),
          'out',
          'mobileclip_image.onnx',
        ),
      );
    });

    test('defaults to a sibling model_kit directory', () {
      final paths = ModelKitPaths.resolve(
        environmentValue: '',
        workingDirectory: r'C:\work\pixelsearch_app',
      );

      expect(paths.root, p.normalize(r'C:\work\model_kit'));
    });

    test('reports all missing fixture inputs together', () {
      final paths = ModelKitPaths.resolve(
        environmentValue: r'C:\missing-model-kit',
      );

      expect(
        () => paths.requireFiles(includeImages: true),
        throwsA(
          isA<StateError>()
              .having(
                (error) => error.message,
                'message',
                contains('PIXELSEARCH_MODELKIT'),
              )
              .having(
                (error) => error.message,
                'missing image model',
                contains('mobileclip_image.onnx'),
              ),
        ),
      );
    });
  });
}
