import 'package:morse_io/testing.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/learn_playback.dart';

/// [LearnPlaybackFactory] for widget tests: every playback shares one
/// [FakeClock] and appends to one [RecordingSink], so a test can advance time
/// deterministically and inspect what would have sounded.
final class FakeLearnPlaybackFactory implements LearnPlaybackFactory {
  FakeLearnPlaybackFactory({FakeClock? clock}) : clock = clock ?? FakeClock() {
    sink = RecordingSink(clock: this.clock);
  }

  final FakeClock clock;
  late final RecordingSink sink;

  /// Settings passed to [create], newest last.
  final List<TrainingSettings> created = <TrainingSettings>[];
  int disposeCalls = 0;

  @override
  Future<LearnPlayback> create(TrainingSettings settings) async {
    created.add(settings);
    return LearnPlayback(
      sink: sink,
      clock: clock,
      flash: null,
      dispose: () async => disposeCalls++,
    );
  }
}
