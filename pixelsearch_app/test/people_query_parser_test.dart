import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/domain/people/people_query.dart';
import 'package:pixelsearch/domain/people/people_search_state.dart';
import 'package:pixelsearch/domain/search/query_text.dart';
import 'package:pixelsearch/domain/search/search_response.dart';
import 'package:pixelsearch/models/photo.dart';

// Neutral placeholder people only.
const dev = NamedPerson('dev', 'Dev', aliases: ['me', 'myself']);
const asha = NamedPerson('asha', 'Asha', aliases: ['Ash']);
const ben = NamedPerson('ben', 'Ben');
const chen = NamedPerson('chen', 'Chen');
const kaiA = NamedPerson('kai-a', 'Kai');
const kaiB = NamedPerson('kai-b', 'Kai');
const rose = NamedPerson('rose', 'Rose');

const withSelf = [dev, asha, ben, chen];
const noSelf = [asha, ben, chen];
const everyone = [dev, asha, ben, chen, kaiA, kaiB, rose];

void expectPeople(
  PeopleQuery result, {
  Set<String> all = const {},
  Set<String> anyOf = const {},
  Set<String> none = const {},
  required String query,
  String? reason,
}) {
  expect(result.required, all, reason: '$reason: required');
  expect(result.anyOf, anyOf, reason: '$reason: anyOf');
  expect(result.excluded, none, reason: '$reason: excluded');
  expect(result.query, query, reason: '$reason: remainder');
}

SearchResponse response({
  PersonFilterSummary? people,
  List<Photo> photos = const [],
}) => SearchResponse(
  request: const SearchRequest(''),
  photos: photos,
  mode: 'semantic',
  people: people,
);

Photo photo(String id) => Photo(
  id: id,
  title: '',
  caption: '',
  tags: const [],
  date: DateTime(2024),
  album: 'Camera',
  source: PhotoSource.sample,
);

void main() {
  group('self and companions', () {
    test('"photos of me with Asha" requires the self person and Asha', () {
      for (final text in [
        'photos of me with Asha',
        'myself & Asha',
        'Me with Asha!',
        'Photos of me with Asha.',
        'photos of me, with Asha?',
      ]) {
        final result = resolvePeopleQuery(text, withSelf);
        expectPeople(result, all: {'dev', 'asha'}, query: '', reason: text);
        expect(result.selfMissing, isFalse, reason: text);
        expect(result.needsChoice, isFalse, reason: text);
      }
    });

    test('missing self is reported and "me" never leaks into the scene', () {
      final result = resolvePeopleQuery(
        'photos of me with Asha',
        noSelf,
        detectMissingSelf: true,
      );
      expect(result.selfMissing, isTrue);
      expectPeople(result, all: {'asha'}, query: '');
      expect(result.mentions.map((m) => m.key), ['me', 'asha']);
      expect(result.mentions.first.isSelf, isTrue);
      expect(result.mentions.first.personId, isNull);
      expect(result.mentions.first.label, isNull);
      expect(result.needsChoice, isFalse);

      // Without detection and without a self person, "me" is still not scene
      // text for this query.
      final plain = resolvePeopleQuery('photos of me with Asha', noSelf);
      expect(plain.selfMissing, isFalse);
      expectPeople(plain, all: {'asha'}, query: '');
    });

    test('detectMissingSelf does not fire when a self person exists', () {
      final result = resolvePeopleQuery(
        'photos of me with Asha',
        withSelf,
        detectMissingSelf: true,
      );
      expect(result.selfMissing, isFalse);
      expectPeople(result, all: {'dev', 'asha'}, query: '');
    });

    test('a request pronoun does not count as a missing self', () {
      final result = resolvePeopleQuery(
        'show me Asha',
        noSelf,
        detectMissingSelf: true,
      );
      expect(result.selfMissing, isFalse);
      expectPeople(result, all: {'asha'}, query: '');
    });

    test('ignoring "me" without a self person suppresses selfMissing', () {
      final result = resolvePeopleQuery(
        'photos of me with Asha',
        noSelf,
        ignoredNames: {'me'},
        detectMissingSelf: true,
      );
      expect(result.selfMissing, isFalse);
      expectPeople(result, all: {'asha'}, query: '');
      expect(result.mentions.map((m) => m.key), ['asha']);
    });
  });

  group('request pronouns', () {
    test('"show me" / "let me see" address the app, not a subject', () {
      for (final text in [
        'show me Asha',
        'let me see Asha',
        'show me photos of Asha',
      ]) {
        final result = resolvePeopleQuery(text, withSelf);
        expectPeople(result, all: {'asha'}, query: '', reason: text);
        expect(result.mentions.map((m) => m.key), ['asha'], reason: text);
      }
      expectPeople(
        resolvePeopleQuery('show me beach photos of Asha', withSelf),
        all: {'asha'},
        query: 'beach',
      );
    });

    test('a coordinated or placed "me" after a request verb is a subject', () {
      expectPeople(
        resolvePeopleQuery('show me and Asha', withSelf),
        all: {'dev', 'asha'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('show me at the beach', withSelf),
        all: {'dev'},
        query: 'the beach',
      );
    });
  });

  group('queries without people', () {
    test('are returned byte-identical with no person filters', () {
      for (final text in [
        'beach near me',
        'show me the beach',
        'photos for me',
        '  two people indoors in 2024  ',
        'A dog on the beach.',
        'red or blue car',
      ]) {
        final result = resolvePeopleQuery(
          text,
          everyone,
          detectMissingSelf: true,
        );
        expect(result.query, text, reason: text);
        expect(result.hasPeople, isFalse, reason: text);
        expect(result.required, isEmpty, reason: text);
        expect(result.anyOf, isEmpty, reason: text);
        expect(result.excluded, isEmpty, reason: text);
        expect(result.mentions, isEmpty, reason: text);
        expect(result.selfMissing, isFalse, reason: text);
        expect(result.needsChoice, isFalse, reason: text);
        expect(result.filters.from, isNull, reason: text);
        expect(result.filters.until, isNull, reason: text);

        // Non-subject "me" never blocks a search when nobody is "This is me".
        final missing = resolvePeopleQuery(
          text,
          noSelf,
          detectMissingSelf: true,
        );
        expect(missing.query, text, reason: text);
        expect(missing.selfMissing, isFalse, reason: text);
        expect(missing.hasPeople, isFalse, reason: text);
      }
    });
  });

  group('possessives and fillers', () {
    test('possessive suffixes and edge fillers are removed', () {
      expectPeople(
        resolvePeopleQuery("Asha's birthday", withSelf),
        all: {'asha'},
        query: 'birthday',
      );
      expectPeople(
        resolvePeopleQuery('only Asha together.', withSelf),
        all: {'asha'},
        query: '',
      );
    });
  });

  group('alternatives (OR)', () {
    test('names joined only by "or" are alternatives', () {
      expectPeople(
        resolvePeopleQuery('Asha or Ben', withSelf),
        anyOf: {'asha', 'ben'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('either Asha or Ben at the park', withSelf),
        anyOf: {'asha', 'ben'},
        query: 'the park',
      );
      expectPeople(
        resolvePeopleQuery('Asha, Ben or Chen', withSelf),
        anyOf: {'asha', 'ben', 'chen'},
        query: '',
      );
    });

    test('mixed "and"/"or" wording falls back to requiring everyone', () {
      expectPeople(
        resolvePeopleQuery('Asha and Ben or Chen', withSelf),
        all: {'asha', 'ben', 'chen'},
        query: '',
      );
    });
  });

  group('exclusions (NOT)', () {
    test('names after without/but not/except are excluded', () {
      expectPeople(
        resolvePeopleQuery('Asha without Ben', withSelf),
        all: {'asha'},
        none: {'ben'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('Asha but not Ben at the beach', withSelf),
        all: {'asha'},
        none: {'ben'},
        query: 'the beach',
      );
      expectPeople(
        resolvePeopleQuery('Asha except Ben or Chen', withSelf),
        all: {'asha'},
        none: {'ben', 'chen'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('Asha without my brother Ben', withSelf),
        all: {'asha'},
        none: {'ben'},
        query: '',
      );
    });

    test('exclusion-only queries keep the scene and include nobody', () {
      final result = resolvePeopleQuery('beach photos without Ben', withSelf);
      expectPeople(result, none: {'ben'}, query: 'beach');
      expect(result.hasPeople, isTrue);
      expect(result.mentions.single.role, PersonRole.excluded);
    });
  });

  group('dates', () {
    test('a year composes with people', () {
      final result = resolvePeopleQuery('me and Asha in 2023', withSelf);
      expectPeople(result, all: {'dev', 'asha'}, query: '');
      expect(result.filters.from, DateTime(2023));
      expect(result.filters.until, DateTime(2024));
    });

    test('"last year" is relative to the supplied clock', () {
      final result = resolvePeopleQuery(
        'Asha at the beach last year',
        withSelf,
        now: DateTime(2026, 9),
      );
      expectPeople(result, all: {'asha'}, query: 'the beach');
      expect(result.filters.from, DateTime(2025));
      expect(result.filters.until, DateTime(2026));
    });

    test('no date words leave the date filters untouched', () {
      final result = resolvePeopleQuery('Asha at the park', withSelf);
      expect(result.filters.from, isNull);
      expect(result.filters.until, isNull);
    });
  });

  group('ambiguity', () {
    const withKai = [dev, asha, ben, chen, kaiA, kaiB];

    test('an ambiguous name inside OR still needs a choice', () {
      final open = resolvePeopleQuery('Asha or Kai', withKai);
      expect(open.needsChoice, isTrue);
      expect(open.ambiguous.keys, ['kai']);
      expect(open.ambiguous['kai']!.map((p) => p.id), ['kai-a', 'kai-b']);
      expect(open.anyOf, isNot(contains('kai-a')));
      expect(open.anyOf, isNot(contains('kai-b')));
      expect(open.required, isNot(contains('kai-a')));
      expect(open.required, isNot(contains('kai-b')));

      final chosen = resolvePeopleQuery(
        'Asha or Kai',
        withKai,
        choices: {'kai': kaiB.id},
      );
      expect(chosen.needsChoice, isFalse);
      expectPeople(chosen, anyOf: {'asha', 'kai-b'}, query: '');
    });

    test('an ambiguous name inside NOT still needs a choice', () {
      final open = resolvePeopleQuery('Asha without Kai', withKai);
      expect(open.needsChoice, isTrue);
      expect(open.excluded, isEmpty);
      final chosen = resolvePeopleQuery(
        'Asha without Kai',
        withKai,
        choices: {'kai': kaiA.id},
      );
      expect(chosen.needsChoice, isFalse);
      expectPeople(chosen, all: {'asha'}, none: {'kai-a'}, query: '');
    });

    test('"me" and "myself" share one self key', () {
      for (final twoSelves in const [
        [
          NamedPerson('dev', 'Dev', aliases: ['me']),
          NamedPerson('ben', 'Ben', aliases: ['me']),
          asha,
        ],
        [
          NamedPerson('dev', 'Dev', aliases: ['me']),
          NamedPerson('ben', 'Ben', aliases: ['myself']),
          asha,
        ],
      ]) {
        final open = resolvePeopleQuery('photos of myself', twoSelves);
        expect(open.needsChoice, isTrue);
        expect(open.ambiguous.keys, [selfKey]);
        expect(open.ambiguous[selfKey]!.map((p) => p.id), ['dev', 'ben']);
        expect(open.required, isEmpty);

        final chosen = resolvePeopleQuery(
          'photos of myself',
          twoSelves,
          choices: {'me': 'ben'},
        );
        expect(chosen.needsChoice, isFalse);
        expectPeople(chosen, all: {'ben'}, query: '');
        expect(chosen.matched, {'me': 'ben'});

        // Ignoring either self word ignores both, and the word itself is not
        // sent to the image model ("Search without me").
        for (final text in ['photos of myself', 'photos of me']) {
          final ignored = resolvePeopleQuery(
            text,
            twoSelves,
            ignoredNames: {'myself'},
          );
          expect(ignored.needsChoice, isFalse, reason: text);
          expect(ignored.hasPeople, isFalse, reason: text);
          expect(ignored.query, isEmpty, reason: text);
        }
        expect(
          resolvePeopleQuery(
            'Asha without me at the beach',
            [const NamedPerson('asha', 'Asha'), ...twoSelves],
            ignoredNames: {'me'},
          ).query,
          'the beach',
        );
      }
    });
  });

  group('mentions', () {
    test('keep query order, display labels, self flag and roles', () {
      final result = resolvePeopleQuery('Ash or me without Ben', withSelf);
      expectPeople(result, anyOf: {'asha', 'dev'}, none: {'ben'}, query: '');
      final mentions = result.mentions;
      expect(mentions.map((m) => m.key), ['ash', 'me', 'ben']);
      expect(mentions.map((m) => m.text), ['Ash', 'me', 'Ben']);
      expect(mentions.map((m) => m.personId), ['asha', 'dev', 'ben']);
      expect(mentions.map((m) => m.label), ['Asha', 'Dev', 'Ben']);
      expect(mentions.map((m) => m.isSelf), [false, true, false]);
      expect(mentions.map((m) => m.role), [
        PersonRole.any,
        PersonRole.any,
        PersonRole.excluded,
      ]);
    });

    test('required mentions and typed text are preserved', () {
      final result = resolvePeopleQuery('Chen with MYSELF and Asha', withSelf);
      expectPeople(result, all: {'chen', 'dev', 'asha'}, query: '');
      expect(result.mentions.map((m) => m.text), ['Chen', 'MYSELF', 'Asha']);
      expect(result.mentions.map((m) => m.key), ['chen', selfKey, 'asha']);
      expect(
        result.mentions.map((m) => m.role),
        everyElement(PersonRole.required),
      );
    });

    test('an ambiguous mention has no person id or label', () {
      final result = resolvePeopleQuery('Kai and Asha', [asha, kaiA, kaiB]);
      expect(result.mentions.map((m) => m.key), ['kai', 'asha']);
      expect(result.mentions.first.personId, isNull);
      expect(result.mentions.first.label, isNull);
      expect(result.mentions.last.label, 'Asha');
      expect(result.matched, {'asha': 'asha'});
    });
  });

  group('manual filters merge with text', () {
    test('required people from the UI join the text people', () {
      final result = resolvePeopleQuery(
        'Asha at the park',
        withSelf,
        filters: const SearchFilters(personIds: {'ben'}, album: 'Camera'),
      );
      expectPeople(result, all: {'asha', 'ben'}, query: 'the park');
      expect(result.filters.album, 'Camera');
    });

    test('any-of people from the UI stay alternatives', () {
      final result = resolvePeopleQuery(
        'Asha',
        withSelf,
        filters: const SearchFilters(anyPersonIds: {'ben', 'chen'}),
      );
      expectPeople(result, all: {'asha'}, anyOf: {'ben', 'chen'}, query: '');
    });

    test('an exclusion-only UI filter with an empty query has people', () {
      final result = resolvePeopleQuery(
        '',
        withSelf,
        filters: const SearchFilters(excludedPersonIds: {'ben'}),
      );
      expect(result.hasPeople, isTrue);
      expectPeople(result, none: {'ben'}, query: '');
    });
  });

  group('common-word names', () {
    test('a name like Rose resolves, and can be ignored', () {
      const people = [dev, asha, rose];
      expectPeople(
        resolvePeopleQuery('rose garden', people),
        all: {'rose'},
        query: 'garden',
      );
      final ignored = resolvePeopleQuery(
        'rose garden',
        people,
        ignoredNames: {'rose'},
      );
      expect(ignored.hasPeople, isFalse);
      expect(ignored.mentions, isEmpty);
      expect(ignored.query, 'rose garden');
    });
  });

  group('prunePeopleSelections', () {
    test('keeps choices and ignored names only while still mentioned', () {
      final pruned = prunePeopleSelections(
        'Asha at the beach',
        {'asha': 'asha', 'kai': 'kai-b', 'me': 'dev'},
        {'rose', 'me'},
      );
      expect(pruned.choices, {'asha': 'asha'});
      expect(pruned.ignored, isEmpty);

      final kept = prunePeopleSelections(
        'Kai and myself near the roses',
        {'kai': 'kai-b', 'me': 'dev'},
        {'rose', 'me', 'myself'},
      );
      expect(kept.choices, {'kai': 'kai-b', 'me': 'dev'});
      // "roses" is not the whole word "rose".
      expect(kept.ignored, {'me', 'myself'});
    });

    test('mentionsNameKey treats me/myself as one key', () {
      expect(mentionsNameKey('photos of myself', 'me'), isTrue);
      expect(mentionsNameKey('photos of me', 'myself'), isTrue);
      expect(mentionsNameKey('Photos of ASHA', 'asha'), isTrue);
      expect(mentionsNameKey('Ashanti beach', 'asha'), isFalse);
      expect(mentionsNameKey('memories', 'me'), isFalse);
    });

    test('self helpers', () {
      expect(selfKey, 'me');
      expect(selfAliases, {'me', 'myself'});
      expect(isSelfAlias(' MySelf '), isTrue);
      expect(isSelfAlias('Dev'), isFalse);
    });
  });

  group('cleanSpokenQuery', () {
    test('removes only sentence punctuation and wrapping quotes', () {
      expect(
        cleanSpokenQuery('Photos of me with Asha.'),
        'Photos of me with Asha',
      );
      expect(cleanSpokenQuery('"beach sunset!"'), 'beach sunset');
      expect(cleanSpokenQuery('Asha, Ben'), 'Asha, Ben');
      expect(cleanSpokenQuery('  beach   at    sunset  '), 'beach at sunset');
      expect(cleanSpokenQuery('Asha?!'), 'Asha');
    });

    test('a cleaned transcript resolves like typed text', () {
      expectPeople(
        resolvePeopleQuery(cleanSpokenQuery('Photos of me with Asha.'), withSelf),
        all: {'dev', 'asha'},
        query: '',
      );
    });

    test('trimQueryEdges strips edge punctuation and fillers', () {
      expect(trimQueryEdges(', the beach.'), 'the beach');
      expect(
        trimQueryEdges('with the beach and', fillers: {'with', 'and'}),
        'the beach',
      );
    });
  });

  group('explainEmptyPeopleSearch', () {
    const labels = {'dev': 'Dev', 'asha': 'Asha', 'ben': 'Ben', 'chen': 'Chen'};

    test('selfMissing comes first', () {
      final query = resolvePeopleQuery(
        'photos of me with Asha',
        noSelf,
        detectMissingSelf: true,
      );
      expect(
        explainEmptyPeopleSearch(query, response())!.kind,
        PeopleEmptyKind.selfMissing,
      );
    });

    test('People turned off', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery('me with Asha', withSelf),
        response(
          people: const PersonFilterSummary(peopleEnabled: false, labels: labels),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.peopleOff);
      expect(state.names, ['you', 'Asha']);
    });

    test('a required person with no assigned photos', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery('me with Asha', withSelf),
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            labels: labels,
            photoCounts: {'dev': 4, 'asha': 0},
          ),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.noAssignedPhotos);
      expect(state.names, ['Asha']);
    });

    test('alternatives are missing only when none has photos', () {
      final query = resolvePeopleQuery('Asha or Ben', withSelf);
      final missing = explainEmptyPeopleSearch(
        query,
        response(
          people: const PersonFilterSummary(peopleEnabled: true, labels: labels),
        ),
      )!;
      expect(missing.kind, PeopleEmptyKind.noAssignedPhotos);
      expect(missing.names, ['Asha', 'Ben']);
      final notTogether = explainEmptyPeopleSearch(
        query,
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            labels: labels,
            photoCounts: {'ben': 2},
          ),
        ),
      )!;
      expect(notTogether.kind, PeopleEmptyKind.notTogether);
    });

    test('not together lists names in query order with "you"', () {
      const summary = PersonFilterSummary(
        peopleEnabled: true,
        labels: labels,
        photoCounts: {'dev': 4, 'asha': 3},
      );
      final forward = explainEmptyPeopleSearch(
        resolvePeopleQuery('me with Asha', withSelf),
        response(people: summary),
      )!;
      expect(forward.kind, PeopleEmptyKind.notTogether);
      expect(forward.names, ['you', 'Asha']);
      final reversed = explainEmptyPeopleSearch(
        resolvePeopleQuery('Asha with me', withSelf),
        response(people: summary),
      )!;
      expect(reversed.names, ['Asha', 'you']);
    });

    test('UI-only people follow the mentioned ones', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery(
          'Asha',
          withSelf,
          filters: const SearchFilters(personIds: {'ben'}),
        ),
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            labels: labels,
            photoCounts: {'asha': 3, 'ben': 2},
          ),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.notTogether);
      expect(state.names, ['Asha', 'Ben']);
    });

    test('labels fall back to the mention label', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery('Asha', withSelf),
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            photoCounts: {'asha': 0},
          ),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.noAssignedPhotos);
      expect(state.names, ['Asha']);
    });

    test('everyone excluded', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery('Asha without Ben', withSelf),
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            labels: labels,
            photoCounts: {'asha': 3, 'ben': 2},
            together: 3,
          ),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.allExcluded);
      expect(state.names, ['Asha']);
      expect(state.count, 3);
    });

    test('none in the date/album/place filters', () {
      final state = explainEmptyPeopleSearch(
        resolvePeopleQuery('me with Asha', withSelf),
        response(
          people: const PersonFilterSummary(
            peopleEnabled: true,
            labels: labels,
            photoCounts: {'dev': 6, 'asha': 5},
            together: 5,
            eligible: 4,
          ),
        ),
      )!;
      expect(state.kind, PeopleEmptyKind.noneInFilters);
      expect(state.names, ['you', 'Asha']);
      expect(state.count, 4);
    });

    test('no scene match reports the remainder and the filtered count', () {
      const summary = PersonFilterSummary(
        peopleEnabled: true,
        labels: labels,
        photoCounts: {'asha': 5},
        together: 5,
        eligible: 4,
        inFilters: 3,
      );
      final query = resolvePeopleQuery('Asha at the beach', withSelf);
      final state = explainEmptyPeopleSearch(query, response(people: summary))!;
      expect(state.kind, PeopleEmptyKind.noSceneMatch);
      expect(state.names, ['Asha']);
      expect(state.count, 3);
      expect(state.remainder, 'the beach');

      // Photos found → no empty state.
      expect(
        explainEmptyPeopleSearch(
          query,
          response(people: summary, photos: [photo('p1')]),
        ),
        isNull,
      );
      // People-only query with matches available and no scene → null.
      expect(
        explainEmptyPeopleSearch(
          resolvePeopleQuery('Asha', withSelf),
          response(people: summary),
        ),
        isNull,
      );
    });

    test('non-person queries and missing summaries explain nothing', () {
      expect(
        explainEmptyPeopleSearch(
          resolvePeopleQuery('beach', withSelf),
          response(
            people: const PersonFilterSummary(peopleEnabled: false),
          ),
        ),
        isNull,
      );
      expect(
        explainEmptyPeopleSearch(
          resolvePeopleQuery('Asha', withSelf),
          response(),
        ),
        isNull,
      );
    });

    test('joinNames', () {
      expect(joinNames([]), '');
      expect(joinNames(['Asha']), 'Asha');
      expect(joinNames(['you', 'Asha']), 'you and Asha');
      expect(joinNames(['a', 'b', 'c']), 'a, b and c');
      expect(joinNames(['Asha', 'Ben'], conjunction: 'or'), 'Asha or Ben');
    });
  });

  group('SearchFilters helpers', () {
    final full = SearchFilters(
      from: DateTime(2024),
      until: DateTime(2025),
      album: 'Camera',
      place: 'Park',
      personIds: const {'b', 'a'},
      anyPersonIds: const {'d', 'c'},
      excludedPersonIds: const {'f', 'e'},
    );

    void expectSamePeople(SearchFilters f) {
      expect(f.personIds, {'a', 'b'});
      expect(f.anyPersonIds, {'c', 'd'});
      expect(f.excludedPersonIds, {'e', 'f'});
    }

    test('withDate/withAlbum/withPlace keep all three person sets', () {
      final dated = full.withDate(DateTime(2020), DateTime(2021));
      expectSamePeople(dated);
      expect(dated.from, DateTime(2020));
      expect(dated.until, DateTime(2021));
      expect(dated.album, 'Camera');
      expect(dated.place, 'Park');

      final album = full.withAlbum('Screenshots');
      expectSamePeople(album);
      expect(album.album, 'Screenshots');
      expect(album.from, DateTime(2024));

      final place = full.withPlace(null);
      expectSamePeople(place);
      expect(place.place, isNull);
      expect(place.album, 'Camera');
    });

    test('withPeople/withoutPeople replace only the person sets', () {
      final replaced = full.withPeople(required: {'x'});
      expect(replaced.personIds, {'x'});
      expect(replaced.anyPersonIds, isEmpty);
      expect(replaced.excludedPersonIds, isEmpty);
      expect(replaced.album, 'Camera');
      expect(replaced.from, DateTime(2024));

      final cleared = full.withoutPeople();
      expect(cleared.hasPeople, isFalse);
      expect(cleared.place, 'Park');
      expect(cleared.isEmpty, isFalse);
      expect(const SearchFilters().isEmpty, isTrue);
      expect(const SearchFilters(excludedPersonIds: {'x'}).isEmpty, isFalse);
    });

    test('toJson keeps person ids local unless asked, and sorts them', () {
      final offline = full.toJson(includePeople: false);
      expect(offline.keys, isNot(contains('person_ids')));
      expect(offline.keys, isNot(contains('any_person_ids')));
      expect(offline.keys, isNot(contains('excluded_person_ids')));
      expect(offline['album'], 'Camera');
      expect(offline['place'], 'Park');
      expect(offline['from'], DateTime(2024).toIso8601String());

      final local = full.toJson();
      expect(local['person_ids'], ['a', 'b']);
      expect(local['any_person_ids'], ['c', 'd']);
      expect(local['excluded_person_ids'], ['e', 'f']);
      expect(const SearchFilters().toJson(), isEmpty);
    });

    test('unresolved person filters fail closed', () {
      for (final filters in const [
        SearchFilters(personIds: {'x'}),
        SearchFilters(anyPersonIds: {'x'}),
        SearchFilters(excludedPersonIds: {'x'}),
      ]) {
        expect(
          () => SearchRequest('', filters: filters).filterCorpus([]),
          throwsStateError,
        );
      }
      final resolved = SearchRequest(
        '',
        filters: const SearchFilters(excludedPersonIds: {'x'}),
        eligiblePhotoIds: const {'p1'},
      );
      expect(
        resolved.filterCorpus([photo('p1'), photo('p2')]).map((p) => p.id),
        ['p1'],
      );
    });
  });

  group('review fixes (2026-10-22)', () {
    test('other negation wording excludes instead of requiring', () {
      expectPeople(
        resolvePeopleQuery('neither Asha nor Ben', withSelf),
        none: {'asha', 'ben'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('everyone but me', withSelf),
        none: {'dev'},
        query: '',
      );
      expectPeople(
        resolvePeopleQuery('photos not of Asha', withSelf),
        none: {'asha'},
        query: '',
      );
    });

    test('scene nouns survive remainder clean-up', () {
      expectPeople(
        resolvePeopleQuery('Asha in the photo booth', withSelf),
        all: {'asha'},
        query: 'the photo booth',
      );
      expectPeople(
        resolvePeopleQuery('Asha taking photos', withSelf),
        all: {'asha'},
        query: 'taking photos',
      );
      expectPeople(
        resolvePeopleQuery('Asha with in-laws', withSelf),
        all: {'asha'},
        query: 'in-laws',
      );
      expectPeople(
        resolvePeopleQuery('show me beach photos of Asha', withSelf),
        all: {'asha'},
        query: 'beach',
      );
    });

    test('saved spellings match even when lower-casing changes them', () {
      const dotted = NamedPerson('i', 'İpek');
      final typed = resolvePeopleQuery('photos of İpek at the beach', [dotted]);
      expectPeople(typed, all: {'i'}, query: 'the beach');
      final upper = resolvePeopleQuery('İPEK', [dotted]);
      expect(upper.required, {'i'});
    });

    test('chips follow the role the search actually uses', () {
      final collapsed = resolvePeopleQuery(
        'Asha or Ben',
        withSelf,
        filters: const SearchFilters(anyPersonIds: {'chen', 'dev'}),
      );
      expect(collapsed.anyOf, isEmpty);
      expect(collapsed.required, containsAll({'asha', 'ben'}));
      expect(
        collapsed.mentions.map((m) => m.role).toSet(),
        {PersonRole.required},
      );
    });
  });
}
