import 'dart:math' as math;

/// Tuning parameters for [EnvelopeGate]. All dB values are power dB.
final class EnvelopeGateConfig {
  const EnvelopeGateConfig({
    this.onDropDb = 6,
    this.offDropDb = 12,
    this.noiseMarginDb = 9,
    this.minContrastDb = 12,
    this.peakDecayDbPerSecond = 6,
    this.noiseAttack = 0.05,
    this.noiseRiseDbPerSecond = 2,
    this.noiseOutlierDb = 10,
    this.minOn = const Duration(milliseconds: 12),
    this.minOff = const Duration(milliseconds: 12),
    this.meterRangeDb = 30,
    this.noiseWarmup = Duration.zero,
  })  : assert(offDropDb > onDropDb, 'offDropDb must exceed onDropDb'),
        assert(noiseAttack > 0 && noiseAttack <= 1, 'noiseAttack in (0, 1]');

  /// Raw "on" when block power exceeds `peak - onDropDb`. 6 dB = a block
  /// that is at least half tone (power grows with duty^2), so mark edges are
  /// placed without bias.
  final double onDropDb;

  /// Raw "off" when block power drops below `peak - offDropDb` (hysteresis).
  final double offDropDb;

  /// Thresholds never sit closer than this to the noise estimate (on), or
  /// 3 dB less (off), so a decayed peak cannot drag them into the noise.
  final double noiseMarginDb;

  /// Gate stays closed until peak exceeds noise by this much. White-noise
  /// maxima hover ~8 dB above the noise mean, so 12 dB rejects pure noise.
  final double minContrastDb;

  /// AGC release: how fast the peak tracker forgets a loud signal.
  final double peakDecayDbPerSecond;

  /// EMA coefficient for the noise estimate on ordinary "off" blocks.
  final double noiseAttack;

  /// Slow creep of the noise estimate towards blocks it cannot trust (tone
  /// blocks and outliers), so a step change in background noise is
  /// eventually adopted instead of latching the gate.
  final double noiseRiseDbPerSecond;

  /// "Off" blocks more than this far above the noise estimate (edge blocks,
  /// clicks) only creep instead of feeding the fast EMA.
  final double noiseOutlierDb;

  /// Shortest tone / silence that is committed; anything briefer is a click
  /// or a dropout and is ignored. Rounded up to whole blocks.
  final Duration minOn;
  final Duration minOff;

  /// Meter scale: dB above the noise estimate that reads as 1.0 when the
  /// signal contrast is smaller than this.
  final double meterRangeDb;

  /// Optional, off by default (zero): the floor is then seeded from the
  /// first block, as it always was. Known limitation of that default: one
  /// unusually quiet first noise block can open the gate on plain noise
  /// (seen at 44.1 kHz as a spurious leading symbol). The warm-up fixes
  /// that case but costs early onsets at low sample rates and can mistake
  /// a steady noise run for a tone, so it is not enabled.
  ///
  /// When enabled, the first stretch is buffered before any decision. One block of white
  /// noise in a narrow bin is exponentially distributed and can sit 10 dB
  /// or more below the mean, so seeding the floor from the first block
  /// alone opens the gate on plain noise. The floor comes from the quiet
  /// blocks before a steady tone run when there is one (a tone may start
  /// in the very first milliseconds), otherwise from the mean of the
  /// stretch; the buffered blocks are then replayed through the gate, so
  /// an early onset keeps its exact block position.
  final Duration noiseWarmup;
}

/// A committed key state change. [atBlock] is the index (0-based, counting
/// blocks fed) of the first block of the new state, which is earlier than
/// the block during which it was committed.
final class GateTransition {
  const GateTransition({required this.isOn, required this.atBlock});

  final bool isOn;
  final int atBlock;

  @override
  String toString() => 'GateTransition(${isOn ? 'on' : 'off'} @ $atBlock)';
}

/// Turns a sequence of block powers into debounced on/off decisions.
///
/// Pipeline per block: clamp -> peak tracker (fast attack, slow release,
/// the AGC) -> noise tracker (EMA over quiet blocks, slow creep otherwise)
/// -> contrast check -> two-threshold raw decision relative to the peak,
/// floored at `noise + margin` -> minimum-duration debounce. Because the
/// thresholds ride on the tracked peak, a whisper-quiet and a clipping-loud
/// tone gate identically as long as the contrast to the noise floor holds.
final class EnvelopeGate {
  EnvelopeGate({
    required this.sampleRate,
    required this.blockSize,
    this.config = const EnvelopeGateConfig(),
  })  : assert(sampleRate > 0, 'sampleRate must be positive'),
        assert(blockSize > 0, 'blockSize must be positive'),
        minOnBlocks = _blocksFor(config.minOn, blockSize, sampleRate),
        minOffBlocks = _blocksFor(config.minOff, blockSize, sampleRate),
        warmupBlocks = config.noiseWarmup == Duration.zero
            ? 0
            : _blocksFor(config.noiseWarmup, blockSize, sampleRate),
        _peakDecay = _perBlock(-config.peakDecayDbPerSecond, blockSize, sampleRate),
        _noiseRise = _perBlock(config.noiseRiseDbPerSecond, blockSize, sampleRate),
        _onFactor = _fromDb(-config.onDropDb),
        _offFactor = _fromDb(-config.offDropDb),
        _noiseOnFactor = _fromDb(config.noiseMarginDb),
        _noiseOffFactor = _fromDb(config.noiseMarginDb - 3),
        _outlierFactor = _fromDb(config.noiseOutlierDb),
        _minContrastRatio = _fromDb(config.minContrastDb);

  /// Power values below this are treated as this (avoids log(0)).
  static const double floorPower = 1e-16;

  final int sampleRate;
  final int blockSize;
  final EnvelopeGateConfig config;

  /// Debounce lengths in blocks (at least 1).
  final int minOnBlocks;
  final int minOffBlocks;

  /// Blocks buffered before the first decision (see
  /// [EnvelopeGateConfig.noiseWarmup]).
  final int warmupBlocks;
  final List<double> _warmup = <double>[];
  final List<GateTransition> _queued = <GateTransition>[];

  final double _peakDecay;
  final double _noiseRise;
  final double _onFactor;
  final double _offFactor;
  final double _noiseOnFactor;
  final double _noiseOffFactor;
  final double _outlierFactor;
  final double _minContrastRatio;

  int _blocks = 0;
  double? _noise;
  double _peak = 0;
  double _lastPower = floorPower;
  bool _rawOn = false;
  bool _committedOn = false;
  int _candidateStart = -1;

  /// Blocks fed so far.
  int get blockCount => _blocks;

  /// Worst-case commit delay in blocks; consumers that time-stamp from the
  /// block clock should hold back their clock by this much.
  /// While the warm-up stretch is buffered nothing is decided yet.
  int get latencyBlocks =>
      math.max(minOnBlocks, minOffBlocks) +
      (_blocks < warmupBlocks ? warmupBlocks : 0);

  Duration get blockDuration => Duration(
        microseconds:
            (blockSize * Duration.microsecondsPerSecond / sampleRate).round(),
      );

  /// Committed (debounced) key state.
  bool get isOn => _committedOn;

  /// Current noise-floor and peak estimates (squared amplitude).
  double get noisePower => _noise ?? floorPower;
  double get peakPower => _peak;

  /// Peak over noise, in dB.
  double get contrastDb => _db(_peak / noisePower);

  /// Whether the contrast is high enough for the gate to open at all.
  bool get hasSignal => _peak / noisePower >= _minContrastRatio;

  /// Meter value 0..1: the last block's level above the noise estimate,
  /// scaled by the signal contrast (AGC) or by
  /// [EnvelopeGateConfig.meterRangeDb], whichever is larger.
  double get level {
    if (_noise == null) return 0;
    final double aboveNoise = _db(_lastPower / noisePower);
    final double range = math.max(contrastDb, config.meterRangeDb);
    return (aboveNoise / range).clamp(0.0, 1.0).toDouble();
  }

  /// Feeds one block's tone power (squared amplitude, as produced by
  /// `GoertzelDetector.power`) and returns every committed state change it
  /// settles (more than one only when the warm-up stretch is replayed).
  List<GateTransition> feedAll(double power) {
    final double p = power > floorPower ? power : floorPower;
    final int index = _blocks++;
    _lastPower = p;
    if (warmupBlocks > 0 && index < warmupBlocks) {
      _warmup.add(p);
      _peak = math.max(p, _peak * _peakDecay);
      if (index < warmupBlocks - 1) return const <GateTransition>[];
      _noise = _initialNoise(_warmup);
      _peak = 0;
      final List<GateTransition> out = <GateTransition>[];
      for (int i = 0; i < _warmup.length; i++) {
        final GateTransition? t = _step(_warmup[i], i);
        if (t != null) out.add(t);
      }
      _warmup.clear();
      return out;
    }
    final GateTransition? t = _step(p, index);
    return t == null ? const <GateTransition>[] : <GateTransition>[t];
  }

  /// [feedAll] returning one transition per call; extra transitions from
  /// a warm-up replay are handed out on the following calls (their
  /// [GateTransition.atBlock] keeps the true position).
  GateTransition? feed(double power) {
    _queued.addAll(feedAll(power));
    return _queued.isEmpty ? null : _queued.removeAt(0);
  }

  /// Noise floor for the warm-up stretch [w]: the quiet blocks before a
  /// steady run (>= [EnvelopeGateConfig.minContrastDb] above them, within
  /// 1 dB of each other) — a tone starting early — or the mean of all.
  double _initialNoise(List<double> w) {
    // A keyed tone is flat block to block; narrow-band noise is not (its
    // block powers are exponentially distributed), so four blocks within
    // 1 dB of each other almost never come from noise.
    final int run = math.max(4, minOnBlocks);
    final double steady = _fromDb(1);
    for (int j = 1; j + run <= w.length; j++) {
      final List<double> tone = w.sublist(j, j + run);
      final double lo = tone.reduce(math.min);
      final double hi = tone.reduce(math.max);
      if (hi / lo > steady) continue;
      // Quiet blocks: before the run and clearly below it (a block only
      // partly covered by the onset is neither).
      final List<double> quiet = <double>[
        for (final double x in w.sublist(0, j))
          if (x * _minContrastRatio <= lo) x,
      ];
      if (quiet.isEmpty) continue;
      return quiet.reduce((a, b) => a + b) / quiet.length;
    }
    return w.reduce((a, b) => a + b) / w.length;
  }

  GateTransition? _step(double p, int index) {
    if (_noise == null) {
      _noise = p;
      _peak = p;
    }
    _peak = math.max(p, _peak * _peakDecay);
    final double noise = _noise!;

    bool raw = false;
    if (_peak / noise >= _minContrastRatio) {
      final double onThreshold =
          math.max(_peak * _onFactor, noise * _noiseOnFactor);
      final double offThreshold =
          math.max(_peak * _offFactor, noise * _noiseOffFactor);
      raw = _rawOn ? p > offThreshold : p > onThreshold;
    }
    _rawOn = raw;

    if (!raw && p < noise * _outlierFactor) {
      _noise = noise + (p - noise) * config.noiseAttack;
    } else {
      _noise = math.min(p, noise * _noiseRise);
    }

    return _debounce(raw, index);
  }

  GateTransition? _debounce(bool raw, int index) {
    if (raw == _committedOn) {
      _candidateStart = -1;
      return null;
    }
    if (_candidateStart < 0) _candidateStart = index;
    final int run = index - _candidateStart + 1;
    final int needed = raw ? minOnBlocks : minOffBlocks;
    if (run < needed) return null;
    _committedOn = raw;
    final int at = _candidateStart;
    _candidateStart = -1;
    return GateTransition(isOn: raw, atBlock: at);
  }

  /// Forgets every estimate and the key state; the block counter restarts.
  void reset() {
    _blocks = 0;
    _noise = null;
    _warmup.clear();
    _queued.clear();
    _peak = 0;
    _lastPower = floorPower;
    _rawOn = false;
    _committedOn = false;
    _candidateStart = -1;
  }

  static int _blocksFor(Duration d, int blockSize, int sampleRate) {
    final double blockUs = blockSize * Duration.microsecondsPerSecond / sampleRate;
    return math.max(1, (d.inMicroseconds / blockUs).ceil());
  }

  static double _perBlock(double dbPerSecond, int blockSize, int sampleRate) =>
      _fromDb(dbPerSecond * blockSize / sampleRate);

  static double _fromDb(double db) => math.pow(10, db / 10).toDouble();

  static double _db(double ratio) =>
      ratio <= 0 ? -160 : 10 * math.log(ratio) / math.ln10;
}
