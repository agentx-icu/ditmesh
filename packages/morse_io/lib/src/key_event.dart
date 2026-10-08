import 'package:morse_core/morse_core.dart';

/// A key transition: [on] is key-down, `!on` is key-up, at clock time [at].
///
/// Named `MorseKeyEvent` (not `KeyEvent`) so it never collides with
/// Flutter's keyboard `KeyEvent` in files that import both.
final class MorseKeyEvent {
  const MorseKeyEvent({required this.on, required this.at});

  const MorseKeyEvent.down(Duration at) : this(on: true, at: at);

  const MorseKeyEvent.up(Duration at) : this(on: false, at: at);

  final bool on;
  final Duration at;

  @override
  String toString() => '${on ? 'down' : 'up'}@${at.inMilliseconds}ms';

  @override
  bool operator ==(Object other) =>
      other is MorseKeyEvent && other.on == on && other.at == at;

  @override
  int get hashCode => Object.hash(on, at);
}

/// Where keying ends up: the decoder's `keyDown` / `keyUp` pair.
///
/// `MorseDecoder` is a final class, so this seam exists to let tests record
/// what the keyers forward without a real decoder.
abstract interface class KeyTarget {
  void keyDown(Duration at);
  void keyUp(Duration at);
}

/// Adapts a [MorseDecoder] to [KeyTarget].
final class MorseDecoderTarget implements KeyTarget {
  const MorseDecoderTarget(this.decoder);

  final MorseDecoder decoder;

  @override
  void keyDown(Duration at) => decoder.keyDown(at);

  @override
  void keyUp(Duration at) => decoder.keyUp(at);
}
