import 'dart:typed_data';

import 'package:morse_dsp/src/pcm.dart';
import 'package:test/test.dart';

void main() {
  group('Pcm.int16FromBytes / bytesFromInt16', () {
    test('ignores an odd trailing byte', () {
      final Uint8List bytes = Uint8List.fromList(<int>[0x01, 0x00, 0xFF, 0x7F, 0x42]);
      final Int16List samples = Pcm.int16FromBytes(bytes);
      expect(samples, <int>[1, 32767]);
    });

    test('honours the endianness on both directions', () {
      final Int16List samples = Int16List.fromList(<int>[1, -2, 32767, -32768]);
      final Uint8List big = Pcm.bytesFromInt16(samples, endian: Endian.big);
      expect(big.sublist(0, 2), <int>[0x00, 0x01]);
      expect(Pcm.int16FromBytes(big, endian: Endian.big), samples);
      expect(Pcm.int16FromBytes(big), isNot(equals(samples)));
      final Uint8List little = Pcm.bytesFromInt16(samples);
      expect(little.sublist(0, 2), <int>[0x01, 0x00]);
      expect(Pcm.int16FromBytes(little), samples);
    });

    test('copies, so an unaligned view is fine', () {
      final Uint8List backing = Uint8List.fromList(<int>[0xAA, 0x02, 0x00, 0x03, 0x00]);
      final Uint8List unaligned = Uint8List.sublistView(backing, 1);
      expect(Pcm.int16FromBytes(unaligned), <int>[2, 3]);
    });
  });

  group('Pcm.downmixInt16', () {
    test('mono scales to the -1..1 range', () {
      final SampleBuffer out = SampleBuffer();
      Pcm.downmixInt16(<int>[32767, -32768, 0], 1, out);
      expect(out.length, 3);
      expect(out[0], closeTo(1, 1e-4));
      expect(out[1], -1);
      expect(out[2], 0);
    });

    test('stereo averages the channels and drops a partial frame', () {
      final SampleBuffer out = SampleBuffer()..add(0.5);
      Pcm.downmixInt16(<int>[16384, 0, 0, -16384, 100], 2, out);
      expect(out.length, 3, reason: 'existing sample + 2 frames');
      expect(out[0], 0.5);
      expect(out[1], closeTo(0.25, 1e-6));
      expect(out[2], closeTo(-0.25, 1e-6));
    });

    test('rejects a channel count below one', () {
      expect(
        () => Pcm.downmixInt16(<int>[1], 0, SampleBuffer()),
        throwsArgumentError,
      );
    });
  });

  group('Pcm.downmixFloat', () {
    test('mono appends the samples unchanged', () {
      final SampleBuffer out = SampleBuffer();
      Pcm.downmixFloat(<double>[0.25, -0.5], 1, out);
      expect(out.length, 2);
      expect(out[0], 0.25);
      expect(out[1], -0.5);
    });

    test('three channels average and drop the partial frame', () {
      final SampleBuffer out = SampleBuffer();
      Pcm.downmixFloat(<double>[0.3, 0.6, 0.9, -1, -1, 1, 0.1], 3, out);
      expect(out.length, 2);
      expect(out[0], closeTo(0.6, 1e-9));
      expect(out[1], closeTo(-1 / 3, 1e-9));
    });

    test('rejects a channel count below one', () {
      expect(
        () => Pcm.downmixFloat(<double>[1], -1, SampleBuffer()),
        throwsArgumentError,
      );
    });
  });

  group('SampleBuffer', () {
    test('starts empty with at least 16 slots and grows on demand', () {
      final SampleBuffer buf = SampleBuffer(2);
      expect(buf.isEmpty, isTrue);
      expect(buf.data.length, greaterThanOrEqualTo(16));
      for (int i = 0; i < 40; i++) {
        buf.add(i.toDouble());
      }
      expect(buf.isEmpty, isFalse);
      expect(buf.length, 40);
      expect(buf.data.length, greaterThanOrEqualTo(40));
      expect(buf[39], 39);
    });

    test('addAll appends in order', () {
      final SampleBuffer buf = SampleBuffer()..add(1);
      buf.addAll(<double>[2, 3, 4]);
      expect(buf.length, 4);
      expect(List<double>.generate(buf.length, (int i) => buf[i]), <double>[1, 2, 3, 4]);
    });

    test('indexing past the length throws even inside the capacity', () {
      final SampleBuffer buf = SampleBuffer()..add(1);
      expect(() => buf[1], throwsRangeError);
      expect(() => buf[-1], throwsRangeError);
    });

    test('consume shifts the remainder forward; clear empties', () {
      final SampleBuffer buf = SampleBuffer()..addAll(<double>[1, 2, 3, 4, 5]);
      buf.consume(0);
      buf.consume(-3);
      expect(buf.length, 5);
      buf.consume(2);
      expect(buf.length, 3);
      expect(buf[0], 3);
      expect(buf[2], 5);
      buf.consume(10);
      expect(buf.isEmpty, isTrue);
      buf.addAll(<double>[7]);
      buf.clear();
      expect(buf.length, 0);
    });

    test('ensureCapacity keeps the existing samples while growing', () {
      final SampleBuffer buf = SampleBuffer(2)..addAll(<double>[1, 2]);
      final int before = buf.data.length;
      buf.ensureCapacity(before * 4);
      expect(buf.data.length, greaterThanOrEqualTo(before * 4));
      expect(buf[0], 1);
      expect(buf[1], 2);
      expect(buf.length, 2);
    });
  });
}
