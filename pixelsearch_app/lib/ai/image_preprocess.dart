import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/ai_contract.dart';

/// A model-ready image tensor: CHW float32 data plus its shape `[1,3,S,S]`.
class PreprocessedImage {
  const PreprocessedImage(this.data, this.shape);
  final Float32List data;
  final List<int> shape;
}

/// Deterministic image preprocessing matching the verified open_clip
/// MobileCLIP-S1 transform (INTERFACE_CONTRACT.md §3):
///
///   RGB → resize shortest side to [size] (antialiased bilinear) →
///   centre-crop [size]×[size] → /255 into [0,1] → NO mean/std → CHW `[1,3,S,S]`.
///
/// The resize replicates PIL / torchvision(antialias) bilinear — a separable
/// triangle filter whose support scales with the downsample ratio — because
/// open_clip resizes a PIL image, which always antialiases. Pure & synchronous,
/// so it is unit-testable without a device or ONNX Runtime.
PreprocessedImage preprocessForClip(
  img.Image source, {
  int size = AiContract.imageSize,
}) {
  // 1. Ensure 8-bit RGB (drop alpha / palette).
  final rgb = (source.numChannels == 3 && source.format == img.Format.uint8)
      ? source
      : source.convert(numChannels: 3, format: img.Format.uint8);
  final w = rgb.width, h = rgb.height;

  // Extract channels as float (0..255).
  //
  // Read straight out of the packed RGB buffer rather than calling getPixel()
  // per pixel: `getPixel` materialises a Pixel accessor for every one of the
  // w*h coordinates, which at 1200x1600 measured ~445 ms per photo on device and
  // dominated indexing throughput (TECHNICAL_DEBT TD-9). The values are the same
  // uint8 channel samples widened to double, so the tensor is **bit-identical** —
  // guarded by the preprocessing fingerprint in preprocessing_golden_test.dart.
  final r = Float64List(w * h), g = Float64List(w * h), b = Float64List(w * h);
  final packed = rgb.getBytes(order: img.ChannelOrder.rgb);
  for (var idx = 0, p = 0; idx < w * h; idx++, p += 3) {
    r[idx] = packed[p].toDouble();
    g[idx] = packed[p + 1].toDouble();
    b[idx] = packed[p + 2].toDouble();
  }

  // 2. Resize shortest side to `size`, preserving aspect ratio. torchvision's
  // Resize(size) sets the longer edge to int(size*long/short) — TRUNCATION, not
  // rounding. That one-pixel detail shifts the crop, so we replicate it exactly.
  final int newW, newH;
  if (w <= h) {
    newW = size;
    newH = (size * h / w).toInt();
  } else {
    newH = size;
    newW = (size * w / h).toInt();
  }

  final hx = _precompute(w, newW);
  final vy = _precompute(h, newH);
  final rV = _vpass(_hpass(r, w, h, newW, hx), newW, h, newH, vy);
  final gV = _vpass(_hpass(g, w, h, newW, hx), newW, h, newH, vy);
  final bV = _vpass(_hpass(b, w, h, newW, hx), newW, h, newH, vy);

  // 3. Centre-crop size×size (torchvision uses Python round-half-to-even for the
  //    offset). 4. Scale /255 into [0,1], lay out CHW.
  final left = _pyRound((newW - size) / 2);
  final top = _pyRound((newH - size) / 2);
  final data = Float32List(3 * size * size);
  const rPlane = 0;
  final gPlane = size * size;
  final bPlane = 2 * size * size;
  var o = 0;
  for (var y = 0; y < size; y++) {
    final srcRow = (top + y) * newW + left;
    for (var x = 0; x < size; x++) {
      final si = srcRow + x;
      data[rPlane + o] = _clip01(rV[si]);
      data[gPlane + o] = _clip01(gV[si]);
      data[bPlane + o] = _clip01(bV[si]);
      o++;
    }
  }
  return PreprocessedImage(data, [1, 3, size, size]);
}

double _clip01(double v255) {
  final v = v255 / AiContract.pixelScale;
  return v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
}

/// Python's round (half-to-even / banker's), as used by torchvision CenterCrop.
int _pyRound(double x) {
  final f = x.floorToDouble();
  final diff = x - f;
  if (diff < 0.5) return f.toInt();
  if (diff > 0.5) return f.toInt() + 1;
  final fi = f.toInt();
  return fi.isEven ? fi : fi + 1; // exactly .5 → nearest even
}

/// PIL/torchvision produce a uint8 image at each resize pass, so reference pixel
/// values are exact multiples of 1/255. Round-and-clamp to match bit-for-bit.
double _u8(double v) {
  final r = v.roundToDouble();
  return r < 0.0 ? 0.0 : (r > 255.0 ? 255.0 : r);
}

/// Precomputed 1-D resample coefficients (triangle filter, PIL-equivalent).
class _Axis {
  _Axis(this.bounds, this.weights);
  final Int32List bounds; // [xmin, n] per output index
  final List<Float64List> weights;
}

_Axis _precompute(int inSize, int outSize) {
  final scale = inSize / outSize;
  final filterscale = scale >= 1.0 ? scale : 1.0;
  final support = filterscale; // triangle filter support = 1.0
  final invScale = 1.0 / filterscale;
  final bounds = Int32List(outSize * 2);
  final weights = List<Float64List>.filled(outSize, Float64List(0));
  for (var i = 0; i < outSize; i++) {
    final center = (i + 0.5) * scale;
    var xmin = (center - support + 0.5).floor();
    if (xmin < 0) xmin = 0;
    var xmax = (center + support + 0.5).floor();
    if (xmax > inSize) xmax = inSize;
    final n = xmax - xmin;
    final k = Float64List(n);
    var sum = 0.0;
    for (var j = 0; j < n; j++) {
      final t = ((xmin + j) - center + 0.5) * invScale;
      final at = t < 0 ? -t : t;
      final wt = at < 1.0 ? 1.0 - at : 0.0;
      k[j] = wt;
      sum += wt;
    }
    if (sum > 0) {
      for (var j = 0; j < n; j++) {
        k[j] /= sum;
      }
    }
    bounds[i * 2] = xmin;
    bounds[i * 2 + 1] = n;
    weights[i] = k;
  }
  return _Axis(bounds, weights);
}

/// Horizontal resample: `src` is (h × inW) row-major → returns (h × outW).
Float64List _hpass(Float64List src, int inW, int h, int outW, _Axis ax) {
  final out = Float64List(h * outW);
  for (var y = 0; y < h; y++) {
    final rowIn = y * inW, rowOut = y * outW;
    for (var x = 0; x < outW; x++) {
      final xmin = ax.bounds[x * 2], n = ax.bounds[x * 2 + 1];
      final k = ax.weights[x];
      var s = 0.0;
      for (var j = 0; j < n; j++) {
        s += k[j] * src[rowIn + xmin + j];
      }
      out[rowOut + x] = _u8(s); // 8-bit intermediate, like PIL
    }
  }
  return out;
}

/// Vertical resample: `src` is (inH × w) → returns (outH × w).
Float64List _vpass(Float64List src, int w, int inH, int outH, _Axis ax) {
  final out = Float64List(outH * w);
  for (var y = 0; y < outH; y++) {
    final ymin = ax.bounds[y * 2], n = ax.bounds[y * 2 + 1];
    final k = ax.weights[y];
    final rowOut = y * w;
    for (var x = 0; x < w; x++) {
      var s = 0.0;
      for (var j = 0; j < n; j++) {
        s += k[j] * src[(ymin + j) * w + x];
      }
      out[rowOut + x] = _u8(s); // 8-bit result, like PIL
    }
  }
  return out;
}
