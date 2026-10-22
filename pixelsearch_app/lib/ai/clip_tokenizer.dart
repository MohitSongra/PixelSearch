import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../core/ai_contract.dart';

/// Exact Dart port of open_clip's `SimpleTokenizer` (CLIP byte-pair encoding),
/// verified id-for-id against Python (see `test/clip_tokenizer_test.dart`).
/// OpenCLIP and the OpenAI CLIP vocabulary are MIT-licensed; their notices are
/// in `assets/licenses/CLIP_TOKENIZER_LICENSE.txt` and on the in-app licence page.
///
/// Pure and deterministic. The vocab (`bpe_simple_vocab_16e6.txt.gz`) is supplied
/// once at construction — from the bundled asset in the app, or from a file in
/// tests — and reused for every call, so nothing is re-parsed per query.
class ClipTokenizer {
  ClipTokenizer._(
    this._byteEncoder,
    this._encoder,
    this._bpeRanks,
    this._pat,
    this.sotToken,
    this.eotToken,
    this.contextLength,
  );

  final Map<int, String> _byteEncoder; // utf-8 byte -> unicode char
  final Map<String, int> _encoder; // symbol -> token id
  final Map<String, int> _bpeRanks; // "first second" -> merge rank
  final RegExp _pat;
  final Map<String, String> _cache = {};

  final int sotToken;
  final int eotToken;
  final int contextLength;

  static const int padToken = AiContract.padToken;

  // --- construction --------------------------------------------------------

  /// Build from the decompressed vocab text (the pure, platform-free path).
  factory ClipTokenizer.fromVocabText(
    String vocabText, {
    int contextLength = AiContract.contextLength,
  }) {
    final byteEncoder = _bytesToUnicode();

    // merges = lines[1 : 49152-256-2+1]  (== lines[1:48895]) — matches open_clip.
    final lines = vocabText.split('\n');
    const mergeEnd = 49152 - 256 - 2 + 1;
    final merges = <List<String>>[];
    for (var i = 1; i < mergeEnd && i < lines.length; i++) {
      final parts = lines[i].split(' ');
      if (parts.length == 2) merges.add(parts);
    }

    // vocab = byte chars + byte chars+'</w>' + merged strings + 2 specials.
    final vocab = <String>[
      ...byteEncoder.values,
      for (final c in byteEncoder.values) '$c</w>',
      for (final m in merges) m[0] + m[1],
      '<start_of_text>',
      '<end_of_text>',
    ];
    final encoder = <String, int>{};
    for (var i = 0; i < vocab.length; i++) {
      encoder[vocab[i]] = i;
    }
    final bpeRanks = <String, int>{};
    for (var i = 0; i < merges.length; i++) {
      bpeRanks['${merges[i][0]} ${merges[i][1]}'] = i;
    }

    // Same token-splitting regex as open_clip (input is already lowercased).
    final pat = RegExp(
      r"<start_of_text>|<end_of_text>|'s|'t|'re|'ve|'m|'ll|'d|\p{L}+|\p{N}|[^\s\p{L}\p{N}]+",
      unicode: true,
      caseSensitive: false,
    );

    return ClipTokenizer._(
      byteEncoder,
      encoder,
      bpeRanks,
      pat,
      encoder['<start_of_text>']!,
      encoder['<end_of_text>']!,
      contextLength,
    );
  }

  /// Build from gzipped vocab bytes (native — uses `dart:io` gzip).
  factory ClipTokenizer.fromGzipBytes(
    Uint8List gz, {
    int contextLength = AiContract.contextLength,
  }) => ClipTokenizer.fromVocabText(
    utf8.decode(gzip.decode(gz)),
    contextLength: contextLength,
  );

  /// Build from a gzipped vocab file on disk (tests / provisioned model dir).
  static Future<ClipTokenizer> fromGzipFile(
    String path, {
    int contextLength = AiContract.contextLength,
  }) async {
    final bytes = await File(path).readAsBytes();
    return ClipTokenizer.fromGzipBytes(bytes, contextLength: contextLength);
  }

  /// Build from the app's bundled gzipped vocab asset (production path).
  static Future<ClipTokenizer> fromAsset({
    String assetKey = 'assets/models/bpe_simple_vocab_16e6.txt.gz',
    int contextLength = AiContract.contextLength,
  }) async {
    final data = await rootBundle.load(assetKey);
    return ClipTokenizer.fromGzipBytes(
      data.buffer.asUint8List(),
      contextLength: contextLength,
    );
  }

  // --- public API ----------------------------------------------------------

  /// Token ids for [text], WITHOUT sot/eot (open_clip `encode`).
  List<int> encode(String text) {
    final out = <int>[];
    final cleaned = _cleanLower(text);
    for (final m in _pat.allMatches(cleaned)) {
      final piece = m.group(0)!;
      final sb = StringBuffer();
      for (final b in utf8.encode(piece)) {
        sb.write(_byteEncoder[b]);
      }
      for (final sym in _bpe(sb.toString()).split(' ')) {
        final id = _encoder[sym];
        if (id != null) out.add(id);
      }
    }
    return out;
  }

  /// Model-ready `[contextLength]` int64 ids: `[sot] + encode + [eot]`, padded
  /// with 0 and truncated (keeping eot last) — exactly open_clip's tokenize().
  Int64List tokenize(String text, {int? contextLength}) {
    final ctx = contextLength ?? this.contextLength;
    var tokens = <int>[sotToken, ...encode(text), eotToken];
    if (tokens.length > ctx) {
      tokens = tokens.sublist(0, ctx);
      tokens[ctx - 1] = eotToken;
    }
    final out = Int64List(ctx); // zero-filled == pad token
    for (var i = 0; i < tokens.length; i++) {
      out[i] = tokens[i];
    }
    return out;
  }

  // --- internals -----------------------------------------------------------

  String _cleanLower(String text) {
    // basic_clean (ftfy is identity for clean text) + html.unescape×2 + strip,
    // then whitespace_clean + lower.
    var t = _htmlUnescape(_htmlUnescape(text)).trim();
    t = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).join(' ');
    return t.toLowerCase();
  }

  String _bpe(String token) {
    final cached = _cache[token];
    if (cached != null) return cached;
    if (token.isEmpty) return token;

    final units = token.split('');
    var word = <String>[
      for (var i = 0; i < units.length; i++)
        i == units.length - 1 ? '${units[i]}</w>' : units[i],
    ];
    if (word.length < 2) {
      final res = '$token</w>';
      _cache[token] = res;
      return res;
    }

    var pairs = _pairs(word);
    while (true) {
      String? best;
      var bestRank = 1 << 62;
      for (final p in pairs) {
        final r = _bpeRanks[p];
        if (r != null && r < bestRank) {
          bestRank = r;
          best = p;
        }
      }
      if (best == null) break;
      final sp = best.indexOf(' ');
      final first = best.substring(0, sp);
      final second = best.substring(sp + 1);

      final newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        final j = word.indexOf(first, i);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }
        newWord.addAll(word.sublist(i, j));
        i = j;
        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }
      word = newWord;
      if (word.length == 1) break;
      pairs = _pairs(word);
    }
    final res = word.join(' ');
    _cache[token] = res;
    return res;
  }

  static Set<String> _pairs(List<String> word) {
    final pairs = <String>{};
    for (var i = 0; i < word.length - 1; i++) {
      pairs.add('${word[i]} ${word[i + 1]}');
    }
    return pairs;
  }

  static Map<int, String> _bytesToUnicode() {
    final bs = <int>[];
    for (var i = 0x21; i <= 0x7E; i++) {
      bs.add(i); // ! .. ~
    }
    for (var i = 0xA1; i <= 0xAC; i++) {
      bs.add(i); // ¡ .. ¬
    }
    for (var i = 0xAE; i <= 0xFF; i++) {
      bs.add(i); // ® .. ÿ
    }
    final cs = List<int>.from(bs);
    var n = 0;
    for (var b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n++;
      }
    }
    final map = <int, String>{};
    for (var i = 0; i < bs.length; i++) {
      map[bs[i]] = String.fromCharCode(cs[i]);
    }
    return map;
  }

  static String _htmlUnescape(String s) {
    if (!s.contains('&')) return s;
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        )
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)),
        );
  }
}
