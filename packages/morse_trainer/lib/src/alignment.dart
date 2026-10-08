/// What happened at one position of an alignment.
enum AlignmentOp {
  /// Target and answer symbols agree.
  match,

  /// Target symbol was answered with a different symbol.
  substitution,

  /// Answer contains a symbol the target does not have.
  insertion,

  /// Target symbol has no counterpart in the answer.
  deletion,
}

/// One column of a global alignment between a target and an answer.
///
/// Exactly one of [target] / [answer] may be null (an insertion has no target,
/// a deletion has no answer).
final class AlignedPair {
  const AlignedPair({this.target, this.answer})
    : assert(
        target != null || answer != null,
        'an aligned pair needs at least one side',
      );

  final String? target;
  final String? answer;

  AlignmentOp get op {
    if (target == null) {
      return AlignmentOp.insertion;
    }
    if (answer == null) {
      return AlignmentOp.deletion;
    }
    return target == answer ? AlignmentOp.match : AlignmentOp.substitution;
  }

  bool get isMatch => op == AlignmentOp.match;

  Map<String, Object?> toJson() => <String, Object?>{'t': target, 'a': answer};

  factory AlignedPair.fromJson(Map<String, Object?> json) =>
      AlignedPair(target: json['t'] as String?, answer: json['a'] as String?);

  @override
  String toString() => '(${target ?? '-'}/${answer ?? '-'})';

  @override
  bool operator ==(Object other) =>
      other is AlignedPair && other.target == target && other.answer == answer;

  @override
  int get hashCode => Object.hash(target, answer);
}

/// Global sequence alignment (Needleman-Wunsch) over symbol lists.
///
/// Used so that one missed or inserted character does not shift every later
/// character out of place when a copy is scored.
abstract final class SequenceAligner {
  /// Aligns [target] against [answer] and returns the columns in order.
  ///
  /// Scoring: [match] for equal symbols, [mismatch] for a substitution and
  /// [gap] for an insertion or deletion. Ties are broken towards a diagonal
  /// move (substitution/match), then deletion, then insertion, which keeps the
  /// result deterministic.
  static List<AlignedPair> align(
    List<String> target,
    List<String> answer, {
    int match = 1,
    int mismatch = -1,
    int gap = -1,
  }) {
    final n = target.length;
    final m = answer.length;
    final score = List<List<int>>.generate(
      n + 1,
      (_) => List<int>.filled(m + 1, 0),
      growable: false,
    );
    for (var i = 1; i <= n; i++) {
      score[i][0] = i * gap;
    }
    for (var j = 1; j <= m; j++) {
      score[0][j] = j * gap;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final diag =
            score[i - 1][j - 1] +
            (target[i - 1] == answer[j - 1] ? match : mismatch);
        final up = score[i - 1][j] + gap;
        final left = score[i][j - 1] + gap;
        var best = diag;
        if (up > best) {
          best = up;
        }
        if (left > best) {
          best = left;
        }
        score[i][j] = best;
      }
    }

    final reversed = <AlignedPair>[];
    var i = n;
    var j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final s = target[i - 1] == answer[j - 1] ? match : mismatch;
        if (score[i][j] == score[i - 1][j - 1] + s) {
          reversed.add(
            AlignedPair(target: target[i - 1], answer: answer[j - 1]),
          );
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && score[i][j] == score[i - 1][j] + gap) {
        reversed.add(AlignedPair(target: target[i - 1]));
        i--;
        continue;
      }
      reversed.add(AlignedPair(answer: answer[j - 1]));
      j--;
    }
    return reversed.reversed.toList(growable: false);
  }
}
