import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/people_repository.dart';
import '../../domain/people/same_person.dart';
import '../../state/people_providers.dart';
import '../../state/providers.dart';
import '../viewer/photo_viewer.dart';
import 'people_widgets.dart';

/// Records one answer and counts it toward this launch's round. Every answer,
/// "Not sure" included, is stored, so a question is never asked twice.
Future<bool> answerSamePersonQuestion(
  BuildContext context,
  WidgetRef ref,
  SamePersonQuestion question,
  SamePersonAnswer answer,
) async {
  // Read before any await: the caller may be gone when the save finishes.
  final saving = ref.read(samePersonSavingProvider.notifier);
  final answered = ref.read(samePersonAnsweredProvider.notifier);
  if (saving.state) return false;
  saving.state = true;
  try {
    final saved = await peopleAction(
      context,
      ref,
      () =>
          ref.read(peopleRepositoryProvider).answerSamePerson(question, answer),
    );
    if (saved) answered.state++;
    return saved;
  } finally {
    saving.state = false;
  }
}

/// Answers are disabled while one is saving and until the next question has
/// loaded; until then the question on screen may already be answered.
bool samePersonBusy(WidgetRef ref) =>
    ref.watch(samePersonSavingProvider) ||
    ref.watch(samePersonQuestionsProvider).isLoading;

/// Questions left to ask in this launch's round (like Google Photos' short
/// "Same or different person?" sessions).
int samePersonRemaining(WidgetRef ref) =>
    ref.watch(samePersonAllowanceProvider) -
    ref.watch(samePersonAnsweredProvider);

void _openPhoto(BuildContext context, WidgetRef ref, PeopleFaceRecord? face) {
  if (face == null) return;
  final photos = ref
      .read(photoLibraryProvider)
      .where((p) => p.id == face.photoId)
      .toList();
  if (photos.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: 0),
    ),
  );
}

/// Full-screen round of up to 20 "Same person?" questions.
class SamePersonScreen extends ConsumerWidget {
  const SamePersonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    final questions = ref.watch(samePersonQuestionsProvider);
    final list = questions.valueOrNull;
    final size = ref.watch(samePersonSessionSizeProvider);
    final answered = ref.watch(samePersonAnsweredProvider);
    final remaining = samePersonRemaining(ref);
    final busy = samePersonBusy(ref);
    void answer(SamePersonQuestion question, SamePersonAnswer value) =>
        answerSamePersonQuestion(context, ref, question, value);
    Widget body;
    Widget? answerBar;
    // After a failed reload the old list may still start with a pair that
    // was just answered, so an error never shows a question.
    if (snapshot == null || list == null || questions.hasError) {
      body = Center(
        child: questions.hasError && !questions.isLoading
            ? const Text('Questions are unavailable.')
            : const CircularProgressIndicator(),
      );
    } else if (list.isEmpty || remaining <= 0) {
      final more = list.length;
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                list.isEmpty
                    ? (answered == 0
                          ? 'No questions right now. Group similar faces or '
                                'name more faces, then come back.'
                          : 'All done. Thanks: you answered $answered '
                                'question${answered == 1 ? '' : 's'}.')
                    : "That's $answered for now. $more more will be asked "
                          'next time you open PixelSearch.',
                key: const ValueKey('same-person-empty'),
                textAlign: TextAlign.center,
              ),
              if (list.isNotEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey('same-person-more'),
                  onPressed: () =>
                      ref.read(samePersonAllowanceProvider.notifier).state +=
                          size,
                  child: Text('Keep going ($size more)'),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // The question in progress is the first of the live list, so merged or
      // answered pairs drop out by themselves and nothing is asked twice.
      final question = list.first;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Question ${answered + 1} of ${answered + remaining.clamp(0, list.length)}',
            key: const ValueKey('same-person-progress'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SamePersonCard(
            key: ValueKey('${question.leftFaceId}|${question.rightFaceId}'),
            question: question,
            snapshot: snapshot,
            busy: busy,
            onAnswer: (value) => answer(question, value),
            showAnswers: false,
          ),
        ],
      );
      // The answers stay visible on small screens and with large text.
      answerBar = SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SamePersonAnswers(
            busy: busy,
            onAnswer: (value) => answer(question, value),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Same person?')),
      body: SafeArea(child: body),
      bottomNavigationBar: answerBar,
    );
  }
}

/// The question itself: two faces, the question and No / Not sure / Yes.
/// [compact] is the inline version on the home screen.
class SamePersonCard extends ConsumerWidget {
  const SamePersonCard({
    super.key,
    required this.question,
    required this.snapshot,
    required this.busy,
    required this.onAnswer,
    this.compact = false,
    this.showAnswers = true,
  });
  final SamePersonQuestion question;
  final PeopleSnapshot snapshot;
  final bool busy;
  final ValueChanged<SamePersonAnswer> onAnswer;
  final bool compact;

  /// False when the screen shows [SamePersonAnswers] in a fixed bottom bar.
  final bool showAnswers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PersonView? person(String? id) =>
        snapshot.people.where((p) => p.record.id == id).firstOrNull;
    PeopleFaceRecord? face(String id) =>
        snapshot.faces.where((f) => f.id == id).firstOrNull;
    String describe(PersonView? p) => p == null
        ? 'Unknown'
        : p.record.name.trim().isNotEmpty
        ? p.label
        : 'Group of ${p.faces.length} face${p.faces.length == 1 ? '' : 's'}';
    final left = person(question.leftPersonId);
    final right = person(question.rightPersonId);
    final named = left != null && left.record.name.trim().isNotEmpty;
    final verify = question.kind == SamePersonKind.verifyAutomatic;
    final title = named
        ? 'Is this ${left.label}?'
        : 'Same or different person?';
    final theme = Theme.of(context);
    final faceSize = compact ? 72.0 : 160.0;
    Widget faceColumn(String key, String faceId, String caption) {
      final record = face(faceId);
      return Column(
        key: ValueKey(key),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capped so both faces and the answers fit on a small phone.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: faceSize,
              maxHeight: faceSize,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FaceImage(face: record),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: compact ? theme.textTheme.bodySmall : null,
          ),
          if (!compact)
            TextButton.icon(
              onPressed: record == null
                  ? null
                  : () => _openPhoto(context, ref, record),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Open photo'),
            ),
        ],
      );
    }

    final answers = SamePersonAnswers(busy: busy, onAnswer: onAnswer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: compact
              ? theme.textTheme.titleMedium
              : theme.textTheme.headlineSmall,
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            verify
                ? 'Grouping added the face on the right to ${describe(left)} '
                      'automatically. Is it really them?'
                : 'These faces look alike. Your answer decides: Yes puts them '
                      'together, No keeps them apart.',
          ),
        ],
        SizedBox(height: compact ? 8 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: faceColumn(
                'same-person-left',
                question.leftFaceId,
                describe(left),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: faceColumn(
                'same-person-right',
                question.rightFaceId,
                verify ? 'Added automatically' : describe(right),
              ),
            ),
          ],
        ),
        if (showAnswers) ...[SizedBox(height: compact ? 8 : 24), answers],
        if (!compact) ...[
          const SizedBox(height: 16),
          Text(
            'Answers stay on this device. Faces that look alike can still be '
            'different people, so answer Not sure when in doubt.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// The prompt on the main screen, asked each time the app opens (like Google
/// Photos): one question at a time, up to the round's 20, answered in place.
class SamePersonPrompt extends ConsumerWidget {
  const SamePersonPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(samePersonPromptDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final snapshot = ref.watch(peopleSnapshotProvider).valueOrNull;
    if (snapshot == null || !snapshot.state.enabled) {
      return const SizedBox.shrink();
    }
    final questions = ref.watch(samePersonQuestionsProvider);
    final list = questions.valueOrNull;
    final remaining = samePersonRemaining(ref);
    // An error keeps the old list, whose first pair may already be answered.
    if (questions.hasError || list == null || list.isEmpty || remaining <= 0) {
      return const SizedBox.shrink();
    }
    final question = list.first;
    final answered = ref.watch(samePersonAnsweredProvider);
    final round = answered + remaining.clamp(0, list.length);
    final busy = samePersonBusy(ref);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('same-person-prompt'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Help improve face groups · ${answered + 1} of $round',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                TextButton(
                  key: const ValueKey('same-person-not-now'),
                  onPressed: () =>
                      ref
                              .read(samePersonPromptDismissedProvider.notifier)
                              .state =
                          true,
                  child: const Text('Not now'),
                ),
              ],
            ),
            SamePersonCard(
              key: ValueKey('${question.leftFaceId}|${question.rightFaceId}'),
              question: question,
              snapshot: snapshot,
              compact: true,
              busy: busy,
              onAnswer: (answer) =>
                  answerSamePersonQuestion(context, ref, question, answer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('same-person-open'),
                onPressed: busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SamePersonScreen(),
                        ),
                      ),
                child: const Text('Open full screen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No / Not sure / Yes.
class SamePersonAnswers extends StatelessWidget {
  const SamePersonAnswers({
    super.key,
    required this.busy,
    required this.onAnswer,
  });
  final bool busy;
  final ValueChanged<SamePersonAnswer> onAnswer;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      OutlinedButton(
        key: const ValueKey('same-person-no'),
        onPressed: busy ? null : () => onAnswer(SamePersonAnswer.no),
        child: const Text('No'),
      ),
      TextButton(
        key: const ValueKey('same-person-unsure'),
        onPressed: busy ? null : () => onAnswer(SamePersonAnswer.notSure),
        child: const Text('Not sure'),
      ),
      FilledButton(
        key: const ValueKey('same-person-yes'),
        onPressed: busy ? null : () => onAnswer(SamePersonAnswer.yes),
        child: const Text('Yes'),
      ),
    ],
  );
}
