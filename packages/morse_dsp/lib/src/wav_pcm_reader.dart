import 'dart:math' as math;
import 'dart:typed_data';

/// Random-access byte source, so a recording can be parsed and read in
/// chunks without loading the whole file. The app backs it with a
/// `RandomAccessFile`; [BytesSource] wraps memory.
abstract interface class ByteSource {
  /// Total length in bytes.
  int get length;

  /// Up to [count] bytes starting at [offset] (fewer only at the end).
  Future<Uint8List> read(int offset, int count);
}

/// A [ByteSource] over bytes already in memory.
final class BytesSource implements ByteSource {
  BytesSource(this.bytes);

  final Uint8List bytes;

  @override
  int get length => bytes.length;

  @override
  Future<Uint8List> read(int offset, int count) async {
    final int start = math.min(math.max(0, offset), bytes.length);
    final int end = math.min(bytes.length, start + math.max(0, count));
    return Uint8List.sublistView(bytes, start, end);
  }
}

/// Why a file was rejected.
enum WavError {
  notRiff,
  notWave,
  missingFmt,
  unsupportedFormat,
  unsupportedBitDepth,
  unsupportedChannels,
  unsupportedRate,
  missingData,
  truncated,
  tooLarge,
  tooLong,
}

final class WavFormatException implements Exception {
  const WavFormatException(this.error, [this.detail = '']);

  final WavError error;
  final String detail;

  @override
  String toString() => 'WavFormatException(${error.name}) $detail';
}

/// Parsed layout of a RIFF/WAVE PCM16 file.
final class WavInfo {
  const WavInfo({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataLength,
  });

  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  /// Byte offset of the first sample.
  final int dataOffset;

  /// Sample bytes (whole frames; a damaged declaration is rejected).
  final int dataLength;

  int get blockAlign => channels * bitsPerSample ~/ 8;

  int get frameCount => dataLength ~/ blockAlign;

  Duration get duration => durationOf(frameCount);

  /// Position of frame [frame] on the recording's sample clock.
  Duration durationOf(int frame) => Duration(
    microseconds: frame * Duration.microsecondsPerSecond ~/ sampleRate,
  );

  /// The frame at [position] (floor).
  int frameAt(Duration position) =>
      position.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;
}

/// RIFF/WAVE reader (functional spec §11.1): PCM16 (format 1 or
/// WAVE_FORMAT_EXTENSIBLE with the PCM subformat), mono or stereo, 8/16/44.1/
/// 48 kHz. The format comes from the headers, never the file extension.
/// Unknown chunks are skipped (with RIFF's odd-size padding byte).
final class WavPcmReader {
  WavPcmReader._(this.source, this.info);

  static const int maxBytes = 50 * 1024 * 1024;
  static const Duration maxDuration = Duration(minutes: 20);
  static const Set<int> supportedRates = <int>{8000, 16000, 44100, 48000};

  final ByteSource source;
  final WavInfo info;

  /// Parses the headers of [source]; throws [WavFormatException].
  static Future<WavPcmReader> open(ByteSource source) async =>
      WavPcmReader._(source, await parse(source));

  static Future<WavInfo> parse(ByteSource source) async {
    final int length = source.length;
    if (length > maxBytes) {
      throw const WavFormatException(WavError.tooLarge, 'over 50 MiB');
    }
    if (length < 12) throw const WavFormatException(WavError.notRiff);
    final ByteData head = ByteData.sublistView(await source.read(0, 12));
    if (_tag(head, 0) != 'RIFF') {
      throw const WavFormatException(WavError.notRiff);
    }
    if (_tag(head, 8) != 'WAVE') {
      throw const WavFormatException(WavError.notWave);
    }
    // The RIFF size must fit the file (one pad byte of slack): a shorter
    // file was cut off, a larger declaration is damaged or streamed.
    final int riffEnd = head.getUint32(4, Endian.little) + 8;
    if (riffEnd > length + 1 || riffEnd < 12) {
      throw const WavFormatException(WavError.truncated, 'RIFF size');
    }
    // Chunks must lie inside the declared RIFF body; bytes after it (some
    // tools append metadata) are not part of the file.
    final int end = riffEnd < length ? riffEnd : length;

    int? rate;
    int? channels;
    int? bits;
    int? dataOffset;
    int? dataDeclared;
    int offset = 12;
    while (offset + 8 <= end) {
      final ByteData chunk = ByteData.sublistView(await source.read(offset, 8));
      final String id = _tag(chunk, 0);
      final int size = chunk.getUint32(4, Endian.little);
      final int body = offset + 8;
      if (id == 'fmt ') {
        if (size < 16 || body + size > end) {
          throw const WavFormatException(WavError.truncated, 'fmt chunk');
        }
        final ByteData fmt = ByteData.sublistView(
          await source.read(body, size),
        );
        int format = fmt.getUint16(0, Endian.little);
        channels = fmt.getUint16(2, Endian.little);
        rate = fmt.getUint32(4, Endian.little);
        final int blockAlign = fmt.getUint16(12, Endian.little);
        bits = fmt.getUint16(14, Endian.little);
        if (format == 0xFFFE) {
          if (size < 40) {
            throw const WavFormatException(WavError.truncated, 'extensible');
          }
          format = fmt.getUint16(24, Endian.little);
        }
        if (format != 1) {
          throw WavFormatException(
            WavError.unsupportedFormat,
            'format $format',
          );
        }
        if (bits != 16) {
          throw WavFormatException(WavError.unsupportedBitDepth, '$bits bit');
        }
        if (channels != 1 && channels != 2) {
          throw WavFormatException(WavError.unsupportedChannels, '$channels');
        }
        if (!supportedRates.contains(rate)) {
          throw WavFormatException(WavError.unsupportedRate, '$rate Hz');
        }
        if (blockAlign != channels * 2) {
          throw WavFormatException(
            WavError.unsupportedFormat,
            'blockAlign $blockAlign',
          );
        }
      } else if (id == 'data') {
        // A data chunk running past the end is a damaged or cut-off file:
        // rejected, never silently clipped (functional spec §11.3).
        if (body + size > end) {
          throw const WavFormatException(WavError.truncated, 'data chunk');
        }
        dataOffset = body;
        dataDeclared = size;
      } else if (body + size > end) {
        throw WavFormatException(WavError.truncated, 'chunk "$id"');
      }
      // Chunks are word aligned: an odd size is followed by a pad byte.
      offset = body + size + (size.isOdd ? 1 : 0);
      if (rate != null && dataOffset != null && offset >= end) break;
    }
    if (rate == null || channels == null || bits == null) {
      throw const WavFormatException(WavError.missingFmt);
    }
    if (dataOffset == null || dataDeclared == null) {
      throw const WavFormatException(WavError.missingData);
    }
    final int blockAlign = channels * 2;
    if (dataDeclared % blockAlign != 0) {
      throw const WavFormatException(WavError.truncated, 'partial frame');
    }
    if (dataDeclared <= 0) throw const WavFormatException(WavError.missingData);
    final WavInfo info = WavInfo(
      sampleRate: rate,
      channels: channels,
      bitsPerSample: bits,
      dataOffset: dataOffset,
      dataLength: dataDeclared,
    );
    if (info.duration > maxDuration) {
      throw const WavFormatException(WavError.tooLong, 'over 20 minutes');
    }
    return info;
  }

  /// Mono samples (-1..1, channels averaged) of frames
  /// `[startFrame, startFrame + frameCount)`, clamped to the recording.
  Future<Float64List> readMono(int startFrame, int frameCount) async {
    final int start = startFrame.clamp(0, info.frameCount);
    final int end = (startFrame + frameCount).clamp(start, info.frameCount);
    final int frames = end - start;
    final Float64List out = Float64List(frames);
    if (frames == 0) return out;
    final int align = info.blockAlign;
    final Uint8List bytes = await source.read(
      info.dataOffset + start * align,
      frames * align,
    );
    final ByteData view = ByteData.sublistView(bytes);
    final int got = bytes.length ~/ align;
    final int ch = info.channels;
    final double scale = 1 / 32768 / ch;
    for (int f = 0; f < got; f++) {
      int sum = 0;
      for (int c = 0; c < ch; c++) {
        sum += view.getInt16(f * align + c * 2, Endian.little);
      }
      out[f] = sum * scale;
    }
    return got == frames ? out : Float64List.sublistView(out, 0, got);
  }

  /// Streams `[startFrame, endFrame)` as mono chunks of [chunkFrames].
  Stream<Float64List> chunks(
    int startFrame,
    int endFrame, {
    int chunkFrames = 4096,
  }) async* {
    if (chunkFrames <= 0) {
      throw ArgumentError.value(chunkFrames, 'chunkFrames', 'must be > 0');
    }
    final int end = endFrame.clamp(0, info.frameCount);
    for (int f = startFrame.clamp(0, end); f < end; f += chunkFrames) {
      yield await readMono(f, math.min(chunkFrames, end - f));
    }
  }

  static String _tag(ByteData d, int at) => String.fromCharCodes(<int>[
    for (int i = 0; i < 4; i++) d.getUint8(at + i),
  ]);
}

/// Downsampled min/max envelope for drawing a waveform.
final class WaveformEnvelope {
  const WaveformEnvelope(this.mins, this.maxs);

  final Float32List mins;
  final Float32List maxs;

  int get length => mins.length;

  /// Builds [buckets] min/max pairs over the whole recording by streaming
  /// chunks; returns null when [isCancelled] turns true.
  static Future<WaveformEnvelope?> build(
    WavPcmReader reader,
    int buckets, {
    int chunkFrames = 16384,
    bool Function()? isCancelled,
  }) async {
    if (buckets <= 0) throw ArgumentError.value(buckets, 'buckets');
    final int total = reader.info.frameCount;
    final Float32List mins = Float32List(buckets);
    final Float32List maxs = Float32List(buckets);
    final List<bool> seen = List<bool>.filled(buckets, false);
    int frame = 0;
    await for (final Float64List chunk in reader.chunks(
      0,
      total,
      chunkFrames: chunkFrames,
    )) {
      if (isCancelled?.call() ?? false) return null;
      for (int i = 0; i < chunk.length; i++, frame++) {
        final int b = math.min(buckets - 1, frame * buckets ~/ total);
        final double v = chunk[i];
        if (!seen[b]) {
          seen[b] = true;
          mins[b] = v;
          maxs[b] = v;
        } else {
          if (v < mins[b]) mins[b] = v;
          if (v > maxs[b]) maxs[b] = v;
        }
      }
    }
    if (isCancelled?.call() ?? false) return null;
    return WaveformEnvelope(mins, maxs);
  }
}
