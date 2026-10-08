import '../clock.dart';
import '../key_event.dart';
import '../sink.dart';

/// [MorseSink] that records every transition with the clock time it saw.
final class RecordingSink implements MorseSink {
  RecordingSink({required Clock clock}) : _clock = clock;

  final Clock _clock;
  final List<MorseKeyEvent> events = <MorseKeyEvent>[];
  int prepareCalls = 0;
  int disposeCalls = 0;
  bool isOn = false;

  /// Transitions as `(on, millis)` pairs, convenient for `expect`.
  List<(bool, int)> get log =>
      events.map((e) => (e.on, e.at.inMilliseconds)).toList(growable: false);

  @override
  Future<void> prepare() async {
    prepareCalls++;
  }

  @override
  void on() {
    isOn = true;
    events.add(MorseKeyEvent.down(_clock.now()));
  }

  @override
  void off() {
    isOn = false;
    events.add(MorseKeyEvent.up(_clock.now()));
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  void clear() => events.clear();
}
