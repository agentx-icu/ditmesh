import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// The QSO transcript. Remote transmissions are copied by ear: their text
/// stays hidden (visually and for screen readers) until the learner asks to
/// see it, which counts as a hint.
class QsoLogView extends StatelessWidget {
  const QsoLogView({
    super.key,
    required this.session,
    required this.revealed,
    required this.onReveal,
    required this.onPlay,
  });

  final QsoSession session;
  final Set<int> revealed;
  final ValueChanged<int> onReveal;

  /// Plays a remote transmission again locally; null while one is playing.
  final ValueChanged<String>? onPlay;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final turns = session.turns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < turns.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: turns[i].fromRemote
                ? _RemoteTurn(
                    index: i,
                    text: turns[i].text,
                    shown: revealed.contains(i),
                    onReveal: () => onReveal(i),
                    onPlay: onPlay == null
                        ? null
                        : () => onPlay!(turns[i].text),
                    caption: s.learnQsoRemote(session.remote.callsign),
                  )
                : Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              turns[i].text.isEmpty ? '—' : turns[i].text,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          if (turns[i].accepted != null) ...<Widget>[
                            const SizedBox(width: 6),
                            Icon(
                              turns[i].accepted!
                                  ? Icons.check_circle_outline
                                  : Icons.highlight_off,
                              size: 18,
                              semanticLabel: turns[i].accepted!
                                  ? s.learnQsoAccepted
                                  : s.learnQsoRejected,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _RemoteTurn extends StatelessWidget {
  const _RemoteTurn({
    required this.index,
    required this.text,
    required this.shown,
    required this.onReveal,
    required this.onPlay,
    required this.caption,
  });

  final int index;
  final String text;
  final bool shown;
  final VoidCallback onReveal;
  final VoidCallback? onPlay;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(caption, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            if (shown)
              SelectableText(text, key: ValueKey('qso-remote-$index'))
            else
              ExcludeSemantics(
                child: Text(
                  s.learnQsoRemoteHidden,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Wrap(
              spacing: 4,
              children: <Widget>[
                TextButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(s.learnQsoListen),
                ),
                if (!shown)
                  TextButton.icon(
                    key: ValueKey('qso-reveal-$index'),
                    onPressed: onReveal,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(s.learnQsoShowText),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
