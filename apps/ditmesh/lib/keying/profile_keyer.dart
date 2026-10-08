import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

import '../i18n/l10n_extension.dart';
import '../training/training_settings.dart';
import 'key_profile.dart';

/// The keyer of one Learn keying surface under a [KeyProfile] (F12): the
/// profile's bindings and paddle orientation, the straight path when an
/// external adapter times its own elements, and its sidetone switch gating
/// the local echo. The surface keeps choosing [KeyerMode] for its paddles.
final class ProfileKeyer {
  ProfileKeyer._(this.profile, this.straight, this.keyer, this.mode);

  /// Builds the keyer for [mode] (straight when the profile's adapter keys
  /// its own elements), feeding [target] and echoing through [sink].
  factory ProfileKeyer.build({
    required KeyProfile profile,
    required KeyerMode mode,
    required KeyTarget target,
    required MorseSink sink,
    required Clock clock,
    required MorseTiming timing,
    MorseSink? sidetone,
  }) {
    // Keyers never dispose their sink, so wrapping it is safe. Only the
    // sound is switched off: a flash or vibration echo stays.
    final echo = gateSidetone(sink, sidetone, () => profile.appSidetone);
    final effective = profile.adapterKeyer ? KeyerMode.straight : mode;
    return switch (effective) {
      KeyerMode.straight => ProfileKeyer._(
        profile,
        StraightKey(target: target, sink: echo),
        null,
        effective,
      ),
      KeyerMode.iambicA || KeyerMode.iambicB => ProfileKeyer._(
        profile,
        null,
        IambicKeyer(
          timing: KeyerTiming.fromMorseTiming(timing),
          target: target,
          sink: echo,
          clock: clock,
          mode: effective == KeyerMode.iambicA ? IambicMode.a : IambicMode.b,
        ),
        effective,
      ),
    };
  }

  /// [sink] with only its [sidetone] member gated by [enabled] (the whole
  /// sink when it is the sidetone itself or no member is given).
  static MorseSink gateSidetone(
    MorseSink sink,
    MorseSink? sidetone,
    bool Function() enabled,
  ) {
    if (sidetone != null && sink is CompositeSink) {
      return CompositeSink([
        for (final s in sink.sinks)
          identical(s, sidetone) ? GatedSink(s, enabled) : s,
      ]);
    }
    return GatedSink(sink, enabled);
  }

  final KeyProfile profile;
  final StraightKey? straight;
  final IambicKeyer? keyer;

  /// The keyer mode actually running.
  final KeyerMode mode;

  /// Releases anything held (no stuck tone) and closes the keyer.
  void dispose() {
    unawaited(straight?.dispose());
    unawaited(keyer?.dispose());
  }

  /// The on-screen key(s) for this keyer, with the profile's bindings.
  Widget widget({
    required Key key,
    required Clock clock,
    required double size,
    required S s,
    Duration? semanticDit,
  }) {
    final binding = profile.binding;
    final straight = this.straight;
    if (straight != null) {
      return Center(
        child: StraightKeyButton(
          key: key,
          input: straight,
          binding: binding,
          clock: clock,
          autofocus: true,
          size: size,
          label: s.learnStraightKeyLabel,
          semanticDit: semanticDit,
          semanticDitLabel: s.learnDitLabel,
          semanticDahLabel: s.learnDahLabel,
        ),
      );
    }
    return PaddleButtons(
      key: key,
      input: keyer!,
      binding: binding,
      swapPaddles: profile.swapPaddles,
      clock: clock,
      autofocus: true,
      height: size,
      ditLabel: s.learnDitLabel,
      dahLabel: s.learnDahLabel,
    );
  }
}
