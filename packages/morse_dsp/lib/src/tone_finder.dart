import 'dart:math' as math;
import 'dart:typed_data';

import 'goertzel.dart';

/// Tuning parameters for [ToneFinder].
final class ToneFinderConfig {
  const ToneFinderConfig({
    this.minHz = 400,
    this.maxHz = 1000,
    this.stepHz = 25,
    this.windowSamples = 2048,
    this.lockWindows = 3,
    this.unlockWindows = 6,
    this.toleranceHz = 50,
    this.minPeakDb = -70,
    this.minProminenceDb = 12,
  })  : assert(maxHz > minHz, 'maxHz must exceed minHz'),
        assert(stepHz > 0, 'stepHz must be positive'),
        assert(windowSamples > 0, 'windowSamples must be positive'),
        assert(lockWindows > 0, 'lockWindows must be positive'),
        assert(unlockWindows > 0, 'unlockWindows must be positive');

  /// Scan range (inclusive) and candidate spacing.
  final double minHz;
  final double maxHz;
  final double stepHz;

  /// Analysis window length in samples. 2048 @ 48 kHz = 42.7 ms, giving a
  /// 23 Hz bin (about one [stepHz]) so a tone half-way between two candidates
  /// still lands inside the Hann main lobe of both.
  final int windowSamples;

  /// Tone windows (not necessarily consecutive) whose peaks agree within
  /// [toleranceHz] before the finder locks.
  final int lockWindows;

  /// Tone windows that agree on a *different* frequency before a lock moves.
  /// Silence never counts, so gaps inside a transmission cannot unlock.
  final int unlockWindows;

  /// How far a peak may sit from the locked (or candidate) frequency and
  /// still be considered the same tone.
  final double toleranceHz;

  /// Peaks below this (dB re full-scale sine) are never tones.
  final double minPeakDb;

  /// A peak must exceed the median of all candidate powers by this many dB
  /// to count as a tone. 12 dB keeps white-noise maxima (which sit ~7 dB
  /// above the median across 25 bins) from producing phantom tones.
  final double minProminenceDb;

  int get candidateCount => ((maxHz - minHz) / stepHz).floor() + 1;
}

/// Result of analysing one window.
final class ToneScan {
  const ToneScan({
    required this.frequencyHz,
    required this.peakDb,
    required this.medianDb,
    required this.isTone,
  });

  /// Interpolated frequency of the strongest candidate.
  final double frequencyHz;

  /// Power of that candidate, dB re full-scale sine.
  final double peakDb;

  /// Median power across all candidates (noise reference).
  final double medianDb;

  /// Whether the peak passed the level and prominence tests.
  final bool isTone;

  double get prominenceDb => peakDb - medianDb;

  @override
  String toString() =>
      'ToneScan(${frequencyHz.toStringAsFixed(1)} Hz, peak '
      '${peakDb.toStringAsFixed(1)} dB, median ${medianDb.toStringAsFixed(1)} '
      'dB, tone: $isTone)';
}

/// Auto-tune: finds the dominant tone in a band and holds on to it.
///
/// Samples are accumulated into non-overlapping Hann-windowed analysis
/// windows; each window is scanned with one [GoertzelDetector] per candidate
/// frequency. A lock needs [ToneFinderConfig.lockWindows] agreeing tone
/// windows and is only released after [ToneFinderConfig.unlockWindows]
/// windows agree on another frequency, so the estimate cannot jump around
/// mid-transmission. Setting [manualFrequencyHz] overrides everything.
final class ToneFinder {
  ToneFinder({this.sampleRate = 48000, this.config = const ToneFinderConfig()})
      : _window = Float64List(config.windowSamples),
        _scratch = Float64List(config.windowSamples),
        _hann = _makeHann(config.windowSamples),
        _detectors = List<GoertzelDetector>.generate(
          config.candidateCount,
          (int i) => GoertzelDetector(
            frequencyHz: config.minHz + i * config.stepHz,
            sampleRate: sampleRate,
            blockSize: config.windowSamples,
          ),
          growable: false,
        ),
        _powersDb = Float64List(config.candidateCount);

  final int sampleRate;
  final ToneFinderConfig config;

  final Float64List _window;
  final Float64List _scratch;
  final Float64List _hann;
  final List<GoertzelDetector> _detectors;
  final Float64List _powersDb;

  int _fill = 0;
  double? _locked;
  double? _provisional;
  double? _candidate;
  double _candidateSum = 0;
  int _candidateRuns = 0;
  ToneScan? _lastScan;

  /// Manual override. While set, [frequencyHz] returns it and scans no
  /// longer move the lock (they still update [lastScan]).
  double? manualFrequencyHz;

  /// Locked tone, if any.
  double? get lockedFrequencyHz => _locked;

  bool get isLocked => _locked != null;

  /// Most recent completed window analysis.
  ToneScan? get lastScan => _lastScan;

  /// Best current estimate: manual override, else the lock, else the latest
  /// provisional peak (so decoding can start before the lock settles). Null
  /// until a tone has been seen.
  double? get frequencyHz => manualFrequencyHz ?? _locked ?? _provisional;

  /// Accumulates mono samples. Returns true when [frequencyHz] changed.
  bool feed(List<double> samples, {int offset = 0, int? length}) {
    final int n = length ?? (samples.length - offset);
    RangeError.checkValidRange(offset, offset + n, samples.length);
    final double? before = frequencyHz;
    int i = offset;
    final int end = offset + n;
    while (i < end) {
      final int take = math.min(end - i, _window.length - _fill);
      _window.setRange(_fill, _fill + take, samples, i);
      _fill += take;
      i += take;
      if (_fill == _window.length) {
        _fill = 0;
        _onScan(scan(_window));
      }
    }
    return _changed(before, frequencyHz);
  }

  /// Analyses one full window (length [ToneFinderConfig.windowSamples])
  /// without touching the lock state. Public so tests and tools can inspect
  /// the spectrum decision directly.
  ToneScan scan(List<double> window, {int offset = 0}) {
    final int n = _window.length;
    RangeError.checkValidRange(offset, offset + n, window.length);
    // Hann window with x2 coherent-gain compensation so peak levels stay
    // comparable to the rectangular-window GoertzelDetector.
    for (int i = 0; i < n; i++) {
      _scratch[i] = window[offset + i] * _hann[i] * 2;
    }
    int peakIndex = 0;
    double peakDb = double.negativeInfinity;
    for (int k = 0; k < _detectors.length; k++) {
      final double db = GoertzelDetector.toDb(_detectors[k].power(_scratch));
      _powersDb[k] = db;
      if (db > peakDb) {
        peakDb = db;
        peakIndex = k;
      }
    }
    final double medianDb = _median(_powersDb);
    final double frequencyHz = _interpolate(peakIndex);
    final bool isTone = peakDb >= config.minPeakDb &&
        peakDb - medianDb >= config.minProminenceDb;
    return ToneScan(
      frequencyHz: frequencyHz,
      peakDb: peakDb,
      medianDb: medianDb,
      isTone: isTone,
    );
  }

  /// Forgets the lock, the candidate history and buffered samples. The
  /// manual override is kept.
  void reset() {
    _fill = 0;
    _locked = null;
    _provisional = null;
    _candidate = null;
    _candidateSum = 0;
    _candidateRuns = 0;
    _lastScan = null;
  }

  void _onScan(ToneScan scan) {
    _lastScan = scan;
    if (!scan.isTone) return; // Silence never changes the lock.
    final double f = scan.frequencyHz;
    _provisional = f;

    final double? locked = _locked;
    if (locked != null && (f - locked).abs() <= config.toleranceHz) {
      _candidate = null;
      _candidateRuns = 0;
      return;
    }

    final double? candidate = _candidate;
    if (candidate != null && (f - candidate).abs() <= config.toleranceHz) {
      _candidateRuns++;
      _candidateSum += f;
    } else {
      _candidate = f;
      _candidateSum = f;
      _candidateRuns = 1;
    }
    final int needed = locked == null ? config.lockWindows : config.unlockWindows;
    if (_candidateRuns >= needed) {
      _locked = _candidateSum / _candidateRuns;
      _candidate = null;
      _candidateSum = 0;
      _candidateRuns = 0;
    }
  }

  /// Parabolic interpolation on the dB values around the peak bin.
  double _interpolate(int k) {
    final double base = config.minHz + k * config.stepHz;
    if (k <= 0 || k >= _powersDb.length - 1) return base;
    final double a = _powersDb[k - 1];
    final double b = _powersDb[k];
    final double c = _powersDb[k + 1];
    final double denom = a - 2 * b + c;
    if (denom >= 0 || !denom.isFinite) return base;
    final double delta = (0.5 * (a - c) / denom).clamp(-0.5, 0.5).toDouble();
    return base + delta * config.stepHz;
  }

  static bool _changed(double? before, double? after) {
    if (before == null || after == null) return before != after;
    return (before - after).abs() > 0.5;
  }

  static double _median(Float64List values) {
    final Float64List sorted = Float64List.fromList(values)..sort();
    final int mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static Float64List _makeHann(int n) {
    final Float64List w = Float64List(n);
    if (n == 1) {
      w[0] = 1;
      return w;
    }
    for (int i = 0; i < n; i++) {
      w[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
    }
    return w;
  }
}
