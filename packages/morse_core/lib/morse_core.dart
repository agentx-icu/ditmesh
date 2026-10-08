/// Pure-Dart Morse code engine.
///
/// Public API contract (v0.1). Other workspace packages (`morse_trainer`,
/// `morse_io`, the app) code against exactly these names; extend freely but
/// do not rename or remove without updating every consumer.
library;

export 'src/alphabet.dart';
export 'src/decoder.dart';
export 'src/element.dart';
export 'src/encoder.dart';
export 'src/telegraph/chinese_telegraph_code.dart';
export 'src/telegraph/telegraph_groups.dart';
export 'src/timing.dart';
