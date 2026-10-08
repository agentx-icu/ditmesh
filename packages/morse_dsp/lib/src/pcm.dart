import 'dart:typed_data';

/// Conversions between raw PCM and the mono `double` samples (nominal range
/// -1..1) that the rest of `morse_dsp` works on.
abstract final class Pcm {
  /// Scale from a signed 16-bit sample to the -1..1 range.
  static const double int16Scale = 1 / 32768;

  /// Decodes interleaved little-endian (or [endian]) 16-bit PCM bytes.
  ///
  /// An odd trailing byte is ignored; callers that stream bytes should carry
  /// it over themselves (see `AudioMorseDecoder.feedBytes`). The result is a
  /// copy, so unaligned input is fine.
  static Int16List int16FromBytes(
    Uint8List bytes, {
    Endian endian = Endian.little,
  }) {
    final int count = bytes.lengthInBytes ~/ 2;
    final Int16List out = Int16List(count);
    final ByteData view = ByteData.sublistView(bytes, 0, count * 2);
    for (int i = 0; i < count; i++) {
      out[i] = view.getInt16(i * 2, endian);
    }
    return out;
  }

  /// Encodes 16-bit samples as little-endian (or [endian]) bytes.
  static Uint8List bytesFromInt16(
    Int16List samples, {
    Endian endian = Endian.little,
  }) {
    final Uint8List out = Uint8List(samples.length * 2);
    final ByteData view = ByteData.sublistView(out);
    for (int i = 0; i < samples.length; i++) {
      view.setInt16(i * 2, samples[i], endian);
    }
    return out;
  }

  /// Averages [channels] interleaved 16-bit channels into mono doubles and
  /// appends them to [out]. A trailing partial frame is dropped.
  static void downmixInt16(List<int> pcm, int channels, SampleBuffer out) {
    if (channels < 1) {
      throw ArgumentError.value(channels, 'channels', 'must be >= 1');
    }
    final int frames = pcm.length ~/ channels;
    final double scale = int16Scale / channels;
    out.ensureCapacity(out.length + frames);
    if (channels == 1) {
      for (int i = 0; i < frames; i++) {
        out.addUnchecked(pcm[i] * scale);
      }
      return;
    }
    for (int f = 0; f < frames; f++) {
      final int base = f * channels;
      int sum = 0;
      for (int c = 0; c < channels; c++) {
        sum += pcm[base + c];
      }
      out.addUnchecked(sum * scale);
    }
  }

  /// Averages [channels] interleaved float channels (already -1..1) into
  /// mono and appends them to [out]. A trailing partial frame is dropped.
  static void downmixFloat(
    List<double> pcm,
    int channels,
    SampleBuffer out,
  ) {
    if (channels < 1) {
      throw ArgumentError.value(channels, 'channels', 'must be >= 1');
    }
    final int frames = pcm.length ~/ channels;
    final double scale = 1 / channels;
    out.ensureCapacity(out.length + frames);
    if (channels == 1) {
      for (int i = 0; i < frames; i++) {
        out.addUnchecked(pcm[i]);
      }
      return;
    }
    for (int f = 0; f < frames; f++) {
      final int base = f * channels;
      double sum = 0;
      for (int c = 0; c < channels; c++) {
        sum += pcm[base + c];
      }
      out.addUnchecked(sum * scale);
    }
  }
}

/// Growable, unboxed `double` FIFO used to carry partial blocks between
/// `feed` calls without reallocating on every chunk.
final class SampleBuffer {
  SampleBuffer([int initialCapacity = 4096])
      : _data = Float64List(initialCapacity < 16 ? 16 : initialCapacity);

  Float64List _data;
  int _length = 0;

  int get length => _length;

  bool get isEmpty => _length == 0;

  /// Backing store; only the first [length] entries are valid.
  Float64List get data => _data;

  double operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    return _data[index];
  }

  void ensureCapacity(int capacity) {
    if (capacity <= _data.length) return;
    int next = _data.length * 2;
    while (next < capacity) {
      next *= 2;
    }
    final Float64List grown = Float64List(next);
    grown.setRange(0, _length, _data);
    _data = grown;
  }

  void add(double sample) {
    ensureCapacity(_length + 1);
    _data[_length++] = sample;
  }

  /// [add] without the capacity check; call [ensureCapacity] first.
  void addUnchecked(double sample) {
    _data[_length++] = sample;
  }

  void addAll(List<double> samples) {
    ensureCapacity(_length + samples.length);
    _data.setRange(_length, _length + samples.length, samples);
    _length += samples.length;
  }

  /// Drops the first [count] samples, shifting the remainder to the front.
  void consume(int count) {
    if (count <= 0) return;
    if (count >= _length) {
      _length = 0;
      return;
    }
    _data.setRange(0, _length - count, _data, count);
    _length -= count;
  }

  void clear() {
    _length = 0;
  }
}
