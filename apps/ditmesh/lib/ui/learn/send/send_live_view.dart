import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/send_session.dart';
import 'send_tips.dart';
import '../../appearance/style_tokens.dart';
import '../../appearance/ui_style.dart';

/// Live send-practice readout: the target (or a "hidden" placeholder), the
/// decoded text so far, the pattern of the character being keyed and the
/// estimated speed. Rebuilds on [SendSession.changes].
class SendLiveView extends StatelessWidget {
  const SendLiveView({
    super.key,
    required this.session,
    required this.hideTarget,
  });

  final SendSession session;

  /// "Copy from memory" mode: the target is masked until the attempt ends.
  final bool hideTarget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: session.changes,
      builder: (context, _) => _Body(session: session, hideTarget: hideTarget),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.session, required this.hideTarget});

  final SendSession session;
  final bool hideTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final tokens = StyleTokens.of(context);
    final styled = tokens != null && tokens.style != UiStyle.classic;
    final mono = theme.textTheme.headlineSmall?.copyWith(
      fontFamily: 'monospace',
      letterSpacing: 2,
      fontSize: styled ? 32 : null,
    );
    final decoded = session.decodedText;
    final pending = session.pendingPattern;
    final wpm = session.estimatedWpm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Label(s.learnSendThis),
        const SizedBox(height: 4),
        if (hideTarget)
          Text(
            s.learnHiddenTarget,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...<Widget>[
          Text(session.target, style: mono),
          Text(
            session.targetPattern,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Label(s.learnDecoded),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(
              styled ? tokens.controlRadius : 10,
            ),
            border: styled ? Border.all(color: scheme.outlineVariant) : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  decoded.isEmpty && pending.isEmpty
                      ? s.learnWaitingForKey
                      : decoded,
                  style: decoded.isEmpty && pending.isEmpty
                      ? theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )
                      : mono,
                ),
              ),
              if (pending.isNotEmpty)
                Text(pending, style: mono?.copyWith(color: scheme.primary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                s.learnPendingPattern(pending.isEmpty ? '-' : pending),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(formatWpm(s, wpm), style: theme.textTheme.labelLarge),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
