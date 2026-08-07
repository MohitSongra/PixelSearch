import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/ai/clip_tokenizer.dart';

const String kVocab =
    '../model_kit/out/bpe_simple_vocab_16e6.txt.gz';
const String kRef =
    '../model_kit/parity/reference_tokens.json';

void main() {
  late ClipTokenizer tok;

  setUpAll(() async {
    tok = await ClipTokenizer.fromGzipFile(kVocab);
  });

  test('special token ids match the contract', () {
    expect(tok.sotToken, 49406);
    expect(tok.eotToken, 49407);
  });

  test('token ids exactly match open_clip for every reference case', () {
    final ref = jsonDecode(File(kRef).readAsStringSync()) as Map<String, dynamic>;
    final cases = (ref['cases'] as List).cast<Map<String, dynamic>>();
    var checked = 0;
    for (final c in cases) {
      final text = c['text'] as String;
      final expectedIds = (c['ids'] as List).cast<int>();
      final expectedToks = (c['tokens77'] as List).cast<int>();
      expect(tok.encode(text), expectedIds, reason: 'encode mismatch: "$text"');
      expect(tok.tokenize(text).toList(), expectedToks,
          reason: 'tokenize mismatch: "$text"');
      checked++;
    }
    expect(checked, greaterThanOrEqualTo(19));
  });
}
