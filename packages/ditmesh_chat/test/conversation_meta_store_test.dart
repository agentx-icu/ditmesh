import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';

/// Refuses to write or remove the draft keys while [fail] is set.
class _FailingDrafts extends MemoryKeyValueStore {
  bool fail = false;

  @override
  Future<void> remove(String key) => fail && key.startsWith('ditmesh_draft_')
      ? Future<void>.error(StateError('draft write refused'))
      : super.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      fail && key.startsWith('ditmesh_draft_')
      ? Future<void>.error(StateError('draft write refused'))
      : super.setString(key, value);
}

/// Draft writes complete only on [release]; intent removals fail at once.
class _SlowDraftFailingIntent extends MemoryKeyValueStore {
  final Completer<void> release = Completer<void>();

  @override
  Future<void> remove(String key) => key.startsWith('ditmesh_send_intent_')
      ? Future<void>.error(StateError('intent removal refused'))
      : release.future.then((_) => super.remove(key));
}

void main() {
  test('a failing intent removal is reported by the draft write, not as an '
      'unhandled error', () async {
    final store = _SlowDraftFailingIntent();
    final meta = ConversationMetaStore(store, accountPrefix: 'A');
    await store.setString('ditmesh_draft_c2c_p_A', 'CQ');
    await meta.setSendIntent('c2c_p', 'dmt:1');
    final write = meta.setDraft('c2c_p', '');
    await pumpEventQueue();
    store.release.complete();
    await expectLater(write, throwsStateError);
  });

  test('a draft write supersedes the send intent', () async {
    final meta = ConversationMetaStore(MemoryKeyValueStore(), accountPrefix: 'A');
    await meta.setDraft('c2c_p', 'CQ');
    await meta.setSendIntent('c2c_p', 'dmt:1');
    expect(meta.sendIntent('c2c_p'), (id: 'dmt:1', draft: 'CQ'));
    expect(meta.allDrafts(), {'c2c_p': 'CQ'}, reason: 'never read as a draft');
    await meta.setDraft('c2c_p', 'CQ');
    expect(meta.sendIntent('c2c_p'), isNull);
  });

  test('a failed draft write leaves the send intent standing', () async {
    final store = _FailingDrafts();
    final meta = ConversationMetaStore(store, accountPrefix: 'A');
    await meta.setDraft('c2c_p', 'CQ');
    await meta.setSendIntent('c2c_p', 'dmt:1');
    store.fail = true;
    await expectLater(meta.setDraft('c2c_p', ''), throwsStateError);
    expect(meta.draft('c2c_p'), 'CQ');
    expect(meta.sendIntent('c2c_p'), (id: 'dmt:1', draft: 'CQ'),
        reason: 'the stored draft is still the one that was sent');
  });


  const prefixA = 'AAAAAAAAAAAAAAAA';
  const prefixB = 'BBBBBBBBBBBBBBBB';
  const c2c = 'c2c_${'1234567890ABCDEF'}';
  late MemoryKeyValueStore store;
  late ConversationMetaStore a;
  late ConversationMetaStore b;

  setUp(() {
    store = MemoryKeyValueStore();
    a = ConversationMetaStore(store, accountPrefix: prefixA);
    b = ConversationMetaStore(store, accountPrefix: prefixB);
  });

  test('pinned, hidden and drafts are scoped per identity', () async {
    await a.setPinned(c2c, true);
    await a.hide(c2c);
    await a.setDraft(c2c, 'CQ');
    expect(a.isPinned(c2c), isTrue);
    expect(a.hidden, {c2c});
    expect(a.draft(c2c), 'CQ');
    expect(b.isPinned(c2c), isFalse);
    expect(b.hidden, isEmpty);
    expect(b.draft(c2c), '');
    expect(store.keys().every((k) => k.endsWith('_$prefixA')), isTrue);
  });

  test('unpinning, unhiding and an empty draft remove their entries', () async {
    await a.setPinned(c2c, true);
    await a.hide(c2c);
    await a.setDraft(c2c, 'CQ');
    await a.setPinned(c2c, false);
    await a.unhide(c2c);
    await a.setDraft(c2c, '');
    expect(a.pinned, isEmpty);
    expect(a.hidden, isEmpty);
    expect(a.draft(c2c), '');
    expect(store.getString('ditmesh_draft_${c2c}_$prefixA'), isNull);
    // Unhiding something not hidden writes nothing.
    final before = store.getStringList('ditmesh_hidden_conversations_$prefixA');
    await a.unhide('c2c_other');
    expect(store.getStringList('ditmesh_hidden_conversations_$prefixA'), before);
  });

  test('forget drops every record of one conversation and keeps the rest', () async {
    const other = 'group_tox_1';
    await a.setPinned(c2c, true);
    await a.setPinned(other, true);
    await a.hide(c2c);
    await a.setDraft(c2c, 'CQ');
    await a.setDraft(other, 'K');
    await a.forget(c2c);
    expect(a.isPinned(c2c), isFalse);
    expect(a.hidden, isEmpty);
    expect(a.draft(c2c), '');
    expect(a.isPinned(other), isTrue);
    expect(a.draft(other), 'K');
  });

  test('queued invites are per friend and dequeue is idempotent', () async {
    final friend = 'F' * 64;
    await a.queueInvite('tox_1', friend);
    await a.queueInvite('tox_2', friend);
    await a.queueInvite('tox_1', 'G' * 64);
    expect(a.queuedGroupsFor(friend), ['tox_1', 'tox_2']);
    expect(a.queuedGroupsFor('G' * 64), ['tox_1']);
    await a.dequeueInvite('tox_1', friend);
    await a.dequeueInvite('tox_1', friend);
    expect(a.queuedGroupsFor(friend), ['tox_2']);
    expect(a.queuedInvites, {'tox_2\t$friend', 'tox_1\t${'G' * 64}'});
  });

  test('clear removes only the own identity keys', () async {
    await a.setPinned(c2c, true);
    await a.setDraft(c2c, 'CQ');
    await a.queueInvite('tox_1', 'F' * 64);
    await b.setPinned(c2c, true);
    await store.setString('global_setting', 'keep');
    await a.clear();
    expect(a.pinned, isEmpty);
    expect(a.draft(c2c), '');
    expect(a.queuedInvites, isEmpty);
    expect(b.isPinned(c2c), isTrue);
    expect(store.getString('global_setting'), 'keep');
  });

  test('an unscoped store never clears anything', () async {
    final global = ConversationMetaStore(store, accountPrefix: '');
    await global.setPinned(c2c, true);
    await a.setPinned(c2c, true);
    await global.clear();
    expect(global.isPinned(c2c), isTrue);
    expect(a.isPinned(c2c), isTrue);
    expect(store.keys(), contains('ditmesh_pinned_conversations'));
  });
}
