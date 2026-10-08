import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../listen/listen_screen.dart';
import '../tools/radio_tools_screen.dart';
import 'playback_settings_sheet.dart';
import 'reference_catalog.dart';
import 'reference_layout.dart';
import 'reference_playback_controller.dart';
import 'reference_playback_settings.dart';
import 'reference_player.dart';
import 'reference_section_view.dart';
import 'translator_screen.dart';

/// Browsable Morse reference: alphabet, punctuation, prosigns, Q-codes, CW
/// abbreviations and the Koch order, each row playable, with one search box
/// that filters every section.
///
/// Phones get tabs in a single column; at [kReferenceTwoPaneMinWidth] and
/// wider a section rail sits beside the content.
///
/// Pass [playerFactory] to control what plays (tests inject a fake clock and
/// a recording sink); the default is a sidetone player. Pass [settings] to
/// share speed / tone with another screen; otherwise the screen owns a
/// default 15 WPM / 700 Hz instance.
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({
    super.key,
    this.playerFactory,
    this.settings,
    this.initialSection = ReferenceSection.alphabet,
  });

  final MorsePlayerFactory? playerFactory;
  final ReferencePlaybackSettings? settings;
  final ReferenceSection initialSection;

  /// Key of the search field, for tests and driving harnesses.
  static const Key searchFieldKey = Key('reference-search');

  /// Key of the app-bar button that opens the radio tools.
  static const Key radioToolsKey = Key('reference-radio-tools');

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  late final ReferencePlaybackSettings _settings;
  late final ReferencePlaybackController _controller;
  final TextEditingController _search = TextEditingController();
  late ReferenceSection _selected = widget.initialSection;
  String _query = '';

  bool get _ownsSettings => widget.settings == null;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? ReferencePlaybackSettings();
    final MorsePlayerFactory factory =
        widget.playerFactory ??
        () => createSidetoneMorsePlayer(frequencyHz: _settings.toneHz);
    _controller = ReferencePlaybackController(
      playerFactory: factory,
      settings: _settings,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsSettings) _settings.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => setState(() => _query = value.trim());

  void _clearQuery() {
    _search.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ReferencePlaybackController>.value(
          value: _controller,
        ),
        ChangeNotifierProvider<ReferencePlaybackSettings>.value(
          value: _settings,
        ),
      ],
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            referenceTwoPaneForWidth(constraints.maxWidth)
            ? _buildTwoPane(context)
            : _buildCompact(context),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    final S s = context.s;
    return AppBar(
      title: Text(s.referenceReferenceTitle),
      actions: <Widget>[
        IconButton(
          tooltip: s.listenTitle,
          icon: const Icon(Icons.mic_none),
          onPressed: () {
            _controller.stop();
            Navigator.of(context).push(ListenScreen.route());
          },
        ),
        IconButton(
          key: ReferenceScreen.radioToolsKey,
          tooltip: s.toolsTitle,
          icon: const Icon(Icons.handyman_outlined),
          onPressed: () {
            _controller.stop();
            Navigator.of(context).push(RadioToolsScreen.route());
          },
        ),
        IconButton(
          tooltip: s.referenceTranslatorTitle,
          icon: const Icon(Icons.swap_horiz),
          onPressed: () => _openTranslator(context),
        ),
        IconButton(
          tooltip: s.referencePlaybackSettings,
          icon: const Icon(Icons.tune),
          onPressed: () => showReferencePlaybackSettings(context, _settings),
        ),
      ],
    );
  }

  /// Pushed as a route (not a tab) so only one sidetone engine is alive at a
  /// time; the settings object is shared so speed/tone follow the user.
  void _openTranslator(BuildContext context) {
    _controller.stop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TranslatorScreen(
          playerFactory: widget.playerFactory,
          settings: _settings,
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: TextField(
      key: ReferenceScreen.searchFieldKey,
      controller: _search,
      onChanged: _onQueryChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.s.referenceSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: context.s.referenceClearSearch,
                icon: const Icon(Icons.close),
                onPressed: _clearQuery,
              ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget _buildCompact(BuildContext context) {
    const List<ReferenceSection> sections = ReferenceSection.values;
    final S s = context.s;
    return DefaultTabController(
      length: sections.length,
      initialIndex: widget.initialSection.index,
      child: Scaffold(
        appBar: _appBar(context),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _searchField(context),
              Expanded(
                child: _query.isEmpty
                    ? Column(
                        children: <Widget>[
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: <Widget>[
                              for (final ReferenceSection section in sections)
                                Tab(text: section.label(s)),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: <Widget>[
                                for (final ReferenceSection section in sections)
                                  ReferenceSectionView(section: section),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ReferenceSearchResults(query: _query),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoPane(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 260,
              child: ReferenceSectionRail(
                selected: _selected,
                onSelected: (ReferenceSection s) => setState(() {
                  _selected = s;
                  if (_query.isNotEmpty) _clearQuery();
                }),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: <Widget>[
                  _searchField(context),
                  Expanded(
                    child: _query.isEmpty
                        ? ReferenceSectionView(section: _selected)
                        : ReferenceSearchResults(query: _query),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side list of sections for the two-pane layout.
class ReferenceSectionRail extends StatelessWidget {
  const ReferenceSectionRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReferenceSection selected;
  final ValueChanged<ReferenceSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        for (final ReferenceSection section in ReferenceSection.values)
          ListTile(
            leading: Icon(section.icon),
            title: Text(section.label(s)),
            trailing: Text(
              '${ReferenceCatalog.entriesFor(section).length}',
              style: theme.textTheme.labelMedium,
            ),
            selected: section == selected,
            selectedTileColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.4,
            ),
            onTap: () => onSelected(section),
          ),
      ],
    );
  }
}
