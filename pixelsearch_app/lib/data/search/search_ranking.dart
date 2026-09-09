import '../../domain/search/hybrid_scorer.dart';
import '../../domain/search/vector_index.dart';
import '../../models/photo.dart';
import '../search_engine.dart';

/// A replayable ranking policy. Defaults exactly match the production baseline.
class RankingPolicy {
  const RankingPolicy(
    this.name, {
    this.topK = 60,
    this.minCosine = 0.15,
    this.wholeWords = false,
    this.includeMlKitLabels = false,
    this.allowLexicalOnly = false,
  });
  final String name;
  final int topK;
  final double? minCosine;
  final bool wholeWords;
  final bool includeMlKitLabels;

  /// Only keyword fallback and historical replays may bypass semantic eligibility.
  final bool allowLexicalOnly;
  Map<String, Object?> toJson() => {
    'name': name,
    'top_k': topK,
    'min_cosine': minCosine,
    'lexical_policy': wholeWords
        ? 'whole_words_experiment'
        : 'production_substrings',
    'include_mlkit_labels': includeMlKitLabels,
    'allow_lexical_only': allowLexicalOnly,
  };
}

/// Experimental lexical control only. No stemming, synonyms, stop-word removal,
/// or alteration of the sentence passed to MobileCLIP.
double wholeWordKeywordScore(
  Photo p,
  List<String> terms, {
  bool includeLabels = true,
}) {
  final words = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  Set<String> tokens(String text) =>
      words.allMatches(text.toLowerCase()).map((m) => m.group(0)!).toSet();
  final blob = tokens(includeLabels ? p.searchBlob : p.metadataSearchBlob);
  final tags = p.tags.map((s) => s.toLowerCase()).toSet();
  final tagWords = tokens(p.tags.join(' '));
  final labels = includeLabels
      ? p.labels.map((s) => s.toLowerCase()).toSet()
      : const <String>{};
  var score = 0.0;
  for (final t in terms) {
    if (tags.contains(t)) {
      score += 3;
    } else if (tagWords.contains(t) || labels.contains(t)) {
      score += 2;
    } else if (blob.contains(t)) {
      score += 1;
    }
  }
  return score;
}

/// The lexical scorer selected by [RankingPolicy]. This keeps diagnostics and
/// ordinary retrieval on the same semantic-hybrid policy.
double lexicalScoreForPolicy(
  Photo photo,
  List<String> terms,
  RankingPolicy policy,
) => policy.wholeWords
    ? wholeWordKeywordScore(
        photo,
        terms,
        includeLabels: policy.includeMlKitLabels,
      )
    : keywordScore(photo, terms, includeLabels: policy.includeMlKitLabels);

class RankingRun {
  const RankingRun({
    required this.policy,
    required this.candidates,
    required this.ranked,
    required this.lexicalScores,
    required this.semanticIds,
    required this.elapsedMs,
  });
  final RankingPolicy policy;
  final List<ScoredCandidate> candidates;
  final List<RankedPhoto> ranked;
  final Map<String, double> lexicalScores;
  final Set<String> semanticIds;
  final double elapsedMs;
}

/// Shared by normal search and diagnostics, so the baseline is not a second
/// implementation that can drift from what users actually receive.
RankingRun rankSearchCandidates(
  String query,
  List<Photo> corpus,
  List<VectorMatch> matches, {
  required RankingPolicy policy,
  HybridScorer scorer = const HybridScorer(),
}) {
  final watch = Stopwatch()..start();
  final terms = policy.wholeWords
      ? RegExp(
          r'[\p{L}\p{N}]+',
          unicode: true,
        ).allMatches(query.toLowerCase()).map((m) => m.group(0)!).toList()
      : queryTerms(query);
  final byId = {for (final p in corpus) p.id: p};
  final lexical = {
    for (final p in corpus) p.id: lexicalScoreForPolicy(p, terms, policy),
  };
  final cosine = {
    for (final m in matches.take(policy.topK))
      if (policy.minCosine == null || m.score >= policy.minCosine!)
        m.id: m.score,
  };
  final ids = {
    ...cosine.keys,
    if (policy.allowLexicalOnly)
      for (final e in lexical.entries)
        if (e.value > 0) e.key,
  };
  final candidates = [
    for (final id in ids)
      if (byId.containsKey(id))
        ScoredCandidate(
          photo: byId[id]!,
          cosine: cosine[id],
          lexicalRaw: lexical[id] ?? 0,
        ),
  ];
  final ranked = scorer.rankDetailed(query, candidates);
  watch.stop();
  return RankingRun(
    policy: policy,
    candidates: candidates,
    ranked: ranked,
    lexicalScores: lexical,
    semanticIds: cosine.keys.toSet(),
    elapsedMs: watch.elapsedMicroseconds / 1000,
  );
}
