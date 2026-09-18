import 'package:flutter/material.dart';
import '../../domain/search/search_response.dart';

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
              if (e['people'] is List)
                for (final person in e['people'] as List)
                  Text('Person: ${person['name']} (${person['assignment']} assignment)'),
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
              Text(
                'Matching terms: ${(e['matching_terms'] as List? ?? []).join(', ')}',
              ),
              if (e['matched_metadata'] is Map) ...[
                for (final field in (e['matched_metadata'] as Map).entries)
                  Text('${field.key}: ${field.value}'),
              ],
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
              Text('Filters: ${response.request.filters.toJson()}'),
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
