import '../key_event.dart';

/// [KeyTarget] that records what a keyer forwarded to "the decoder".
final class RecordingKeyTarget implements KeyTarget {
  final List<MorseKeyEvent> events = <MorseKeyEvent>[];

  /// Transitions as `(on, millis)` pairs, convenient for `expect`.
  List<(bool, int)> get log =>
      events.map((e) => (e.on, e.at.inMilliseconds)).toList(growable: false);

  @override
  void keyDown(Duration at) => events.add(MorseKeyEvent.down(at));

  @override
  void keyUp(Duration at) => events.add(MorseKeyEvent.up(at));

  void clear() => events.clear();
}
