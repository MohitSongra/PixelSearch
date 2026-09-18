/// Mirrored from ModelKit FACE_CONTRACT.md. Independent of MobileCLIP.
abstract final class FaceContract {
  static const id = 'sface-2021dec-mlkit-landmarks-v1';
  static const asset = 'assets/models/face_recognition_sface_2021dec.onnx';
  static const sha256 =
      '0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79';
  static const dimensions = 128;
  static const imageSize = 112;
  static const input = 'data';
  static const output = 'fc1';
  static const minFacePixels = 100;
  static const landmarks = <(double, double)>[
    (38.2946, 51.6963),
    (73.5318, 51.5014),
    (56.0252, 71.7366),
    (41.5493, 92.3655),
    (70.7299, 92.2041),
  ];
}
