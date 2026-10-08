/// Morse reference + translator feature.
///
/// Entry widgets for navigation: [ReferenceScreen] and [TranslatorScreen].
/// Both take an optional [MorsePlayerFactory] (tests inject a fake) and an
/// optional shared [ReferencePlaybackSettings].
library;

export 'morse_pattern_text.dart';
export 'pattern_decoder.dart';
export 'reference_catalog.dart';
export 'reference_localized_text.dart';
export 'reference_playback_controller.dart';
export 'reference_playback_settings.dart';
export 'reference_player.dart';
export 'reference_screen.dart';
export 'translator_screen.dart';
