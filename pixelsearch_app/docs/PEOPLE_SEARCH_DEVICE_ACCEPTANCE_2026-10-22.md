# People Search Device Acceptance - 2026-10-22

**Status: Host verified; device acceptance run 2026-10-22.** The build was
installed in place on the test phone and exercised the same day. At the user's
request the assistant drove the app over adb, reading the accessibility tree
(no screenshots), and did not name, confirm, reject or answer anything about
any face. Aggregate numbers only: no names, photo identifiers, serials, paths,
digests or URLs.

`<A>` and `<B>` stand for two people the user has named (slots P3 and P0 of the
session's private P0-P4 labels); "me" is the person marked "This is me".

## Scope

The 2026-10-22 People search change set (see `CHANGELOG.md`):

- Person queries in `resolvePeopleQuery`: required, any-of ("or") and excluded
  ("without" and similar) roles, a shared self key for "me"/"myself", request
  verbs ("show me photos of X"), and the missing-self state.
- `matchPeoplePhotos` membership, name-only queries without the text model.
- The "Similar faces" review (`rankFaceSuggestions`) with per-face Add / Not X
  and Undo; New faces multi-select; the This-is-me holder; Delete person.
- Search chips, the People filter chip, explained empty states, spoken
  punctuation cleanup, and the online guard.
- The `deleteAssets` safety fix (review pairs are kept, calibration fails closed).
- Added later the same day at the user's request (ADR-020): "Group similar
  faces" (`groupNow`, the existing validated grouping run once while processing
  stays paused) and a smaller naming list (tiny and duplicate faces hidden, each
  unnamed group counted once, largest groups first).
- Added later still, at the user's request (ADR-021): Google-style "Same
  person?" confirmations (`buildSamePersonQuestions`, `answerSamePerson`,
  `SamePersonScreen`) that compare two faces and offer No / Not sure / Yes.
- Then (ADR-022): rounds of 20 questions per launch, never repeated, asked on
  the main screen (`SamePersonPrompt`), and the fixes from an independent
  review. At the end of the day the user resumed People processing.

Unchanged and out of scope: face detection and SFace, `FaceContract`, grouping
and calibration rules, ranking constants, the CLIP model and schema v6.

## Build (Windows host, 2026-10-22)

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | No issues |
| `flutter test --no-pub test/` | 499 passed, 2 skipped on the grouping build (496 + 2 before the grouping change; 372 + 1 on 2026-10-21); 512 passed, 2 skipped on the first "Same person?" build; 526 passed, 2 skipped on the final build (see below) |
| `python -I tool/check_repository.py` | Passed |
| `flutter build apk --debug --no-pub` | Built; versionCode 1, debuggable |
| Signer of the built APK | Matches the app installed on the phone (apksigner comparison; digest not recorded) |

The skips are the real SFace worker test (needs
`--dart-define=SFACE_MODEL_TEST=true`) and the documented KI-16 bug test.
`test/people_suggestions_test.dart` had 25 tests on this build (+3 for
`groupNow` and the naming list); after the review fixes it has 27. An independent review of the first implementation (four
dimensions, each finding verified) found 24 issues; the fixes are in this
build. Linux CI was not re-run. A probable, unconfirmed cause of the earlier
Linux failures: existing 320 px widget tests pass only with the Windows Segoe
font loaded as Roboto; the new tests pass without it.

## Device baseline B0

Vivo I2214, API 36. Backup taken on 2026-10-22 before any install; aggregate
counts from the app database.

| Measurement | B0 |
| --- | --- |
| Installed app | Debug build, versionCode 1, last updated 2026-09-18 (the 2026-10-18 wave was never installed) |
| SQLite | Integrity ok, schema 6 |
| Photos / embeddings | 1,916 / 1,916 |
| People | Enabled, **paused** |
| Photos scanned for faces | 485 |
| Faces | 2,342 (336 ready, 2,006 small) |
| Named persons | 5 (1 with the This-is-me alias, 0 hidden) |
| Assignments | 6 manual, 0 automatic |
| Faces marked Not a face | 7 |
| Suggestion decisions | 6 accept, 1 reject |
| Review rounds | Archived: 40 calibration + 20 validation pairs. Current: 60 calibration + 20 fresh validation pairs |
| Saved calibration | **Passed**: calibration 46 same / 14 different; validation 16 same / 4 different, 0 false joins, 16 true joins; threshold about 0.462 |

- **Review gate.** The app states the result as "Passed this reviewed sample;
  not a general accuracy guarantee". The holdout is small (4 different-person
  pairs). This **contradicts earlier docs** that say the gate failed and the
  threshold is empty (`PEOPLE_VALIDATION_2026-09-18.md`, the 2026-10-18 table in
  `PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md`, and the 2026-10-21 handbook); those
  describe the first round.
- **Automatic grouping had not run on B0** (0 automatic assignments) because
  processing was paused. Resuming processing would let automatic grouping
  assign faces; that was the user's decision and had not been done on B0. Later
  the same day the user asked for one explicit grouping run (below), and at the
  end of the day the user resumed processing (below).
- The named people share no photo with the self person, so "photos of me with
  `<A>`" is correctly empty on B0.

## Device results (2026-10-22)

### Install and backups

- **B0b**, a fresh backup just before the install, was identical to B0 in every
  table.
- **Install** (`adb install -r`, the verified debug APK): firstInstallTime
  unchanged, signature unchanged, the installed binary identical to the built
  APK, and `run-as` works.
- **B1**, after the first launch and a force-stop: every table identical to
  B0b. Only app assets, the image cache, the WorkManager database and shader
  cache files changed.
- The People header after the install read 485 of 1916 photos processed,
  Paused, 2342 faces, 5 groups (unchanged).
- Later builds were installed the same way (three installs for the search and
  grouping builds; two more for "Same person?", below). **B2**, taken before
  the second install, was identical to B1 in every table: the searches wrote
  nothing.

### Searches

Expected values come from backup B1. The five named people had 1, 1, 1, 2 and 1
photos, and none shares a photo with the "This is me" person.

| Query | Result | Expected | Verdict |
| --- | --- | --- | --- |
| `photos of me with <A>` | Chips "You" and `<A>`; "No photos of you and `<A>` together" | Not together | PASS |
| `<A>` | 2 results | 2 | PASS |
| `<A> at the beach` | "2 photos of `<A>`, none match "the beach"" and "Show all 2 photos", which gives 2 results with a People filter chip | Scene miss | PASS |
| `Photos of me with <A>.` | Same as without the full stop | Same | PASS |
| `show me photos of <A>` | 2 results, no "You" chip | 2 | PASS |
| `<A> without me` | 2 results; chips `<A>` and "not You" | 2 | PASS |
| `<B> or <A>` | 3 results; "either" chips | 3 | PASS |
| `me` | 1 result; chip "You" | 1 | PASS |

### Hidden person

With `<A>` hidden, typing `<A>` shows no person chip and searches the words as
text (60 results by image meaning). People ⋮ Show hidden people, then `<A>`,
then "Search photos of `<A>`" gives 2 results. Unhide restored the person.

### Similar faces (view only)

For a person with one large manually named face, "Review similar faces (58)"
opened with the explanation ("This is not recognition…"), the paused note and
"1994 unnamed faces are too small to compare". Tiles expose "Unnamed face N,
not selected" to screen readers. For people whose only faces are small, the
screen asks for a clear, large face of that person first. No face was added or
rejected: identity decisions are the user's.

### Group similar faces (user-approved)

The root cause was shown to the user first (aggregate, from backup analysis):
2,342 detected faces in 430 photos; 336 are large enough (at least 100 px) for
an SFace descriptor and 2,006 are not, so the current face contract can never
group them. 67 photos have 10 or more faces. Duplicates are a minor factor: 26
overlapping same-photo detection pairs and about 20 near-identical cross-photo
pairs (the same image saved twice). The user's example, a group photo of the
user with a named person, has 22 and 25 faces of 25-77 px: none is comparable,
and the user's own face there is unnamed, so "photos of me with" that person is
correctly empty until that face is named.

After the user approved the run:

- The People header read 2342 faces, 142 groups. New faces read "1402 to name"
  (2,329 face entries before), with "Show small faces (798)".
- One named person (`<B>`) went from 1 to 4 photos (3 automatic additions).
- **B3**: 266 faces assigned `automatic`: 3 to that named person and the rest
  into 137 new unnamed groups (142 persons in total). Only `people_faces` and
  `people_persons` changed; reviews, scans, decisions, photos and embeddings
  are identical. Processing is still paused, the threshold is unchanged, 0
  faces are assigned to a person they were rejected for, and there are 0
  orphans.
- A host simulation of the same code on a copy of B1 predicted exactly 266
  grouped faces, 137 unnamed groups and 3 faces into a named person.

### Persistence and polish

- After a force-stop and relaunch: `<A>` 2 results, `me` 1, `<B>` 4
  (after grouping), all unchanged.
- After the third install, the "Group similar faces" menu item is enabled on
  first open, and New faces lists unnamed groups largest first (16, 9, 9, 9, 9
  and 8 photos).

### Same person? (2026-10-22)

Added later the same day at the user's request (ADR-021): Google-style "Is this
the same person?" cards that compare two faces and offer No, Not sure and Yes.

Host (Windows, 2026-10-22): `flutter analyze --no-pub` reports no issues;
`flutter test --no-pub test/` gives 512 passed, 2 skipped (the same two skips),
including 13 new tests in `test/people_same_person_test.dart`;
`python -I tool/check_repository.py` passed; the debug APK built with the same
signer.

On the device (view only):

- **Install and backups.** Two more builds were installed in place with
  `adb install -r` (five installs by then; four more followed, below), each
  after a fresh backup: **B4**
  before the fourth install and **B5** before the fifth. B3, B4 and B5 are
  identical in every database table: viewing the questions writes nothing.
- **Entry tile.** The People screen showed "Same person? | 122 quick questions
  to make grouping more accurate". The 122 questions are 3 verify questions
  (the 3 faces grouping added automatically to `<B>`) and 119 group pairs whose
  closest faces score at or above the floor, the lowest score among review
  pairs the user judged "same" (about 0.398). A host simulation of the same
  code on a copy of B3 counted 9,347 possible group pairs, of which only 11
  score 0.5 or more.
- **First card.** "Is this `<B>`?", with the right-hand face captioned "Added
  automatically" and the No / Not sure / Yes answers.
- **No answers by the assistant.** Identity decisions are the user's. At B5
  the effect of each answer was host-tested only; the user's later answers were
  checked through backup counts (B5 to B6, below).

Review score ranges in B3 (current round; cosine; aggregate):

| Subset | Judged same | Judged different |
| --- | --- | --- |
| Calibration | 46 pairs, 0.398-0.996 | 14 pairs, 0.307-0.439 |
| Validation | 16 pairs, 0.478-0.997 | 4 pairs, 0.329-0.399 |

The same- and different-person ranges overlap in calibration, and the floor
(about 0.398) is below the highest different-person calibration score (0.439),
so some questions can show two different people. The floor only selects which
pairs to ask about; the user's answer decides.

### The user's answers (B5 to B6)

Between B5 and B6 the user answered "Same person?" questions and named faces on
the phone. The assistant did not answer or name anything. Aggregate changes:

| Measurement | B5 | B6 |
| --- | --- | --- |
| Persons (groups) | 142 | 127 |
| Assignments: manual / automatic / unassigned | 6 / 266 / 2,070 | 35 / 239 / 2,068 |
| Decisions: accept / reject | 6 / 1 | 35 / 736 |
| Photos showing the "This is me" person | 1 | 11 |
| Photos of `<A>` that also show "me" | 0 of 2 | 2 of 2 |

Only `people_decisions`, `people_faces` and `people_persons` changed. Processing
stayed paused, the threshold is unchanged, and the must-be-zero checks are 0
(faces assigned to a rejected person, dismissed but assigned faces, orphans).
The 736 rejects come from No answers, which record a reject for every face of
both groups. After the install below, `photos of me with <A>` returned 2
results with chips "You" and `<A>` (B1: the not-together state). The user had
named their own face in the shared photos.

### Review fixes and rounds (2026-10-22)

An independent review of `groupNow`, the naming list and "Same person?" (each
finding verified) confirmed 14 issues. All are fixed in this build:

- A Yes to two groups made every automatically grouped face manual, including
  faces the user never saw. Now only the two compared faces are confirmed; the
  rest stay automatic and can be asked about (ADR-021).
- An earlier Not sure stopped a merge from carrying a reject over. A reject now
  replaces it.
- `groupNow` and a concurrent `applyGrouping` could both commit. The grouping
  run now advances the generation, creates a person row only once a face joins
  it, and the menu action suspends processing and holds the processing lease.
- Face sizes for the naming list ignored the decoder's power-of-two scaling.
- Duplicate detections came back in New faces after grouping.
- Question building ran on the UI isolate for up to 600 faces; it now
  estimates the pairwise work and uses `compute()` above 20,000.
- Grouping copy overstated the evidence; the dialog and result message now
  state the holdout sizes and where faces went.
- Small layout and state issues: the New faces header at 320 px, naming counts
  recomputed on every build, answer buttons off screen with large text (now a
  fixed bottom bar), a stale People screen after leaving mid-answer, and a
  missing busy guard on "Group similar faces".

The user then asked for rounds of 20 questions on each launch, never repeated,
asked on the main screen like Google Photos (ADR-022, with sources). Host
(Windows, 2026-10-22): `flutter analyze --no-pub` reports no issues; `flutter
test --no-pub test/` gives 522 passed, 2 skipped; `python -I
tool/check_repository.py` passed; the debug APK built with the same signer.

- **B7**, before the sixth install, was identical to B6 in every table.
- **Install** (`adb install -r`): firstInstallTime unchanged, installed binary
  identical to the built APK.
- **No questions left.** The main screen showed no prompt and People showed no
  "Same person?" tile. The same code run on a copy of B7 found 0 questions: of
  the group pairs, 79 were already answered No or Not sure, 104 share a photo,
  7,319 score below the floor (about 0.398) and 1 joins two named people. No
  automatic faces remain in named people. So the prompt and rounds are
  host-tested only.
- **Processing resumed.** Asked whether to resume processing so that more
  faces, and more questions, can be found, the user chose to resume and to keep
  the floor (strong pairs only). The assistant tapped "Continue people
  processing" at the user's request. The results are below.

### Resumed processing (2026-10-22)

- **The pass.** Processing started at about 10:41 and all 1,916 photos were
  processed by 11:02: 1,431 photos in about 20 minutes, about 1.2 photos per
  second (1,321 photos in 1,104 s between two readings). The app stayed in the
  foreground with the screen on, the phone charging over USB. Progress was read
  every 2 minutes from read-only copies of the database, which may have slowed
  the scan slightly.
- **Grouping.** After the full pass the validated `applyGrouping` ran (the
  review gate had passed): automatic assignments 239 to 324, groups 127 to 152.
  Nothing was added to a named person (their photo counts are unchanged).
- **B8** (app stopped after the pass): 1,916 of 1,916 photos scanned, faces
  2,342 to 2,642, descriptors 336 to 397. Only `people_faces`,
  `people_persons` and `people_scans` changed; the other 11 tables, including
  photos, embeddings, reviews and decisions, are identical to B7. Manual
  assignments (35), decisions (35 accept, 736 reject) and the threshold are
  unchanged; every must-be-zero check is 0; integrity ok.
- **On screen.** People: "1916 of 1916 photos processed | 2642 faces | 152
  groups", "Same person? | 70 quick questions to make grouping more accurate"
  and "New faces found | 1497 to name". Main screen: "Help improve face groups
  · 1 of 20 | Same or different person?" with No, Not sure, Yes, "Not now" and
  "Open full screen". The assistant answered nothing.
- **Host simulation on a copy of B8.** The same 70 questions: 0 about automatic
  faces in named people and 70 group pairs, 5 of them offering a named person;
  closest-face scores 0.399 to 0.983, 15 at 0.5 or more. "1497 to name" also
  matches.

### Final builds (2026-10-22)

A second verification pass over the code and these docs (four checkers, each
finding checked by a skeptic) found three more code issues, all fixed with
tests that fail without the fix. Answering the same pair twice was possible
through "Open full screen" during a save. An answered pair could be shown again
after a failed reload. A group-pair answer did not check that the compared
faces were still in their groups. The device check then showed that a name-only
search was labelled "Matched by on-device semantic search"; it now says
"Matched by assigned faces". Host: analyzer clean, 526 passed, 2 skipped.

- **Seventh install** (the home-prompt fix), after **B8**: firstInstallTime
  unchanged, installed binary identical to the built APK, `run-as` works.
- **Eighth install** (the verification fixes), after **B9**: B9 identical to
  B8 in every table, so the seventh install and viewing the prompt wrote
  nothing. Same checks passed.
- **Ninth install** (the tooltip), after **B10**: B10 differs from B9 only by
  one People processing-lease row, taken after launch and left by the
  force-stop for the backup (leases expire). Same checks passed.
- On the final build: the main-screen prompt shows as above;
  `photos of me with <A>` and `<A>` each give 2 results labelled "Matched by
  assigned faces".

### Not done on the device

- By the assistant: naming faces, confirming or rejecting suggestions and
  answering "Same person?" questions. These are identity decisions. The user
  named faces and answered questions themselves; their effect was checked only
  through aggregate backup counts (B5 to B6 above).
- Answering through the main-screen prompt and rounds: the prompt was shown
  after the resumed pass (70 questions), but answering is the user's; the
  round counting is host-tested only.
- Voice input: only typed queries were run.

## Acceptance table

`<scene>` is a scene word ("the beach" in this run). Rows P19 and P20 were
added for the grouping change, row P21 for the "Same person?" change, and rows
P22 to P24 for the user's answers, the rounds build and resumed processing.

| ID | Case | Expected | Result |
| --- | --- | --- | --- |
| P1 | In-place upgrade (G3-G4) | firstInstallTime unchanged, versionCode 1, installed APK = built APK, `run-as` works | PASS: firstInstallTime and signature unchanged, installed binary = built APK, `run-as` works |
| P2 | First open (G5) | 1,916 photos; People paused; B1 differs only in the People generation | PASS: 485 of 1916 processed, Paused; B1 identical to B0b in every table |
| P3 | This is me | Naming dialog shows the current holder; only one person holds it | Not run (naming flow; identity decisions are the user's) |
| P4 | Name `<A>` in New faces | "Saved `<A>`." (with Review similar for a detailed face); only the chosen faces are assigned | Not run (identity decision; host-tested) |
| P5 | Similar faces: Add | Nothing is added until Add; added faces are manual | Viewed only: explanation and paused note shown; nothing added |
| P6 | Similar faces: Not `<A>` | Rejected faces never return for `<A>`, also after restart | Not run (identity decision; host-tested) |
| P7 | Undo | Undo reverses only the latest decision | Not run (no decision made; host-tested) |
| P8 | `photos of me with <A>` | Shared photos, or the not-together state | PASS: not-together state |
| P9 | `<A>` | `<A>`'s photos, newest first | PASS: 2 results (expected 2) |
| P10 | `<A> at <scene>` | Ranked within `<A>`'s photos, or the scene-miss state offering all | PASS: scene-miss state; "Show all 2 photos" gives 2 |
| P11 | `show me photos of <A>` | `<A>`'s photos; no "You" chip | PASS: 2 results, no "You" chip |
| P12 | Voice-style punctuation | Punctuation removed; same result as the typed query | PASS for a typed trailing full stop; voice input not run |
| P13 | `<A> or <B>`, `<A> without <B>` | "either" chips / "not `<B>`" chip; correct photo sets | PASS: `<B> or <A>` 3 with "either" chips; `<A> without me` 2 with "not You" (exclusion run with the self person) |
| P14 | Hide, search, unhide `<B>` | A hidden `<B>` is not resolved from text; resolves again after unhide | PASS, run with `<A>` hidden: no chip, text search; "Search photos of `<A>`" 2; unhide restored |
| P15 | People filter chip | All of them / Any of them; combines with `<scene>`; Clear removes it | Partly: the chip appeared after "Show all 2 photos"; the picker and Clear were not recorded |
| P16 | Empty states | Each empty result explains why and offers a next step | PASS for not together and scene miss; the other empty states were not recorded |
| P17 | Restart persistence | Names, This is me, rejections and hidden state survive a force-stop | PASS: `<A>` 2, `me` 1, `<B>` 4 after relaunch; no rejections were made |
| P18 | B2 invariants (G7) | Faces, scans, reviews unchanged; paused 1; automatic 0; deltas reconcile | PASS: B2 identical to B1 in every table (no identity actions, so no deltas) |
| P19 | Group similar faces (user-approved) | Assigns only after a passed review; processing stays paused; only People faces and persons change | PASS: 266 automatic; B3 as above; matches the host simulation |
| P20 | Naming list | Tiny and duplicate faces hidden, not deleted; each unnamed group counted once, largest first | PASS: 1402 to name, 798 behind "Show small faces"; groups listed largest first |
| P21 | Same person? (view only) | Entry tile with a question count; a card with two faces and No / Not sure / Yes; viewing writes nothing | PASS (view only): 122 questions; first card "Is this `<B>`?" with "Added automatically"; B3, B4 and B5 identical in every table; no question answered |
| P22 | The user's answers and naming (B5 to B6) | Only People faces, persons and decisions change; must-be-zero checks stay 0; `photos of me with <A>` finds shared photos once "me" is named there | PASS: 142 to 127 groups, 35 manual, 736 rejects, 0 in every must-be-zero check; `photos of me with <A>` 2 results |
| P23 | Rounds and the main-screen prompt | Up to 20 questions per launch, never repeated; the prompt shows only while questions remain | PASS (view only): with 0 questions left (B7) no prompt was shown; after the resumed pass the prompt showed "Help improve face groups · 1 of 20" (70 questions). Answering and round counting host-tested |
| P24 | Resumed processing (user's choice) | Scanning continues while the app is open; after the full pass the validated grouping runs; no manual assignment changes | PASS: 1,916 of 1,916 photos in about 20 minutes; grouping +85 automatic, 127 to 152 groups, nothing added to a named person; manual, decisions, reviews and threshold unchanged; only People faces, persons and scans changed (B7 to B8) |

## Procedure (planned before the run; followed on 2026-10-22)

Run from `pixelsearch_app/` in Git Bash. `<serial>` is the one attached device;
backups go to the git-ignored `local_evaluation/`. PowerShell 5.1 `>` re-encodes
binary output, so use Git Bash redirection or the byte-safe copy in
`tool/run_search_evaluation.ps1`. Record serials, hashes and signature digests
only in the private session, never here. In the run, the assistant drove the
app over adb at the user's request; the user approved the grouping run.

**G1. Read-only checks.**

```sh
adb devices
adb -s <serial> shell dumpsys package com.pixelsearch.pixelsearch \
  | grep -E "versionCode|DEBUGGABLE|firstInstallTime|lastUpdateTime|signatures"
adb -s <serial> shell pidof com.pixelsearch.pixelsearch   # empty: app not running
```

Expect versionCode 1, DEBUGGABLE and an unchanged firstInstallTime.

**G2. Fresh backup and rollback copy.**

```sh
adb -s <serial> exec-out run-as com.pixelsearch.pixelsearch tar -cf - . \
  > local_evaluation/<backup>.tar
tar -tf local_evaluation/<backup>.tar > /dev/null          # validate the archive
adb -s <serial> shell pm path com.pixelsearch.pixelsearch   # installed APK location
adb -s <serial> pull <installed-apk> local_evaluation/<previous>.apk
```

Run the aggregate audit (below) and compare it with B0.

**G3. Install in place** (the verified debug APK only):

```sh
adb -s <serial> install -r build/app/outputs/flutter-apk/app-debug.apk
```

**G4. Post-install checks.** Repeat the G1 `dumpsys` (firstInstallTime
unchanged, versionCode 1), pull the installed APK again and confirm it is
byte-identical to the built APK, and confirm `run-as` still works.

**G5. First open and B1.** The user opens the app once, checks the photo count
and that People shows paused, then force-stops it. Take backup B1. All
non-People tables must be identical to the G2 backup, and the People tables
identical except the generation.

**G6. User-driven acceptance.** The user names and judges faces; the assistant
never judges identities, never changes review ratings and never pauses or
resumes processing without the user's decision. Run the acceptance table above and the cases in
`PEOPLE_NAME_SEARCH_DEVICE_ACCEPTANCE.md`.

**G7. B2.** Take backup B2. The faces, scans and reviews tables are unchanged
(no processing, no rating changes), paused is still 1, automatic assignments
are still 0, and the deltas in persons, manual assignments, decisions and
dismissed faces match what the user reports doing.

**G8. Record or roll back.** Fill the Result column with aggregate outcomes. If
a check fails, roll back (below) and record the failure.

## What the host can verify from backups

On an extracted copy of the app database, with read-only queries that print
counts only (never names, aliases, crop paths or ids):

- `PRAGMA integrity_check` and the schema version.
- Photo and embedding counts.
- People faces by quality, by assignment (manual / automatic) and dismissed.
- Scans; persons (total, self, hidden); decisions by kind; review pairs by
  subset and judgment.
- People state: enabled, paused, generation, threshold present.
- Per-table content comparison between B0, B1 and B2 (compare digests in the
  session; do not record them).

The host cannot verify on-screen behavior, wording, voice input, or whether a
face belongs to a person. Those are the user's observations.

## Rollback

```sh
adb -s <serial> install -r local_evaluation/<previous>.apk
```

Same signer, versionCode 1, data kept. Confirm with the G1 and G4 checks. The
G2 backup stays as the data reference; restoring app data is a separate,
user-approved step.

## Never do

- Uninstall the app or run `pm clear`.
- Run `flutter run`, `flutter install` or `flutter test ... -d <device>`;
  Flutter's post-test uninstall destroyed a private index once (KI-12).
- Install a release-signed build (it cannot update the debug-signed install).
- Take screenshots or screen recordings of personal photos or faces.
- Commit or publish backups, pulled APKs or database copies.
- Pause or resume People processing without the user's decision, change
  review ratings, or judge identities.
- Write names, photo identifiers, serials, paths or digests into tracked docs.
