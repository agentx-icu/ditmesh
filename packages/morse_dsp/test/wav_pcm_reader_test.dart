import 'dart:typed_data';

import 'package:morse_dsp/morse_dsp.dart';
import 'package:test/test.dart';

import 'support/wav_bytes.dart';

Future<WavPcmReader> _open(Uint8List bytes) =>
    WavPcmReader.open(BytesSource(bytes));

Matcher _rejects(WavError e) =>
    throwsA(isA<WavFormatException>().having((x) => x.error, 'error', e));

void main() {
  final Int16List ramp = Int16List.fromList(
    List<int>.generate(200, (i) => (i - 100) * 300),
  );

  group('formats', () {
    for (final int rate in <int>[8000, 16000, 44100, 48000]) {
      for (final int channels in <int>[1, 2]) {
        test('$rate Hz × $channels ch', () async {
          final Int16List pcm = Int16List(ramp.length * channels);
          for (int i = 0; i < ramp.length; i++) {
            pcm[i * channels] = ramp[i];
            if (channels == 2) pcm[i * 2 + 1] = -ramp[i] ~/ 2;
          }
          final WavPcmReader r = await _open(
            wavBytes(pcm, sampleRate: rate, channels: channels),
          );
          expect(r.info.sampleRate, rate);
          expect(r.info.channels, channels);
          expect(r.info.frameCount, ramp.length);
          expect(r.info.duration.inMicroseconds, ramp.length * 1000000 ~/ rate);
          final Float64List mono = await r.readMono(10, 5);
          for (int i = 0; i < 5; i++) {
            final int v = ramp[10 + i];
            final double expected = channels == 1
                ? v / 32768
                : (v + (-v ~/ 2)) / 2 / 32768;
            expect(mono[i], closeTo(expected, 1e-9));
          }
        });
      }
    }

    test('WAVE_FORMAT_EXTENSIBLE with PCM subformat', () async {
      final r = await _open(wavBytes(ramp, extensible: true));
      expect(r.info.frameCount, 200);
    });

    test(
      'unknown chunks and odd padding are skipped; fmt after data',
      () async {
        final r = await _open(
          wavBytes(
            ramp,
            before: [
              ('LIST', [1, 2, 3]),
              ('junk', List<int>.filled(10, 7)),
            ],
          ),
        );
        expect(r.info.frameCount, 200);
        expect((await r.readMono(0, 1))[0], closeTo(ramp[0] / 32768, 1e-9));
        final r2 = await _open(wavBytes(ramp, fmtAfterData: true));
        expect(r2.info.frameCount, 200);
      },
    );

    test('chunks cover the range and downmix', () async {
      final r = await _open(wavBytes(ramp));
      final parts = await r.chunks(0, 200, chunkFrames: 64).toList();
      expect(parts.map((c) => c.length), [64, 64, 64, 8]);
      final env = await WaveformEnvelope.build(r, 4, chunkFrames: 33);
      expect(env!.length, 4);
      expect(env.mins[0], closeTo(ramp[0] / 32768, 1e-6));
      expect(env.maxs[3], closeTo(ramp[199] / 32768, 1e-6));
      var calls = 0;
      expect(
        await WaveformEnvelope.build(
          r,
          4,
          chunkFrames: 50,
          isCancelled: () => ++calls > 1,
        ),
        isNull,
      );
    });
  });

  group('rejection', () {
    test('not RIFF / not WAVE / damaged', () async {
      expect(_open(Uint8List(4)), _rejects(WavError.notRiff));
      final bytes = wavBytes(ramp);
      final notWave = Uint8List.fromList(bytes)..setAll(8, 'AVI '.codeUnits);
      expect(_open(notWave), _rejects(WavError.notWave));
      final garbage = Uint8List.fromList(bytes)..setAll(0, 'RIFX'.codeUnits);
      expect(_open(garbage), _rejects(WavError.notRiff));
    });

    test('unsupported encodings', () async {
      expect(
        _open(wavBytes(ramp, format: 3)),
        _rejects(WavError.unsupportedFormat),
      );
      expect(
        _open(wavBytes(ramp, extensible: true, format: 3)),
        _rejects(WavError.unsupportedFormat),
      );
      expect(
        _open(wavBytes(ramp, bits: 24)),
        _rejects(WavError.unsupportedBitDepth),
      );
      expect(
        _open(wavBytes(Int16List(300), channels: 3)),
        _rejects(WavError.unsupportedChannels),
      );
      expect(
        _open(wavBytes(ramp, sampleRate: 22050)),
        _rejects(WavError.unsupportedRate),
      );
    });

    test('missing chunks', () async {
      final noData = Uint8List.fromList(wavBytes(ramp).sublist(0, 36));
      ByteData.sublistView(noData).setUint32(4, 28, Endian.little);
      expect(_open(noData), _rejects(WavError.missingData));
      final noFmt = wavBytes(ramp);
      // Replace the real fmt id so none is found.
      final s = String.fromCharCodes(noFmt);
      final at = s.indexOf('fmt ');
      final bytes = Uint8List.fromList(noFmt)..setAll(at, 'xxxx'.codeUnits);
      expect(_open(bytes), _rejects(WavError.missingFmt));
    });

    test('truncated or overflowing files are rejected', () async {
      final full = wavBytes(ramp);
      expect(_open(full.sublist(0, 30)), _rejects(WavError.truncated));
      final listTooBig = wavBytes(
        ramp,
        before: [
          ('LIST', [1, 2]),
        ],
      );
      ByteData.sublistView(listTooBig).setUint32(16, 1 << 30, Endian.little);
      expect(_open(listTooBig), _rejects(WavError.truncated));
      expect(
        _open(full.sublist(0, full.length - 101)),
        _rejects(WavError.truncated),
      );
      expect(
        _open(wavBytes(ramp, declaredDataSize: 0xFFFFFFF0)),
        _rejects(WavError.truncated),
      );
      // A data size that is not a whole number of frames is damage too.
      final odd = wavBytes(ramp, declaredDataSize: 399);
      expect(_open(odd), _rejects(WavError.truncated));
      // A RIFF size claiming more than the file holds.
      final riff = Uint8List.fromList(full);
      ByteData.sublistView(riff).setUint32(4, full.length + 100, Endian.little);
      expect(_open(riff), _rejects(WavError.truncated));
      // A RIFF size smaller than the chunks it contains: the declared end
      // is enforced, not the physical file length.
      for (final int declared in <int>[0, 4, 28, 36]) {
        final short = Uint8List.fromList(full);
        ByteData.sublistView(short).setUint32(4, declared, Endian.little);
        expect(
          _open(short),
          throwsA(isA<WavFormatException>()),
          reason: 'RIFF size $declared',
        );
      }
    });

    test('bytes after the declared RIFF end are ignored', () async {
      final extra = Uint8List.fromList(<int>[
        ...wavBytes(ramp),
        1, 2, 3, 4, 5, 6, 7, 8, //
      ]);
      final r = await _open(extra);
      expect(r.info.frameCount, ramp.length);
    });

    test('size and duration limits', () async {
      final big = _FakeLength(WavPcmReader.maxBytes + 1);
      expect(WavPcmReader.open(big), _rejects(WavError.tooLarge));
      // 21 minutes of 8 kHz mono is under 50 MiB but too long.
      final long = wavBytes(Int16List(8000 * 60 * 21), sampleRate: 8000);
      expect(_open(long), _rejects(WavError.tooLong));
    });
  });
}

final class _FakeLength implements ByteSource {
  _FakeLength(this.length);

  @override
  final int length;

  @override
  Future<Uint8List> read(int offset, int count) async => Uint8List(count);
}
