import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../keying/key_profile.dart';
import '../../keying/key_profiles.dart';
import 'morse_pattern_text.dart';
import 'reference_layout.dart';
import 'reference_playback_controller.dart';

/// Tap to key: a straight key (touch, or Space on a keyboard) feeding a
/// [MorseDecoder]; the decoded text and the character being keyed are shown
/// live. Sidetone comes from the playback controller's sink so keying sounds
/// like playback.
class TapToKeyView extends StatefulWidget {
  const TapToKeyView({super.key, required this.clock, this.twoPane = false});

  /// Timeline shared by the key widget and the decoder tick.
  final Clock clock;
  final bool twoPane;

  /// How often pending gaps are resolved into character / word boundaries.
  static const Duration tickInterval = Duration(milliseconds: 50);

  static const Key decodedKey = Key('translator-key-decoded');
  static const Key clearKey = Key('translator-key-clear');

  @override
  State<TapToKeyView> createState() => _TapToKeyViewState();
}

class _TapToKeyViewState extends State<TapToKeyView> {
  final MorseDecoder _decoder = MorseDecoder();
  late final StraightKey _key;
  late final StreamSubscription<DecodeEvent> _events;
  Timer? _tick;
  String _text = '';
  String _pending = '';

  /// The device key profile (F12): straight-key bindings and whether the
  /// app sounds its own sidetone while keying.
  KeyProfile _profile = KeyProfile.defaults;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profile = KeyProfiles.of(context);
  }

  @override
  void initState() {
    super.initState();
    final ReferencePlaybackController controller = context
        .read<ReferencePlaybackController>();
    controller.stop();
    _key = StraightKey(
      target: MorseDecoderTarget(_decoder),
      sink: GatedSink(controller.sink, () => _profile.appSidetone),
    );
    _events = _decoder.events.listen((_) => _refresh());
    _scheduleTick();
  }

  void _scheduleTick() {
    _tick = widget.clock.schedule(TapToKeyView.tickInterval, _onTick);
  }

  void _onTick() {
    _tick = null;
    if (!mounted) return;
    _decoder.tick(widget.clock.now());
    _refresh();
    _scheduleTick();
  }

  void _refresh() {
    final String text = _decoder.text;
    final String pending = _decoder.pendingPattern;
    if (text == _text && pending == _pending) return;
    setState(() {
      _text = text;
      _pending = pending;
    });
  }

  void _clear() {
    _decoder.clearText();
    _refresh();
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(_events.cancel());
    unawaited(_key.dispose());
    _decoder.dispose();
    super.dispose();
  }

  double get _estimatedWpm {
    final int ditMs = _decoder.estimatedDit.inMilliseconds;
    return ditMs <= 0 ? 0 : 1200 / ditMs;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;

    final Widget textPane = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.referenceKeyDecodedLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Flexible(
                child: Text(
                  s.referenceEstimatedSpeed('${_estimatedWpm.round()}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              IconButton(
                key: TapToKeyView.clearKey,
                tooltip: s.referenceClear,
                icon: const Icon(Icons.clear_all),
                onPressed: _text.isEmpty && _pending.isEmpty ? null : _clear,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _text.isEmpty ? s.referenceEmptyOutput : _text,
                key: TapToKeyView.decodedKey,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          Text(s.referenceKeyPendingLabel, style: theme.textTheme.labelLarge),
          MorsePatternText(
            _pending.isEmpty ? s.referenceEmptyOutput : _pending,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
          ),
        ],
      ),
    );

    final Widget keyPane = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          StraightKeyButton(
            input: _key,
            binding: _profile.binding,
            clock: widget.clock,
            label: s.referenceKeyLabel,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Text(
            _profile.isDefault
                ? s.referenceKeyHint
                : s.keysHintCustom(keyLabels(_profile.binding.straight)),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (widget.twoPane) {
      return Row(
        children: <Widget>[
          Expanded(child: textPane),
          const VerticalDivider(width: 1),
          SizedBox(width: 320, child: keyPane),
        ],
      );
    }
    return ReferenceMinHeight(
      minHeight: 440,
      child: Column(
        children: <Widget>[
          Expanded(child: textPane),
          keyPane,
        ],
      ),
    );
  }
}
