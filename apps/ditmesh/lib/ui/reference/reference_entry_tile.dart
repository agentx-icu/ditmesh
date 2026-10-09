import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_pattern_text.dart';
import 'reference_catalog.dart';
import 'reference_playback_controller.dart';

/// One list row of the reference: label, pattern (with playback highlight),
/// meaning and a play / stop button. Tap plays, long-press shows the
/// mnemonic when the entry has one.
class ReferenceEntryTile extends StatelessWidget {
  const ReferenceEntryTile({
    super.key,
    required this.entry,
    this.showPosition = false,
  });

  final ReferenceEntry entry;

  /// Prefix the row with the entry's Koch position.
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    final ReferencePlaybackController controller = context
        .watch<ReferencePlaybackController>();
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final bool playing = controller.isPlayingId(entry.id);
    final int? active = controller.activeMarkFor(entry.id);
    final String? meaning = entry.meaning(Localizations.localeOf(context));
    final int? position = entry.position;

    return ListTile(
      selected: playing,
      leading: SizedBox(
        width: showPosition ? 88 : 56,
        child: Row(
          children: <Widget>[
            if (showPosition && position != null)
              SizedBox(
                width: 32,
                child: Text(
                  '$position',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (showPosition) const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const <String>['Menlo', 'Consolas'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      title: MorsePatternText(entry.pattern, activeMark: active),
      subtitle: meaning == null || meaning.isEmpty ? null : Text(meaning),
      trailing: IconButton(
        tooltip: playing ? s.referenceStop : s.referencePlay,
        icon: Icon(
          playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
        ),
        onPressed: () => controller.toggle(entry.id, entry.playText),
      ),
      onTap: () => controller.toggle(entry.id, entry.playText),
      onLongPress: entry.hasMnemonic
          ? () => showReferenceMnemonic(context, entry)
          : null,
    );
  }
}

/// Shows the mnemonic for [entry] in a dialog, with a play button.
Future<void> showReferenceMnemonic(BuildContext context, ReferenceEntry entry) {
  final ReferencePlaybackController controller = context
      .read<ReferencePlaybackController>();
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final ThemeData theme = Theme.of(dialogContext);
      final S s = dialogContext.s;
      final Locale locale = Localizations.localeOf(dialogContext);
      final String? meaning = entry.meaning(locale);
      final int? position = entry.position;
      return AlertDialog(
        scrollable: true,
        title: Text(entry.label, style: theme.textTheme.displaySmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChangeNotifierProvider<ReferencePlaybackController>.value(
              value: controller,
              child: Consumer<ReferencePlaybackController>(
                builder: (_, ReferencePlaybackController c, _) =>
                    MorsePatternText(
                      entry.pattern,
                      activeMark: c.activeMarkFor(entry.id),
                      style: theme.textTheme.headlineSmall,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.referenceMnemonicTitle, style: theme.textTheme.labelLarge),
            Text(
              entry.mnemonic(locale) ?? '',
              style: theme.textTheme.bodyLarge,
            ),
            if (meaning != null && meaning.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(s.referenceMeaningLabel, style: theme.textTheme.labelLarge),
              Text(meaning),
            ],
            if (position != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(s.referenceKochPositionValue(position)),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => controller.play(entry.id, entry.playText),
            icon: const Icon(Icons.play_arrow),
            label: Text(s.referencePlay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.referenceClose),
          ),
        ],
      );
    },
  );
}
