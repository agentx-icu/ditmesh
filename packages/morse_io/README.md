[简体中文](./README.zh-CN.md)

# morse_io

Flutter I/O layer shared by DitMesh and MorseCQ (one identical copy in each
repository): renders `morse_core` timelines to **sound**,
**haptics** and **light**, and turns on-screen / keyboard **keying** into
`MorseDecoder` events. Targets Android, iOS, macOS, Windows and Linux.

## Architecture

```
                 List<MorseElement>            paddles / key / keyboard
                        │                                 │
                  ┌─────▼─────┐                 ┌─────────▼─────────┐
                  │MorsePlayer│                 │ StraightKey       │
                  │ (Clock)   │                 │ IambicKeyer(Clock)│
                  └──┬─────┬──┘                 └───┬───────────┬───┘
     PlayerEvent ◄───┘     │ on()/off()             │ on()/off() │ keyDown/keyUp(at)
                           ▼                        ▼            ▼
                       MorseSink ◄──────────────────┘        KeyTarget ─► MorseDecoder
              ┌───────────┼──────────────┬─────────────┐
        SidetoneSink  HapticSink     FlashSink     CompositeSink
        (flutter_soloud) (HapticFeedback  (ValueListenable
                          + vibration)    + torch_light)
```

* **One concern per file** under `lib/src/`. Public API is re-exported from
  `lib/morse_io.dart`; test doubles from `lib/testing.dart`.
* **`Clock`** (`now()`, `schedule(delay, cb)`) is injected everywhere time
  matters. `SystemClock.shared` is the default so widgets, keyers and the
  decoder's `tick` share one timeline; `FakeClock` drives tests.
* **`MorseSink`** is intentionally dumb (`prepare / on / off / dispose`).
  All timing lives in `MorsePlayer` and the keyers so sound, vibration and
  light stay sample-aligned.
* **`MorsePlayer`** schedules every boundary at an *absolute* time
  (`startAt + cumulativeOffset`) so a late timer never accumulates drift;
  `FakeClock(timerLatency:)` proves this in `test/player_test.dart`.
* **`IambicKeyer`** is an explicit `idle → mark → gap` state machine with
  dit/dah memory; mode B's extra element falls out of the "opposite paddle
  held at element start" latch, mode A clears that latch when a squeeze is
  fully released.
* **`KeyTarget`** exists because `MorseDecoder` is `final`; wrap a real
  decoder with `MorseDecoderTarget`. `KeyerTiming` carries explicit
  dit/dah/gap durations; build it with `KeyerTiming.fromMorseTiming` in the
  app.
* Keyer transitions are `MorseKeyEvent` (not `KeyEvent`, which Flutter owns).

## Plugins and why these versions

| Plugin | Version | Platforms (pubspec `flutter.plugin.platforms`) | Notes |
| --- | --- | --- | --- |
| `flutter_soloud` | `^4.1.7` | android, ios, linux, macos, windows (+web) | 5.x (5.0.0-pre.2+) moved to native-asset hooks and needs `native_toolchain_c ^0.19.4` → `meta ^1.19`, which Flutter 3.41.9 pins to 1.17.0; pub cannot resolve it. 4.1.7 is the newest release that resolves and is a classic FFI plugin, so `flutter test` never compiles C. |
| `vibration` | `^3.2.1` | android, ios | Duration-accurate start/cancel pulses; falls back to `HapticFeedback.heavyImpact()` when `hasCustomVibrationsSupport()` is false. |
| `torch_light` | `^1.1.0` | android, ios | 2.0.0 requires Dart 3.12 / Flutter 3.44. 1.1.0 is a plain `MethodChannel` plugin, so it is inert on desktop and `FlashSink` never calls it there anyway. |

Every plugin sits behind an interface (`SoloudApi`, `HapticApi`, `TorchApi`)
with a production adapter (`FlutterSoloudApi`, `FlutterHapticApi`,
`TorchLightApi`). Tests inject fakes; CI never touches native audio,
vibration or camera code.

## Sidetone approach

`SidetoneSink.prepare()` initialises SoLoud (48 kHz, 512-frame buffer, mono),
loads a `WaveForm.sin` source, tunes it to `frequencyHz` (default 700) and
starts it **looping at volume 0**, protected from voice culling. `on()` /
`off()` only call `fadeVolume(voice, target, ramp)` with a 5 ms ramp: the
mixer applies the envelope, so there is no allocation, decode or scheduling
on the keying hot path and no click at the gate edges. Frequency and volume
can be changed while the tone plays. If SoLoud is already initialised by the
app, the sink shares the engine and does not `deinit()` it on dispose.

## Per-platform notes (need on-device verification)

Nothing below can run in CI (no audio device, vibrator, camera or GPU).

### All platforms
* **Sidetone latency target < 30 ms** key-to-sound. Measure with a contact
  microphone / oscilloscope, or record the screen tap + speaker. Expect
  ~2 × bufferSize (≈21 ms at 512/48 kHz) plus OS output latency. Lower
  `FlutterSoloudApi(bufferSize: 256)` if the device copes; watch for
  underrun crackle.
* Confirm the 5 ms ramp is click-free at 700 Hz on the device speaker; if
  not, raise `SidetoneSink(ramp:)` to 8–10 ms.
* `MorsePlayer` timing accuracy under load (Dart timers are not real-time;
  drift compensation keeps boundaries honest but jitter of 1–4 ms per edge
  is normal).

### iOS
* **Audio session**: `flutter_soloud` 4.x runs miniaudio with
  `sessionCategory = none` and never activates the session, so the app owns
  it. `FlutterSoloudApi` sets `playback` + `mixWithOthers` (via
  `audio_session`, `PlatformAudioSessionApi`) right before it starts the
  engine: the tone plays with the silent switch on and does not stop the
  user's music. The `record` plugin leaves the session in `playAndRecord`;
  the app's microphone source calls `configureForPlayback()` after capture.
* **Background**: `SidetoneSink` stops its silent looping voice while the app
  is backgrounded (`AppForeground`, Android/iOS only), so the engine idles
  its device and nothing plays in the background; a fresh voice starts on
  return. That is why the app declares no `audio` background mode (it would
  be unused; App Review 2.5.4). Key-downs in the background are
  ignored.
* **Interruptions**: every `on()` first calls `resumeVoice` (`setPause(false)`,
  which restarts a device the OS stopped) and replaces a lost voice, so a
  call or Siri interruption whose end is never signalled cannot leave the
  tone dead. Verify on a device: tone after a phone call, after Siri, after
  playing music in another app.
* **Screen**: hands-free sessions hold `WakelockScreenWake` while they run
  (Listen does), since auto-lock would background the app.
* Haptics: `Vibration.vibrate(duration:)` uses `CHHapticEngine` (iPhone 8+);
  `cancel()` only works for those custom haptics. Pulse start latency is
  typically 20–40 ms and cannot be measured here.
* Torch: `torch_light` needs no Info.plist entry but the camera must not be
  in use elsewhere.

### Android
* `flutter_soloud` uses AAudio low-latency (MMAP) by default; verify on a
  mid-range device that 512 frames does not underrun, and that the stream is
  not captured by screen recording (expected with MMAP).
* Haptics: `hasCustomVibrationsSupport()` decides start/cancel vs impact.
  Requires `<uses-permission android:name="android.permission.VIBRATE"/>`.
  Amplitude control varies by OEM; pulse length accuracy is ± ~10 ms at best.
* Torch: `torch_light` needs `android.permission.CAMERA` and
  `<uses-feature android:name="android.hardware.camera.flash"/>` declared.

### macOS / Windows / Linux
* Haptics and torch are compiled in but gated off by `defaultTargetPlatform`
  (`HapticSink.isEnabled == false`, `FlashSink.torchActive == false`).
* Keyboard keying (`KeyboardKeyBinding`: Space = straight, left/right Ctrl =
  dit/dah) is the primary input; verify key-up events arrive for Ctrl on
  Linux/Wayland and that OS key repeat does not leak (repeats are ignored in
  code).
* macOS: `flutter_soloud` needs the app sandbox to allow audio output
  (default). Linux: ALSA/PulseAudio device selection is miniaudio's; test
  headphone hot-plug.

## What CI cannot verify

* Audible output, actual latency, click-free envelope, speaker/headphone
  routing, silent-switch behaviour, audio-session interruptions.
* Vibration presence, strength, pulse-length accuracy, `cancel()` support.
* Torch availability, brightness, camera contention.
* Real touch-screen multi-touch behaviour (tests use synthetic pointers) and
  hardware key repeat semantics per OS.
* Timer jitter under real scheduler load.

Everything else — scheduling, state machines, sink call sequences, widget
pointer/keyboard handling — is covered by `flutter test packages/morse_io`.

## Development

```bash
export PATH=/home/user/flutter/bin:$PATH
flutter pub get                       # at the workspace root
flutter analyze packages/morse_io
flutter test packages/morse_io
```
