import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixelsearch/domain/people/face_alignment.dart';
import 'package:pixelsearch/domain/people/face_contract.dart';
import 'package:pixelsearch/domain/people/face_grouping.dart';
import 'package:pixelsearch/domain/people/people_query.dart';
import 'package:pixelsearch/domain/search/search_response.dart';

Float32List unitFace(double degrees) {
  final angle = degrees * math.pi / 180;
  return Float32List(128)
    ..[0] = math.cos(angle)
    ..[1] = math.sin(angle);
}

FaceVector face(
  String id,
  double angle, {
  String? photo,
  String? person,
  Set<String> rejected = const {},
}) => FaceVector(
  id: id,
  photoId: photo ?? id,
  vector: unitFace(angle),
  personId: person,
  rejectedPeople: rejected,
);

FacePair pair(
  String subset,
  double score,
  String judgment, [
  String id = 'p',
]) => FacePair(
  left: '$id-a',
  right: '$id-b',
  subset: subset,
  cosine: score,
  judgment: judgment,
);

void main() {
  test(
    'same-photo constraints include manually assigned faces without descriptors',
    () {
      final grouped = groupFaces(
        [face('a', 0, person: 'A'), face('b', 0, photo: 'two')],
        .8,
        personPhotos: {
          'A': {'one', 'two'},
        },
      );
      expect(grouped['b'], 'person:b');
    },
  );
  test('SFace tensor is raw RGB CHW, not CLIP normalization or BGR', () {
    final image = img.Image(width: 112, height: 112)
      ..setPixelRgb(0, 0, 17, 91, 240);
    final tensor = faceTensor(image);
    expect(tensor.length, 3 * 112 * 112);
    expect([tensor[0], tensor[12544], tensor[25088]], [17, 91, 240]);
    expect(
      () => faceTensor(img.Image(width: 1, height: 1)),
      throwsFormatException,
    );
  });

  test('alignment reproduces identity and inverse similarity landmarks', () {
    expect(
      faceTransform(FaceContract.landmarks),
      orderedEquals([1, 0, 0, 0, 1, 0]),
    );
    final source = [
      for (final p in FaceContract.landmarks) (2 * p.$1 + 10, 2 * p.$2 - 8),
    ];
    final transform = faceTransform(source);
    final expected = [.5, 0, -5, 0, .5, 4];
    for (var i = 0; i < 6; i++) {
      expect(transform[i], closeTo(expected[i], 1e-10));
    }
    expect(
      () => faceTransform(List.filled(5, (0.0, 0.0))),
      throwsFormatException,
    );
    expect(() => faceTransform([(double.nan, 0)]), throwsFormatException);
  });

  test(
    'face vectors reject wrong dimensions, NaN, zero and non-unit norms',
    () {
      expect(validFaceVector(unitFace(0)), isTrue);
      expect(validFaceVector(Float32List(512)), isFalse);
      expect(validFaceVector(Float32List(128)), isFalse);
      expect(validFaceVector(unitFace(0)..[1] = double.nan), isFalse);
      expect(
        () => faceCosine(unitFace(0), Float32List(128)),
        throwsFormatException,
      );
    },
  );

  test('complete-link does not bridge two distant endpoints', () {
    final input = [face('a', 0), face('b', 30), face('c', 60)];
    final grouped = groupFaces(input, .8);
    expect(grouped['a'], grouped['b']);
    expect(grouped['c'], isNot(grouped['a']));
    expect(groupFaces(input.reversed.toList(), .8), grouped);
  });

  test(
    'established groups are not merged and ambiguous faces stay unassigned',
    () {
      final groups = groupFaces([
        face('a', 0, person: 'A'),
        face('b', 40, person: 'B'),
        face('c', 20),
      ], .9);
      expect(groups, {'c': null});
    },
  );

  test(
    'same-photo distinct faces and rejected assignments cannot auto-join',
    () {
      final grouped = groupFaces([
        face('a', 0, person: 'A', photo: 'one'),
        face('b', 0, photo: 'one'),
        face('c', 0, rejected: {'A', 'person:b', 'person:c'}),
      ], .8);
      expect(grouped['b'], 'person:b');
      expect(grouped['c'], isNull);
    },
  );

  test('frozen review is deterministic, bounded and photo-disjoint', () {
    final input = [
      for (var i = 0; i < 80; i++)
        face('face$i', i * 2.0, photo: 'photo${i ~/ 2}'),
    ];
    final pairs = buildFaceReview(input);
    expect(pairs.length, 60);
    expect(pairs.every((p) => p.judgment == 'pending'), isTrue);
    expect(
      buildFaceReview(input.reversed.toList()).map((p) => p.id),
      pairs.map((p) => p.id),
    );
    final lookup = {for (final f in input) f.id: f.photoId};
    final cal = <String>{}, validation = <String>{};
    for (final p in pairs) {
      expect(lookup[p.left], isNot(lookup[p.right]));
      (p.subset == 'calibration' ? cal : validation).addAll([
        lookup[p.left]!,
        lookup[p.right]!,
      ]);
    }
    expect(cal.intersection(validation), isEmpty);
  });

  final passing = [
    pair('calibration', .9, 'same', 'a'),
    pair('calibration', .8, 'same', 'b'),
    pair('calibration', .7, 'different', 'c'),
    pair('validation', .85, 'same', 'd'),
    pair('validation', .6, 'different', 'e'),
    pair('validation', .99, 'unsure', 'f'),
  ];

  test('threshold maximizes calibration recall, Unsure excluded', () {
    final result = calibrateFaces(passing);
    expect(result.threshold, .8);
    expect(result.calibrationTrueJoins, 2);
    expect(result.validationTrueJoins, 1);
    expect(result.validationFalseJoins, 0);
    expect(result.validationSame, 1);
    expect(result.validationDifferent, 1);
  });
  test('validation cannot tune threshold to rescue a failed holdout', () {
    final result = calibrateFaces([
      ...passing,
      pair('validation', .82, 'different', 'g'),
    ]);
    expect(result.passed, isFalse);
    expect(result.threshold, isNull);
    expect(result.validationFalseJoins, 1);
    expect(result.candidateThreshold, .8);
    expect(result.falseJoinPairIds, ['g-a|g-b']);
    expect(result.toJson()['threshold'], isNull);
  });
  test(
    'device failure identifies the false join without enabling its cutoff',
    () {
      // Boundary scores from the 2026-09-18 device review, rounded to four
      // decimals; their order, and so the outcome, is unchanged.
      final result = calibrateFaces([
        pair('calibration', .4308, 'same', 'c30'),
        pair('calibration', .4092, 'different', 'c31'),
        pair('validation', .5594, 'different', 'v55'),
        pair('validation', .4392, 'same', 'v56'),
        pair('validation', .4077, 'same', 'v57'),
        pair('validation', .3784, 'different', 'v58'),
      ]);
      expect(result.passed, isFalse);
      expect(result.threshold, isNull);
      expect(result.candidateThreshold, .4308);
      expect(result.falseJoinPairIds, ['v55-a|v55-b']);
      expect(result.missedSamePairIds, ['v57-a|v57-b']);
      expect(result.reason, contains('1 of 2 different-person'));
    },
  );
  test('no successful test matches is distinct from a false join', () {
    final result = calibrateFaces([
      pair('calibration', .9, 'same'),
      pair('calibration', .5, 'different'),
      pair('validation', .8, 'same'),
      pair('validation', .4, 'different'),
    ]);
    expect(result.passed, isFalse);
    expect(result.candidateThreshold, .9);
    expect(result.falseJoinPairIds, isEmpty);
    expect(result.reason, contains('none of the 1 same-person'));
  });
  test('fresh validation sampling is deterministic and capped at 20', () {
    final input = [for (var i = 0; i < 25; i++) face('f$i', i * 3.0)];
    final pairs = buildFreshFaceValidation(input);
    expect(pairs, hasLength(20));
    expect(
      pairs.every((p) => p.subset == 'validation' && p.judgment == 'pending'),
      isTrue,
    );
    expect(
      buildFreshFaceValidation(input.reversed.toList()).map((p) => p.id),
      pairs.map((p) => p.id),
    );
  });
  test(
    'missing classes, pending, inseparable and invalid reviews stay disabled',
    () {
      for (final sample in [
        <FacePair>[],
        [pair('calibration', .8, 'same')],
        [...passing, pair('validation', .2, 'pending')],
        [...passing, pair('calibration', .95, 'different')],
        [...passing, pair('validation', double.nan, 'different')],
      ]) {
        expect(calibrateFaces(sample).passed, isFalse);
      }
    },
  );

  const names = [
    NamedPerson('m', 'Alice Example', aliases: ['Alice']),
    NamedPerson('s', 'Casey'),
    NamedPerson('s2', 'Casey'),
    NamedPerson('a', 'Ann'),
  ];
  const friends = [
    NamedPerson('me', 'Alice', aliases: ['me', 'myself']),
    NamedPerson('bob', 'Bob'),
  ];
  test('named friends and self aliases produce a strict two-person query', () {
    for (final text in [
      'me with my friend Bob',
      'myself and Bob',
      'photos of me with my friend Bob',
      'Alice, Bob',
      'Alice & Bob',
    ]) {
      final result = resolvePeopleQuery(text, friends);
      expect(result.filters.personIds, {'me', 'bob'}, reason: text);
      expect(result.query, isEmpty, reason: text);
    }
  });
  test('friend wording is removed only beside an identified name', () {
    final result = resolvePeopleQuery(
      'me with my friend Bob at the beach last year',
      friends,
      now: DateTime(2026, 9),
    );
    expect(result.filters.personIds, {'me', 'bob'});
    expect(result.query, 'the beach');
    expect(result.filters.from, DateTime(2025));
    expect(
      resolvePeopleQuery('Alice with my friend dancing', friends).query,
      'my friend dancing',
    );
    expect(
      resolvePeopleQuery('my friend at the beach', friends).query,
      'my friend at the beach',
    );
  });
  test(
    'request pronouns do not turn Bob-only searches into self searches',
    () {
      for (final text in [
        'show me photos of Bob',
        'find me pictures of my friend Bob',
        'give me all photos of Bob',
      ]) {
        final result = resolvePeopleQuery(text, friends);
        expect(result.filters.personIds, {'bob'}, reason: text);
        expect(result.query, isEmpty, reason: text);
      }
    },
  );
  test('names, nicknames, scene phrases and local years compose', () {
    final query = resolvePeopleQuery(
      'Photos of Alice at the beach last year',
      names,
      now: DateTime(2026, 9),
    );
    expect(query.filters.personIds, {'m'});
    expect(query.query, 'the beach');
    expect(query.filters.from, DateTime(2025));
    expect(query.filters.until, DateTime(2026));
    expect(resolvePeopleQuery('Alice in 2023', names).query, isEmpty);
    expect(resolvePeopleQuery('Alice and Ann', names).filters.personIds, {
      'm',
      'a',
    });
    expect(resolvePeopleQuery('Alice and Ann', names).query, isEmpty);
  });
  test(
    'whole-name match avoids substrings and chooses longest assigned name',
    () {
      expect(
        resolvePeopleQuery('a banner at sunset', names).filters.personIds,
        isEmpty,
      );
      final query = resolvePeopleQuery('Alice Example', names);
      expect(query.query, isEmpty);
      expect(query.matched, {'alice example': 'm'});
      expect(
        resolvePeopleQuery('Alice photosynthesis', names).query,
        'photosynthesis',
      );
    },
  );
  test(
    'ambiguous names require choosing a person, and ignored chips stay removed',
    () {
      expect(resolvePeopleQuery('Casey', names).needsChoice, isTrue);
      expect(
        resolvePeopleQuery(
          'Casey',
          names,
          choices: {'casey': 's2'},
        ).filters.personIds,
        {'s2'},
      );
      expect(
        resolvePeopleQuery(
          'Casey',
          names,
          choices: {'casey': 'unknown'},
        ).needsChoice,
        isTrue,
      );
      expect(
        resolvePeopleQuery(
          'Alice',
          names,
          ignoredNames: {'alice'},
        ).filters.personIds,
        isEmpty,
      );
    },
  );
  test(
    'ordinary search stays unchanged, unresolved person filters fail closed',
    () {
      const query = '  two people indoors in 2024  ';
      expect(resolvePeopleQuery(query, names).query, query);
      expect(
        () => const SearchRequest(
          '',
          filters: SearchFilters(personIds: {'missing'}),
        ).filterCorpus([]),
        throwsStateError,
      );
      expect(
        const SearchRequest('', eligiblePhotoIds: {}).filterCorpus([]),
        isEmpty,
      );
    },
  );
}
