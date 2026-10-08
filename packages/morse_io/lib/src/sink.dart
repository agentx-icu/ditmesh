/// An output modality for Morse key state: sound, haptics, light.
///
/// Sinks are deliberately dumb: they only know whether the key is currently
/// down. Timing lives in [MorsePlayer] / the keyers so that every modality
/// stays sample-accurate with the others.
///
/// Contract:
/// * [prepare] must be awaited once before the first [on]. It may be called
///   again; implementations treat repeated calls as no-ops.
/// * [on] / [off] are synchronous and must be cheap: they run on the timer
///   callback that keys the element and are latency-critical.
/// * [off] when already off (and [on] when already on) is a no-op.
/// * After [dispose] the sink is unusable.
abstract interface class MorseSink {
  Future<void> prepare();
  void on();
  void off();
  Future<void> dispose();
}

/// Fans every call out to a list of sinks, in order.
final class CompositeSink implements MorseSink {
  CompositeSink(Iterable<MorseSink> sinks)
      : sinks = List<MorseSink>.unmodifiable(sinks);

  final List<MorseSink> sinks;

  @override
  Future<void> prepare() =>
      Future.wait(sinks.map((s) => s.prepare())).then((_) {});

  @override
  void on() {
    for (final sink in sinks) {
      sink.on();
    }
  }

  @override
  void off() {
    for (final sink in sinks) {
      sink.off();
    }
  }

  @override
  Future<void> dispose() =>
      Future.wait(sinks.map((s) => s.dispose())).then((_) {});
}

/// Forwards to [inner] while [enabled] says so, e.g. the app's own keying
/// sidetone switched off because an external keyer makes its own. [off]
/// always passes through, so turning the gate off mid-mark can never leave
/// a tone stuck on.
final class GatedSink implements MorseSink {
  GatedSink(this.inner, this.enabled);

  final MorseSink inner;
  final bool Function() enabled;

  @override
  Future<void> prepare() => inner.prepare();

  @override
  void on() {
    if (enabled()) inner.on();
  }

  @override
  void off() => inner.off();

  @override
  Future<void> dispose() => inner.dispose();
}

/// A sink that does nothing. Handy for silent playback or as a default.
final class NullSink implements MorseSink {
  const NullSink();

  @override
  Future<void> prepare() async {}

  @override
  void on() {}

  @override
  void off() {}

  @override
  Future<void> dispose() async {}
}
