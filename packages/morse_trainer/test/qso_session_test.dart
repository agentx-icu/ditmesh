import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  const local = QsoStation(callsign: 'BD1XYZ', name: 'LI', qth: 'BEIJING');
  const remote = QsoStation(callsign: 'K1ABC', name: 'BOB', qth: 'BOSTON');

  QsoEvaluation eval(
    String text,
    QsoStage stage, {
    QsoScenario scenario = QsoScenario.respondToCq,
  }) => QsoEvaluator.evaluate(
    text,
    stage: stage,
    scenario: scenario,
    local: local,
    remote: remote,
  );

  group('allowed variants per stage', () {
    final table = <QsoStage, (List<String>, List<(String, QsoIssue)>)>{
      QsoStage.callConfirm: (
        ['K1ABC DE BD1XYZ K', 'K1ABC DE BD1XYZ BD1XYZ KN', 'k1abc de bd1xyz ('],
        [
          ('K1ABD DE BD1XYZ K', QsoIssue.wrongRemoteCall),
          ('K1ABC DE BD1XYA K', QsoIssue.wrongLocalCall),
          ('BD1XYZ DE K1ABC K', QsoIssue.reversedCalls),
          ('K1ABC BD1XYZ K', QsoIssue.missingDe),
          ('K1ABC DE BD1XYZ', QsoIssue.missingEnding),
          // Substring-only matches do not pass.
          ('XK1ABC DE BD1XYZ K', QsoIssue.wrongRemoteCall),
        ],
      ),
      QsoStage.exchange: (
        [
          'UR RST 599 NAME LI QTH BEIJING K',
          'R R TNX BOB UR RST 5NN 5NN NAME IS LI LI QTH IS BEIJING HW? K',
          'RST 579 QTH BEIJING NAME LI',
        ],
        [
          ('UR RST 699 NAME LI QTH BEIJING K', QsoIssue.invalidRst),
          ('UR 599 NAME LI QTH BEIJING K', QsoIssue.missingRst),
          ('UR RST 599 NAME BOB QTH BEIJING K', QsoIssue.wrongName),
          ('UR RST 599 NAME LI QTH BOSTON K', QsoIssue.wrongQth),
          ('UR RST 599 QTH BEIJING K', QsoIssue.missingName),
          ('UR RST 599 NAME LI K', QsoIssue.missingQth),
        ],
      ),
      QsoStage.confirmInfo: (
        ['R R TNX BOB', 'QSL BOB 73', 'R FB BOB QTH BOSTON'],
        [
          ('TNX BOB', QsoIssue.missingAck),
          ('R R TNX BOX', QsoIssue.wrongRemoteName),
        ],
      ),
      QsoStage.closing: (
        ['73 <SK>', 'TU 73 CUL K1ABC DE BD1XYZ <SK>'],
        [('73 K', QsoIssue.missingSk), ('TU <SK>', QsoIssue.missing73)],
      ),
    };
    for (final entry in table.entries) {
      test(entry.key.name, () {
        for (final ok in entry.value.$1) {
          expect(eval(ok, entry.key).accepted, isTrue, reason: ok);
        }
        for (final (bad, issue) in entry.value.$2) {
          final e = eval(bad, entry.key);
          expect(e.accepted, isFalse, reason: bad);
          expect(e.issues, contains(issue), reason: bad);
        }
      });
    }

    test('call CQ needs CQ, DE, the local call and K', () {
      expect(
        eval('CQ CQ DE BD1XYZ BD1XYZ K', QsoStage.callCq).accepted,
        isTrue,
      );
      expect(
        eval('CQ DE BD1XYZ', QsoStage.callCq).issues,
        contains(QsoIssue.missingEnding),
      );
      expect(
        eval('CQ DE K1ABC K', QsoStage.callCq).issues,
        contains(QsoIssue.wrongLocalCall),
      );
      expect(
        eval('DE BD1XYZ K', QsoStage.callCq).issues,
        contains(QsoIssue.missingCq),
      );
    });

    test('call-CQ exchange also checks the callsign pair', () {
      expect(
        eval(
          'K1ABC DE BD1XYZ UR RST 599 NAME LI QTH BEIJING K',
          QsoStage.exchange,
          scenario: QsoScenario.callCq,
        ).accepted,
        isTrue,
      );
      expect(
        eval(
          'UR RST 599 NAME LI QTH BEIJING K',
          QsoStage.exchange,
          scenario: QsoScenario.callCq,
        ).issues,
        contains(QsoIssue.missingDe),
      );
    });

    test('repeat and slow-down intents come first', () {
      expect(eval('PSE AGN', QsoStage.exchange).intent, QsoIntent.repeat);
      expect(eval('AGN?', QsoStage.exchange).intent, QsoIntent.repeat);
      expect(eval('QRS', QsoStage.exchange).intent, QsoIntent.slowDown);
      expect(eval('PSE QRS', QsoStage.exchange).intent, QsoIntent.slowDown);
      expect(eval('AGN 73 <SK>', QsoStage.closing).intent, QsoIntent.answer);
    });

    test('keyed prosigns need no word gap; CQ courtesy words pass', () {
      expect(eval('TU 73<SK>', QsoStage.closing).accepted, isTrue);
      expect(
        eval('CQ CQ DE BD1XYZ BD1XYZ PSE K', QsoStage.callCq).accepted,
        isTrue,
      );
      expect(
        eval('CQ DE BD1XYZ K1ABC K', QsoStage.callCq).issues,
        contains(QsoIssue.wrongLocalCall),
      );
      // A malformed call next to the right one is still wrong.
      expect(
        eval('CQ DE BDIXYZ BD1XYZ K', QsoStage.callCq).issues,
        contains(QsoIssue.wrongLocalCall),
      );
    });

    test('cut numbers only inside the RST slot', () {
      expect(QsoEvaluator.isValidRst('5NN'), isTrue);
      expect(QsoEvaluator.isValidRst('59T'), isFalse);
      expect(QsoEvaluator.isValidRst('ANN'), isTrue);
      expect(QsoEvaluator.isValidRst('NAME'), isFalse);
    });
  });

  group('QsoSession', () {
    QsoSession start(QsoScenario scenario, {int seed = 3}) => QsoSession.start(
      scenario: scenario,
      seed: seed,
      local: local,
      characterWpm: 20,
      effectiveWpm: 12,
    );

    test('the same seed gives the same remote station and texts', () {
      final a = start(QsoScenario.respondToCq);
      final b = start(QsoScenario.respondToCq);
      expect(a.remote.callsign, b.remote.callsign);
      expect(a.lastRemoteText, b.lastRemoteText);
      expect(a.remote.callsign, isNot(local.callsign));
    });

    void complete(QsoSession s) {
      var n = 0;
      String answer() => switch (s.stage) {
        QsoStage.callCq => 'CQ CQ DE BD1XYZ K',
        QsoStage.callConfirm => '${s.remote.callsign} DE BD1XYZ K',
        QsoStage.exchange =>
          '${s.remote.callsign} DE BD1XYZ UR RST 599 NAME LI QTH BEIJING K',
        QsoStage.confirmInfo => 'R R TNX ${s.remote.name}',
        QsoStage.closing => 'TU 73 <SK>',
        QsoStage.done => '',
      };
      while (!s.isDone) {
        final reply = s.submit('s${n++}', answer());
        expect(reply.evaluation.accepted, isTrue, reason: '${s.stage}');
      }
    }

    test('respond to CQ completes', () {
      final s = start(QsoScenario.respondToCq);
      expect(s.lastRemoteText, startsWith('CQ CQ CQ DE ${s.remote.callsign}'));
      complete(s);
      expect(s.firstTryStages, s.answerStages);
      expect(s.lastRemoteText, 'TU 73 EE');
    });

    test('call CQ completes and the learner opens', () {
      final s = start(QsoScenario.callCq);
      expect(s.lastRemoteText, isNull);
      complete(s);
      expect(s.isDone, isTrue);
    });

    test('AGN repeats without advancing; QRS slows within limits', () {
      final s = start(QsoScenario.respondToCq);
      final cq = s.lastRemoteText;
      final agn = s.submit('a', 'PSE AGN');
      expect(agn.remoteText, cq);
      expect(agn.advanced, isFalse);
      expect(s.repeats, 1);
      for (var i = 0; i < 10; i++) {
        s.submit('q$i', 'QRS');
      }
      expect(s.effectiveWpm, 5);
      expect(s.stage, QsoStage.callConfirm);
    });

    test('a duplicate submission produces one remote reply', () {
      final s = start(QsoScenario.respondToCq);
      final text = '${s.remote.callsign} DE BD1XYZ K';
      final first = s.submit('same', text);
      final second = s.submit('same', text);
      expect(first.advanced, isTrue);
      expect(second.duplicate, isTrue);
      expect(s.turns.where((t) => t.fromRemote), hasLength(2));
    });

    test('errors keep the stage; hints get specific after three', () {
      final s = start(QsoScenario.respondToCq);
      expect(s.hint().level, 1);
      for (var i = 0; i < 3; i++) {
        final r = s.submit('e$i', 'K1ZZZ DE BD1XYZ K');
        expect(r.advanced, isFalse);
      }
      final h = s.hint();
      expect(h.level, 2);
      expect(h.example, contains(s.remote.callsign));
      expect(s.hints, 2);
      expect(s.stage, QsoStage.callConfirm);
    });

    test('restores text and state from JSON', () {
      final s = start(QsoScenario.respondToCq);
      s.submit('1', '${s.remote.callsign} DE BD1XYZ K');
      final back = QsoSession.fromJson(s.toJson());
      expect(back.stage, QsoStage.exchange);
      expect(back.lastRemoteText, s.lastRemoteText);
      expect(back.submit('1', 'x').duplicate, isTrue);
    });
  });
}
