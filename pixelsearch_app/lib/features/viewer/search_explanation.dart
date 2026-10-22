import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../domain/people/people_search_state.dart';
import '../../domain/search/search_response.dart';

/// Readable filters for the explanation sheet. Person ids are local
/// identifiers and are never shown; names come from the search summary.
String describeFilters(SearchResponse response) {
  final f = response.request.filters;
  final labels = response.people?.labels ?? const <String, String>{};
  List<String> names(Set<String> ids) => [
    for (final id in ids) labels[id] ?? 'a person',
  ];
  return [
    if (f.personIds.isNotEmpty) 'People: ${joinNames(names(f.personIds))}',
    if (f.anyPersonIds.isNotEmpty)
      'Any of: ${joinNames(names(f.anyPersonIds), conjunction: 'or')}',
    if (f.excludedPersonIds.isNotEmpty)
      'Not: ${joinNames(names(f.excludedPersonIds), conjunction: 'or')} (assigned faces only)',
    if (f.from != null || f.until != null)
      'Date: ${f.from == null ? '…' : Dates.short(f.from!)} – '
          '${f.until == null ? '…' : Dates.short(f.until!.subtract(const Duration(days: 1)))}',
    if (f.album != null) 'Album: ${f.album}',
    if (f.place != null) 'Place: ${f.place}',
  ].join(' · ');
}

class SearchExplanation extends StatelessWidget {
  const SearchExplanation({
    super.key,
    required this.response,
    required this.photoId,
  });
  final SearchResponse response;
  final String photoId;
  @override
  Widget build(BuildContext context) {
    final e = response.explanations[photoId];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why this matched',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(response.request.query),
            Text('Mode: ${response.mode}'),
            if (e == null)
              const Text('No ranking evidence for this browsing result.'),
            if (e != null) ...[
              if (e['people'] is List && (e['people'] as List).isNotEmpty) ...[
                const Text('Matched by assigned faces'),
                for (final person in e['people'] as List)
                  Text(
                    '${person['name'] ?? 'Unnamed person'} — face assigned '
                    '${person['assignment'] == 'automatic' ? 'automatically' : 'manually'}',
                  ),
              ],
              for (final field in [
                'cosine',
                'cosine_used',
                'semantic',
                'lexical',
                'face',
                'score',
              ])
                if (e[field] is num)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (field) {
                      'cosine' => 'Raw cosine',
                      'cosine_used' => 'Cosine used after gate',
                      'semantic' => 'Normalized semantic signal',
                      'lexical' => 'Normalized metadata signal',
                      'face' => 'Face signal',
                      _ => 'Final ranking score',
                    }),
                    trailing: Text((e[field] as num).toStringAsFixed(4)),
                  ),
              if (e['weighted'] is Map) ...[
                const Text('Weighted contributions'),
                for (final part in (e['weighted'] as Map).entries)
                  Text(
                    '${part.key}: ${(part.value as num).toStringAsFixed(4)}',
                  ),
              ],
              if (e.containsKey('matching_terms'))
                Text(
                  'Matching terms: ${(e['matching_terms'] as List? ?? []).join(', ')}',
                ),
              if (e['matched_metadata'] is Map) ...[
                for (final field in (e['matched_metadata'] as Map).entries)
                  Text('${field.key}: ${field.value}'),
              ],
              if (e.containsKey('mlkit_labels_used'))
                Text(
                  e['mlkit_labels_used'] == true
                      ? 'ML Kit labels are included in lexical matching.'
                      : 'Stored ML Kit labels were not used in this ranking.',
                ),
              if (e['gate'] != null)
                Text(
                  'Raw cosine gate: ${e['gate']} | Candidate limit: ${e['pool']}',
                ),
            ],
            if (!response.request.filters.isEmpty)
              Text('Filters: ${describeFilters(response)}'),
            const SizedBox(height: 12),
            const Text(
              'Similarity scores are not probabilities or guarantees of relevance.',
            ),
          ],
        ),
      ),
    );
  }
}
