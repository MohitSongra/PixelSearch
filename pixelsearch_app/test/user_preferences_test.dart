import 'package:flutter_test/flutter_test.dart';
import 'package:pixelsearch/data/user_preferences.dart';
import 'package:pixelsearch/models/photo.dart';

Photo photo({
  String name = 'document.jpg',
  List<String> labels = const ['dog'],
}) => Photo(
  id: '123',
  assetName: name,
  title: '',
  caption: '',
  tags: const [],
  date: DateTime(2026),
  album: 'Camera',
  source: PhotoSource.device,
  labels: labels,
);

void main() {
  String? disk;
  UserPreferences store() => UserPreferences(
    read: () async => disk,
    write: (contents) async => disk = contents,
  );
  setUp(() => disk = null);

  test(
    'fresh install shows setup; Not now completion survives restart and empty library',
    () async {
      final first = store();
      expect(await first.shouldSkipOnboarding(() async => 0), false);
      await first.completeOnboarding();
      expect(await store().shouldSkipOnboarding(() async => 0), true);
    },
  );

  test(
    'upgrade with an existing index skips onboarding and persists decision',
    () async {
      expect(await store().shouldSkipOnboarding(() async => 1916), true);
      expect(await store().shouldSkipOnboarding(() async => 0), true);
    },
  );

  test('failed library read is not interpreted as an empty library', () async {
    await expectLater(
      store().shouldSkipOnboarding(() async => throw StateError('unreadable')),
      throwsStateError,
    );
    expect(disk, isNull);
  });

  test(
    'empty correction survives restart and reindex, never mutates model labels',
    () async {
      final original = photo();
      await store().correctLabels(original, []);
      final reopened = store();
      await reopened.load();
      expect(
        reopened.applyLabelCorrection(photo(labels: ['dog', 'animal'])).labels,
        isEmpty,
      );
      expect(original.labels, ['dog']);
      expect(
        reopened.applyLabelCorrection(photo(name: 'different.jpg')).labels,
        ['dog'],
      );
      await reopened.resetLabels(original);
      expect(reopened.applyLabelCorrection(original).labels, ['dog']);
    },
  );

  test('concurrent setup and label saves preserve both decisions', () async {
    final preferences = store();
    await Future.wait([
      preferences.correctLabels(photo(), [' Document ', 'document', 'Text']),
      preferences.completeOnboarding(),
    ]);
    final reopened = store();
    await reopened.load();
    expect(reopened.onboardingComplete, true);
    expect(reopened.applyLabelCorrection(photo()).labels, ['document', 'text']);
  });

  test(
    'failed writes do not publish corrections or block a later save',
    () async {
      var fail = true;
      final preferences = UserPreferences(
        read: () async => null,
        write: (_) async {
          if (fail) throw StateError('disk full');
        },
      );
      await expectLater(
        preferences.correctLabels(photo(), []),
        throwsStateError,
      );
      expect(preferences.hasLabelCorrection(photo()), false);
      fail = false;
      await preferences.correctLabels(photo(), ['document']);
      expect(preferences.applyLabelCorrection(photo()).labels, ['document']);
    },
  );
}
