[简体中文](./README.zh-CN.md)

# morse_core

Pure-Dart Morse code engine for DitMesh: alphabet, PARIS / Farnsworth timing,
text → timeline encoder and a streaming decoder for hand-keyed input. No
Flutter dependency, so it runs in the app, in `morse_trainer` / `morse_io`
and in plain `dart test`.

## API overview

| Symbol | Purpose |
| --- | --- |
| `MorseAlphabet` | `international` (A–Z, 0–9, ITU punctuation), `prosigns` (AR, SK, BT, KN, AS, SN, SOS, CT, HH), `kochOrder` (LCWO sequence, 43 entries), `encodeChar` / `encodeProsign` / `decodePattern` / `decodeProsignPattern`. |
| `MorseTiming` | `wpm` + optional `farnsworthWpm`. `dit`, `dah`, `intraGap`, `charGap`, `wordGap` as `Duration` (rounded to µs); `ditMs` as a double. |
| `MorseElement` / `MorseElementKind` | One on/off segment of a timeline: `dit`, `dah`, `intraGap`, `charGap`, `wordGap`. |
| `MorseEncoder` | `toPattern("SOS")` → `"... --- ..."`, `encode(text, timing)` → `List<MorseElement>`, `totalDuration`. |
| `MorseDecoder` / `DecoderConfig` / `DecodeEvent` | Streaming decoder: `keyDown(at)` / `keyUp(at)` / `tick(now)` / `flush()`; `text`, `pendingPattern`, `estimatedDit`, `events`. |
| `ChineseTelegraphCode` / `TelegraphCodebook` / `TelegraphUnit` | Chinese telegraph code (中文电码): `codeOf('中')` → `'0022'`, `charsOf('0948')`, `encode(text)`, `transliterate('CQ 中文')` → `'CQ 0022 2429'` (what goes on the key), `decode('0022 2429')`. Mainland (1983) and Taiwan / HK codebooks; tables generated from Unicode Unihan (`kMainlandTelegraph` / `kTaiwanTelegraph`) by `tool/gen_telegraph_table.dart` into `src/telegraph/telegraph_table.g.dart` (Unicode License v3, notice in `THIRD_PARTY_NOTICES.md`). |

Prosigns are written in angle brackets in text (`CQ <AR>`) and decode back to
the same form. Words in a pattern string are separated by ` / `.

## Timing

* `dit = 1200 / wpm` ms; dah = 3 dit; intra-character gap = 1 dit;
  character gap = 3 dit; word gap = 7 dit.
* Farnsworth (`farnsworthWpm < wpm`), ARRL formula with `c = wpm`,
  `s = farnsworthWpm`: the 19 gap units of PARIS get
  `ta = (60c − 37.2s) / (s·c)` seconds in total, so
  `charGap = 3·ta/19`, `wordGap = 7·ta/19` (ratio stays 3:7). Elements and
  intra gaps are unchanged. With `c == s` this collapses to the standard gaps.
* A timeline never starts or ends with a gap; a word gap replaces the
  preceding character gap. `PARIS` alone is therefore 43 dit; the canonical
  50-dit word includes the 7-dit word gap that follows it.

## Decoder algorithm

Input is a sequence of monotonic `keyDown` / `keyUp` timestamps; `tick(now)`
lets a silence resolve into a character or word boundary before the next key
press, and `flush()` commits the last character.

* **Dit estimate.** The last 32 mark durations are split into a short and a
  long cluster with a two-centroid 1-D k-means, seeded at the current
  estimate `d` and `3d`. The clustering runs on `log(duration)`: keying jitter
  is proportional to element length, so on a linear scale the dah cluster is
  three times wider than the dit cluster and a midpoint boundary sits inside
  the dahs (each absorbed dah pulls the estimate up, moving the boundary
  further in). On a log scale both clusters have equal width and the boundary
  falls at the geometric mean (~1.73 dit), in the empty band between them.
  `estimatedDit` is the arithmetic mean of the short cluster. If the marks all
  look alike (long/short mean ratio < 2), they are dits when shorter than the
  dah threshold derived from the current estimate, otherwise dahs (estimate =
  mean / 3). The overall median is never used, so dah-heavy text
  (`OTTO 000 MOM`) does not bias the estimate. If the seeded boundary leaves
  one cluster empty, the split is re-seeded from the sample extremes so a bad
  prior self-corrects. `adaptive: false` pins the estimate to `initialDit`.
* **Thresholds** sit at midpoints: mark ≥ `ditDahThreshold` (2.0) × dit is a
  dah; gap ≥ `charGapThreshold` (2.0) × dit ends a character; gap ≥
  `wordGapThreshold` (5.0) × dit ends a word.
* **Farnsworth adaptation.** The last 64 gaps are kept. Gaps under the
  char-gap multiple are intra gaps; the rest are split into a char-gap and a
  word-gap cluster (same k-means, seeded at `3d` / `7d`). When both clusters
  are evident (ratio ≥ 1.8) and the char-gap cluster is clearly longer than
  3 dit (> 4 dit), the thresholds move to the midpoints between the observed
  intra / char and char / word clusters; otherwise the configured multiples
  apply. `isFarnsworthAdapted`, `charGapThreshold` and `wordGapThreshold`
  expose the effective values.
* **Confidence** is 1.0 when a mark is at least 50 % away from its threshold,
  falling linearly to 0.5 at the threshold. A character event carries the
  weakest of its elements' confidences. Word events carry 1.0: a boundary is
  reported the moment the silence crosses the threshold, when the final gap
  length is not yet known.
* **Events** (`events` is a synchronous broadcast stream): `element` on every
  key-up, `character` when a character gap resolves (`text` = the character,
  or `<NAME>` for a prosign), `unknownPattern` for an undecodable pattern
  (`text` = `<PATTERN>`, also appended to `text`), `word` with `text = ' '`.

### Cold start and seeding

The very first mark is judged only against `DecoderConfig.initialDit`
(80 ms ≈ 15 WPM by default). A trainer that knows the lesson speed should
pass `initialDit: timing.dit`. Farnsworth spacing is recognised once one
real word gap has been observed after some character gaps: before that, a
12-dit character gap is indistinguishable from a slow word gap, so the first
word of a cold Farnsworth run may come out letter-spaced. `clearText()` drops
the decoded text but keeps the learned timing, for exactly that warm-up case;
`reset()` forgets everything.

### Jitter tolerance (measured, 213-char corpus, 20 seeds)

| Jitter model | ±20 % | ±30 % | ±35 % |
| --- | --- | --- | --- |
| Triangular (human-like, bounded) | 100 % | min 99.1 % | min 96.7 %, mean 98.5 % |
| Uniform (every extreme equally likely) | 100 % | min 95.3 %, mean 98.3 % | min 82 %, mean 90.5 % |

Uniform ±35 % is past what fixed 2.0-dit midpoints can do: a 3-unit dah or
character gap lands at 1.95 dit as often as anywhere else in its band. The
estimator stays locked in that regime (no collapse), which is what the test
suite pins down.

## Running the tests

```bash
export PATH=/home/user/flutter/bin:$PATH
cd /path/to/ditmesh && dart pub get          # workspace root
cd packages/morse_core
dart analyze .
dart test
```
