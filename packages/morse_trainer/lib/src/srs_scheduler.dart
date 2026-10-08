import 'dart:math';

import 'char_stats.dart';
import 'session_score.dart';

/// Leitner box state for one symbol.
final class SrsCard {
  /// [dueAt] is stored in UTC so cards compare equal regardless of the zone
  /// the caller's clock reported and survive a JSON round trip unchanged.
  SrsCard({required this.box, required DateTime dueAt})
    : assert(box >= 0, 'box must be >= 0'),
      dueAt = dueAt.toUtc();

  /// 0 = drill every session ... [SrsScheduler.maxBox] = well known.
  final int box;

  /// When the symbol should next be drilled (UTC).
  final DateTime dueAt;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  Map<String, Object?> toJson() => <String, Object?>{
    'box': box,
    'dueAt': dueAt.toIso8601String(),
  };

  factory SrsCard.fromJson(Map<String, Object?> json) => SrsCard(
    box: (json['box'] as num).toInt(),
    dueAt: DateTime.parse(json['dueAt'] as String),
  );

  @override
  String toString() => 'SrsCard(box $box, due $dueAt)';

  @override
  bool operator ==(Object other) =>
      other is SrsCard && other.box == box && other.dueAt == dueAt;

  @override
  int get hashCode => Object.hash(box, dueAt);
}

/// Leitner-style spaced repetition over symbols.
///
/// Immutable: every mutation returns a new scheduler so it can live inside an
/// immutable progress object. Boxes run `0..maxBox`; a correct result promotes
/// one box, a miss demotes one box, and the next due time is
/// `now + intervals[box]`.
final class SrsScheduler {
  SrsScheduler({
    Map<String, SrsCard> cards = const <String, SrsCard>{},
    List<Duration> intervals = defaultIntervals,
  }) : assert(intervals.isNotEmpty, 'intervals must not be empty'),
       cards = Map<String, SrsCard>.unmodifiable(cards),
       intervals = List<Duration>.unmodifiable(intervals);

  /// Box 0 is always due; higher boxes wait progressively longer.
  static const List<Duration> defaultIntervals = <Duration>[
    Duration.zero,
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
  ];

  final Map<String, SrsCard> cards;
  final List<Duration> intervals;

  int get maxBox => intervals.length - 1;

  bool contains(String char) => cards.containsKey(char);

  SrsCard? cardFor(String char) => cards[char];

  /// Box of [char], or null if it has never been introduced.
  int? boxOf(String char) => cards[char]?.box;

  /// Adds any of [chars] not yet tracked at box 0, due immediately.
  SrsScheduler introduce(Iterable<String> chars, DateTime now) {
    final next = Map<String, SrsCard>.of(cards);
    for (final c in chars) {
      next.putIfAbsent(c, () => SrsCard(box: 0, dueAt: now));
    }
    return SrsScheduler(cards: next, intervals: intervals);
  }

  /// Promotes ([correct] true) or demotes [char] and reschedules it. A symbol
  /// that was not tracked yet is introduced first.
  SrsScheduler record(
    String char, {
    required bool correct,
    required DateTime now,
  }) {
    // A stored box beyond this scheduler's intervals (a file written with a
    // longer interval list) is treated as the top box.
    final current = min(maxBox, cards[char]?.box ?? 0);
    final box = correct ? min(maxBox, current + 1) : max(0, current - 1);
    final next = Map<String, SrsCard>.of(cards);
    next[char] = SrsCard(box: box, dueAt: now.add(intervals[box]));
    return SrsScheduler(cards: next, intervals: intervals);
  }

  /// Applies a session: each symbol that appeared is demoted when its
  /// per-symbol accuracy is below [passAccuracy]. A good result promotes a
  /// symbol only when it was due (or not tracked yet); copying a symbol that
  /// is not due yet leaves its box alone, so daily lesson drills, which
  /// contain every learned symbol, do not push the whole set to the top box
  /// in a few days.
  SrsScheduler applyScore(
    SessionScore score, {
    required DateTime now,
    double passAccuracy = 0.9,
  }) => applyCharStats(score.charStats, now: now, passAccuracy: passAccuracy);

  /// [applyScore] over explicit per-symbol results (e.g. a score filtered to
  /// the learned symbols).
  SrsScheduler applyCharStats(
    Map<String, CharStats> stats, {
    required DateTime now,
    double passAccuracy = 0.9,
  }) {
    var next = this;
    final chars = stats.keys.toList()..sort();
    for (final c in chars) {
      final correct = stats[c]!.accuracy >= passAccuracy;
      final card = cards[c];
      if (correct && card != null && !card.isDue(now)) {
        continue;
      }
      next = next.record(c, correct: correct, now: now);
    }
    return next;
  }

  /// Symbols due at [now], soonest-due first (ties by symbol). Pass [shuffle]
  /// to randomise the order deterministically for a given seed.
  List<String> dueChars(DateTime now, {Random? shuffle}) {
    final due = cards.entries.where((e) => e.value.isDue(now)).toList()
      ..sort((a, b) {
        final byDue = a.value.dueAt.compareTo(b.value.dueAt);
        return byDue != 0 ? byDue : a.key.compareTo(b.key);
      });
    final result = due.map((e) => e.key).toList();
    if (shuffle != null) {
      result.shuffle(shuffle);
    }
    return result;
  }

  /// Symbols in [chars] that are due, plus any in [chars] not yet tracked.
  List<String> dueOrNew(Iterable<String> chars, DateTime now) {
    final set = chars.toSet();
    final due = dueChars(now).where(set.contains).toList();
    for (final c in chars) {
      if (!cards.containsKey(c)) {
        due.add(c);
      }
    }
    return due;
  }

  /// Box -> number of symbols in it.
  Map<int, int> get boxCounts {
    final counts = <int, int>{};
    for (final card in cards.values) {
      counts[card.box] = (counts[card.box] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'intervalsMs': intervals.map((d) => d.inMilliseconds).toList(),
    'cards': <String, Object?>{
      for (final entry in cards.entries) entry.key: entry.value.toJson(),
    },
  };

  factory SrsScheduler.fromJson(Map<String, Object?> json) {
    final rawIntervals = json['intervalsMs'] as List<Object?>?;
    final rawCards = json['cards'] as Map<String, Object?>? ?? const {};
    return SrsScheduler(
      intervals: rawIntervals == null || rawIntervals.isEmpty
          ? defaultIntervals
          : rawIntervals
                .map((v) => Duration(milliseconds: (v! as num).toInt()))
                .toList(),
      cards: <String, SrsCard>{
        for (final entry in rawCards.entries)
          entry.key: SrsCard.fromJson(entry.value! as Map<String, Object?>),
      },
    );
  }

  @override
  String toString() => 'SrsScheduler(${cards.length} cards, boxes $boxCounts)';
}
