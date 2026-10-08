import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:morse_core/morse_core.dart';

/// Receive-practice channel presets (F11). [clear] is the default and plays
/// exactly like ordinary practice.
enum RadioPreset {
  clear,

  /// Light background noise and gentle fading.
  light,

  /// Stronger noise, deeper fading, one adjacent interfering signal and
  /// small timing variation.
  radio;

  static RadioPreset parse(String? name) => values.firstWhere(
    (p) => p.name == name,
    orElse: () => RadioPreset.clear,
  );
}

/// One immutable, reproducible channel scenario. The same [version],
/// settings and [seed] render the same exercise (timing exactly; audio
/// samples up to floating-point rounding of the platform's `sin`).
///
/// Speeds and tone are the learner's own; conditions never change them.
@immutable
final class RadioScenario {
  const RadioScenario({
    required this.preset,
    required this.seed,
    required this.characterWpm,
    required this.effectiveWpm,
    required this.toneHz,
    this.noise = 0,
    this.fadeDepth = 0,
    this.fadePeriod = const Duration(seconds: 6),
    this.interference = 0,
    this.interferenceOffsetHz = 0,
    this.timingVariation = 0,
    this.version = currentVersion,
  });

  /// The scenario a [preset] stands for at the learner's speeds and tone.
  factory RadioScenario.preset(
    RadioPreset preset, {
    required int seed,
    required double characterWpm,
    required double effectiveWpm,
    required double toneHz,
  }) => switch (preset) {
    RadioPreset.clear => RadioScenario(
      preset: preset,
      seed: seed,
      characterWpm: characterWpm,
      effectiveWpm: effectiveWpm,
      toneHz: toneHz,
    ),
    RadioPreset.light => RadioScenario(
      preset: preset,
      seed: seed,
      characterWpm: characterWpm,
      effectiveWpm: effectiveWpm,
      toneHz: toneHz,
      noise: 0.25,
      fadeDepth: 0.35,
      fadePeriod: const Duration(seconds: 7),
    ),
    RadioPreset.radio => RadioScenario(
      preset: preset,
      seed: seed,
      characterWpm: characterWpm,
      effectiveWpm: effectiveWpm,
      toneHz: toneHz,
      noise: 0.5,
      fadeDepth: 0.6,
      fadePeriod: const Duration(seconds: 5),
      interference: 0.35,
      interferenceOffsetHz: 180,
      timingVariation: 0.12,
    ),
  };

  static const int currentVersion = 1;

  /// Bounds every renderer and parser enforces.
  static const double maxNoise = 1;
  static const double maxFadeDepth = 0.9;
  static const double maxInterference = 0.8;
  static const double maxTimingVariation = 0.25;

  final int version;
  final RadioPreset preset;
  final int seed;
  final double characterWpm;
  final double effectiveWpm;
  final double toneHz;

  /// Background noise relative to the signal's peak (0..[maxNoise]).
  final double noise;

  /// How far the signal fades at its weakest (0..[maxFadeDepth]).
  final double fadeDepth;
  final Duration fadePeriod;

  /// Level of one interfering Morse signal (0..[maxInterference]).
  final double interference;
  final double interferenceOffsetHz;

  /// Largest relative change of one element's duration
  /// (0..[maxTimingVariation]).
  final double timingVariation;

  bool get isClear =>
      noise == 0 && fadeDepth == 0 && interference == 0 && timingVariation == 0;

  MorseTiming get timing => MorseTiming(
    wpm: characterWpm,
    farnsworthWpm: effectiveWpm < characterWpm ? effectiveWpm : null,
  );

  /// The scenario of round [index] of a session: same channel, its own seed.
  RadioScenario forRound(int index) => RadioScenario(
    preset: preset,
    seed: seed + index * 7919,
    characterWpm: characterWpm,
    effectiveWpm: effectiveWpm,
    toneHz: toneHz,
    noise: noise,
    fadeDepth: fadeDepth,
    fadePeriod: fadePeriod,
    interference: interference,
    interferenceOffsetHz: interferenceOffsetHz,
    timingVariation: timingVariation,
    version: version,
  );

  /// Key under which comparable results are grouped (same channel and
  /// speeds; the seed does not matter).
  String get comparableKey =>
      'v$version/${preset.name}/'
      '${characterWpm.toStringAsFixed(1)}/${effectiveWpm.toStringAsFixed(1)}';

  Map<String, Object?> toJson() => {
    'v': version,
    'preset': preset.name,
    'seed': seed,
    'characterWpm': characterWpm,
    'effectiveWpm': effectiveWpm,
    'toneHz': toneHz,
    'noise': noise,
    'fadeDepth': fadeDepth,
    'fadePeriodMs': fadePeriod.inMilliseconds,
    'interference': interference,
    'interferenceOffsetHz': interferenceOffsetHz,
    'timingVariation': timingVariation,
  };

  /// Null for malformed input; out-of-range values are clamped.
  static RadioScenario? fromJson(Object? json) {
    if (json is! Map) return null;
    double n(String k, double max) {
      final v = json[k];
      return v is num && v.isFinite ? v.toDouble().clamp(0, max) : 0;
    }

    final seed = json['seed'];
    final cw = json['characterWpm'];
    final ew = json['effectiveWpm'];
    final tone = json['toneHz'];
    if (seed is! int || cw is! num || ew is! num || tone is! num) return null;
    final period = json['fadePeriodMs'];
    return RadioScenario(
      version: json['v'] is int ? json['v']! as int : currentVersion,
      preset: RadioPreset.parse(
        json['preset'] is String ? json['preset']! as String : null,
      ),
      seed: seed,
      characterWpm: cw.toDouble(),
      effectiveWpm: ew.toDouble(),
      toneHz: tone.toDouble(),
      noise: n('noise', maxNoise),
      fadeDepth: n('fadeDepth', maxFadeDepth),
      fadePeriod: Duration(
        milliseconds: period is int && period >= 1000 ? period : 6000,
      ),
      interference: n('interference', maxInterference),
      interferenceOffsetHz: n('interferenceOffsetHz', 1000),
      timingVariation: n('timingVariation', maxTimingVariation),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RadioScenario && _same(toJson(), other.toJson());

  static bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

/// Bounded, seeded timing variation of a timeline.
abstract final class RadioTiming {
  /// [timeline] with each element's duration scaled by a factor in
  /// `[1 - v, 1 + v]` (v = [RadioScenario.timingVariation], bounded). The
  /// element order and kinds never change and every duration stays
  /// positive, so symbols can neither reorder nor vanish.
  static List<MorseElement> vary(
    List<MorseElement> timeline,
    RadioScenario scenario,
  ) {
    final v = scenario.timingVariation.clamp(
      0.0,
      RadioScenario.maxTimingVariation,
    );
    if (v == 0) return List<MorseElement>.of(timeline);
    final rng = Random(scenario.seed ^ 0x5eed);
    return [
      for (final e in timeline)
        MorseElement(
          e.kind,
          Duration(
            microseconds: max(
              1,
              (e.duration.inMicroseconds * (1 + v * (rng.nextDouble() * 2 - 1)))
                  .round(),
            ),
          ),
        ),
    ];
  }
}

/// Renders a scenario to mono PCM (pure Dart; the app plays the WAV through
/// `morse_io`). The target signal and every added effect are generated
/// separately and mixed with a fixed headroom, then scaled down if needed
/// so the result never clips and never peaks above a clean rendering.
abstract final class RadioRenderer {
  static const int sampleRate = 22050;

  /// Peak of a clean rendering; a noisy one never exceeds it.
  static const double cleanPeak = 0.5;
  static const Duration ramp = Duration(milliseconds: 5);

  /// Text the interfering station keys over and over.
  static const String interfererText = 'CQ TEST DE DL0XX K';

  static int _n(Duration d) =>
      (d.inMicroseconds * sampleRate / Duration.microsecondsPerSecond).round();

  /// Samples in [-1, 1] for [text] under [scenario], with lead-in and tail.
  static Float32List render(
    String text,
    RadioScenario scenario, {
    Duration leadIn = const Duration(milliseconds: 400),
    Duration tail = const Duration(milliseconds: 400),
  }) {
    final target = RadioTiming.vary(
      MorseEncoder.encode(text, scenario.timing),
      scenario,
    );
    final lead = _n(leadIn);
    var total = lead + _n(tail);
    for (final e in target) {
      total += _n(e.duration);
    }
    final out = Float32List(total);
    final rng = Random(scenario.seed);
    _keyed(out, target, lead, scenario.toneHz, 1);

    final fade = scenario.fadeDepth.clamp(0.0, RadioScenario.maxFadeDepth);
    if (fade > 0) {
      final period = max(1, _n(scenario.fadePeriod));
      final phase = rng.nextDouble() * 2 * pi;
      for (var i = 0; i < total; i++) {
        final w = 0.5 - 0.5 * cos(2 * pi * i / period + phase);
        out[i] *= 1 - fade * w;
      }
    }
    final level = scenario.interference.clamp(
      0.0,
      RadioScenario.maxInterference,
    );
    if (level > 0) {
      final other = Float32List(total);
      final timing = MorseTiming(wpm: max(12, scenario.characterWpm - 4));
      final qrm = MorseEncoder.encode(interfererText, timing);
      var cursor = -rng.nextInt(max(1, _n(MorseEncoder.totalDuration(qrm))));
      while (cursor < total) {
        _keyed(other, qrm, cursor, scenario.toneHz + scenario.interferenceOffsetHz, level);
        cursor += _n(MorseEncoder.totalDuration(qrm)) + _n(timing.wordGap);
      }
      for (var i = 0; i < total; i++) {
        out[i] += other[i];
      }
    }
    final noise = scenario.noise.clamp(0.0, RadioScenario.maxNoise);
    if (noise > 0) {
      // Gaussian noise through a one-pole low-pass: a soft hiss rather than
      // a harsh white noise.
      var y = 0.0;
      for (var i = 0; i < total; i++) {
        final u1 = max(1e-12, rng.nextDouble());
        final u2 = rng.nextDouble();
        final g = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
        y += 0.35 * (g - y);
        out[i] += noise * 0.6 * y;
      }
    }
    var peak = 0.0;
    for (final v in out) {
      peak = max(peak, v.abs());
    }
    final scale = peak == 0 ? 0.0 : cleanPeak / max(peak, 1.0);
    for (var i = 0; i < total; i++) {
      out[i] = (out[i] * scale).clamp(-cleanPeak, cleanPeak);
    }
    return out;
  }

  static void _keyed(
    Float32List into,
    List<MorseElement> timeline,
    int start,
    double hz,
    double gain,
  ) {
    final omega = 2 * pi * hz / sampleRate;
    final rampN = _n(ramp);
    var cursor = start;
    for (final e in timeline) {
      final n = _n(e.duration);
      if (e.on) {
        final r = min(rampN, n ~/ 2);
        for (var i = 0; i < n; i++) {
          final at = cursor + i;
          if (at < 0 || at >= into.length) continue;
          final env = i < r
              ? 0.5 - 0.5 * cos(pi * i / r)
              : i >= n - r
              ? 0.5 - 0.5 * cos(pi * (n - i) / r)
              : 1.0;
          into[at] += gain * env * sin(omega * i);
        }
      }
      cursor += n;
    }
  }

  /// PCM16 mono WAV bytes of [samples].
  static Uint8List wav(Float32List samples) {
    final out = Uint8List(44 + samples.length * 2);
    final d = ByteData.sublistView(out);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        d.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    d.setUint32(4, 36 + samples.length * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, sampleRate, Endian.little);
    d.setUint32(28, sampleRate * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    d.setUint32(40, samples.length * 2, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      d.setInt16(44 + i * 2, (samples[i] * 32767).round(), Endian.little);
    }
    return out;
  }

  /// Length of [samples] at [sampleRate].
  static Duration lengthOf(Float32List samples) => Duration(
    microseconds: samples.length * Duration.microsecondsPerSecond ~/ sampleRate,
  );
}
