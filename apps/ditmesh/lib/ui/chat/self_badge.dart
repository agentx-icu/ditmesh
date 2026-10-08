import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';

/// Avatar of the note-to-self conversation (contacts and conversation list).
class SelfAvatar extends StatelessWidget {
  const SelfAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.secondaryContainer,
      child: Icon(Icons.bookmark, color: scheme.onSecondaryContainer),
    );
  }
}

/// The "Me" / "我" chip next to the own display name.
class SelfBadge extends StatelessWidget {
  const SelfBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.s.chatSelfMe,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
