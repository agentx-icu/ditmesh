import 'dart:async';

import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../keying/key_profiles.dart';
import '../../../keying/profile_keyer.dart';
import '../../../training/send_session.dart';
import '../../../training/training_settings.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../send/keyer_legend.dart';

/// On-screen straight key or paddles (plus Space / Ctrl keys when a
/// hardware keyboard is present) feeding a [SendSession] as decoder. Owns
/// the keyer objects and the decoder tick; the parent owns the session and
/// the playback. Both keying modalities are always available.
class KeyerPanel extends StatefulWidget {
  const KeyerPanel({
    super.key,
    required this.session,
    required this.playback,
    required this.mode,
    this.enabled = true,
    this.size = 150,
  });

  final SendSession session;
  final LearnPlayback playback;
  final KeyerMode mode;

  /// False while the remote station is sending: keying is ignored.
  final bool enabled;
  final double size;

  static const Duration tickPeriod = Duration(milliseconds: 40);

  @override
  State<KeyerPanel> createState() => KeyerPanelState();
}

class KeyerPanelState extends State<KeyerPanel> {
  ProfileKeyer? _keyer;
  Timer? _tick;
  int _generation = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First build, or the device key profile (F12) changed meanwhile.
    // Always read (and so subscribe), even before the keyer exists.
    final profile = KeyProfiles.of(context);
    if (_keyer == null || profile != _keyer!.profile) _build();
  }

  @override
  void didUpdateWidget(KeyerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (!identical(old.session, widget.session) ||
        old.mode != widget.mode ||
        old.enabled != widget.enabled) {
      _build();
    }
  }

  /// Drops a held key (focus loss, background, remote turn) without
  /// measuring it.
  void releaseHeld() {
    widget.session.cancelHeld();
    _build();
    if (mounted) setState(() {});
  }

  void _build() {
    widget.session.cancelHeld();
    _keyer?.dispose();
    _keyer = null;
    _generation++;
    if (!widget.enabled) return;
    final playback = widget.playback;
    _keyer = ProfileKeyer.build(
      profile: KeyProfiles.of(context, listen: false),
      mode: widget.mode,
      target: widget.session,
      sink: playback.sink,
      sidetone: playback.sidetone,
      clock: playback.clock,
      timing: widget.session.nominalTiming,
    );
  }

  void _scheduleTick() {
    if (_disposed) return;
    final clock = widget.playback.clock;
    _tick = clock.schedule(KeyerPanel.tickPeriod, () {
      if (_disposed) return;
      widget.session.tick(clock.now());
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _keyer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final playback = widget.playback;
    final keyer = _keyer;
    final Widget key = keyer == null
        ? SizedBox(height: widget.size)
        : keyer.widget(
            key: ValueKey<String>('panel-key-$_generation'),
            clock: playback.clock,
            size: widget.size,
            s: s,
            semanticDit: widget.session.nominalTiming.dit,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        key,
        if (hasPhysicalKeyboardByDefault && widget.enabled) ...<Widget>[
          const SizedBox(height: 8),
          KeyerLegend(mode: keyer?.mode ?? widget.mode),
        ],
      ],
    );
  }
}
