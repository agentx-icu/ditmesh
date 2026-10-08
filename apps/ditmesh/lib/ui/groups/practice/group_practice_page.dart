import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/group_practice.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_controller_host.dart';
import 'group_practice_session_page.dart';

/// Group practice sessions of one group (F14): a manually coordinated,
/// local workflow. The instructor keys exercises in the group chat as
/// usual; each member copies them here at their own speed. Nothing on this
/// page or below it sends anything to the group.
class GroupPracticePage extends StatefulWidget {
  const GroupPracticePage({
    super.key,
    required this.conversationId,
    required this.groupTitle,
  });

  final String conversationId;
  final String groupTitle;

  static Future<void> open(
    BuildContext context, {
    required String conversationId,
    required String groupTitle,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GroupPracticePage(
        conversationId: conversationId,
        groupTitle: groupTitle,
      ),
    ),
  );

  @override
  State<GroupPracticePage> createState() => _GroupPracticePageState();
}

class _GroupPracticePageState extends State<GroupPracticePage> {
  TrainingController? _controller;
  GroupPracticeBook _book = GroupPracticeBook.empty;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final host = Provider.of<TrainingControllerHost?>(context, listen: false);
      if (host == null) throw StateError('no training host');
      final c = await host.controller();
      final book = await c.readGroupPractice();
      if (!mounted) return;
      setState(() {
        _controller = c;
        _book = book;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _create() async {
    final s = context.s;
    final c = _controller;
    if (c == null) return;
    final title = TextEditingController(text: widget.groupTitle);
    var role = GroupPracticeRole.participant;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(s.groupPracticeNew),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('gp-title'),
                controller: title,
                decoration: InputDecoration(labelText: s.groupPracticeTitleField),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in GroupPracticeRole.values)
                    ChoiceChip(
                      key: Key('gp-role-${r.name}'),
                      label: Text(groupRoleLabel(s, r)),
                      selected: role == r,
                      onSelected: (_) => setLocal(() => role = r),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.actionCancel),
            ),
            FilledButton(
              key: const Key('gp-create'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.groupPracticeCreate),
            ),
          ],
        ),
      ),
    );
    final name = title.text.trim();
    title.dispose();
    if (ok != true || !mounted) return;
    final session = GroupPracticeSession(
      id: GroupPracticeBook.newId('gps'),
      conversationId: widget.conversationId,
      title: name.isEmpty ? widget.groupTitle : name,
      role: role,
      createdAt: DateTime.now(),
    );
    final GroupPracticeBook book;
    try {
      book = await c.updateGroupPractice((b) => b.add(session));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(s.learnProgressSaveFailed)),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _book = book);
    await _openSession(session.id);
  }

  Future<void> _openSession(String id) async {
    final c = _controller;
    if (c == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupPracticeSessionPage(controller: c, sessionId: id),
      ),
    );
    final book = await c.readGroupPractice();
    if (mounted) setState(() => _book = book);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final locale = Localizations.localeOf(context).toString();
    final sessions = _book.forConversation(widget.conversationId);
    return Scaffold(
      appBar: AppBar(title: Text(s.groupPracticeTitle)),
      floatingActionButton: _controller == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('gp-new'),
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: Text(s.groupPracticeNew),
            ),
      body: SafeArea(
        top: false,
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  // No host or no identity: say so; anything else is a
                  // read failure, not a missing identity.
                  child: Text(
                    _error is StateError || _error is ChatException
                        ? s.learnIdentityRequired
                        : s.errorUnknown,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(s.groupPracticeIntro),
                  ),
                  const SizedBox(height: 8),
                  for (final session in sessions)
                    ListTile(
                      key: Key('gp-session-${session.id}'),
                      leading: Icon(
                        session.completed
                            ? Icons.task_alt
                            : Icons.school_outlined,
                      ),
                      title: Text(session.title),
                      subtitle: Text(
                        '${groupRoleLabel(s, session.role)} · '
                        '${DateFormat.yMd(locale).add_Hm().format(session.createdAt.toLocal())} · '
                        '${s.groupPracticeRoundsDone(session.summary.done, session.summary.rounds)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openSession(session.id),
                    ),
                ],
              ),
      ),
    );
  }
}

String groupRoleLabel(S s, GroupPracticeRole role) => switch (role) {
  GroupPracticeRole.instructor => s.groupPracticeInstructor,
  GroupPracticeRole.participant => s.groupPracticeParticipant,
};
