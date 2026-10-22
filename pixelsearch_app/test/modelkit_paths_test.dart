import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../integration_test/support/modelkit_paths.dart';

void main() {
  // Paths are built from the host's own root ("C:\" or "/"), so the same
  // expectations hold on the Windows host and the Linux CI runner.
  final root = p.rootPrefix(p.current);

  group('ModelKitPaths', () {
    test('uses an explicit location before the sibling checkout default', () {
      final models = p.join(root, 'models', 'pixelsearch');
      final paths = ModelKitPaths.resolve(
        environmentValue: models,
        workingDirectory: p.join(root, 'work', 'pixelsearch_app'),
      );

      expect(paths.root, p.normalize(models));
      expect(
        paths.imageModel,
        p.join(p.normalize(models), 'out', 'mobileclip_image.onnx'),
      );
    });

    test('defaults to a sibling model_kit directory', () {
      final paths = ModelKitPaths.resolve(
        environmentValue: '',
        workingDirectory: p.join(root, 'work', 'pixelsearch_app'),
      );

      expect(paths.root, p.join(root, 'work', 'model_kit'));
    });

    test('reports all missing fixture inputs together', () {
      final paths = ModelKitPaths.resolve(
        environmentValue: p.join(root, 'missing-model-kit'),
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
