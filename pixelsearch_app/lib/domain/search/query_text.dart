/// Text clean-up shared by typed person queries and speech transcripts.
library;

final _wrappingQuotes = RegExp('^["“”‘’\']+|["“”‘’\']+\$');
final _trailingSentencePunctuation = RegExp(r'[.!?…]+$');

/// Speech recognisers append sentence punctuation and sometimes quotes
/// ("Photos of me with Asha."). Remove only those, never inner text.
String cleanSpokenQuery(String text) {
  var cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  String previous;
  do {
    previous = cleaned;
    cleaned = cleaned
        .replaceAll(_wrappingQuotes, '')
        .replaceAll(_trailingSentencePunctuation, '')
        .trim();
  } while (cleaned != previous);
  return cleaned;
}

const _edgePunctuation = r'''[,;:&+.!?…"“”‘’()\-]''';
// A filler word must end at a space, the end or punctuation other than a
// hyphen, so "in-laws" keeps its "in".
const _wordEnd = r'''[,;:&+.!?…"“”‘’()]''';

/// Repeatedly strips edge punctuation and the given filler words from both
/// ends until the text no longer changes.
String trimQueryEdges(String text, {Set<String> fillers = const {}}) {
  final words = fillers.map(RegExp.escape).join('|');
  final leading = RegExp(
    '^(?:$_edgePunctuation+\\s*${words.isEmpty ? '' : '|(?:$words)(?=\\s|\$|$_wordEnd)\\s*'})',
    caseSensitive: false,
  );
  final trailing = RegExp(
    '(?:\\s*$_edgePunctuation+${words.isEmpty ? '' : '|(?:^|\\s)(?:$words)'})\$',
    caseSensitive: false,
  );
  var result = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  String previous;
  do {
    previous = result;
    result = result.replaceFirst(leading, '').trim();
    result = result.replaceFirst(trailing, '').trim();
  } while (result != previous);
  return result;
}
