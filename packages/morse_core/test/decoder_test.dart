import 'dart:async';

import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

import 'helpers/feed.dart';

const String kSentence = 'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG 0123456789';

/// 200+ character mixed corpus (letters, digits, punctuation, spaces).
final String kCorpus = <String>[
  'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG',
  'CQ CQ CQ DE W1AW W1AW K',
  'PARIS 0123456789 PARIS',
  'R U OK? YES = 73 + 88, TNX!',
  'RST 599 QTH LONDON NAME BOB',
  'VVV SOS TEST 1234 END.',
  'HELLO WORLD, THIS IS A LONGER LINE OF TEXT.',
].join(' ');

/// Decode [kCorpus] keyed at [wpm] with [jitter], seeded with the lesson dit
/// (as a trainer does), scoring one code unit per committed symbol.
double corpusAccuracy(JitterFn jitter, {double wpm = 20}) {
  final MorseTiming timing = MorseTiming(wpm: wpm);
  final MorseDecoder d =
      MorseDecoder(config: DecoderConfig(initialDit: timing.dit));
  final List<DecodeEvent> events = <DecodeEvent>[];
  final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
  try {
    feedTimeline(d, MorseEncoder.encode(kCorpus, timing), jitter: jitter);
    d.flush();
    return accuracy(kCorpus, renderEvents(events));
  } finally {
    unawaited(sub.cancel());
    d.dispose();
  }
}

void main() {
  test('corpus is at least 200 characters', () {
    expect(kCorpus.length, greaterThanOrEqualTo(200));
  });

  group('MorseDecoder perfect timing', () {
    for (final double wpm in <double>[12, 20]) {
      test('decodes the sentence exactly at $wpm WPM', () {
        final List<MorseElement> timeline =
            MorseEncoder.encode(kSentence, MorseTiming(wpm: wpm));
        expect(decodeTimeline(timeline), kSentence);
      });
    }

    test('decodes the full corpus exactly at 15 WPM', () {
      final List<MorseElement> timeline =
          MorseEncoder.encode(kCorpus, const MorseTiming(wpm: 15));
      expect(decodeTimeline(timeline), kCorpus);
    });

    test('estimatedDit converges to the keyed dit', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', const MorseTiming(wpm: 20)));
      expect(d.estimatedDit.inMicroseconds, closeTo(60000, 500));
    });

    test('perfect timing yields confidence 1.0 on every event', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      final List<DecodeEvent> events = <DecodeEvent>[];
      final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
      addTearDown(sub.cancel);
      feedTimeline(d, MorseEncoder.encode('SOS SOS', const MorseTiming(wpm: 20)));
      d.flush();
      expect(events, isNotEmpty);
      for (final DecodeEvent e in events) {
        expect(e.confidence, 1.0, reason: '$e');
      }
    });

    test('confidence drops toward 0.5 for marks near the dit/dah threshold', () {
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(
              adaptive: false, initialDit: Duration(milliseconds: 100)));
      addTearDown(d.dispose);
      final List<DecodeEvent> events = <DecodeEvent>[];
      final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
      addTearDown(sub.cancel);
      // Threshold is 200 ms; a 190 ms mark is 5 % away -> confidence 0.55.
      d.keyDown(Duration.zero);
      d.keyUp(const Duration(milliseconds: 190));
      expect(events.single.kind, DecodeEventKind.element);
      expect(events.single.pattern, '.');
      expect(events.single.confidence, closeTo(0.55, 1e-9));
    });
  });

  group('MorseDecoder jitter tolerance (seeded RNG)', () {
    // Bounds below were set from a 20-seed sweep of each model; see README
    // "Jitter tolerance" for the measured minima.
    test('uniform ±20 % jitter -> >= 99 % character accuracy', () {
      for (int seed = 1; seed <= 5; seed++) {
        expect(corpusAccuracy(uniformJitter(0.20, seed: seed)),
            greaterThanOrEqualTo(0.99),
            reason: 'seed $seed');
      }
    });

    test('uniform ±20 % with the default 80 ms seed at 20 WPM stays >= 98 %',
        () {
      // Cold start: the very first mark is judged against the default seed,
      // so a dah jittered short can cost the first character.
      final List<MorseElement> timeline =
          MorseEncoder.encode(kCorpus, const MorseTiming(wpm: 20));
      for (int seed = 1; seed <= 5; seed++) {
        final String decoded =
            decodeTimeline(timeline, jitter: uniformJitter(0.20, seed: seed));
        expect(accuracy(kCorpus, decoded), greaterThanOrEqualTo(0.98),
            reason: 'seed $seed: $decoded');
      }
    });

    test('triangular ±35 % jitter -> >= 95 % character accuracy', () {
      for (int seed = 1; seed <= 5; seed++) {
        expect(corpusAccuracy(triangularJitter(0.35, seed: seed)),
            greaterThanOrEqualTo(0.95),
            reason: 'seed $seed');
      }
    });

    test('triangular ±30 % jitter across seeds and speeds stays >= 97 %', () {
      for (final double wpm in <double>[12, 20, 25]) {
        for (int seed = 1; seed <= 5; seed++) {
          expect(corpusAccuracy(triangularJitter(0.30, seed: seed), wpm: wpm),
              greaterThanOrEqualTo(0.97),
              reason: 'wpm $wpm seed $seed');
        }
      }
    });

    test('uniform ±35 % is past the midpoint-threshold design limit', () {
      // With uniform jitter a 3-unit dah or char gap sits at 1.95 dit as
      // often as anywhere else, below the 2.0-dit midpoint, so ~8 % of
      // symbols are lost by construction. The estimator must still stay
      // locked (no collapse): document the floor rather than the target.
      for (int seed = 1; seed <= 5; seed++) {
        expect(corpusAccuracy(uniformJitter(0.35, seed: seed)),
            greaterThanOrEqualTo(0.80),
            reason: 'seed $seed');
      }
    });

    test('estimatedDit stays within 25 % of the truth under ±35 % jitter', () {
      // The estimate is the arithmetic mean of the short cluster (~15 dits in
      // a 32-mark window); under uniform ±35 % that sample mean itself moves
      // by up to ~20 %. What this pins down is that no dah is ever absorbed
      // into the dit cluster (which would show up as a jump past 2x).
      const MorseTiming t = MorseTiming(wpm: 20);
      final MorseDecoder d = MorseDecoder(config: DecoderConfig(initialDit: t.dit));
      addTearDown(d.dispose);
      final List<MorseElement> timeline = MorseEncoder.encode(kCorpus, t);
      final JitterFn jitter = uniformJitter(0.35, seed: 3);
      // Feed one element at a time so we can watch the estimate.
      for (int i = 0; i < timeline.length; i++) {
        feedTimeline(d, <MorseElement>[timeline[i]],
            jitter: jitter,
            start: Duration(seconds: 10 * (i + 1)));
        if (i > 40) {
          expect(d.estimatedDit.inMicroseconds,
              closeTo(t.dit.inMicroseconds, t.dit.inMicroseconds * 0.25),
              reason: 'element $i');
        }
      }
    });
  });

  group('MorseDecoder cluster estimator', () {
    test('dah-heavy text "OTTO 000 MOM" decodes correctly (all dahs)', () {
      const MorseTiming t = MorseTiming(wpm: 20);
      final List<MorseElement> timeline = MorseEncoder.encode('OTTO 000 MOM', t);
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, timeline);
      expect(d.flush(), 'OTTO 000 MOM');
      // The estimator must not have locked onto the dah length.
      expect(d.estimatedDit.inMicroseconds, closeTo(t.dit.inMicroseconds, 1000));
    });

    test('dah-heavy then mixed text keeps decoding', () {
      const MorseTiming t = MorseTiming(wpm: 12);
      const String text = 'OTTO 000 MOM SOS PARIS';
      expect(decodeTimeline(MorseEncoder.encode(text, t)), text);
    });

    test('dit-only text decodes at a speed near the seed', () {
      const String text = 'EEE SSS HHH ISH';
      expect(
          decodeTimeline(MorseEncoder.encode(text, const MorseTiming(wpm: 15))),
          text);
    });

    test('adaptive=false keeps estimatedDit constant', () {
      const Duration seed = Duration(milliseconds: 60);
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(adaptive: false, initialDit: seed));
      addTearDown(d.dispose);
      expect(d.estimatedDit, seed);
      // Key at a different speed; the estimate must not follow.
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', const MorseTiming(wpm: 12)));
      expect(d.estimatedDit, seed);
      // At the matching speed it still decodes.
      d.reset();
      expect(d.estimatedDit, seed);
      feedTimeline(d, MorseEncoder.encode('CQ DE', const MorseTiming(wpm: 20)));
      expect(d.flush(), 'CQ DE');
      expect(d.estimatedDit, seed);
    });
  });

  group('MorseDecoder Farnsworth adaptation', () {
    const MorseTiming fw = MorseTiming(wpm: 18, farnsworthWpm: 8);

    test('adapted thresholds sit between the observed gap clusters', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', fw));
      expect(d.isFarnsworthAdapted, isTrue);
      expect(d.charGapThreshold, greaterThan(fw.intraGap));
      expect(d.charGapThreshold, lessThan(fw.charGap));
      expect(d.wordGapThreshold, greaterThan(fw.charGap));
      expect(d.wordGapThreshold, lessThan(fw.wordGap));
    });

    test('decodes correctly once the gap distribution has been observed', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      // One warm-up word pair teaches the decoder the stretched spacing
      // (before the first real word gap arrives, a 12.9-dit char gap is
      // indistinguishable from a slow word gap).
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', fw));
      d.flush();
      d.clearText();
      feedTimeline(d, MorseEncoder.encode(kSentence, fw));
      expect(d.flush(), kSentence);
    });

    test('cold start: everything after the first word gap is exact', () {
      final String decoded = decodeTimeline(MorseEncoder.encode(kSentence, fw));
      final String tail = kSentence.substring(kSentence.indexOf(' '));
      expect(decoded, endsWith(tail));
      // First word is keyed as single letters split by "word" gaps at worst.
      expect(decoded.replaceAll(' ', ''), kSentence.replaceAll(' ', ''));
    });

    test('standard spacing is not mistaken for Farnsworth', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, MorseEncoder.encode(kSentence, const MorseTiming(wpm: 20)));
      expect(d.isFarnsworthAdapted, isFalse);
      expect(d.flush(), kSentence);
    });

    test('moderate Farnsworth (20/15) decodes after warm-up', () {
      const MorseTiming t = MorseTiming(wpm: 20, farnsworthWpm: 15);
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', t));
      d.clearText();
      feedTimeline(d, MorseEncoder.encode(kSentence, t));
      expect(d.flush(), kSentence);
    });
  });

  group('MorseDecoder events and state', () {
    test('events stream emits element, character and word events in order',
        () {
      final MorseDecoder d = MorseDecoder();
      final List<DecodeEvent> events = <DecodeEvent>[];
      final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
      addTearDown(sub.cancel);
      addTearDown(d.dispose);

      feedTimeline(d, MorseEncoder.encode('AB CD', const MorseTiming(wpm: 20)));
      d.flush();

      final List<String> summary = events.map((DecodeEvent e) {
        switch (e.kind) {
          case DecodeEventKind.element:
            return e.pattern!;
          case DecodeEventKind.character:
            return 'C:${e.text}';
          case DecodeEventKind.word:
            return 'W';
          case DecodeEventKind.unknownPattern:
            return 'U:${e.pattern}';
        }
      }).toList();

      expect(summary, <String>[
        '.', '-', 'C:A', //
        '-', '.', '.', '.', 'C:B', //
        'W', //
        '-', '.', '-', '.', 'C:C', //
        '-', '.', '.', 'C:D', //
      ]);
      final DecodeEvent charA = events[2];
      expect(charA.pattern, '.-');
      expect(charA.text, 'A');
      expect(events[8].text, ' ');
      expect(renderEvents(events), 'AB CD');
      expect(d.text, 'AB CD');
    });

    test('word event comes from tick() during a long silence', () {
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(initialDit: Duration(milliseconds: 60)));
      addTearDown(d.dispose);
      final List<DecodeEvent> events = <DecodeEvent>[];
      final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
      addTearDown(sub.cancel);

      // E: one dit ending at 60 ms.
      d.keyDown(Duration.zero);
      d.keyUp(const Duration(milliseconds: 60));
      expect(d.pendingPattern, '.');
      expect(d.text, '');
      d.tick(const Duration(milliseconds: 100)); // 40 ms gap: nothing yet
      expect(d.text, '');
      d.tick(const Duration(milliseconds: 200)); // 140 ms >= 2 dit: char
      expect(d.text, 'E');
      expect(d.pendingPattern, '');
      d.tick(const Duration(milliseconds: 300)); // 240 ms < 5 dit: no word yet
      expect(d.text, 'E');
      d.tick(const Duration(milliseconds: 400)); // 340 ms >= 5 dit: word
      expect(d.text, 'E ');
      d.tick(const Duration(seconds: 5)); // no duplicate spaces
      expect(d.text, 'E ');
      expect(events.map((DecodeEvent e) => e.kind), <DecodeEventKind>[
        DecodeEventKind.element,
        DecodeEventKind.character,
        DecodeEventKind.word,
      ]);
    });

    test('flush commits the trailing character', () {
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(initialDit: Duration(milliseconds: 60)));
      addTearDown(d.dispose);
      // Key "A" (.-) with no trailing gap resolution.
      d.keyDown(Duration.zero);
      d.keyUp(const Duration(milliseconds: 60));
      d.keyDown(const Duration(milliseconds: 120));
      d.keyUp(const Duration(milliseconds: 300));
      expect(d.text, '');
      expect(d.pendingPattern, '.-');
      expect(d.flush(), 'A');
      expect(d.text, 'A');
      expect(d.pendingPattern, '');
      // Flushing again is a no-op.
      expect(d.flush(), 'A');
    });

    test('unknown pattern is reported and rendered as <pattern>', () {
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(initialDit: Duration(milliseconds: 60)));
      addTearDown(d.dispose);
      final List<DecodeEvent> events = <DecodeEvent>[];
      final StreamSubscription<DecodeEvent> sub = d.events.listen(events.add);
      addTearDown(sub.cancel);
      // "..--.." is '?', "..--." is nothing.
      Duration t = Duration.zero;
      for (final String s in '..--.'.split('')) {
        d.keyDown(t);
        t += Duration(milliseconds: s == '.' ? 60 : 180);
        d.keyUp(t);
        t += const Duration(milliseconds: 60);
      }
      d.flush();
      final DecodeEvent last = events.last;
      expect(last.kind, DecodeEventKind.unknownPattern);
      expect(last.pattern, '..--.');
      expect(last.text, '<..--.>');
      expect(d.text, '<..--.>');
    });

    test('prosign patterns decode to their bracketed name', () {
      final String decoded = decodeTimeline(
          MorseEncoder.encode('CQ <SK>', const MorseTiming(wpm: 20)));
      expect(decoded, 'CQ <SK>');
    });

    test('reset clears text, pending, and learned timing', () {
      final MorseDecoder d = MorseDecoder();
      addTearDown(d.dispose);
      feedTimeline(d, MorseEncoder.encode('PARIS PARIS', const MorseTiming(wpm: 5)));
      expect(d.text, isNotEmpty);
      expect(d.estimatedDit, isNot(d.config.initialDit));
      d.reset();
      expect(d.text, '');
      expect(d.pendingPattern, '');
      expect(d.estimatedDit, d.config.initialDit);
      expect(d.isFarnsworthAdapted, isFalse);
    });

    test('duplicate keyDown / keyUp calls are ignored', () {
      final MorseDecoder d = MorseDecoder(
          config: const DecoderConfig(initialDit: Duration(milliseconds: 60)));
      addTearDown(d.dispose);
      d.keyUp(Duration.zero); // not down: ignored
      d.keyDown(Duration.zero);
      d.keyDown(const Duration(milliseconds: 30)); // already down: ignored
      d.keyUp(const Duration(milliseconds: 60));
      d.keyUp(const Duration(milliseconds: 70)); // already up: ignored
      expect(d.pendingPattern, '.');
    });

    test('dispose closes the events stream', () async {
      final MorseDecoder d = MorseDecoder();
      final Future<List<DecodeEvent>> all = d.events.toList();
      d.dispose();
      expect(await all, isEmpty);
    });
  });
}
