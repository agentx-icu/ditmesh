import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

void main() {
  const MorseTiming timing = MorseTiming(wpm: 20, farnsworthWpm: 10);

  group('MorseWavExport.render', () {
    final List<MorseElement> timeline = MorseEncoder.encode('PARIS', timing);
    final Uint8List wav = MorseWavExport.render(
      timeline,
      toneHz: 600,
      amplitude: 0.5,
      leadIn: const Duration(milliseconds: 100),
      tail: const Duration(milliseconds: 100),
    );
    final ByteData d = ByteData.sublistView(wav);
    String tag(int at) => String.fromCharCodes(wav.sublist(at, at + 4));

    test('header is PCM16 mono 48 kHz with consistent sizes', () {
      expect(tag(0), 'RIFF');
      expect(tag(8), 'WAVE');
      expect(tag(12), 'fmt ');
      expect(d.getUint16(20, Endian.little), 1);
      expect(d.getUint16(22, Endian.little), 1);
      expect(d.getUint32(24, Endian.little), 48000);
      expect(d.getUint16(34, Endian.little), 16);
      expect(tag(36), 'data');
      expect(d.getUint32(40, Endian.little), wav.length - 44);
      expect(d.getUint32(4, Endian.little), wav.length - 8);
    });

    test('length matches the timeline at 48 kHz', () {
      final Duration total = MorseWavExport.durationOf(
        timeline,
        leadIn: const Duration(milliseconds: 100),
        tail: const Duration(milliseconds: 100),
      );
      final int samples = (wav.length - 44) ~/ 2;
      expect(samples, closeTo(total.inMicroseconds * 48000 / 1e6, 20));
    });

    int sample(int i) => d.getInt16(44 + i * 2, Endian.little);

    test('no clicks: silence at the ends, ramped marks, bounded peak', () {
      final int n = (wav.length - 44) ~/ 2;
      expect(sample(0), 0);
      expect(sample(n - 1), 0);
      // First mark begins after the 100 ms lead-in; its first 5 ms ramp up.
      const int start = 4800;
      expect(sample(start).abs(), lessThan(5));
      var peak = 0;
      for (int i = 0; i < n; i++) {
        peak = sample(i).abs() > peak ? sample(i).abs() : peak;
      }
      expect(peak, closeTo(0.5 * 32767, 200));
      // Envelope maxima per cycle grow monotonically through the ramp.
      var last = -1;
      for (int c = 0; c < 3; c++) {
        var m = 0;
        for (int i = start + c * 80; i < start + (c + 1) * 80; i++) {
          if (sample(i).abs() > m) m = sample(i).abs();
        }
        expect(m, greaterThan(last));
        last = m;
      }
    });
  });

  group('limits and segments', () {
    test('over ten minutes is refused; empty is refused', () {
      final long = List.filled(400, 'PARIS').join(' ');
      expect(
        () => MorseWavExport.renderText(long, const MorseTiming(wpm: 5)),
        throwsA(isA<WavExportException>()),
      );
      expect(
        () => MorseWavExport.render(const <MorseElement>[]),
        throwsA(isA<WavExportException>()),
      );
    });

    test('an over-long word is split between symbols, nothing lost', () {
      const slow = MorseTiming(wpm: 10, farnsworthWpm: 5);
      final word = '0' * 200;
      final parts = MorseWavExport.segments(word, slow);
      expect(parts.length, greaterThan(1));
      expect(parts.join(), word);
      for (final part in parts) {
        expect(
          MorseEncoder.totalDuration(MorseEncoder.encode(part, slow)),
          lessThan(MorseWavExport.maxDuration),
        );
      }
      final prosigns = MorseWavExport.segments('<SK>' * 150, slow);
      expect(prosigns.join(), '<SK>' * 150);
    });

    test('segments split at word boundaries and each fits', () {
      final long = List.filled(400, 'PARIS').join(' ');
      const t = MorseTiming(wpm: 5);
      final parts = MorseWavExport.segments(long, t);
      expect(parts.length, greaterThan(1));
      expect(parts.join(' '), long);
      for (final p in parts) {
        expect(
          MorseWavExport.durationOf(
            MorseEncoder.encode(p, t),
            leadIn: const Duration(milliseconds: 500),
            tail: const Duration(milliseconds: 500),
          ),
          lessThanOrEqualTo(MorseWavExport.maxDuration),
        );
      }
    });
  });

  test('safeFileName', () {
    expect(safeFileName('My/CW:practice?*'), 'My CW practice');
    expect(safeFileName('  ..  '), 'morse');
    expect(safeFileName('CON'), '_CON');
    expect(safeFileName('com1.wav'), '_com1.wav');
    expect(safeFileName('练习 Übung\u0007'), '练习 Übung');
    expect(safeFileName('x' * 200).length, 80);
    expect(safeFileName('name.'), 'name');
    // 80 emoji are 320 bytes: capped by encoded length, not characters.
    final emoji = safeFileName('\u{1F4FB}' * 80);
    expect(utf8.encode(emoji).length, lessThanOrEqualTo(120));
    expect(emoji.runes.every((r) => r == 0x1F4FB), isTrue);
  });
}
