import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'receive_session.dart';
import 'training_controller.dart';

/// Copying one received chat message (functional spec §6.2). The message
/// text is frozen when practice starts; unsupported characters are listed
/// and left out only after the learner confirmed the trainable text.
/// Replays after the first listen, symbol hints and a full reveal are
/// tracked: once assisted, the attempt stays assisted.
final class ChatCopySession {
  ChatCopySession({
    required String text,
    required this.conversationId,
    required this.messageId,
    required this.profileKey,
    required this.timing,
    required this.toneHz,
    String? id,
  }) : analysis = MaterialImport.analyze(text, MaterialKind.text),
       id = id ?? ExerciseIds.next(DateTime.now(), Random()) {
    target = analysis.items.join(' ');
  }

  final String id;
  final String conversationId;
  final String messageId;
  final String profileKey;
  final MorseTiming timing;
  final double toneHz;
  final MaterialAnalysis analysis;
  late final String target;

  final Set<Assistance> _assistance = <Assistance>{};
  bool _played = false;
  int _hinted = 0;
  bool _revealed = false;
  SessionScore? _score;

  /// Local origin reference (never sent anywhere).
  String get sourceRef => 'chat:$profileKey/$conversationId/$messageId';

  bool get canPractise => target.isNotEmpty;
  Set<Assistance> get assistance => Set<Assistance>.unmodifiable(_assistance);
  bool get isRevealed => _revealed;
  SessionScore? get score => _score;

  List<String> get _symbols => MorseText.symbols(target);

  /// Keys for every supported symbol in the message, course order first.
  List<String> keypadChars(List<String> courseOrder) {
    final used = _symbols.toSet();
    return <String>[
      ...courseOrder.where(used.contains),
      ...(used.difference(courseOrder.toSet()).toList()..sort()),
    ];
  }

  List<MorseElement> get timeline => MorseEncoder.encode(target, timing);

  /// Call on every playback: the second and later count as a replay.
  void markPlayed() {
    if (_score != null) return;
    if (_played) _assistance.add(Assistance.replay);
    _played = true;
  }

  /// The symbols shown so far by hints.
  List<String> get hintedSymbols => _symbols.take(_hinted).toList();

  /// Reveals the next symbol; returns false when nothing is left.
  bool hint() {
    if (_score != null || _hinted >= _symbols.length) return false;
    _hinted++;
    _assistance.add(Assistance.hint);
    return true;
  }

  void revealAll() {
    if (_score != null) return;
    _revealed = true;
    _assistance.add(Assistance.reveal);
  }

  /// Scores the copy once; later calls return the first score.
  SessionScore submit(String answer, DateTime now) => _score ??=
      SessionScore.evaluate(target, answer, at: now, drillKind: 'chat');
}

/// Practice of a session's errors on learned symbols only.
extension FocusedPractice on TrainingController {
  /// A focused drill on [symbols] restricted to the learned set (topped up
  /// to two symbols), or null when none of them is learned.
  ReceiveSession? startFocusSession(Iterable<String> symbols) {
    final learned = learnedChars;
    final pool = symbols.where(learned.contains).toSet().toList();
    if (pool.isEmpty) return null;
    for (final c in learned.reversed) {
      if (pool.length >= 2) break;
      if (!pool.contains(c)) pool.add(c);
    }
    final t = trainerSettings;
    return ReceiveSession(
      generator: RandomGroupsDrill(
        chars: pool,
        groupCount: 1,
        groupSize: t.groupSize,
      ),
      chars: pool,
      timing: t.toTiming(),
      charBudget: t.sessionLengthChars,
      lesson: currentLesson,
      source: ExerciseSource.focus,
      random: random,
      now: now,
    );
  }
}
