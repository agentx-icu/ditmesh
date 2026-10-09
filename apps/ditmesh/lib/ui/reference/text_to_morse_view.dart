import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morse_core/morse_core.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import '../responsive.dart';
import 'morse_pattern_text.dart';
import 'reference_playback_controller.dart';

/// Text → Morse: the pattern updates as the user types, can be played with
/// the current mark highlighted, and copied to the clipboard.
class TextToMorseView extends StatefulWidget {
  const TextToMorseView({super.key, this.twoPane = false, this.initialText});

  final bool twoPane;
  final String? initialText;

  /// Playback id used with the shared [ReferencePlaybackController].
  static const String playId = 'translator:text';

  static const Key inputKey = Key('translator-text-input');
  static const Key playKey = Key('translator-text-play');
  static const Key copyKey = Key('translator-text-copy');
  static const Key telegraphKey = Key('translator-text-telegraph');
  static const Key codebookKey = Key('translator-text-codebook');

  @override
  State<TextToMorseView> createState() => _TextToMorseViewState();
}

class _TextToMorseViewState extends State<TextToMorseView> {
  static final RegExp _prosignToken = RegExp(r'<([^<>]+)>');

  late final TextEditingController _text = TextEditingController(
    text: widget.initialText ?? '',
  );
  String _pattern = '';
  String _skipped = '';

  /// What is actually keyed: [_text] with Chinese characters replaced by
  /// their four-digit telegraph codes (`中文` → `0022 2429`).
  String _source = '';

  /// The telegraph codes of the input, space separated, or empty.
  String _telegraph = '';

  /// Whether either codebook knows a character of the input: the codebook
  /// switch is offered then, even if the current book has no code for it
  /// (`國` is Taiwan-only, `国` mainland-only).
  bool _anyCoded = false;
  TelegraphCodebook _codebook = TelegraphCodebook.mainland;

  @override
  void initState() {
    super.initState();
    _recompute(_text.text);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) => setState(() => _recompute(value));

  void _recompute(String text) {
    _source = ChineseTelegraphCode.transliterate(text, codebook: _codebook);
    _pattern = MorseEncoder.toPattern(_source);
    _skipped = _unsupportedChars(_source);
    _telegraph = ChineseTelegraphCode.encode(text, codebook: _codebook)
        .where((TelegraphUnit u) => u.hasCode)
        .map((TelegraphUnit u) => u.code!)
        .join(' ');
    _anyCoded = TelegraphCodebook.values.any(
      (TelegraphCodebook b) =>
          ChineseTelegraphCode.containsCodedChars(text, codebook: b),
    );
  }

  void _setCodebook(TelegraphCodebook book) {
    if (book == _codebook) return;
    // The pattern changes under the player: stop rather than let the old
    // audio run on beside the new display.
    final ReferencePlaybackController controller = context
        .read<ReferencePlaybackController>();
    if (controller.isPlayingId(TextToMorseView.playId)) controller.stop();
    setState(() {
      _codebook = book;
      _recompute(_text.text);
    });
  }

  /// Distinct characters of [text] that have no Morse code, in order of first
  /// appearance. Valid `<AR>`-style prosigns are not reported.
  static String _unsupportedChars(String text) {
    final String stripped = text.replaceAllMapped(
      _prosignToken,
      (Match m) => MorseAlphabet.encodeProsign(m[1]!) == null ? m[0]! : ' ',
    );
    final Set<String> seen = <String>{};
    final StringBuffer out = StringBuffer();
    for (final int rune in stripped.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch.trim().isEmpty || MorseAlphabet.encodeChar(ch) != null) continue;
      if (seen.add(ch)) out.write(ch);
    }
    return out.toString();
  }

  Future<void> _copy() async {
    final String copied = context.s.referencePatternCopied;
    await Clipboard.setData(ClipboardData(text: displayMorsePattern(_pattern)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final ReferencePlaybackController controller = context
        .watch<ReferencePlaybackController>();
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final bool playing = controller.isPlayingId(TextToMorseView.playId);
    final int? active = controller.activeMarkFor(TextToMorseView.playId);
    final bool hasPattern = _pattern.isNotEmpty;

    final Widget input = Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        key: TextToMorseView.inputKey,
        controller: _text,
        onChanged: _onChanged,
        minLines: widget.twoPane ? null : 3,
        maxLines: widget.twoPane ? null : 6,
        expands: widget.twoPane,
        textAlignVertical: TextAlignVertical.top,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          label: FieldLabel(s.referenceTextInputLabel),
          hintText: s.referenceTextInputHint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );

    final Widget output = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.referencePatternOutputLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: TextToMorseView.copyKey,
                tooltip: s.referenceCopyPattern,
                icon: const Icon(Icons.copy),
                onPressed: hasPattern ? _copy : null,
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                key: TextToMorseView.playKey,
                onPressed: hasPattern
                    ? () => controller.toggle(TextToMorseView.playId, _source)
                    : null,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label: Text(playing ? s.referenceStop : s.referencePlay),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: MorsePatternText(
                hasPattern ? _pattern : s.referenceEmptyOutput,
                activeMark: active,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          if (_anyCoded) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.referenceTelegraphCodes(
                  _telegraph.isEmpty ? s.referenceTelegraphNone : _telegraph,
                ),
                key: TextToMorseView.telegraphKey,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<TelegraphCodebook>(
                key: TextToMorseView.codebookKey,
                showSelectedIcon: false,
                segments: <ButtonSegment<TelegraphCodebook>>[
                  ButtonSegment<TelegraphCodebook>(
                    value: TelegraphCodebook.mainland,
                    label: Text(s.referenceTelegraphMainland),
                  ),
                  ButtonSegment<TelegraphCodebook>(
                    value: TelegraphCodebook.taiwan,
                    label: Text(s.referenceTelegraphTaiwan),
                  ),
                ],
                selected: <TelegraphCodebook>{_codebook},
                onSelectionChanged: (Set<TelegraphCodebook> v) =>
                    _setCodebook(v.first),
              ),
            ),
          ],
          if (_skipped.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.referenceSkippedChars(_skipped),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.twoPane) {
      return Row(
        children: <Widget>[
          Expanded(child: input),
          const VerticalDivider(width: 1),
          Expanded(child: output),
        ],
      );
    }
    return MinHeightScrollView(
      minHeight: 360,
      child: Column(
        children: <Widget>[
          input,
          const Divider(height: 1),
          Expanded(child: output),
        ],
      ),
    );
  }
}
