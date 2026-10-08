import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/chat_copy_session.dart';
import '../../../training/group_practice.dart';
import '../../../training/training_controller.dart';
import '../../chat/chat_layout.dart';
import '../../chat/morse_playback_settings.dart';
import '../../learn/chat_copy/chat_copy_screen.dart';
import '../../learn/learn_playback.dart';
import 'group_practice_page.dart';

/// One local group practice session (F14): its rounds (references to
/// ordinary group messages), copying a round on the shared copy-practice
/// page at the learner's own speed, the instructor's turn checklist, and a
/// summary. Answers, scores and drafts stay on this device; the result to
/// share is only shown, for the learner to key in the chat if they choose.
class GroupPracticeSessionPage extends StatefulWidget {
  const GroupPracticeSessionPage({
    super.key,
    required this.controller,
    required this.sessionId,
  });

  final TrainingController controller;
  final String sessionId;

  @override
  State<GroupPracticeSessionPage> createState() =>
      _GroupPracticeSessionPageState();
}

class _GroupPracticeSessionPageState extends State<GroupPracticeSessionPage> {
  GroupPracticeSession? _session;

  /// Round messages read from history.
  final Map<String, ChatMessage> _messages = {};

  /// Messages not found in history on the last read. Shown, never stored:
  /// a history that is still loading reads as empty too, so this must stay
  /// reversible (it clears as soon as the message is found).
  final Set<String> _missing = {};

  /// History could not be read (no chat session): rounds say so instead of
  /// waiting forever, and are read again when chat connects.
  bool _notConnected = false;
  StreamSubscription<bool>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _sessionSub = _chat.sessionChanges.listen((up) {
      if (up && _notConnected) unawaited(_resolveAll());
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _sessionSub?.cancel().ignore();
    super.dispose();
  }

  ChatService get _chat => context.read<ChatService>();

  Future<void> _load() async {
    final book = await widget.controller.readGroupPractice();
    final session = book.byId(widget.sessionId);
    if (!mounted) return;
    setState(() => _session = session);
    await _resolveAll();
  }

  Future<void> _resolveAll() async {
    final session = _session;
    if (session == null) return;
    setState(() => _notConnected = false);
    for (final r in session.rounds) {
      if (!await _resolve(session, r)) break;
    }
  }

  /// Reads a round's message; false when chat is not connected.
  Future<bool> _resolve(GroupPracticeSession s, GroupPracticeRound r) async {
    final List<ChatMessage> rows;
    try {
      rows = await _chat.loadAround(
        s.conversationId,
        r.messageId,
        before: 0,
        after: 0,
      );
    } on ChatException {
      if (mounted) setState(() => _notConnected = true);
      return false;
    }
    if (!mounted) return false;
    final hit = rows.where((m) => m.id == r.messageId).firstOrNull;
    setState(() {
      if (hit != null) {
        _messages[r.messageId] = hit;
        _missing.remove(r.messageId);
      } else {
        _messages.remove(r.messageId);
        _missing.add(r.messageId);
      }
    });
    return true;
  }

  /// Applies [f]; false (with a message) when it could not be saved.
  Future<bool> _update(GroupPracticeBook Function(GroupPracticeBook) f) async {
    try {
      final book = await widget.controller.updateGroupPractice(f);
      if (mounted) setState(() => _session = book.byId(widget.sessionId));
      return true;
    } on Object {
      if (mounted) showSnack(context, context.s.learnProgressSaveFailed);
      return false;
    }
  }

  Future<void> _delete(GroupPracticeSession session) async {
    final s = context.s;
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.groupPracticeDeleteTitle),
        content: Text(s.groupPracticeDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            key: const Key('gp-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (await _update((b) => b.remove(session.id))) navigator.pop();
  }

  Future<void> _addRounds() async {
    final s = context.s;
    final session = _session!;
    List<ChatMessage> history;
    try {
      history = await _chat.loadHistory(session.conversationId, limit: 50);
    } on ChatException {
      if (mounted) showSnack(context, s.groupPracticeNotConnected);
      return;
    }
    if (!mounted) return;
    final instructor = session.role == GroupPracticeRole.instructor;
    final taken = session.rounds.map((r) => r.messageId).toSet();
    final candidates = history.reversed
        .where((m) => m.isMine == instructor && !taken.contains(m.id))
        .toList();
    final picked = await showModalBottomSheet<ChatMessage>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: candidates.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.groupPracticeNoMessages),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final m in candidates)
                    ListTile(
                      key: Key('gp-pick-${m.id}'),
                      title: Text(
                        // Participants pick by sender and time: the text is
                        // the exercise, not to be read before copying.
                        instructor ? m.text : (m.senderName ?? m.senderId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(formatMessageTime(sheet, m.timestamp)),
                      onTap: () => Navigator.of(sheet).pop(m),
                    ),
                ],
              ),
      ),
    );
    if (picked == null || !mounted) return;
    _messages[picked.id] = picked;
    await _update(
      (b) => b.addRound(
        session.id,
        roundId: GroupPracticeBook.newId('gpr'),
        messageId: picked.id,
        messageAt: picked.timestamp,
      ),
    );
  }

  Future<void> _copy(GroupPracticeRound round) async {
    final message = _messages[round.messageId];
    if (message == null) return;
    final settings = MorsePlaybackSettings.of(context, listen: false);
    final c = widget.controller;
    // Each member copies at their own chosen speed and tone.
    final copy = ChatCopySession(
      text: message.text,
      conversationId: message.conversationId,
      messageId: message.id,
      profileKey: c.profileKey,
      timing: settings.timing,
      toneHz: settings.toneHz,
    );
    LearnPlaybackFactory factory;
    try {
      factory = context.read<LearnPlaybackFactory>();
    } on ProviderNotFoundException {
      factory = const DevicePlaybackFactory();
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatCopyScreen(
          controller: c,
          playback: factory,
          session: copy,
        ),
      ),
    );
    final attempt = GroupPracticeStore.attemptOf(
      copy.id,
      copy.score,
      copy.assistance,
    );
    if (attempt == null) return;
    await _update((b) => b.recordAttempt(widget.sessionId, round.id, attempt));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final instructor = session.role == GroupPracticeRole.instructor;
    final sum = session.summary;
    final missing = session.rounds
        .where((r) => _missing.contains(r.messageId))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          IconButton(
            tooltip: s.actionDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(session),
          ),
        ],
      ),
      floatingActionButton: session.completed
          ? null
          : FloatingActionButton.extended(
              key: const Key('gp-add-round'),
              onPressed: _addRounds,
              icon: const Icon(Icons.playlist_add),
              label: Text(s.groupPracticeAddRound),
            ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(
              '${groupRoleLabel(s, session.role)} · '
              '${instructor ? s.groupPracticeInstructorHint : s.groupPracticeParticipantHint}',
            ),
            const SizedBox(height: 8),
            Text(
              s.groupPracticeLocalNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_notConnected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(s.groupPracticeNotConnected)),
                  TextButton(
                    key: const Key('gp-retry'),
                    onPressed: _resolveAll,
                    child: Text(s.actionRetry),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            for (final (i, r) in session.rounds.indexed) _round(i, r, instructor),
            const Divider(height: 32),
            Card(
              key: const Key('gp-summary'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.groupPracticeSummary, style: Theme.of(context).textTheme.titleSmall),
                    Text(s.groupPracticeRoundsDone(sum.done, sum.rounds)),
                    if (missing > 0)
                      Text(s.groupPracticeUnavailableCount(missing)),
                    if (sum.attempts > 0) ...[
                      Text(s.groupPracticeAccuracy((sum.accuracy * 100).round())),
                      if (sum.assisted > 0) Text(s.groupPracticeAssisted(sum.assisted)),
                      const SizedBox(height: 8),
                      Text(
                        s.groupPracticeShareHint(
                          sum.done,
                          sum.rounds,
                          (sum.accuracy * 100).round(),
                        ),
                        key: const Key('gp-share'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!session.completed)
              OutlinedButton(
                key: const Key('gp-complete'),
                onPressed: () => _update((b) => b.complete(session.id)),
                child: Text(s.groupPracticeComplete),
              ),
          ],
        ),
      ),
    );
  }

  Widget _round(int i, GroupPracticeRound r, bool instructor) {
    final s = context.s;
    final message = _messages[r.messageId];
    final unavailable = _missing.contains(r.messageId);
    final last = r.attempts.isEmpty ? null : r.attempts.last;
    final subtitle = unavailable
        ? s.groupPracticeSourceGone
        : message == null
        ? (_notConnected
              ? s.groupPracticeNotConnected
              : s.groupPracticeSourceLoading)
        : [
            if (instructor || last != null) message.text,
            formatMessageTime(context, r.messageAt),
            if (last != null)
              s.groupPracticeAttemptResult(
                (last.accuracy * 100).round(),
                r.attempts.length,
              ),
          ].join('\n');
    return Card(
      child: ListTile(
        key: Key('gp-round-$i'),
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text(
          r.state == GroupRoundState.done
              ? s.groupPracticeRoundDone
              : unavailable
              ? s.groupPracticeRoundUnavailable
              : s.groupPracticeRoundOpen,
        ),
        subtitle: Text(subtitle),
        trailing: Wrap(
          children: [
            if (unavailable)
              IconButton(
                key: Key('gp-recheck-$i'),
                tooltip: s.actionRetry,
                icon: const Icon(Icons.refresh),
                onPressed: () => _resolve(_session!, r),
              ),
            if (!instructor && message != null && !unavailable)
              IconButton(
                key: Key('gp-copy-$i'),
                tooltip: s.groupPracticeCopy,
                icon: const Icon(Icons.hearing),
                onPressed: () => _copy(r),
              ),
            if (instructor && !unavailable)
              Checkbox(
                key: Key('gp-done-$i'),
                value: r.state == GroupRoundState.done,
                onChanged: (v) => _update(
                  (b) => b.setRoundState(
                    widget.sessionId,
                    r.id,
                    v == true ? GroupRoundState.done : GroupRoundState.open,
                  ),
                ),
              ),
            IconButton(
              tooltip: s.groupPracticeRemoveRound,
              icon: const Icon(Icons.close),
              onPressed: () => _update((b) => b.removeRound(widget.sessionId, r.id)),
            ),
          ],
        ),
      ),
    );
  }
}
