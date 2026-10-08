import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_pattern_text.dart';
import 'reference_catalog.dart';
import 'reference_entry_tile.dart';
import 'reference_localized_text.dart';
import 'reference_mnemonics.dart';
import 'reference_playback_controller.dart';

/// A–Z and 0–9 as tappable cards. Tap plays, long-press shows the mnemonic.
///
/// Cards are at least 48 px on each side (they are ~100 px), so the grid is
/// comfortable with a thumb as well as a mouse.
class AlphabetGrid extends StatelessWidget {
  const AlphabetGrid({super.key, required this.entries, this.hint});

  final List<ReferenceEntry> entries;

  /// Optional line shown above the grid.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size contentSize = _measureCardContent(context, entries);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gridWidth = math.max(0, constraints.maxWidth - 24);
        // Retain the usual density unless scaled text requires wider cards.
        final int usualColumns = math.max(1, (gridWidth / 128).ceil());
        final int fittingColumns = math.max(
          1,
          ((gridWidth + 8) / (contentSize.width + 12 + 8)).floor(),
        );
        final int columns = math.min(usualColumns, fittingColumns);
        final double cardWidth = (gridWidth - (columns - 1) * 8) / columns;
        return CustomScrollView(
          slivers: <Widget>[
            if (hint != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: math.max(
                    cardWidth / 1.05,
                    contentSize.height + 16 + 4,
                  ),
                ),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) =>
                    AlphabetCard(entry: entries[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Measure the exact display styles with the active (possibly nonlinear)
/// scaler. Bold patterns cover the width of the currently highlighted mark.
Size _measureCardContent(BuildContext context, List<ReferenceEntry> entries) {
  final ThemeData theme = Theme.of(context);
  final TextStyle labelStyle =
      (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.bold,
      );
  final TextStyle patternStyle = morsePatternTextStyle(
    context,
    style: theme.textTheme.bodyMedium,
  ).copyWith(fontWeight: FontWeight.bold);
  final TextPainter painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.localeOf(context),
    maxLines: 1,
  );
  double width = 36;
  double labelHeight = 0;
  double patternHeight = 0;
  for (final ReferenceEntry entry in entries) {
    painter.text = TextSpan(text: entry.label, style: labelStyle);
    painter.layout();
    width = math.max(width, painter.width);
    labelHeight = math.max(labelHeight, painter.height);
    painter.text = TextSpan(
      text: displayMorsePattern(entry.pattern),
      style: patternStyle,
    );
    painter.layout();
    width = math.max(width, painter.width);
    patternHeight = math.max(patternHeight, painter.height);
  }
  painter.dispose();
  return Size(
    width.ceilToDouble(),
    (labelHeight + patternHeight).ceilToDouble(),
  );
}

/// One character card of the [AlphabetGrid].
class AlphabetCard extends StatelessWidget {
  const AlphabetCard({super.key, required this.entry});

  final ReferenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final ReferencePlaybackController controller = context
        .watch<ReferencePlaybackController>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool playing = controller.isPlayingId(entry.id);
    final int? active = controller.activeMarkFor(entry.id);
    final String language = referenceLanguageFor(
      Localizations.localeOf(context),
    );

    return Semantics(
      button: true,
      label:
          '${entry.label}, ${ReferenceMnemonics.spokenRhythm(entry.pattern, language: language)}',
      hint: context.s.referenceAlphabetHint,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: playing ? scheme.primaryContainer : null,
        child: InkWell(
          onTap: () => controller.toggle(entry.id, entry.playText),
          onLongPress: () => showReferenceMnemonic(context, entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      entry.label,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: playing ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    if (playing)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                MorsePatternText(
                  entry.pattern,
                  activeMark: active,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                  color: playing ? scheme.onPrimaryContainer : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
