part of 'conversation_screen.dart';

extension _ConversationScreenView on _ConversationScreenState {
  Widget _buildRoom(BuildContext context) {
    final settings = ConversationPlaybackPreferences.settingsFor(context, _id);
    _autoPlay.update(context, settings: settings);
    final Group? group = _group();
    final bool conference = group?.kind == GroupKind.conference;

    return Scaffold(
      appBar: ConversationAppBar(
        service: _service,
        target: widget.target,
        settings: settings,
        embedded: widget.embedded,
        onMenu: (a) => unawaited(_onMenu(a)),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final practice = widget.target.isSelf
                ? _messages.reversed
                      .where((message) => !message.isLocation)
                      .firstOrNull
                : null;
            final wide = box.maxWidth >= 810;
            final history = _buildList(settings);
            final guidance = practice == null
                ? null
                : FirstContactCard(
                    service: _service,
                    practice: practice,
                    onPlay: () => unawaited(
                      _playback.toggle(
                        practice.id,
                        practice.text,
                        settings.timing,
                        toneHz: settings.toneHz,
                        recording: practice.recording,
                        original: settings.originalRhythm,
                      ),
                    ),
                  );
            return Column(
              children: [
                if (conference) const ConferenceNote(),
                Expanded(
                  child: wide && (group != null || guidance != null)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: history),
                            SizedBox(
                              width: 260,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  12,
                                  24,
                                  8,
                                ),
                                child: group == null
                                    ? guidance!
                                    : GroupMembersPreview(
                                        service: _service,
                                        group: group,
                                        onMembers: () =>
                                            unawaited(_onMenu('members')),
                                        onPractice: () =>
                                            unawaited(_onMenu('practice')),
                                      ),
                              ),
                            ),
                          ],
                        )
                      : history,
                ),
                ConversationComposer(
                  service: _service,
                  target: widget.target,
                  playback: _playback,
                  settings: settings,
                  paneHeight: box.maxHeight,
                  onSent: (_) => _showLatest(),
                  guidance: wide ? null : guidance,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
