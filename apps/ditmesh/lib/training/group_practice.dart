import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'training_controller.dart';

/// Who the learner is in a local group practice session (F14). Roles are a
/// local label: nothing is enforced on, or announced to, other members.
enum GroupPracticeRole {
  instructor,
  participant;

  static GroupPracticeRole parse(Object? name) => values.firstWhere(
    (r) => r.name == name,
    orElse: () => GroupPracticeRole.participant,
  );
}

/// A round's local state. [unavailable]: its source message is gone
/// (deleted or cleared) — never a completed round.
enum GroupRoundState {
  open,
  done,
  unavailable;

  static GroupRoundState parse(Object? name) => values.firstWhere(
    (r) => r.name == name,
    orElse: () => GroupRoundState.open,
  );
}

/// One local copy attempt of a round; [exerciseId] is the shared exercise
/// record that already carries the credit.
@immutable
final class GroupPracticeAttempt {
  const GroupPracticeAttempt({
    required this.exerciseId,
    required this.at,
    required this.correct,
    required this.total,
    required this.assisted,
  });

  final String exerciseId;
  final DateTime at;
  final int correct;
  final int total;
  final bool assisted;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'at': at.toUtc().toIso8601String(),
    'correct': correct,
    'total': total,
    'assisted': assisted,
  };

  static GroupPracticeAttempt? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['exerciseId'];
    final at = DateTime.tryParse('${j['at']}');
    final c = j['correct'];
    final t = j['total'];
    if (id is! String || at == null || c is! int || t is! int) return null;
    return GroupPracticeAttempt(
      exerciseId: id,
      at: at,
      correct: c,
      total: t,
      assisted: j['assisted'] == true,
    );
  }
}

/// A round refers to an ordinary group message by id; the text is read
/// from history when needed and never copied here.
@immutable
final class GroupPracticeRound {
  const GroupPracticeRound({
    required this.id,
    required this.messageId,
    required this.messageAt,
    this.state = GroupRoundState.open,
    this.attempts = const [],
  });

  final String id;
  final String messageId;
  final DateTime messageAt;
  final GroupRoundState state;
  final List<GroupPracticeAttempt> attempts;

  GroupPracticeRound copyWith({
    GroupRoundState? state,
    List<GroupPracticeAttempt>? attempts,
  }) => GroupPracticeRound(
    id: id,
    messageId: messageId,
    messageAt: messageAt,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'messageId': messageId,
    'messageAt': messageAt.toUtc().toIso8601String(),
    'state': state.name,
    'attempts': [for (final a in attempts) a.toJson()],
  };

  static GroupPracticeRound? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final msg = j['messageId'];
    final at = DateTime.tryParse('${j['messageAt']}');
    if (id is! String || msg is! String || at == null) return null;
    final raw = j['attempts'];
    return GroupPracticeRound(
      id: id,
      messageId: msg,
      messageAt: at,
      state: GroupRoundState.parse(j['state']),
      attempts: [
        if (raw is List)
          for (final a in raw) ?GroupPracticeAttempt.fromJson(a),
      ],
    );
  }
}

/// Totals of a session; reading them adds no exercise and no credit.
typedef GroupPracticeSummary = ({
  int rounds,
  int done,
  int unavailable,
  int attempts,
  int assisted,
  double accuracy,
});

/// One local session in one group conversation.
@immutable
final class GroupPracticeSession {
  const GroupPracticeSession({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.role,
    required this.createdAt,
    this.rounds = const [],
    this.completed = false,
  });

  final String id;
  final String conversationId;
  final String title;
  final GroupPracticeRole role;
  final DateTime createdAt;
  final List<GroupPracticeRound> rounds;
  final bool completed;

  GroupPracticeSession copyWith({
    List<GroupPracticeRound>? rounds,
    bool? completed,
  }) => GroupPracticeSession(
    id: id,
    conversationId: conversationId,
    title: title,
    role: role,
    createdAt: createdAt,
    rounds: rounds ?? this.rounds,
    completed: completed ?? this.completed,
  );

  GroupPracticeSummary get summary {
    var attempts = 0;
    var assisted = 0;
    var correct = 0;
    var total = 0;
    for (final r in rounds) {
      attempts += r.attempts.length;
      assisted += r.attempts.where((a) => a.assisted).length;
      // The latest attempt of a round is its result.
      if (r.attempts.isNotEmpty) {
        correct += r.attempts.last.correct;
        total += r.attempts.last.total;
      }
    }
    return (
      rounds: rounds.length,
      done: rounds.where((r) => r.state == GroupRoundState.done).length,
      unavailable: rounds
          .where((r) => r.state == GroupRoundState.unavailable)
          .length,
      attempts: attempts,
      assisted: assisted,
      accuracy: total == 0 ? 0 : correct / total,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'title': title,
    'role': role.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'completed': completed,
    'rounds': [for (final r in rounds) r.toJson()],
  };

  static GroupPracticeSession? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final conv = j['conversationId'];
    final title = j['title'];
    final at = DateTime.tryParse('${j['createdAt']}');
    if (id is! String || conv is! String || title is! String || at == null) {
      return null;
    }
    final raw = j['rounds'];
    return GroupPracticeSession(
      id: id,
      conversationId: conv,
      title: title,
      role: GroupPracticeRole.parse(j['role']),
      createdAt: at,
      completed: j['completed'] == true,
      rounds: [
        if (raw is List)
          for (final r in raw) ?GroupPracticeRound.fromJson(r),
      ],
    );
  }
}

/// Every local group practice session of the learning profile, stored as
/// one training document (so restart keeps it and identity backups carry
/// it). Pure value operations; [GroupPracticeStore] persists them.
@immutable
final class GroupPracticeBook {
  const GroupPracticeBook(this.sessions);

  static const GroupPracticeBook empty = GroupPracticeBook([]);
  static const int version = 1;
  static const int maxAttemptsPerRound = 20;

  /// Written by a newer DitMesh: must not be overwritten by this one.
  static bool isNewer(Map<String, Object?>? j) {
    final v = j?['v'];
    return v is int && v > version;
  }

  final List<GroupPracticeSession> sessions;

  List<GroupPracticeSession> forConversation(String conversationId) => [
    for (final s in sessions)
      if (s.conversationId == conversationId) s,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  GroupPracticeSession? byId(String id) =>
      sessions.where((s) => s.id == id).firstOrNull;

  GroupPracticeBook _replace(GroupPracticeSession next) => GroupPracticeBook([
    for (final s in sessions) s.id == next.id ? next : s,
  ]);

  GroupPracticeBook add(GroupPracticeSession session) =>
      GroupPracticeBook([...sessions, session]);

  GroupPracticeBook remove(String sessionId) =>
      GroupPracticeBook([...sessions.where((s) => s.id != sessionId)]);

  /// Appends a round for [messageId]; a message already in the session is
  /// not added twice.
  GroupPracticeBook addRound(
    String sessionId, {
    required String roundId,
    required String messageId,
    required DateTime messageAt,
  }) {
    final s = byId(sessionId);
    if (s == null || s.rounds.any((r) => r.messageId == messageId)) {
      return this;
    }
    return _replace(
      s.copyWith(
        rounds: [
          ...s.rounds,
          GroupPracticeRound(
            id: roundId,
            messageId: messageId,
            messageAt: messageAt,
          ),
        ],
      ),
    );
  }

  GroupPracticeBook removeRound(String sessionId, String roundId) {
    final s = byId(sessionId);
    if (s == null) return this;
    return _replace(
      s.copyWith(rounds: [...s.rounds.where((r) => r.id != roundId)]),
    );
  }

  GroupPracticeBook setRoundState(
    String sessionId,
    String roundId,
    GroupRoundState state,
  ) => _mapRound(sessionId, roundId, (r) => r.copyWith(state: state));

  /// Adds [attempt] to the round (marking it done). The same exercise id is
  /// recorded once, however often this is called.
  GroupPracticeBook recordAttempt(
    String sessionId,
    String roundId,
    GroupPracticeAttempt attempt,
  ) => _mapRound(sessionId, roundId, (r) {
    if (r.attempts.any((a) => a.exerciseId == attempt.exerciseId)) return r;
    final all = [...r.attempts, attempt];
    return r.copyWith(
      // The exercise records keep every attempt; a round keeps the latest.
      attempts: all.length > maxAttemptsPerRound
          ? all.sublist(all.length - maxAttemptsPerRound)
          : all,
      state: r.state == GroupRoundState.unavailable
          ? r.state
          : GroupRoundState.done,
    );
  });

  GroupPracticeBook complete(String sessionId) {
    final s = byId(sessionId);
    return s == null ? this : _replace(s.copyWith(completed: true));
  }

  GroupPracticeBook _mapRound(
    String sessionId,
    String roundId,
    GroupPracticeRound Function(GroupPracticeRound) f,
  ) {
    final s = byId(sessionId);
    if (s == null) return this;
    return _replace(
      s.copyWith(rounds: [for (final r in s.rounds) r.id == roundId ? f(r) : r]),
    );
  }

  Map<String, Object?> toJson() => {
    'v': version,
    'sessions': [for (final s in sessions) s.toJson()],
  };

  static GroupPracticeBook fromJson(Map<String, Object?>? j) {
    if (j == null || j['v'] != version) return empty;
    final raw = j['sessions'];
    return GroupPracticeBook([
      if (raw is List)
        for (final s in raw) ?GroupPracticeSession.fromJson(s),
    ]);
  }

  static String newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '_${Random().nextInt(1 << 30).toRadixString(36)}';
}

/// Persistence of the [GroupPracticeBook] through the training controller's
/// documents (serialized read-modify-write; covered by its flush).
extension GroupPracticeStore on TrainingController {
  static const String doc = 'group_practice';

  Future<GroupPracticeBook> readGroupPractice() async =>
      GroupPracticeBook.fromJson(await readDoc(doc));

  Future<GroupPracticeBook> updateGroupPractice(
    GroupPracticeBook Function(GroupPracticeBook book) change,
  ) => docTransaction(() async {
    final raw = await readDoc(doc);
    if (GroupPracticeBook.isNewer(raw)) {
      throw StateError('group practice written by a newer version');
    }
    final next = change(GroupPracticeBook.fromJson(raw));
    await writeDoc(doc, next.toJson());
    return next;
  });

  /// The local attempt for a scored copy (null when nothing was scored).
  static GroupPracticeAttempt? attemptOf(
    String exerciseId,
    SessionScore? score,
    Set<Assistance> assistance,
  ) => score == null
      ? null
      : GroupPracticeAttempt(
          exerciseId: exerciseId,
          at: score.at ?? DateTime.now(),
          correct: score.correctChars,
          total: score.totalChars,
          assisted: assistance.isNotEmpty,
        );
}
