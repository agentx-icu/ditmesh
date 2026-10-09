import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'alphabet_grid.dart';
import 'koch_order_view.dart';
import 'reference_catalog.dart';
import 'reference_entry_tile.dart';

/// Renders one whole section of the reference in the layout that suits it:
/// a grid for the alphabet, a numbered list for the Koch order, a plain list
/// for everything else.
class ReferenceSectionView extends StatelessWidget {
  const ReferenceSectionView({super.key, required this.section});

  final ReferenceSection section;

  @override
  Widget build(BuildContext context) {
    final List<ReferenceEntry> entries = ReferenceCatalog.entriesFor(section);
    return switch (section) {
      ReferenceSection.alphabet => AlphabetGrid(
        entries: entries,
        hint: context.s.referenceAlphabetHint,
      ),
      ReferenceSection.koch => KochOrderView(entries: entries),
      _ => ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) =>
            ReferenceEntryTile(entry: entries[index]),
      ),
    };
  }
}

/// Search hits across every section, grouped under section headers.
class ReferenceSearchResults extends StatelessWidget {
  const ReferenceSearchResults({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final Map<ReferenceSection, List<ReferenceEntry>> groups =
        ReferenceCatalog.search(query);
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.referenceNoResults),
        ),
      );
    }
    final ThemeData theme = Theme.of(context);
    final List<Widget> rows = <Widget>[];
    for (final MapEntry<ReferenceSection, List<ReferenceEntry>> g
        in groups.entries) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: <Widget>[
              Icon(g.key.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  g.key.label(s),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.referenceEntryCount(g.value.length),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );
      for (final ReferenceEntry e in g.value) {
        rows.add(
          ReferenceEntryTile(
            entry: e,
            showPosition: e.section == ReferenceSection.koch,
          ),
        );
      }
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: rows);
  }
}
