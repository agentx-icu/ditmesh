import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';
import 'package:tim2tox_dart/interfaces/draft_preferences_service.dart';

void main() {
  late MemoryKeyValueStore store;
  late Tim2ToxPreferencesAdapter a;
  late Tim2ToxPreferencesAdapter b;

  setUp(() {
    store = MemoryKeyValueStore();
    a = Tim2ToxPreferencesAdapter(store, accountPrefix: 'AAAAAAAAAAAAAAAA');
    b = Tim2ToxPreferencesAdapter(store, accountPrefix: 'BBBBBBBBBBBBBBBB');
  });

  test('identity-bound keys are scoped per account prefix', () async {
    await a.setGroups({'tox_1'});
    await a.setFriendNickname('F', 'alice');
    await a.setGroupType('tox_1', 'conference');
    expect(await b.getGroups(), isEmpty);
    expect(await b.getFriendNickname('F'), isNull);
    expect(await a.getGroups(), {'tox_1'});
    expect(await a.getGroupType('tox_1'), 'conference');
    expect(a.accountScopedKey('k'), 'k_AAAAAAAAAAAAAAAA');
  });

  test('files are never auto-downloaded, whatever was stored', () async {
    await store.setInt('auto_download_size_limit', 50);
    await a.setAutoDownloadSizeLimit(30);
    expect(await a.getAutoDownloadSizeLimit(), 0);
  });

  test('network-level keys are global', () async {
    await a.setCurrentBootstrapNode('node.tox', 33445, 'PK');
    final node = await b.getCurrentBootstrapNode();
    expect(node?.host, 'node.tox');
    expect(node?.port, 33445);
    expect(await Tim2ToxBootstrapAdapter(store).getBootstrapHost(), 'node.tox');
  });

  test('Tim2Tox legacy friend dismissal key is account scoped', () async {
    await a.setStringList('dismissed_friend_applications', ['PEER|CQ']);
    expect(await a.getStringList('dismissed_friend_applications'), ['PEER|CQ']);
    expect(await b.getStringList('dismissed_friend_applications'), isNull);
    await a.clear();
    expect(await a.getStringList('dismissed_friend_applications'), isNull);
  });

  test(
    'existing global refusal records migrate once to the current identity',
    () async {
      await store.setStringList('dismissed_friend_applications', ['PEER|CQ']);
      expect(await a.getStringList('dismissed_friend_applications'), [
        'PEER|CQ',
      ]);
      expect(store.keys(), {'dismissed_friend_applications_AAAAAAAAAAAAAAAA'});
      expect(await b.getStringList('dismissed_friend_applications'), isNull);
    },
  );

  test(
    'clear removes legacy refusals before a replacement can inherit them',
    () async {
      await store.setStringList('dismissed_friend_applications', ['PEER|CQ']);
      await a.clear();
      expect(await b.getStringList('dismissed_friend_applications'), isNull);
      expect(store.keys(), isEmpty);
    },
  );

  test(
    'clear collects full-address read receipt queues for this identity',
    () async {
      final self = 'A' * 76;
      final peer = 'B' * 76;
      await a.setStringList('pending_read_receipts_${self}_PEER', ['message']);
      await a.setStringList('pending_group_read_receipts_$self', ['message']);
      await b.setStringList('pending_read_receipts_${peer}_PEER', ['other']);
      await a.clear();
      expect(store.keys(), {'pending_read_receipts_${peer}_PEER'});
    },
  );

  test(
    'clear() removes only this account, never the global settings',
    () async {
      await a.setGroups({'tox_1'});
      await b.setGroups({'tox_2'});
      await a.setCurrentBootstrapNode('node.tox', 33445, 'PK');
      await a.clear();
      expect(await a.getGroups(), isEmpty);
      expect(await b.getGroups(), {'tox_2'});
      expect((await a.getCurrentBootstrapNode())?.host, 'node.tox');
    },
  );

  test('quit-group helpers and group identity removal', () async {
    await a.addQuitGroup('tox_9');
    expect(await a.getQuitGroups(), {'tox_9'});
    await a.removeQuitGroup('tox_9');
    expect(await a.getQuitGroups(), isEmpty);
    await a.setGroupChatId('tox_1', 'c' * 64);
    await a.setGroupType('tox_1', 'group');
    await a.removeGroupIdentity('tox_1');
    expect(await a.getGroupChatId('tox_1'), isNull);
    expect(await a.getGroupType('tox_1'), isNull);
  });

  test('receive options refuse to write an unscoped global slot', () async {
    final unscoped = Tim2ToxPreferencesAdapter(store, accountPrefix: '');
    await unscoped.setC2CReceiveMessageOpt('peer', 2);
    expect(store.keys(), isEmpty);
    await a.setC2CReceiveMessageOpt('peer', 2);
    expect(await a.getC2CReceiveMessageOpt('peer'), 2);
    expect(await b.getC2CReceiveMessageOpt('peer'), 0);
    // An explicit full Tox ID wins over the adapter's own prefix.
    expect(
      await b.getC2CReceiveMessageOpt('peer', 'AAAAAAAAAAAAAAAA${'0' * 60}'),
      2,
    );
  });

  test('drafts round-trip and empty text removes', () async {
    await a.saveConversationDraft(
      accountToxId: 'A' * 76,
      draft: const ConversationDraft(
        conversationID: 'c2c_x',
        text: 'CQ CQ',
        timestamp: 42,
      ),
    );
    final d = await a.loadConversationDraft(
      accountToxId: 'A' * 76,
      conversationID: 'c2c_x',
    );
    expect(d?.text, 'CQ CQ');
    expect(d?.timestamp, 42);
    await a.saveConversationDraft(
      accountToxId: 'A' * 76,
      draft: const ConversationDraft(
        conversationID: 'c2c_x',
        text: '',
        timestamp: 0,
      ),
    );
    expect(
      await a.loadConversationDraft(
        accountToxId: 'A' * 76,
        conversationID: 'c2c_x',
      ),
      isNull,
    );
  });

  test('conversation meta store shares the scope and the clear', () async {
    final meta = ConversationMetaStore(
      store,
      accountPrefix: 'AAAAAAAAAAAAAAAA',
    );
    await meta.setPinned('c2c_p', true);
    await meta.setDraft('c2c_p', 'draft');
    await meta.hide('group_g');
    await meta.queueInvite('tox_1', 'PEER');
    expect(meta.isPinned('c2c_p'), isTrue);
    expect(meta.draft('c2c_p'), 'draft');
    expect(meta.hidden, {'group_g'});
    expect(meta.queuedGroupsFor('PEER'), ['tox_1']);
    await meta.dequeueInvite('tox_1', 'PEER');
    expect(meta.queuedInvites, isEmpty);
    await a.clear();
    expect(meta.isPinned('c2c_p'), isFalse);
    expect(meta.draft('c2c_p'), '');
  });
}
