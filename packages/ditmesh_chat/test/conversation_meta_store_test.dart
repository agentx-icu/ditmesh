import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';

void main() {
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
