/// Morse I/O for Flutter: render timelines to sound / haptics / light and
/// turn on-screen or keyboard keying into decoder events.
///
/// Test doubles (fake clock, recording sink / key target) live in
/// `package:morse_io/testing.dart`.
library;

export 'src/app_foreground.dart';
export 'src/audio_session_api.dart';
export 'src/clip_player.dart';
export 'src/clock.dart';
export 'src/engine_leases.dart';
export 'src/flash_sink.dart';
export 'src/haptic_sink.dart';
export 'src/iambic_keyer.dart';
export 'src/key_event.dart';
export 'src/keyboard_binding.dart';
export 'src/keyer_timing.dart';
export 'src/player.dart';
export 'src/screen_wake.dart';
export 'src/sidetone_sink.dart';
export 'src/sink.dart';
export 'src/soloud_api.dart';
export 'src/straight_key.dart';
export 'src/wav_export.dart';
export 'src/widgets/flash_overlay.dart';
export 'src/widgets/paddle_buttons.dart';
export 'src/widgets/straight_key_button.dart';
