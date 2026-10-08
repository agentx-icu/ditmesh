import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 3, 12);
  var counter = 0;

  SessionSummary attempt({
    int total = 60,
    double strict = 0.97,
    double charWpm = 20,
    double effWpm = 8,
    ExerciseSource source = ExerciseSource.review,
    Set<Assistance>? assistance = const {},
    String kind = 'groups',
    int daysAgo = 0,
    int lesson = 10,
  }) {
    final correct = (total * strict).round();
    return SessionSummary(
      at: now.subtract(Duration(days: daysAgo, minutes: 10 - counter)),
      totalChars: total,
      correctChars: correct,
      drillKind: kind,
      lesson: lesson,
      id: 'ex${counter++}',
      source: source,
      characterWpm: charWpm,
      effectiveWpm: effWpm,
      insertions: 0,
      assistance: assistance,
    );
  }

  SpeedAdvice eval(
    List<SessionSummary> h, {
    double char = 20,
    double eff = 8,
    int? lesson,
  }) => SpeedRecommender.evaluate(
    h,
    characterWpm: char,
    effectiveWpm: eff,
    now: now,
    currentLesson: lesson,
  );

  test('three strong attempts raise the effective speed by one', () {
    final a = eval([attempt(), attempt(), attempt()]);
    expect(a.kind, SpeedAdviceKind.increaseEffective);
    expect(a.effectiveWpm, 9);
    expect(a.characterWpm, 20);
    expect(a.evidenceKey, isNotNull);
  });

  test('two attempts are insufficient evidence', () {
    expect(eval([attempt(), attempt()]).kind, SpeedAdviceKind.insufficient);
  });

  test('short, assisted, legacy, old or sending attempts do not count', () {
    final h = [
      attempt(total: 40),
      attempt(assistance: {Assistance.replay}),
      attempt(assistance: null),
      attempt(daysAgo: 15),
      attempt(source: ExerciseSource.send),
      attempt(source: ExerciseSource.placement),
      attempt(),
      attempt(),
    ];
    expect(eval(h).kind, SpeedAdviceKind.insufficient);
  });

  test('one attempt below 90 % blocks an increase', () {
    final a = eval([attempt(), attempt(strict: 0.88), attempt(strict: 1)]);
    expect(a.kind, SpeedAdviceKind.hold);
  });

  test('three weak attempts suggest slowing down, never below 5 WPM', () {
    final weak = [
      attempt(strict: 0.7),
      attempt(strict: 0.7),
      attempt(strict: 0.6),
    ];
    final a = eval(weak);
    expect(a.kind, SpeedAdviceKind.decrease);
    expect(a.effectiveWpm, 7);
    final floor = [
      attempt(strict: 0.7, effWpm: 5),
      attempt(strict: 0.7, effWpm: 5),
      attempt(strict: 0.6, effWpm: 5),
    ];
    expect(eval(floor, eff: 5).kind, SpeedAdviceKind.hold);
  });

  test('effective equal to character speed raises both', () {
    final h = [attempt(effWpm: 20), attempt(effWpm: 20), attempt(effWpm: 20)];
    final a = eval(h, eff: 20);
    expect(a.kind, SpeedAdviceKind.increaseBoth);
    expect(a.characterWpm, 21);
    expect(a.effectiveWpm, 21);
  });

  test('evidence must match the current speeds and drill kind', () {
    final h = [
      attempt(effWpm: 7),
      attempt(effWpm: 7),
      attempt(kind: 'words'),
      attempt(),
    ];
    // Newest comparable kind is groups with only one comparable attempt
    // at 8 wpm; the words attempt is another kind.
    expect(eval(h).kind, SpeedAdviceKind.insufficient);
  });

  test('course evidence from an older lesson is ignored', () {
    final h = [
      attempt(source: ExerciseSource.course, lesson: 9),
      attempt(source: ExerciseSource.course, lesson: 9),
      attempt(source: ExerciseSource.course, lesson: 10),
    ];
    expect(eval(h, lesson: 10).kind, SpeedAdviceKind.insufficient);
    expect(eval(h).kind, SpeedAdviceKind.increaseEffective);
  });

  test('only the latest five attempts are weighed', () {
    final h = [
      for (var i = 0; i < 3; i++) attempt(strict: 0.5),
      for (var i = 0; i < 5; i++) attempt(strict: 0.98),
    ];
    expect(eval(h).kind, SpeedAdviceKind.increaseEffective);
    expect(eval(h).samples, 5);
  });
}
