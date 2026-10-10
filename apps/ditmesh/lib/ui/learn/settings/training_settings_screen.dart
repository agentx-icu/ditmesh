import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_settings.dart';
import '../../common/app_bar_title.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';

/// Training preferences (speed, tone, session length, feedback outputs) for
/// chat copy, group practice and the recording workbench. Pushed from the Me
/// page through `kTrainingSettingsRoute`.
class TrainingSettingsScreen extends StatefulWidget {
  const TrainingSettingsScreen({
    super.key,
    required this.controller,
    required this.playback,
  });

  /// Text keyed by "Play sample"; a Morse procedure word, never localised.
  static const String sampleText = 'CQ';

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<TrainingSettingsScreen> createState() => _TrainingSettingsScreenState();
}

class _TrainingSettingsScreenState extends State<TrainingSettingsScreen> {
  late TrainingSettings _draft = widget.controller.settings;
  LearnPlayback? _sample;
  StreamSubscription<PlayerEvent>? _sampleSub;
  bool _samplePlaying = false;

  /// Bumped when the feedback outputs change; a sample bundle created for an
  /// older generation is thrown away instead of played.
  int _sampleGeneration = 0;

  /// True while a sample bundle is being created.
  bool _creatingSample = false;

  TrainerSettings get _t => _draft.trainer;

  String _wpm(S s, double wpm) => s.learnWpmValue(wpm.toStringAsFixed(0));
  String _hz(S s, double hz) => s.learnHzValue(hz.round().toString());

  /// Updates the draft; persists when [persist] (slider release, toggles).
  void _apply(TrainingSettings next, {bool persist = true}) {
    final outputsChanged =
        next.soundEnabled != _draft.soundEnabled ||
        next.flashEnabled != _draft.flashEnabled ||
        next.hapticEnabled != _draft.hapticEnabled;
    setState(() => _draft = next);
    if (outputsChanged) {
      // The sample's sinks were built from the old switches; rebuild them
      // on the next "Play sample".
      _dropSample();
    }
    _sample?.sidetone?.frequencyHz = next.trainer.toneHz;
    if (persist) {
      unawaited(widget.controller.updateSettings(next));
    }
  }

  void _applyTrainer(TrainerSettings trainer, {bool persist = true}) =>
      _apply(_draft.copyWith(trainer: trainer), persist: persist);

  void _setCharacterWpm(double wpm, {bool persist = true}) {
    final fw = _t.farnsworthWpm;
    _applyTrainer(
      _t.copyWith(
        characterWpm: wpm,
        farnsworthWpm: fw == null ? null : math.min(fw, wpm),
      ),
      persist: persist,
    );
  }

  void _setFarnsworth(bool on) {
    if (on) {
      final fw = math.min(_t.characterWpm, 8.0);
      _applyTrainer(_t.copyWith(farnsworthWpm: fw));
    } else {
      _applyTrainer(_t.copyWith(clearFarnsworth: true));
    }
  }

  void _dropSample() {
    _sampleGeneration++;
    final sample = _sample;
    _sample = null;
    unawaited(_sampleSub?.cancel());
    _sampleSub = null;
    if (sample != null) {
      sample.player.stop();
      unawaited(sample.dispose());
    }
    _samplePlaying = false;
  }

  Future<void> _playSample() async {
    if (_samplePlaying || _creatingSample) {
      return;
    }
    setState(() => _samplePlaying = true);
    var playback = _sample;
    if (playback == null) {
      // Only one creation runs at a time; a switch flipped meanwhile bumps
      // the generation, and the bundle built for the old switches is thrown
      // away and built again.
      _creatingSample = true;
      try {
        while (playback == null) {
          final generation = _sampleGeneration;
          final created = await widget.playback.create(_draft);
          if (!mounted) {
            await created.dispose();
            return;
          }
          if (generation == _sampleGeneration) {
            playback = created;
          } else {
            await created.dispose();
            if (!mounted) {
              return;
            }
          }
        }
      } finally {
        _creatingSample = false;
      }
      _sample = playback;
      _sampleSub = playback.player.events.listen((event) {
        if ((event is PlayerCompleted || event is PlayerStopped) && mounted) {
          setState(() => _samplePlaying = false);
        }
      });
      // Rebuild now so a flash-only sample shows its overlay while playing.
      setState(() => _samplePlaying = true);
    }
    playback.sidetone?.frequencyHz = _t.toneHz;
    playback.player.play(
      MorseEncoder.encode(TrainingSettingsScreen.sampleText, _t.toTiming()),
    );
  }

  @override
  void dispose() {
    unawaited(_sampleSub?.cancel());
    unawaited(_sample?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final flash = _sample?.flash;
    final body = ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        _SliderTile(
          title: s.learnCharacterSpeed,
          value: _wpm(s, _t.characterWpm),
          slider: Slider(
            value: _t.characterWpm.clamp(
              TrainingSettings.minCharacterWpm,
              TrainingSettings.maxCharacterWpm,
            ),
            min: TrainingSettings.minCharacterWpm,
            max: TrainingSettings.maxCharacterWpm,
            divisions:
                (TrainingSettings.maxCharacterWpm -
                        TrainingSettings.minCharacterWpm)
                    .round(),
            label: _wpm(s, _t.characterWpm),
            onChanged: (v) =>
                _setCharacterWpm(v.roundToDouble(), persist: false),
            onChangeEnd: (v) => _setCharacterWpm(v.roundToDouble()),
          ),
        ),
        SwitchListTile(
          title: Text(s.learnFarnsworth),
          subtitle: Text(s.learnFarnsworthHelp),
          value: _t.farnsworthWpm != null,
          onChanged: _setFarnsworth,
        ),
        if (_t.farnsworthWpm != null) _buildFarnsworthSlider(s),
        const Divider(),
        _SliderTile(
          title: s.learnTone,
          value: _hz(s, _t.toneHz),
          trailing: IconButton.filledTonal(
            tooltip: s.learnPlaySample,
            onPressed: _samplePlaying || _creatingSample ? null : _playSample,
            icon: Icon(_samplePlaying ? Icons.volume_up : Icons.play_arrow),
          ),
          slider: Slider(
            value: _t.toneHz.clamp(
              TrainingSettings.minToneHz,
              TrainingSettings.maxToneHz,
            ),
            min: TrainingSettings.minToneHz,
            max: TrainingSettings.maxToneHz,
            divisions:
                ((TrainingSettings.maxToneHz - TrainingSettings.minToneHz) / 10)
                    .round(),
            label: _hz(s, _t.toneHz),
            onChanged: (v) => _applyTrainer(
              _t.copyWith(toneHz: v.roundToDouble()),
              persist: false,
            ),
            onChangeEnd: (v) =>
                _applyTrainer(_t.copyWith(toneHz: v.roundToDouble())),
          ),
        ),
        const Divider(),
        _SliderTile(
          title: s.learnSessionLength,
          value: s.learnCharsCount(_t.sessionLengthChars),
          slider: Slider(
            value: _t.sessionLengthChars
                .clamp(
                  TrainingSettings.minSessionChars,
                  TrainingSettings.maxSessionChars,
                )
                .toDouble(),
            min: TrainingSettings.minSessionChars.toDouble(),
            max: TrainingSettings.maxSessionChars.toDouble(),
            divisions:
                (TrainingSettings.maxSessionChars -
                    TrainingSettings.minSessionChars) ~/
                10,
            label: s.learnCharsCount(_t.sessionLengthChars),
            onChanged: (v) => _applyTrainer(
              _t.copyWith(sessionLengthChars: v.round()),
              persist: false,
            ),
            onChangeEnd: (v) =>
                _applyTrainer(_t.copyWith(sessionLengthChars: v.round())),
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(
            s.learnFeedback,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          dense: true,
        ),
        SwitchListTile(
          title: Text(s.learnSound),
          secondary: const Icon(Icons.volume_up_outlined),
          value: _draft.soundEnabled,
          onChanged: (v) => _apply(_draft.copyWith(soundEnabled: v)),
        ),
        SwitchListTile(
          title: Text(s.learnFlash),
          secondary: const Icon(Icons.flashlight_on_outlined),
          value: _draft.flashEnabled,
          onChanged: (v) => _apply(_draft.copyWith(flashEnabled: v)),
        ),
        if (isTouchPlatform)
          SwitchListTile(
            title: Text(s.learnHaptic),
            secondary: const Icon(Icons.vibration),
            value: _draft.hapticEnabled,
            onChanged: (v) => _apply(_draft.copyWith(hapticEnabled: v)),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.learnSettingsTitle)),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: flash == null
                ? body
                : FlashOverlay(isOn: flash, child: body),
          ),
        ),
      ),
    );
  }

  Widget _buildFarnsworthSlider(S s) {
    final max = _t.characterWpm;
    final min = math.min(TrainingSettings.minFarnsworthWpm, max);
    final value = (_t.farnsworthWpm ?? max).clamp(min, max);
    final divisions = (max - min).round();
    return _SliderTile(
      title: s.learnEffectiveSpeed,
      value: _wpm(s, value),
      slider: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions > 0 ? divisions : null,
        label: _wpm(s, value),
        onChanged: (v) => _applyTrainer(
          _t.copyWith(farnsworthWpm: v.roundToDouble()),
          persist: false,
        ),
        onChangeEnd: (v) =>
            _applyTrainer(_t.copyWith(farnsworthWpm: v.roundToDouble())),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.slider,
    this.trailing,
  });

  final String title;
  final String value;
  final Slider slider;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          // The value sits in the title row so a long title wraps instead of
          // being squeezed to a few characters by a wide trailing value at
          // large text on a phone.
          title: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(title),
              Text(value, style: theme.textTheme.titleMedium),
            ],
          ),
          trailing: trailing,
        ),
        slider,
      ],
    );
  }
}
