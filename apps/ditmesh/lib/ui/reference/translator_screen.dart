import 'package:flutter/material.dart';
import 'package:morse_io/morse_io.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_to_text_view.dart';
import 'playback_settings_sheet.dart';
import 'reference_layout.dart';
import 'reference_playback_controller.dart';
import 'reference_playback_settings.dart';
import 'reference_player.dart';
import 'tap_to_key_view.dart';
import 'text_to_morse_view.dart';

/// The three tools of the translator.
enum TranslatorMode {
  textToMorse(Icons.text_fields),
  morseToText(Icons.graphic_eq),
  key(Icons.radio_button_checked);

  const TranslatorMode(this.icon);

  final IconData icon;

  /// Localised segment label.
  String label(S s) => switch (this) {
    TranslatorMode.textToMorse => s.referenceModeTextToMorse,
    TranslatorMode.morseToText => s.referenceModeMorseToText,
    TranslatorMode.key => s.referenceModeKey,
  };
}

/// Two-way Morse translator: text to pattern (with playback), typed pattern
/// to text (with an on-screen keypad), and a straight key that decodes what
/// you send.
///
/// [clock] is the timeline the hand key and its decoder share; pass the same
/// fake clock the [playerFactory] uses in tests. Defaults to
/// [SystemClock.shared].
class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({
    super.key,
    this.playerFactory,
    this.settings,
    this.clock,
    this.initialMode = TranslatorMode.textToMorse,
    this.initialText,
  });

  final MorsePlayerFactory? playerFactory;
  final ReferencePlaybackSettings? settings;
  final Clock? clock;
  final TranslatorMode initialMode;

  /// Pre-filled text for the Text → Morse tool.
  final String? initialText;

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  late final ReferencePlaybackSettings _settings;
  late final ReferencePlaybackController _controller;
  late final Clock _clock;
  late TranslatorMode _mode = widget.initialMode;

  bool get _ownsSettings => widget.settings == null;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? SystemClock.shared;
    _settings = widget.settings ?? ReferencePlaybackSettings();
    final MorsePlayerFactory factory =
        widget.playerFactory ??
        () => createSidetoneMorsePlayer(
          frequencyHz: _settings.toneHz,
          clock: _clock,
        );
    _controller = ReferencePlaybackController(
      playerFactory: factory,
      settings: _settings,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  void _selectMode(Set<TranslatorMode> selection) {
    if (selection.isEmpty || selection.first == _mode) return;
    _controller.stop();
    setState(() => _mode = selection.first);
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ReferencePlaybackController>.value(
          value: _controller,
        ),
        ChangeNotifierProvider<ReferencePlaybackSettings>.value(
          value: _settings,
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.referenceTranslatorTitle),
          actions: <Widget>[
            IconButton(
              tooltip: s.referencePlaybackSettings,
              icon: const Icon(Icons.tune),
              onPressed: () =>
                  showReferencePlaybackSettings(context, _settings),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool twoPane = referenceTwoPaneForWidth(
                constraints.maxWidth,
              );
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SegmentedButton<TranslatorMode>(
                      showSelectedIcon: false,
                      // Equal-width segments; icons only when there is room,
                      // so three labels fit a 360 px phone without overflow.
                      expandedInsets: EdgeInsets.zero,
                      segments: <ButtonSegment<TranslatorMode>>[
                        for (final TranslatorMode m in TranslatorMode.values)
                          ButtonSegment<TranslatorMode>(
                            value: m,
                            label: Text(
                              m.label(s),
                              maxLines: 1,
                              softWrap: false,
                            ),
                            icon: twoPane ? Icon(m.icon) : null,
                          ),
                      ],
                      selected: <TranslatorMode>{_mode},
                      onSelectionChanged: _selectMode,
                    ),
                  ),
                  Expanded(
                    child: switch (_mode) {
                      TranslatorMode.textToMorse => TextToMorseView(
                        twoPane: twoPane,
                        initialText: widget.initialText,
                      ),
                      TranslatorMode.morseToText => MorseToTextView(
                        twoPane: twoPane,
                      ),
                      TranslatorMode.key => TapToKeyView(
                        clock: _clock,
                        twoPane: twoPane,
                      ),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
