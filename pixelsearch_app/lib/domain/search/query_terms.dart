/// Split a raw query into normalized, lower-cased search terms.
///
/// Lives in the domain layer so both the data-layer lexical scorer
/// ([keywordScore]) and the domain-layer [HybridScorer] share one definition
/// without the domain depending on data (Clean Architecture).
List<String> queryTerms(String query) => query
    .trim()
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();
