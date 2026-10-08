import 'dart:math';

import '../callsign_drill.dart';
import '../word_lists.dart';

/// The two initial simulator scenarios (functional spec §5.1).
enum QsoScenario {
  /// The remote station calls CQ; the learner answers.
  respondToCq,

  /// The learner calls CQ; a remote station answers.
  callCq;

  static QsoScenario parse(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => QsoScenario.respondToCq,
  );
}

/// Learner-side stages, in order. Each stage waits for one accepted
/// transmission from the learner.
enum QsoStage {
  /// Call CQ with the local callsign (call-CQ scenario only).
  callCq,

  /// `{REMOTE} DE {LOCAL} K` (respond scenario only).
  callConfirm,

  /// RST, name and QTH (call-CQ: also the callsign pair).
  exchange,

  /// Acknowledge the remote's information: `R` plus the remote's name.
  confirmInfo,

  /// `73` and `<SK>`.
  closing,

  /// Finished.
  done;

  static QsoStage parse(String? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => QsoStage.done);
}

/// One station's controlled-vocabulary details.
final class QsoStation {
  const QsoStation({
    required this.callsign,
    required this.name,
    required this.qth,
  });

  final String callsign;
  final String name;
  final String qth;

  static final RegExp _call = RegExp(r'^[A-Z0-9]{1,3}[0-9][A-Z0-9]{0,3}[A-Z]$');
  static final RegExp _word = RegExp(r'^[A-Z]{2,12}$');

  /// Whether [callsign] looks like an amateur callsign (format only; it does
  /// not claim the callsign exists).
  static bool isValidCallsign(String callsign) =>
      _call.hasMatch(callsign.trim().toUpperCase());

  /// Names and QTHs are single controlled-vocabulary words.
  static bool isValidWord(String word) =>
      _word.hasMatch(word.trim().toUpperCase());

  QsoStation normalized() => QsoStation(
    callsign: callsign.trim().toUpperCase(),
    name: name.trim().toUpperCase(),
    qth: qth.trim().toUpperCase(),
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'callsign': callsign,
    'name': name,
    'qth': qth,
  };

  factory QsoStation.fromJson(Map<String, Object?> json) => QsoStation(
    callsign: json['callsign']! as String,
    name: json['name']! as String,
    qth: json['qth']! as String,
  );

  /// A random but seed-stable station; QTHs are single words.
  factory QsoStation.random(Random random) {
    final qths = WordLists.qthNames.where((q) => !q.contains(' ')).toList();
    String call;
    do {
      call = CallsignDrill(count: 1).nextCallsign(random);
    } while (!isValidCallsign(call));
    return QsoStation(
      callsign: call,
      name: WordLists
          .operatorNames[random.nextInt(WordLists.operatorNames.length)],
      qth: qths[random.nextInt(qths.length)],
    );
  }
}

/// The remote station's scripted transmissions. Templates are complete
/// text snapshots; the session fills them once per seed so every repeat is
/// identical.
abstract final class QsoScript {
  static const int version = 1;

  /// Signal reports the remote may give.
  static const List<String> remoteReports = <String>[
    '599',
    '579',
    '589',
    '559',
    '5NN',
  ];

  static List<QsoStage> stagesFor(QsoScenario scenario) => switch (scenario) {
    QsoScenario.respondToCq => const <QsoStage>[
      QsoStage.callConfirm,
      QsoStage.exchange,
      QsoStage.confirmInfo,
      QsoStage.closing,
    ],
    QsoScenario.callCq => const <QsoStage>[
      QsoStage.callCq,
      QsoStage.exchange,
      QsoStage.confirmInfo,
      QsoStage.closing,
    ],
  };

  /// What the remote sends before the learner's [stage] (null: the learner
  /// opens, as when calling CQ).
  static String? remoteBefore(
    QsoScenario scenario,
    QsoStage stage, {
    required QsoStation local,
    required QsoStation remote,
    required String report,
  }) {
    final l = local.callsign;
    final r = remote.callsign;
    switch ((scenario, stage)) {
      case (QsoScenario.respondToCq, QsoStage.callConfirm):
        return 'CQ CQ CQ DE $r $r K';
      case (QsoScenario.respondToCq, QsoStage.exchange):
        return '$l DE $r GM TNX FER CALL UR RST $report $report '
            'NAME ${remote.name} ${remote.name} QTH ${remote.qth} '
            '${remote.qth} HW? $l DE $r K';
      case (QsoScenario.callCq, QsoStage.callCq):
        return null;
      case (QsoScenario.callCq, QsoStage.exchange):
        return '$l DE $r $r K';
      case (_, QsoStage.confirmInfo):
        final intro = scenario == QsoScenario.callCq
            ? 'R R TNX ${local.name} UR RST $report $report NAME '
                  '${remote.name} ${remote.name} QTH ${remote.qth} '
                  '${remote.qth}'
            : 'R R FB ${local.name} TNX FER RPRT';
        return '$l DE $r $intro QSL? $l DE $r K';
      case (_, QsoStage.closing):
        return 'R TU ${local.name} TNX QSO 73 $l DE $r <SK>';
      case (_, QsoStage.done):
        return 'TU 73 EE';
      default:
        return null;
    }
  }
}
