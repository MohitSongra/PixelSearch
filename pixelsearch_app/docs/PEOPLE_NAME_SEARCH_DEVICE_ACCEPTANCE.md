# People Name Search Device Acceptance

This checklist records the manual-confirmation People workflow. Do not record
face images, face vectors, names of private people, or photo identifiers here.

## Preconditions

- Use an existing indexed gallery and enable People processing.
- Wait until the People screen shows new face observations.
- Do not enable automatic grouping; its validation gate must remain off unless a
  separate independent review passes.

## Acceptance Run

1. Open **Search > People > New faces** and manually name two confirmed people.
   Add `me` to the first person's aliases where appropriate.
2. Confirm that a one-person name query returns only photos manually assigned to
   that person.
3. Confirm that a two-person query, such as `me with [second person]`, returns
   only photos containing both confirmed assignments.
4. Confirm that a scene query, such as `[person] at the beach`, retains the
   scene phrase and limits the candidate set to the confirmed person.
5. Leave one similar-looking or unassigned face unassigned; confirm it is not
   returned as the named person.
6. Rename, remove an assignment, dismiss a non-face, restart the app, and check
   that the following searches reflect the current local assignments.

## Non-Sensitive Evidence and Unit Verification

Date: 2026-10-18.

### Automated Unit and Integration Coverage (`test/people_name_search_test.dart`)

| Acceptance Specification | Test Status | Notes |
| --- | --- | --- |
| Aliases resolution (`me`, `myself`, nicknames) | VERIFIED (PASS) | Case-insensitive, multi-alias support, preposition trimming |
| Ambiguous names handling | VERIFIED (PASS) | Requires explicit user choice, never guesses identity |
| Disjoint / ambiguous query combination | VERIFIED (PASS) | Retains unique person, isolates ambiguous person |
| Multi-person intersection (`me with [person B]`) | VERIFIED (PASS) | Strict mathematical intersection of confirmed photo IDs |
| Unassigned / similar face exclusion | VERIFIED (PASS) | Unassigned faces (`personId == null`) never appear in named queries |
| Honest empty state on zero assignments | VERIFIED (PASS) | Disjoint or empty person queries return empty photo set |
| Rename / alias correction | VERIFIED (PASS) | Immediately invalidates cache and matches updated labels |
| Remove assignment / face reassignment | VERIFIED (PASS) | Excludes removed photos immediately from query results |
| Dismiss face (`not a face`) | VERIFIED (PASS) | Sets `dismissed = true`, excludes from unassigned list and search |
| Restart persistence | VERIFIED (PASS) | Fresh repository instance preserves all names, aliases, and dismissals |
| Person plus scene ranking (`[person A] at the beach`) | VERIFIED (PASS) | Scopes candidates to eligible person set before cosine ranking |
| Name-only queries | VERIFIED (PASS) | Chronological keyword search bypassing text encoder |

### Physical Device Non-Sensitive Baseline (Vivo I2214)

| Check | Result | Non-sensitive count / observation |
| --- | --- | --- |
| Library index baseline | VERIFIED | 1,916 indexed photos, 1,916 embeddings |
| Face processing checkpoint | VERIFIED | 485 photos processed, 2,342 face detections |
| Descriptor quality breakdown | VERIFIED | 336 ready descriptors, 2,006 small-face observations |
| Pair review calibration | RECORDED | 31 Same, 9 Different |
| Pair review validation | RECORDED | 15 Same, 5 Different |
| Automatic grouping status | OFF | Validation false join on pair 56 (cosine 0.4392 > 0.4308 cutoff); gate closed |
| Local database integrity | VERIFIED | SQLite schema 6 integrity `ok` |

Use screenshots only with the owners' consent. This checklist validates product
behavior, not face-recognition accuracy.

## Additional cases for the 2026-10-22 build

Added 2026-10-22. Status: partly run on the device on 2026-10-22 (typed
queries only, no identity actions by the assistant); aggregate results are in
`PEOPLE_SEARCH_DEVICE_ACCEPTANCE_2026-10-22.md`. Passed: 10, 11 (the exclusion
was run with "me"), 12 (hide, search, unhide; the online guard was not
recorded), 14 (not together and scene miss) and 16 (names). Not run: 7, 9 and
13; 8 was viewed only (no Add or Not); 15 was checked with a typed trailing
full stop, not voice. `<A>` and `<B>` stand for two
people the user has named; `<scene>` is a scene word. The user names and judges
faces; the assistant never judges identities. People processing stays paused,
and no review rating is changed.

7. **This is me holder.** Open the naming dialog for `<A>`. The "This is me"
   option names the person who currently holds it; only one person can hold it.
   Leave it unchanged unless the user chooses to move it.
8. **Similar faces.** From `<A>`'s page open **Review similar faces**. The screen
   says nothing is added to `<A>` until the user chooses Add. Add some faces,
   mark one **Not `<A>`**, use Undo once, and try **Show more**. Leave and reopen:
   faces marked Not `<A>` do not return, and no face was added without Add.
9. **Self missing (optional, only if the user agrees to untick This is me
   for the test).** `photos of me` shows "Which person is you?" with Open People
   and 'Search without "me"'. Restore This is me afterwards.
10. **Request verbs.** `show me photos of <A>` returns `<A>`'s photos with no
    "You" chip.
11. **or / without.** `<A> or <B>` returns photos with either person and shows
    "either" chips. `<A> without <B>` returns `<A>`'s photos with no assigned
    `<B>` face and shows a "not `<B>`" chip.
12. **Hidden person.** Hide `<B>`. Typing `<B>` creates no person chip; if the
    user has already enabled online refinement, it is still blocked for that
    name and nothing is sent. Unhide `<B>` and confirm that `<B>` resolves again.
13. **People filter chip.** Choose `<A>` and `<B>` in the People filter, switch
    between All of them and Any of them, combine with `<scene>` text, then Clear.
14. **Empty states.** `photos of me with <A>` when they share no assigned photo
    says they are not together; `<A> at <scene>` with no match offers all of
    `<A>`'s photos; a date or album filter that excludes them says none match
    the filters.
15. **Voice punctuation.** Dictate `photos of <A>` with spoken punctuation; the
    local search runs without the punctuation and matches the typed query.
16. **Restart persistence.** Force-stop and reopen; names, This is me, rejected
    suggestions and hidden state are unchanged.

