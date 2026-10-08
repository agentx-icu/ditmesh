import 'dart:typed_data';

import 'package:morse_core/morse_core.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:morse_dsp/testing.dart';
import 'package:test/test.dart';

const String _sentence = 'SOS THE QUICK BROWN FOX';

/// Feeds [pcm] in [chunk]-frame pieces and returns the trimmed text.
String _decode(
  AudioMorseDecoder decoder,
  Int16List pcm, {
  int channels = 1,
  int chunk = 960,
}) {
  final int step = chunk * channels;
  for (int i = 0; i < pcm.length; i += step) {
    final int end = i + step < pcm.length ? i + step : pcm.length;
    decoder.feed(pcm.sublist(i, end), channels: channels);
  }
  return decoder.text.trim();
}

void main() {
  group('AudioMorseDecoder round trip', () {
    for (final double wpm in <double>[15, 25]) {
      for (final double hz in <double>[600, 800]) {
        for (final double snr in <double>[20, 6]) {
          test('$_sentence @ $wpm WPM, $hz Hz, SNR $snr dB', () {
            final Int16List pcm = SyntheticMorse(toneHz: hz, snrDb: snr)
                .renderText(_sentence, wpm: wpm);
            final AudioMorseDecoder decoder = AudioMorseDecoder();
            addTearDown(decoder.dispose);
            expect(_decode(decoder, pcm), _sentence);
            expect(decoder.isToneLocked, isTrue, reason: 'auto-tune lock');
            expect(decoder.detectedFrequency, closeTo(hz, 15));
            expect(decoder.estimatedWpm, closeTo(wpm, wpm * 0.15));
          });
        }
      }
    }

    test('SOS at 20 WPM, no noise', () {
      final Int16List pcm = SyntheticMorse().renderText('SOS');
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      expect(_decode(decoder, pcm), 'SOS');
      expect(decoder.isToneOn, isFalse);
    });

    test('quiet and loud signals both decode', () {
      for (final double amplitude in <double>[0.03, 0.95]) {
        final Int16List pcm = SyntheticMorse(amplitude: amplitude, snrDb: 20)
            .renderText('CQ CQ DE DITMESH', wpm: 20);
        final AudioMorseDecoder decoder = AudioMorseDecoder();
        addTearDown(decoder.dispose);
        // 'C' starts with a dah; the core decoder seeds at 80 ms (15 WPM), so
        // start after a dit-first word to keep this a DSP test.
        expect(_decode(decoder, pcm), endsWith('CQ DE DITMESH'),
            reason: 'amplitude $amplitude');
      }
    });

    test('is deterministic across chunk sizes', () {
      final Int16List pcm =
          SyntheticMorse(snrDb: 10).renderText(_sentence, wpm: 20);
      final List<String> results = <String>[];
      for (final int chunk in <int>[100, 960, 4096, pcm.length]) {
        final AudioMorseDecoder decoder = AudioMorseDecoder();
        results.add(_decode(decoder, pcm, chunk: chunk));
        decoder.dispose();
      }
      expect(results.toSet(), <String>{_sentence});
    });

    test('feedBytes carries an odd trailing byte across calls', () {
      final Int16List pcm = SyntheticMorse().renderText('SOS');
      final Uint8List bytes = Pcm.bytesFromInt16(pcm);
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      for (int i = 0; i < bytes.length; i += 1001) {
        final int end = i + 1001 < bytes.length ? i + 1001 : bytes.length;
        decoder.feedBytes(Uint8List.sublistView(bytes, i, end));
      }
      expect(decoder.text.trim(), 'SOS');
    });
  });

  group('AudioMorseDecoder stereo', () {
    test('downmixes interleaved stereo', () {
      final Int16List pcm = SyntheticMorse(channels: 2, snrDb: 20)
          .renderText('SOS SOS', wpm: 20);
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      expect(_decode(decoder, pcm, channels: 2), 'SOS SOS');
    });

    test('decodes a tone present on one channel only', () {
      final Int16List mono = SyntheticMorse(snrDb: 20).renderText('SOS');
      final Int16List stereo = Int16List(mono.length * 2);
      for (int i = 0; i < mono.length; i++) {
        stereo[2 * i] = mono[i];
      }
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      expect(_decode(decoder, stereo, channels: 2), 'SOS');
    });
  });

  group('AudioMorseDecoder tuning and control', () {
    test('manual frequency disables auto-tune and can be re-enabled', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      expect(decoder.autoTune, isTrue);
      expect(decoder.detectedFrequency, AudioMorseDecoder.defaultFrequencyHz);
      decoder.manualFrequencyHz = 650;
      expect(decoder.autoTune, isFalse);
      expect(decoder.detectedFrequency, 650);
      final Int16List pcm = SyntheticMorse(toneHz: 650).renderText('SOS');
      expect(_decode(decoder, pcm), 'SOS');
      expect(decoder.isToneLocked, isFalse);
      decoder.autoTune = true;
      expect(decoder.autoTune, isTrue);
    });

    test('manual mode never retunes or locks', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder(
        autoTune: false,
        manualFrequencyHz: 1000,
      );
      addTearDown(decoder.dispose);
      final Int16List pcm = SyntheticMorse(toneHz: 500).renderText('SOS');
      _decode(decoder, pcm);
      expect(decoder.detectedFrequency, 1000);
      expect(decoder.isToneLocked, isFalse);
      // The finder is idle in manual mode, so it has no opinion either.
      expect(decoder.lastToneScan, isNull);
    });

    test('emits decode events and level values while feeding', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      final List<DecodeEvent> events = <DecodeEvent>[];
      final List<double> levels = <double>[];
      decoder.events.listen(events.add);
      decoder.signalLevel.listen(levels.add);
      final Int16List pcm = SyntheticMorse().renderText('E');
      _decode(decoder, pcm);
      expect(
        events.where((DecodeEvent e) => e.kind == DecodeEventKind.character),
        hasLength(1),
      );
      // The level stream is asynchronous; it is delivered after this test's
      // synchronous body completes, so only check it is not closed here.
      expect(decoder.position, greaterThan(Duration.zero));
      expect(levels, isEmpty);
    });

    test('clearText keeps speed, reset forgets it', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder();
      addTearDown(decoder.dispose);
      final Int16List pcm = SyntheticMorse().renderText('SOS', wpm: 25);
      _decode(decoder, pcm);
      final Duration learned = decoder.estimatedDit;
      expect(learned.inMilliseconds, closeTo(48, 8));
      decoder.clearText();
      expect(decoder.text, isEmpty);
      expect(decoder.estimatedDit, learned);
      decoder.reset();
      expect(decoder.estimatedDit, const Duration(milliseconds: 80));
      expect(decoder.position, Duration.zero);
    });

    test('commitPending flushes a half-received character', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder(autoTune: false);
      addTearDown(decoder.dispose);
      final Int16List pcm = SyntheticMorse(
        tail: Duration.zero,
      ).renderText('E');
      // Trailing silence is too short for the decoder to close the 'E'...
      _decode(decoder, pcm);
      // ...except for the gate's own commit latency, so pad one block of
      // silence to commit the key-up, then flush.
      decoder.feed(Int16List(256 * 4));
      expect(decoder.commitPending(), 'E');
    });

    test('feed after dispose throws', () {
      final AudioMorseDecoder decoder = AudioMorseDecoder()..dispose();
      expect(() => decoder.feed(Int16List(256)), throwsStateError);
    });
  });

  group('Pcm', () {
    test('bytes round-trip', () {
      final Int16List samples = Int16List.fromList(<int>[0, 1, -1, 32767, -32768]);
      final Uint8List bytes = Pcm.bytesFromInt16(samples);
      expect(bytes.length, 10);
      expect(Pcm.int16FromBytes(bytes), samples);
    });

    test('toByteChunks splits by frames', () {
      final Int16List pcm = Int16List(10);
      final List<Uint8List> chunks = SyntheticMorse.toByteChunks(pcm, 4);
      expect(chunks.map((Uint8List c) => c.length), <int>[8, 8, 4]);
    });
  });

  test('live decoding: a tone 5 ms after the start is not swallowed', () {
    final Int16List pcm = SyntheticMorse(
      leadIn: const Duration(milliseconds: 5),
    ).renderText('TEST');
    final AudioMorseDecoder decoder = AudioMorseDecoder();
    decoder.feed(pcm);
    decoder.commitPending();
    expect(decoder.text.trim(), 'TEST');
    decoder.dispose();
  });

  for (final int rate in <int>[8000, 16000, 44100, 48000]) {
    test('live decoding keeps a tone one quiet block in at $rate Hz', () {
      final Int16List pcm = SyntheticMorse(
        sampleRate: rate,
        leadIn: Duration(microseconds: 256 * 1000000 ~/ rate),
      ).renderText('TEST');
      final AudioMorseDecoder decoder = AudioMorseDecoder(sampleRate: rate);
      decoder.feed(pcm);
      decoder.commitPending();
      expect(decoder.text.trim(), 'TEST');
      decoder.dispose();
    });
  }

  test('live decoding of pure noise yields no text (seed 1430)', () {
    final Int16List pcm = SyntheticMorse(
      sampleRate: 44100,
      seed: 1430,
      snrDb: 20,
      leadIn: Duration.zero,
      tail: const Duration(seconds: 1),
    ).render(const <MorseElement>[]);
    final AudioMorseDecoder decoder = AudioMorseDecoder(sampleRate: 44100);
    decoder.feed(pcm);
    expect(decoder.text.trim(), isEmpty, reason: 'before flushing');
    decoder.commitPending();
    expect(decoder.text.trim(), isEmpty);
    decoder.dispose();
  });
}
