import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import '../responsive.dart';
import 'morse_keypad.dart';
import 'pattern_decoder.dart';

/// Morse → Text: the user types `.` / `-` / space / `/` (or taps the
/// keypad) and the decoded text follows. Unknown patterns render as
/// `<pattern>`.
class MorseToTextView extends StatefulWidget {
  const MorseToTextView({super.key, this.twoPane = false});

  final bool twoPane;

  static const Key inputKey = Key('translator-morse-input');
  static const Key outputKey = Key('translator-morse-output');
  static const Key copyKey = Key('translator-morse-copy');

  /// Characters the pattern field accepts: marks, gaps, and the display /
  /// lookalike glyphs [PatternDecoder.normalize] understands.
  static final RegExp allowedInput = RegExp(r'[.\-/ |_*·−•–—]');

  @override
  State<MorseToTextView> createState() => _MorseToTextViewState();
}

class _MorseToTextViewState extends State<MorseToTextView> {
  final TextEditingController _input = TextEditingController();
  String _decoded = '';
  bool _hasUnknown = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) => setState(() {
    _decoded = PatternDecoder.decode(value);
    _hasUnknown = PatternDecoder.hasUnknown(value);
  });

  void _insert(String s) {
    final TextEditingValue v = _input.value;
    final TextSelection sel = v.selection;
    final int start = sel.isValid ? sel.start : v.text.length;
    final int end = sel.isValid ? sel.end : v.text.length;
    final String text = v.text.replaceRange(start, end, s);
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + s.length),
    );
    _onChanged(text);
  }

  void _backspace() {
    final TextEditingValue v = _input.value;
    if (v.text.isEmpty) return;
    final TextSelection sel = v.selection;
    int start;
    int end;
    if (sel.isValid && !sel.isCollapsed) {
      start = sel.start;
      end = sel.end;
    } else {
      end = sel.isValid ? sel.end : v.text.length;
      if (end == 0) return;
      start = end - 1;
    }
    final String text = v.text.replaceRange(start, end, '');
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start),
    );
    _onChanged(text);
  }

  void _clear() {
    _input.clear();
    _onChanged('');
  }

  Future<void> _copy() async {
    final String copied = context.s.referenceTextCopied;
    await Clipboard.setData(ClipboardData(text: _decoded));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final TextStyle mono = (theme.textTheme.titleLarge ?? const TextStyle())
        .copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const <String>[
            'Menlo',
            'Consolas',
            'Courier New',
          ],
          letterSpacing: 2,
        );

    final Widget input = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          TextField(
            key: MorseToTextView.inputKey,
            controller: _input,
            onChanged: _onChanged,
            style: mono,
            minLines: 2,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(MorseToTextView.allowedInput),
            ],
            decoration: InputDecoration(
              label: FieldLabel(s.referencePatternInputLabel),
              hintText: s.referencePatternInputHint,
              // Instructions in body text, not the large monospace input
              // style, and free to grow the field: German at 2x on a 320 px
              // phone needs nine lines of it.
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              hintMaxLines: 12,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          MorseKeypad(
            onInsert: _insert,
            onBackspace: _backspace,
            onClear: _clear,
          ),
        ],
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
                  s.referenceTextOutputLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: MorseToTextView.copyKey,
                tooltip: s.referenceCopyText,
                icon: const Icon(Icons.copy),
                onPressed: _decoded.isEmpty ? null : _copy,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _decoded.isEmpty ? s.referenceEmptyOutput : _decoded,
                key: MorseToTextView.outputKey,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          if (_hasUnknown)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.referenceUnknownPatternHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.twoPane) {
      return Row(
        children: <Widget>[
          Expanded(child: SingleChildScrollView(child: input)),
          const VerticalDivider(width: 1),
          Expanded(child: output),
        ],
      );
    }
    return MinHeightScrollView(
      minHeight: 460,
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
