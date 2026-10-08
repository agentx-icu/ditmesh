import 'package:morse_core/morse_core.dart';

import 'session_score.dart';

/// The Koch method: characters are learnt at full speed, two to start with
/// and one more each lesson, and a lesson is passed once a session is copied
/// at 90 % or better.
///
/// Lesson numbers are 1-based. Lesson `n` teaches `order[0 .. n]` inclusive,
/// i.e. `n + 1` symbols; lesson 1 covers the first two.
final class KochCourse {
  KochCourse({
    List<String>? order,
    this.passAccuracy = 0.90,
    this.minCharsPerSession = defaultMinCharsPerSession,
  }) : assert(
         passAccuracy > 0 && passAccuracy <= 1,
         'passAccuracy must be in (0, 1]',
       ),
       assert(minCharsPerSession >= 0, 'minCharsPerSession must be >= 0'),
       order = List<String>.unmodifiable(order ?? MorseAlphabet.kochOrder);

  /// Default for [minCharsPerSession]. Apps that let the learner pick a
  /// session length should not offer anything shorter, or lesson sessions
  /// could never unlock the next lesson.
  static const int defaultMinCharsPerSession = 50;

  /// Teaching order. Defaults to [MorseAlphabet.kochOrder].
  final List<String> order;

  /// Session accuracy required to unlock the next lesson.
  final double passAccuracy;

  /// Minimum symbols a session must contain to count towards unlocking.
  final int minCharsPerSession;

  /// Number of lessons (one fewer than the number of symbols; 0 if the order
  /// has fewer than two symbols).
  int get lessonCount => order.length < 2 ? 0 : order.length - 1;

  /// Lowest valid lesson number when the course has any lessons.
  int get firstLesson => 1;

  bool isValidLesson(int lesson) => lesson >= 1 && lesson <= lessonCount;

  /// Clamps [lesson] into `1..lessonCount` (returns 1 for an empty course).
  int clampLesson(int lesson) {
    if (lessonCount == 0) {
      return 1;
    }
    if (lesson < 1) {
      return 1;
    }
    return lesson > lessonCount ? lessonCount : lesson;
  }

  /// All symbols known at [lesson] (the first `lesson + 1` of [order]).
  List<String> charsForLesson(int lesson) {
    _checkLesson(lesson);
    return List<String>.unmodifiable(order.sublist(0, lesson + 1));
  }

  /// Same as [charsForLesson] but as a set, handy for drill filters.
  Set<String> charSetForLesson(int lesson) => charsForLesson(lesson).toSet();

  /// The symbol introduced by [lesson]. For lesson 1 this is the second
  /// symbol of [order]; both of its symbols are new but one must be named.
  String newCharForLesson(int lesson) {
    _checkLesson(lesson);
    return order[lesson];
  }

  /// Symbols introduced in the last [count] lessons up to and including
  /// [lesson]; used to give recently unlocked symbols extra drill weight.
  Set<String> recentCharsForLesson(int lesson, {int count = 2}) {
    _checkLesson(lesson);
    final first = lesson - count + 1 < 1 ? 1 : lesson - count + 1;
    final recent = <String>{for (var l = first; l <= lesson; l++) order[l]};
    // Lesson 1 introduces both order[0] and order[1]; order[0] counts as
    // recent whenever the window of [count] lessons reaches lesson 1.
    if (first == 1) {
      recent.add(order[0]);
    }
    return recent;
  }

  /// The lesson in which [char] is first taught, or null if not in the course.
  int? lessonFor(String char) {
    final index = order.indexOf(char);
    if (index < 0 || lessonCount == 0) {
      return null;
    }
    return index == 0 ? 1 : index;
  }

  bool isLastLesson(int lesson) => lesson >= lessonCount;

  /// Unlock rule: [SessionScore.strictAccuracy] >= [passAccuracy] and enough
  /// symbols in the session.
  ///
  /// The strict figure counts inserted symbols against the copy, so typing
  /// every candidate for a symbol the trainee cannot tell apart does not
  /// pass the lesson.
  bool passes(SessionScore score) =>
      score.totalChars >= minCharsPerSession &&
      score.strictAccuracy >= passAccuracy;

  /// The lesson to continue with after [score] was recorded at [lesson]:
  /// one higher when [passes] and not already at the end.
  int nextLesson(int lesson, SessionScore score) {
    _checkLesson(lesson);
    if (passes(score) && !isLastLesson(lesson)) {
      return lesson + 1;
    }
    return lesson;
  }

  void _checkLesson(int lesson) {
    if (!isValidLesson(lesson)) {
      throw RangeError.range(lesson, 1, lessonCount, 'lesson');
    }
  }

  @override
  String toString() =>
      'KochCourse(${order.length} symbols, $lessonCount lessons, '
      'pass ${(passAccuracy * 100).round()}% over >= $minCharsPerSession)';
}
