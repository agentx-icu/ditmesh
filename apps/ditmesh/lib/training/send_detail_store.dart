import 'dart:convert';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'send_session.dart';
import 'training_controller.dart';

/// Saved key timing of one send attempt (functional spec §7.3): target,
/// target speed, relative mark/gap durations, alignment result and the
/// diagnostic version. Never a microphone recording.
final class SendDetail {
  const SendDetail({
    required this.ref,
    required this.target,
    required this.timing,
    required this.marks,
    required this.gaps,
    required this.estimatedDit,
    required this.at,
    this.aligned = false,
    this.diagnosticVersion = SendTimeline.diagnosticVersion,
  });

  final String ref;
  final String target;
  final MorseTiming timing;
  final List<Duration> marks;
  final List<Duration> gaps;
  final Duration estimatedDit;
  final DateTime at;
  final bool aligned;
  final int diagnosticVersion;

  SendTimeline timeline() => SendTimeline.build(
    target: target,
    marks: marks,
    gaps: gaps,
    timing: timing,
    estimatedDit: estimatedDit,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'v': 1,
    'ref': ref,
    'target': target,
    'wpm': timing.wpm,
    'farnsworthWpm': timing.farnsworthWpm,
    'marksUs': [for (final m in marks) m.inMicroseconds],
    'gapsUs': [for (final g in gaps) g.inMicroseconds],
    'ditUs': estimatedDit.inMicroseconds,
    'at': at.toIso8601String(),
    'aligned': aligned,
    'diagnosticVersion': diagnosticVersion,
  };

  factory SendDetail.fromJson(Map<String, Object?> json) => SendDetail(
    ref: json['ref']! as String,
    target: json['target']! as String,
    timing: MorseTiming(
      wpm: (json['wpm']! as num).toDouble(),
      farnsworthWpm: (json['farnsworthWpm'] as num?)?.toDouble(),
    ),
    marks: [
      for (final m in json['marksUs']! as List<Object?>)
        Duration(microseconds: (m! as num).toInt()),
    ],
    gaps: [
      for (final g in json['gapsUs']! as List<Object?>)
        Duration(microseconds: (g! as num).toInt()),
    ],
    estimatedDit: Duration(microseconds: (json['ditUs']! as num).toInt()),
    at: DateTime.parse(json['at']! as String),
    aligned: json['aligned'] as bool? ?? false,
    diagnosticVersion: (json['diagnosticVersion'] as num?)?.toInt() ?? 1,
  );
}

/// Rhythm details as training documents plus a size index, trimmed to a
/// cache budget. Trimming only deletes detail documents: summaries in the
/// progress file and favourites the learner kept are never removed.
extension SendDetailStore on TrainingController {
  static const String indexDoc = 'send_index';
  static const int defaultBudgetBytes = 20 * 1024 * 1024;

  /// Writes the detail of a finished [session] and returns its reference.
  /// Call before recording the session so the summary never points at a
  /// detail that was not written.
  Future<String> saveSendDetail(
    SendSession session,
    SendDiagnostics result, {
    int budgetBytes = defaultBudgetBytes,
  }) async {
    final ref = 'send_${session.id.replaceAll(RegExp('[^a-z0-9_]'), '_')}';
    final detail = SendDetail(
      ref: ref,
      target: session.target,
      timing: session.nominalTiming,
      marks: session.marks,
      gaps: session.gaps,
      estimatedDit: result.attempt.estimatedDit,
      at: now(),
      aligned: SendTimeline.build(
        target: session.target,
        marks: session.marks,
        gaps: session.gaps,
        timing: session.nominalTiming,
        estimatedDit: result.attempt.estimatedDit,
      ).aligned,
    );
    final json = detail.toJson();
    await docTransaction(() async {
      await writeDoc(ref, json);
      final index = await _index();
      // Saving the same attempt again keeps whether it was kept.
      final kept = index.any((e) => e['ref'] == ref && e['favorite'] == true);
      index.removeWhere((e) => e['ref'] == ref);
      index.add(<String, Object?>{
        'ref': ref,
        'bytes': utf8.encode(jsonEncode(json)).length,
        'at': detail.at.toIso8601String(),
        'favorite': kept,
      });
      await _trim(index, budgetBytes);
    });
    return ref;
  }

  Future<SendDetail?> loadSendDetail(String ref) async {
    try {
      final json = await readDoc(ref);
      return json == null ? null : SendDetail.fromJson(json);
    } on Object {
      // A missing or damaged detail never blocks the rest of the progress.
      return null;
    }
  }

  /// Marks a detail as kept: excluded from cache trimming.
  Future<void> setSendDetailFavorite(String ref, bool favorite) =>
      docTransaction(() async {
        final index = await _index();
        for (final e in index) {
          if (e['ref'] == ref) e['favorite'] = favorite;
        }
        await writeDoc(indexDoc, <String, Object?>{'entries': index});
      });

  Future<bool> isSendDetailFavorite(String ref) async =>
      (await _index()).any((e) => e['ref'] == ref && e['favorite'] == true);

  Future<List<Map<String, Object?>>> _index() async {
    final json = await readDoc(indexDoc);
    final entries = json?['entries'];
    if (entries is! List) return <Map<String, Object?>>[];
    return [
      for (final e in entries)
        if (e is Map<String, Object?>) Map<String, Object?>.of(e),
    ];
  }

  Future<void> _trim(List<Map<String, Object?>> index, int budget) async {
    int total() =>
        index.fold<int>(0, (n, e) => n + ((e['bytes'] as num?)?.toInt() ?? 0));
    index.sort((a, b) => (a['at']! as String).compareTo(b['at']! as String));
    final victims = <String>[];
    while (total() > budget) {
      final at = index.indexWhere((e) => e['favorite'] != true);
      if (at < 0) break;
      victims.add(index.removeAt(at)['ref']! as String);
    }
    await writeDoc(indexDoc, <String, Object?>{'entries': index});
    for (final ref in victims) {
      await deleteDoc(ref);
    }
  }
}
