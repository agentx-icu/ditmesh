import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

import '../../i18n/l10n_extension.dart';
import '../../keying/key_profile.dart';
import '../../keying/profile_keyer.dart';
import '../../training/training_settings.dart';

/// Tries a key profile (F12): the on-screen key(s) with the draft's
/// bindings, a live "key down" lamp, the app sidetone if the draft keeps
/// it, and the decoded text. Testing only: nothing is sent, saved or
/// credited.
class KeyTestArea extends StatefulWidget {
  const KeyTestArea({
    super.key,
    required this.profile,
    this.sink,
    this.clock,
  });

  final KeyProfile profile;

  /// Echo sink; a sidetone when null (tests pass a recording sink).
  final MorseSink? sink;
  final Clock? clock;

  static const Key lampKey = Key('key-test-lamp');
  static const Key releaseKey = Key('key-test-release');
  static const Key decodedKey = Key('key-test-decoded');

  @override
  State<KeyTestArea> createState() => _KeyTestAreaState();
}

class _KeyTestAreaState extends State<KeyTestArea> {
  late final MorseSink _sink = widget.sink ?? SidetoneSink();
  late final Clock _clock = widget.clock ?? SystemClock.shared;
  // The lamp shows every key-down; only the sound follows the draft's
  // sidetone switch.
  late final _Lamp _lamp = _Lamp(
    GatedSink(_sink, () => widget.profile.appSidetone),
    () {
      if (mounted) setState(() {});
    },
  );
  final MorseDecoder _decoder = MorseDecoder();
  StreamSubscription<DecodeEvent>? _events;
  ProfileKeyer? _keyer;
  Timer? _tick;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_sink.prepare());
    _events = _decoder.events.listen((_) {
      if (mounted) setState(() {});
    });
    _build();
    _tick = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _decoder.tick(_clock.now());
    });
  }

  @override
  void didUpdateWidget(KeyTestArea old) {
    super.didUpdateWidget(old);
    if (old.profile != widget.profile) _build();
  }

  void _build() {
    // Disposing the previous keyer releases anything held.
    _keyer?.dispose();
    _generation++;
    _keyer = ProfileKeyer.build(
      profile: widget.profile.copyWith(appSidetone: true),
      mode: widget.profile.keyerMode,
      target: MorseDecoderTarget(_decoder),
      sink: _lamp,
      clock: _clock,
      timing: const MorseTiming(wpm: 18),
    );
  }

  /// Explicit stop / reset: a lost key-up can never leave a tone on.
  void _release() {
    _build();
    _lamp.off();
    setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _keyer?.dispose();
    unawaited(_events?.cancel());
    _decoder.dispose();
    if (widget.sink == null) unawaited(_sink.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final keyer = _keyer!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  key: KeyTestArea.lampKey,
                  size: 16,
                  color: _lamp.isOn
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.keysTestTitle, style: theme.textTheme.titleSmall),
                ),
                TextButton(
                  key: KeyTestArea.releaseKey,
                  onPressed: _release,
                  child: Text(s.keysTestRelease),
                ),
              ],
            ),
            Text(s.keysTestNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            keyer.widget(
              key: ValueKey('key-test-$_generation'),
              clock: _clock,
              size: 96,
              s: s,
            ),
            const SizedBox(height: 8),
            Text(
              '${_decoder.text}${_decoder.pendingPattern}',
              key: KeyTestArea.decodedKey,
              style: theme.textTheme.titleMedium,
            ),
            if (widget.profile.adapterKeyer &&
                widget.profile.keyerMode != KeyerMode.straight)
              Text(s.keysAdapterActive, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Mirrors key-down state for the lamp and forwards to the echo sink.
final class _Lamp implements MorseSink {
  _Lamp(this._inner, this._changed);

  final MorseSink _inner;
  final VoidCallback _changed;
  bool isOn = false;

  @override
  Future<void> prepare() => _inner.prepare();

  @override
  void on() {
    _inner.on();
    if (!isOn) {
      isOn = true;
      _changed();
    }
  }

  @override
  void off() {
    _inner.off();
    if (isOn) {
      isOn = false;
      _changed();
    }
  }

  @override
  Future<void> dispose() => _inner.dispose();
}
