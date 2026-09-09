/// Single Dart mirror of INTERFACE_CONTRACT.md (owned by ModelKit — the source
/// of truth). Do **not** change a value here without bumping the contract and
/// re-verifying parity; any drift from the contract is a critical bug.
///
/// See `docs/INTERFACE_CONTRACT.md` (§0 versions, §3 image, §4 text).
class AiContract {
  AiContract._();

  // --- Versions (contract §0 / §9) ---
  static const String modelId = 'MobileCLIP-S1';
  static const String modelVersion = '1.0';

  /// Governs the STORED image-embedding pipeline (model + image preprocessing).
  /// Bump ⇒ full, resumable re-index of every photo. See MIGRATIONS.md §B.
  static const String embeddingVersion = '1';

  /// Version of the physical exported files (ONNX + vocab). v3 repairs the
  /// invalid fp16 Cast metadata emitted by the previous converter; model and
  /// preprocessing contracts are unchanged (see MIGRATIONS.md).
  static const String artifactVersion = '3';

  /// The on-device SQLite schema version (AppDatabase.schemaVersion). v4 adds
  /// saved folder selection; model artifacts and embeddings are unchanged.
  static const int schemaVersion = 4;

  // --- Model geometry (contract §1, §3, §4) ---
  static const int embeddingDim = 512;

  /// Shorter side is resized to this, then a centre [imageSize]×[imageSize] crop.
  static const int imageSize = 256;

  static const int contextLength = 77;
  static const int sotToken = 49406;
  static const int eotToken = 49407;
  static const int padToken = 0;

  // Pixel handling (contract §3): decode RGB → resize shortest side (bilinear,
  // antialias) → centre-crop → /255 into [0,1] → NO mean/std → CHW float32.
  static const double pixelScale = 255.0;

  // ONNX tensor names (contract §3, §4).
  static const String imageInputName = 'pixel_values';
  static const String imageOutputName = 'image_embeds';
  static const String textInputName = 'input_ids';
  static const String textOutputName = 'text_embeds';
}
