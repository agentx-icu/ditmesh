[简体中文](./README.zh-CN.md)

# morse_trainer

Training pedagogy for DitMesh as **pure Dart** (no Flutter imports): the Koch
course, Farnsworth settings, drill generators, alignment-based scoring, spaced
repetition, send-practice diagnostics and learner progress. It depends on
`morse_core` for types only (`MorseTiming`, `MorseAlphabet.kochOrder`); audio,
haptics and persistence belong to `morse_io` and the app.

Everything is deterministic given a `Random` seed and an injected clock
(`DateTime now` parameters), so the app and its tests can replay sessions.

## Symbols, not code units

A trainer "char" is one Morse symbol as produced by `MorseText.tokenize`: a
letter, digit or punctuation mark, **or** a bracketed prosign such as `<BT>`,
which counts as a single symbol. Every API that takes or returns chars uses
this convention, so `<BT>` in `MorseAlphabet.kochOrder` just works.

## Class map

| Concern | Types | File |
| --- | --- | --- |
| Koch course | `KochCourse` (lesson char sets, unlock rule `passes`, `nextLesson`) | `src/koch_course.dart` |
| Settings | `TrainerSettings` (char/Farnsworth wpm, tone, session length, `toTiming()`, JSON) | `src/trainer_settings.dart` |
| Drills | `Drill`, `DrillGenerator` | `src/drill.dart` |
| | `RandomGroupsDrill` (weighted groups of 5) | `src/random_groups_drill.dart` |
| | `WordDrill` (+ `WordLists.commonWords`, `WordLists.cwAbbreviations`, `WordLists.qCodes`; `WordDrill.radioShorthand` mixes the last two) | `src/word_drill.dart`, `src/word_lists.dart` |
| | `NumberGroupsDrill` (digit groups from the allowed digits) | `src/number_groups_drill.dart` |
| | `ConfusableDrill` (minimal pairs from the confusion matrix and one-element pattern neighbours) | `src/confusable_drill.dart` |
| | `CallsignDrill` (prefix + digit + suffix, optional symbol filter) | `src/callsign_drill.dart` |
| | `QsoDrill` (templated exchanges, single line or full QSO) | `src/qso_drill.dart` |
| | `ContestExchangeDrill` (`call 599 nnn`, optionally cut numbers `5NN TT7`) | `src/contest_drill.dart` |
| Scoring | `SessionScore` (Needleman-Wunsch alignment, per-char stats), `ConfusionMatrix`, `CharStats`, `SequenceAligner` | `src/session_score.dart`, `src/confusion_matrix.dart`, `src/char_stats.dart`, `src/alignment.dart` |
| Weighting / SRS | `CharWeights` (`w = max(floor, 1 + k(1 - acc))` x recency boost), `SrsScheduler` (Leitner boxes 0..4, `dueChars(now)`) | `src/char_weights.dart`, `src/srs_scheduler.dart` |
| Send practice | `SendAttempt`, `SendDiagnostics`, `SendIssue`, `SendIssueKind`, `SendThresholds` | `src/send_practice.dart` |
| Progress | `TrainerProgress`, `SessionSummary`, `TrainerStore`, `InMemoryTrainerStore` | `src/trainer_progress.dart`, `src/session_summary.dart`, `src/trainer_store.dart` |
| Text | `MorseText` (tokeniser shared by everything above) | `src/morse_text.dart` |

## How the app is expected to wire it

```dart
final course = KochCourse();                     // MorseAlphabet.kochOrder
var progress = await store.load() ?? TrainerProgress();
final settings = TrainerSettings.fromJson(prefsJson);

// 1. Pick a drill for the current lesson, weighted towards weak/new symbols.
final chars = course.charsForLesson(progress.currentLesson);
final weights = CharWeights.fromStats(
  progress.charStats,
  recent: course.recentCharsForLesson(progress.currentLesson),
);
final generator = RandomGroupsDrill.forLength(
  chars: chars,
  totalChars: settings.sessionLengthChars,
  groupSize: settings.groupSize,
  weights: weights,
);
final drill = generator.generate(Random(seed));

// 2. Play it through morse_io at settings.toTiming() / settings.toneHz,
//    collect the trainee's typed copy.

// 3. Score, then fold into progress and let the course decide on unlocking.
final score = SessionScore.evaluate(
  drill.text,
  typedAnswer,
  at: clock.now(),
  elapsed: stopwatch.elapsed,
  lesson: progress.currentLesson,
  drillKind: drill.kind,
);
progress = progress
    .recordSession(score, now: clock.now())      // stats, streak, SRS, confusion
    .advanceIfPassed(course, score);            // >= 90 % over >= 50 chars
await store.save(progress);

// Optional: bias the next drill towards SRS-due symbols.
final due = progress.srs.dueOrNew(chars, clock.now());
```

Send practice: feed the decoder's marks/gaps and dit estimate into
`SendAttempt(...).evaluate()` and show `SendDiagnostics.issues` (each has a
`kind`, `severity` and `describe()` string) plus `measuredWpm`.

`TrainerStore` is an interface; the app supplies the file / preferences
implementation. `InMemoryTrainerStore` round-trips through JSON so tests
exercise the same serialisation a real store would.

## Development

```bash
dart pub get                       # at the workspace root
dart analyze packages/morse_trainer
dart test packages/morse_trainer
```

Every file stays under 500 lines (CI gate) and the workspace lint set applies.
