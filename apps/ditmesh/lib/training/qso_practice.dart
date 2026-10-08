import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'training_controller.dart';

/// Persistence and crediting for the interactive QSO simulator (F02).
///
/// The session (text and state only — never a held key or playback) is
/// kept as a draft document so an interrupted QSO can be resumed. A
/// finished QSO is one exercise of source `qso`: activity credit only, its
/// semantic score never touches copying statistics or lesson unlocks.
extension QsoPractice on TrainingController {
  static const String draftDoc = 'qso_draft';
  static const String stationDoc = 'qso_station';

  /// Whether the course is far enough along for the simulator.
  bool get qsoUnlocked => currentLesson >= TrainingController.qsoFromLesson;

  Future<QsoStation?> loadQsoStation() async {
    try {
      final json = await readDoc(stationDoc);
      return json == null ? null : QsoStation.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> saveQsoStation(QsoStation station) =>
      writeDoc(stationDoc, station.normalized().toJson());

  /// The saved draft: unfinished text state, or a finished QSO whose
  /// result was not saved yet (see [finishQso]).
  Future<QsoDraft?> loadQsoDraft() async {
    try {
      final json = await readDoc(draftDoc);
      final raw = json?['session'];
      if (raw is! Map<String, Object?>) return null;
      return QsoDraft(
        session: QsoSession.fromJson(raw),
        pendingText: json!['pendingText'] as String? ?? '',
        pendingId: json['pendingId'] as String?,
        active: Duration(
          milliseconds: (json['activeMs'] as num?)?.toInt() ?? 0,
        ),
      );
    } on Object {
      return null;
    }
  }

  /// Keeps text and state only (never a held key or playback), including a
  /// keyed reply that was not sent yet and its submission id.
  Future<void> saveQsoDraft(
    QsoSession session, {
    String pendingText = '',
    String? pendingId,
    Duration active = Duration.zero,
  }) => writeDoc(draftDoc, <String, Object?>{
    'session': session.toJson(),
    'pendingText': pendingText,
    'pendingId': pendingId,
    'activeMs': active.inMilliseconds,
  });

  Future<void> discardQsoDraft() => deleteDoc(draftDoc);

  /// Parked finished QSOs, one document each (`qso_finished_<seed>`).
  static const String finishedPrefix = 'qso_finished_';

  static String _finishedDoc(QsoSession s) =>
      '$finishedPrefix${s.scenario.name}_${s.seed}'.toLowerCase();

  /// Records a finished QSO. It is first parked in its own document (never
  /// overwritten by another QSO), then credited, then removed — only once
  /// the result is on disk, so a crash or a failed write never loses it.
  /// [recoverFinishedQso] commits parked QSOs again; their ids are never
  /// evicted from de-duplication, so this cannot credit twice.
  Future<bool> finishQso(QsoSession session, Duration active) async {
    final doc = _finishedDoc(session);
    try {
      await writeDoc(doc, <String, Object?>{
        'session': session.toJson(),
        'activeMs': active.inMilliseconds,
      });
      await discardQsoDraft();
    } on Object {
      // Recording below still runs; only crash recovery is weaker.
    }
    final outcome = await recordQso(session, active);
    if (!outcome.saved) return false;
    try {
      await deleteDoc(doc);
    } on Object {
      // Committing it again later is a no-op (same, protected id).
    }
    return true;
  }

  /// Commits every QSO parked by [finishQso] whose save did not complete.
  /// Runs whenever learning data loads.
  Future<void> recoverFinishedQso() async {
    List<String> names;
    try {
      names = await docNames();
    } on Object {
      return;
    }
    for (final name in names.where((n) => n.startsWith(finishedPrefix))) {
      try {
        final json = await readDoc(name);
        final raw = json?['session'];
        if (raw is! Map<String, Object?>) continue;
        final session = QsoSession.fromJson(raw);
        final active = Duration(
          milliseconds: (json!['activeMs'] as num?)?.toInt() ?? 0,
        );
        final outcome = await recordQso(session, active);
        if (outcome.saved) await deleteDoc(name);
      } on Object {
        // Tried again next time.
      }
    }
  }

  /// Credits a finished QSO once (its id is derived from the seed, so a
  /// resumed and finished session cannot be credited twice).
  Future<ReceiveOutcome> recordQso(QsoSession session, Duration active) {
    final sent = session.turns
        .where((t) => !t.fromRemote && (t.accepted ?? false))
        .map((t) => t.text)
        .join(' ');
    final score = SessionScore.evaluate(
      sent,
      sent,
      at: now(),
      drillKind: 'qso-sim',
    );
    return recordExercise(
      score: score,
      id: 'qso_${session.scenario.name}_${session.seed}',
      source: ExerciseSource.qso,
      assistance: <Assistance>{
        if (session.hints > 0) Assistance.hint,
        if (session.repeats > 0) Assistance.replay,
      },
      answered: session.learnerTurns > 0,
      completed: session.isDone,
      timing: MorseTiming(
        wpm: session.characterWpm,
        farnsworthWpm: session.effectiveWpm < session.characterWpm
            ? session.effectiveWpm
            : null,
      ),
      active: active,
    );
  }
}

/// A stored simulator draft.
final class QsoDraft {
  const QsoDraft({
    required this.session,
    this.pendingText = '',
    this.pendingId,
    this.active = Duration.zero,
  });

  final QsoSession session;

  /// A keyed reply that was not sent yet.
  final String pendingText;

  /// Its submission id, so sending it after a restore cannot double-submit.
  final String? pendingId;
  final Duration active;
}
