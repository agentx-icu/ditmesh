[简体中文](./README.zh-CN.md)

# morse_dsp

Pure-Dart audio Morse decoding for the DitMesh workspace: 16-bit PCM from a
microphone (or a file) goes in, decoded text comes out. No Flutter imports —
`dart test` runs it, and the app only adds the capture layer on top.

## Pipeline

```text
                 ┌──────────────┐
 pcm16 / bytes ─►│  downmix to  │──► SampleBuffer (carries partial blocks)
 (N channels)    │ mono double  │
                 └──────────────┘
                        │  blocks of `blockSize` samples (256 @ 48 kHz ≈ 5.3 ms)
                        ▼
      ┌───────────────────────────────┐        ┌────────────────────────────┐
      │ GoertzelDetector.power(block) │◄─tune──│ ToneFinder (auto-tune)     │
      │ squared tone amplitude, 0..1  │        │ 25 Goertzels over 400–1000 │
      └───────────────────────────────┘        │ Hz, Hann 2048-sample window│
                        │                      │ lock / unlock hysteresis   │
                        ▼                      └────────────────────────────┘
      ┌───────────────────────────────┐
      │ EnvelopeGate.feed(power)      │  peak tracker (AGC) + noise tracker
      │ → GateTransition(on/off, blk) │  → contrast check → two thresholds
      └───────────────────────────────┘  → min on/off debounce
                        │  block index × blockSize / sampleRate  (sample clock)
                        ▼
      ┌───────────────────────────────┐
      │ MorseDecoder (morse_core)     │  keyDown / keyUp / tick
      │ .text .pendingPattern .events │
      └───────────────────────────────┘
```

`AudioMorseDecoder` is the façade that owns all four stages. Time is derived
from the number of samples consumed, never from the wall clock, so the same
bytes always decode to the same text no matter how they are chunked.

```dart
final decoder = AudioMorseDecoder();               // 48 kHz, 256-sample blocks
recorderStream.listen((bytes) => decoder.feedBytes(bytes));
decoder.events.listen((e) => print(decoder.text)); // or poll .text
```

## Parameters

| Component | Parameter | Default | Meaning |
|-----------|-----------|---------|---------|
| `AudioMorseDecoder` | `sampleRate` | 48000 | Input rate; every stage derives its timing from it |
| | `blockSize` | 256 | Samples per gate decision (5.3 ms). Smaller = finer edges, noisier |
| | `autoTune` | true | Let `ToneFinder` pick the frequency |
| | `manualFrequencyHz` | 700 | Used when auto-tune is off, and as the fallback before a tone is found |
| `GoertzelDetector` | `frequencyHz` | — | Bin centre; bandwidth is `sampleRate / blockSize` (187.5 Hz) |
| `ToneFinderConfig` | `minHz` / `maxHz` / `stepHz` | 400 / 1000 / 25 | Scan band and candidate spacing (25 candidates) |
| | `windowSamples` | 2048 | Analysis window (42.7 ms, 23 Hz bins, Hann) |
| | `lockWindows` | 3 | Agreeing tone windows before locking |
| | `unlockWindows` | 6 | Agreeing windows on *another* tone before the lock moves; silence never counts |
| | `toleranceHz` | 50 | "Same tone" distance |
| | `minPeakDb` | −70 | Below this (dBFS) nothing is a tone |
| | `minProminenceDb` | 12 | Peak must beat the median candidate by this much (rejects white-noise maxima) |
| `EnvelopeGateConfig` | `onDropDb` / `offDropDb` | 6 / 12 | Raw on above `peak − 6 dB`, off below `peak − 12 dB` (hysteresis). 6 dB = a block that is ≥ 50 % tone, so edges are placed without bias |
| | `noiseMarginDb` | 9 | Thresholds never sit closer than this to the noise estimate (off: −3 dB) |
| | `minContrastDb` | 12 | Peak must exceed noise by this much or the gate stays closed |
| | `peakDecayDbPerSecond` | 6 | AGC release |
| | `noiseAttack` | 0.05 | EMA coefficient of the noise tracker on quiet blocks |
| | `noiseRiseDbPerSecond` | 2 | Creep towards untrusted (tone / outlier) blocks so a noise step is eventually adopted |
| | `noiseOutlierDb` | 10 | Quiet blocks further above the noise estimate than this only creep |
| | `minOn` / `minOff` | 12 ms / 12 ms | Debounce: shorter tones / gaps are clicks / dropouts (rounded up to blocks) |
| | `meterRangeDb` | 30 | Meter full-scale when the contrast is smaller |
| `SyntheticMorse` (testing) | `toneHz` / `amplitude` / `snrDb` / `seed` | 700 / 0.4 / null / 1 | Renders `List<MorseElement>` to PCM16 with raised-cosine key ramps and seeded Gaussian noise |

SNR in `SyntheticMorse` is tone power over *wideband* noise power. The
detector only sees the noise inside its ~188 Hz bin, so a 6 dB wideband SNR
is about 27 dB in-bin; the design limit is roughly 0 dB wideband for
256-sample blocks.

## Speeds

The `morse_core` decoder adapts its dit estimate from the marks it sees and is
seeded at 80 ms (15 WPM). With 5.3 ms blocks and 12 ms debounce the pipeline
tracks 5–40 WPM. A transmission whose *first* character starts with a dah at a
speed far from 15 WPM can mis-decode that one character; everything after the
first dit-carrying character is fine.

## Limits

* **One signal at a time.** There is no multi-signal separation: the tone
  finder locks the dominant tone in 400–1000 Hz and the gate keys on that one
  bin. Two stations in the passband decode as garbage.
* **Keyed tones only.** A continuous carrier is adopted as "noise" by the
  tracker after a few seconds (`noiseRiseDbPerSecond`) and stops gating.
* **Speech, music, clicks.** Anything with energy in the bin that lasts longer
  than `minOn` will produce marks. Debounce rejects clicks, not talk.
* **Frequency range.** 400–1000 Hz by default; retune `ToneFinderConfig` (and
  keep `windowSamples` ≥ `sampleRate / stepHz` so a tone half-way between
  candidates still lands in both main lobes).
* **Sample rate must match.** Feeding 44.1 kHz audio to a 48 kHz decoder
  shifts the tone band and the timing by 8 %; construct the decoder with the
  recorder's real rate.
* **Timing resolution is one block.** Mark edges are quantised to `blockSize`
  samples (5.3 ms); above ~40 WPM use 128-sample blocks.

## Testing

```bash
cd packages/morse_dsp && dart test
```

Round-trip tests render a sentence with `SyntheticMorse` at 15 and 25 WPM,
600 and 800 Hz, 20 and 6 dB SNR (plus stereo downmix, quiet/loud, manual
tune, chunk-size determinism) and expect the exact text back.
