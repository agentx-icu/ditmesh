/// Pure-Dart audio Morse decoding: PCM in, text out.
///
/// Pipeline: `GoertzelDetector` (tone power per block) -> `EnvelopeGate`
/// (adaptive on/off) -> `MorseDecoder` from `morse_core`, with `ToneFinder`
/// auto-tuning the detector. `AudioMorseDecoder` wires them together.
/// Test helpers live in `package:morse_dsp/testing.dart`.
library;

export 'src/audio_decode_segment.dart';
export 'src/audio_morse_decoder.dart';
export 'src/envelope_gate.dart';
export 'src/goertzel.dart';
export 'src/pcm.dart' show Pcm;
export 'src/tone_finder.dart';
export 'src/wav_pcm_reader.dart';
