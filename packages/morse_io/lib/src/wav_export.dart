import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_core/morse_core.dart';

/// Why an export was refused.
enum WavExportError { tooLong, wordTooLong, empty }

final class WavExportException implements Exception {
  const WavExportException(this.error);

  final WavExportError error;

  @override
  String toString() => 'WavExportException(${error.name})';
}

/// Offline practice audio (functional spec §9.2): PCM16 mono WAV at
/// [sampleRate], each mark a sine with raised-cosine attack and release so
/// there are no clicks. The file is exactly the timeline (plus optional
/// silence), so its duration matches the chosen speeds.
abstract final class MorseWavExport {
  static const int sampleRate = 48000;
  static const Duration maxDuration = Duration(minutes: 10);
  static const Duration defaultRamp = Duration(milliseconds: 5);

  static int _samples(Duration d) =>
      (d.inMicroseconds * sampleRate / Duration.microsecondsPerSecond).round();

  /// Duration of [timeline] plus lead-in and tail silence.
  static Duration durationOf(
    List<MorseElement> timeline, {
    Duration leadIn = Duration.zero,
    Duration tail = Duration.zero,
  }) => MorseEncoder.totalDuration(timeline) + leadIn + tail;

  /// Renders [timeline] to WAV bytes. Throws [WavExportException] when the
  /// result would exceed [maxDuration] or is empty.
  static Uint8List render(
    List<MorseElement> timeline, {
    double toneHz = 700,
    double amplitude = 0.5,
    Duration ramp = defaultRamp,
    Duration leadIn = const Duration(milliseconds: 500),
    Duration tail = const Duration(milliseconds: 500),
  }) {
    if (!timeline.any((e) => e.on)) {
      throw const WavExportException(WavExportError.empty);
    }
    if (durationOf(timeline, leadIn: leadIn, tail: tail) > maxDuration) {
      throw const WavExportException(WavExportError.tooLong);
    }
    final int lead = _samples(leadIn);
    int total = lead + _samples(tail);
    for (final e in timeline) {
      total += _samples(e.duration);
    }
    final Uint8List out = Uint8List(44 + total * 2);
    final ByteData d = ByteData.sublistView(out);
    _header(d, total * 2);
    final double omega = 2 * math.pi * toneHz / sampleRate;
    final int rampN = _samples(ramp);
    final double peak = amplitude.clamp(0.0, 1.0) * 32767;
    int cursor = lead;
    for (final e in timeline) {
      final int n = _samples(e.duration);
      if (e.on) {
        final int r = math.min(rampN, n ~/ 2);
        for (int i = 0; i < n; i++) {
          final double env = _envelope(i, n, r);
          final double v = peak * env * math.sin(omega * i);
          d.setInt16(44 + (cursor + i) * 2, v.round(), Endian.little);
        }
      }
      cursor += n;
    }
    return out;
  }

  /// Renders [text] at [timing].
  static Uint8List renderText(
    String text,
    MorseTiming timing, {
    double toneHz = 700,
    double amplitude = 0.5,
  }) => render(
    MorseEncoder.encode(text, timing),
    toneHz: toneHz,
    amplitude: amplitude,
  );

  /// Splits [text] at word boundaries into explicit segments that each
  /// render within [maxDuration] (including lead-in and tail). A single
  /// word longer than that is split between its symbols (prosigns stay
  /// whole), so all content is exported. Throws [WavExportException] only
  /// when one symbol alone cannot fit.
  static List<String> segments(
    String text,
    MorseTiming timing, {
    Duration maxDuration = MorseWavExport.maxDuration,
    Duration padding = const Duration(seconds: 1),
  }) {
    final List<String> words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final List<String> out = <String>[];
    List<String> current = <String>[];
    Duration len(List<String> ws) =>
        MorseEncoder.totalDuration(MorseEncoder.encode(ws.join(' '), timing)) +
        padding;
    final List<String> pieces = <String>[];
    for (final String w in words) {
      if (len(<String>[w]) <= maxDuration) {
        pieces.add(w);
        continue;
      }
      // Cut the word between symbols: each piece is played as its own word.
      String piece = '';
      for (final Match m in RegExp(r'<[^<>\s]+>|.').allMatches(w)) {
        final String symbol = m[0]!;
        if (len(<String>[symbol]) > maxDuration) {
          throw const WavExportException(WavExportError.wordTooLong);
        }
        if (piece.isNotEmpty && len(<String>[piece + symbol]) > maxDuration) {
          pieces.add(piece);
          piece = '';
        }
        piece += symbol;
      }
      if (piece.isNotEmpty) pieces.add(piece);
    }
    for (final String w in pieces) {
      final List<String> next = <String>[...current, w];
      if (current.isNotEmpty && len(next) > maxDuration) {
        out.add(current.join(' '));
        current = <String>[w];
      } else {
        current = next;
      }
    }
    if (current.isNotEmpty) out.add(current.join(' '));
    return out;
  }

  static double _envelope(int i, int n, int ramp) {
    if (ramp <= 0) return 1;
    if (i < ramp) return 0.5 * (1 - math.cos(math.pi * i / ramp));
    final int fromEnd = n - 1 - i;
    if (fromEnd < ramp) return 0.5 * (1 - math.cos(math.pi * fromEnd / ramp));
    return 1;
  }

  static void _header(ByteData d, int dataBytes) {
    void tag(int at, String s) {
      for (int i = 0; i < 4; i++) {
        d.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    d.setUint32(4, 36 + dataBytes, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little); // PCM
    d.setUint16(22, 1, Endian.little); // mono
    d.setUint32(24, sampleRate, Endian.little);
    d.setUint32(28, sampleRate * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    d.setUint32(40, dataBytes, Endian.little);
  }
}

/// A file name safe on all five platforms: path separators, reserved and
/// control characters removed, Windows device names avoided, Unicode
/// letters kept. Capped at [maxLength] characters **and** [maxBytes] UTF-8
/// bytes (file systems limit names to 255 bytes; the rest is left for a
/// part suffix and extension). [fallback] when nothing is left.
String safeFileName(
  String title, {
  String fallback = 'morse',
  int maxLength = 80,
  int maxBytes = 120,
}) {
  final String cleaned = title
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^[ .]+|[ .]+$'), '');
  List<int> runes = cleaned.runes.toList();
  if (runes.length > maxLength) runes = runes.sublist(0, maxLength);
  while (runes.isNotEmpty &&
      utf8.encode(String.fromCharCodes(runes)).length > maxBytes) {
    runes = runes.sublist(0, runes.length - 1);
  }
  String name = String.fromCharCodes(
    runes,
  ).trim().replaceAll(RegExp(r'[ .]+$'), '');
  if (name.isEmpty) name = fallback;
  const Set<String> reserved = <String>{
    'CON', 'PRN', 'AUX', 'NUL', //
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
  };
  final String stem = name.split('.').first.toUpperCase();
  if (reserved.contains(stem)) name = '_$name';
  return name;
}
