import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';

/// The preference families Tim2Tox reads for avatars, remarks, the blacklist,
/// receive options and downloads. ditmesh never shows most of them, but the
/// adapter must still scope them per identity (or keep them global) the way
/// toxee does, so a profile import lands on the same slots.
void main() {
  const prefixA = 'AAAAAAAAAAAAAAAA';
  const prefixB = 'BBBBBBBBBBBBBBBB';
  late MemoryKeyValueStore store;
  late Tim2ToxPreferencesAdapter a;
  late Tim2ToxPreferencesAdapter b;

  setUp(() {
    store = MemoryKeyValueStore();
    a = Tim2ToxPreferencesAdapter(store, accountPrefix: prefixA);
    b = Tim2ToxPreferencesAdapter(store, accountPrefix: prefixB);
  });

  group('verbatim keys', () {
    test('bool, int and string sets are stored unscoped', () async {
      await a.setBool('flag', true);
      await a.setInt('count', 7);
      await a.setStringSet('set', {'b', 'a'});
      expect(await a.getBool('flag'), isTrue);
      expect(await a.getInt('count'), 7);
      expect(await a.getStringSet('set'), {'a', 'b'});
      // Verbatim: the other identity reads the same slot.
      expect(await b.getBool('flag'), isTrue);
      expect(store.keys(), {'flag', 'count', 'set'});
      expect(await a.getBool('missing'), isNull);
      expect(await a.getInt('missing'), isNull);
      expect(await a.getStringSet('missing'), isEmpty);
    });

    test('remove drops the verbatim key', () async {
      await a.setString('k', 'v');
      await a.remove('k');
      expect(await a.getString('k'), isNull);
      expect(store.keys(), isEmpty);
    });
  });

  group('groups', () {
    test('setQuitGroups replaces the scoped set', () async {
      await a.addQuitGroup('tox_1');
      await a.setQuitGroups({'tox_9', 'tox_2'});
      expect(await a.getQuitGroups(), {'tox_2', 'tox_9'});
      expect(await b.getQuitGroups(), isEmpty);
      expect(store.getStringList('quit_groups_list_$prefixA'), [
        'tox_2',
        'tox_9',
      ]);
    });

    test(
      'avatar, notification and introduction clear on null or empty',
      () async {
        await a.setGroupAvatar('g', '/p/a.png');
        await a.setGroupNotification('g', 'net at 8');
        await a.setGroupIntroduction('g', 'CW only');
        expect(await a.getGroupAvatar('g'), '/p/a.png');
        expect(await a.getGroupNotification('g'), 'net at 8');
        expect(await a.getGroupIntroduction('g'), 'CW only');
        expect(await b.getGroupAvatar('g'), isNull);

        await a.setGroupAvatar('g', null);
        await a.setGroupNotification('g', '');
        await a.setGroupIntroduction('g', null);
        expect(await a.getGroupAvatar('g'), isNull);
        expect(await a.getGroupNotification('g'), isNull);
        expect(await a.getGroupIntroduction('g'), isNull);
        expect(store.keys(), isEmpty, reason: 'cleared slots are removed');
      },
    );

    test(
      'owner and chat id are scoped; an empty chat id removes the slot',
      () async {
        await a.setGroupOwner('g', 'OWNER');
        await a.setGroupChatId('g', 'C' * 64);
        expect(await a.getGroupOwner('g'), 'OWNER');
        expect(await a.getGroupChatId('g'), 'C' * 64);
        expect(await b.getGroupOwner('g'), isNull);
        await a.setGroupChatId('g', '');
        expect(await a.getGroupChatId('g'), isNull);
        expect(store.keys(), {'group_owner_g_$prefixA'});
      },
    );
  });

  group('self profile', () {
    test('avatar hash and path are scoped and clearable', () async {
      await a.setSelfAvatarHash('abc');
      await a.setAvatarPath('/me.png');
      expect(await a.getSelfAvatarHash(), 'abc');
      expect(await a.getAvatarPath(), '/me.png');
      expect(await b.getSelfAvatarHash(), isNull);
      expect(await b.getAvatarPath(), isNull);
      await a.setSelfAvatarHash(null);
      await a.setAvatarPath('');
      expect(await a.getSelfAvatarHash(), isNull);
      expect(await a.getAvatarPath(), isNull);
      expect(store.keys(), isEmpty);
    });
  });

  group('friends', () {
    test('status, avatar and remark families are scoped', () async {
      await a.setFriendStatusMessage('F', 'QRV');
      await a.setFriendAvatarPath('F', '/f.png');
      await a.setFriendAvatarHash('F', 'h1');
      await a.setFriendRemark('F', 'Ann');
      expect(await a.getFriendStatusMessage('F'), 'QRV');
      expect(await a.getFriendAvatarPath('F'), '/f.png');
      expect(await a.getFriendAvatarHash('F'), 'h1');
      expect(await a.getFriendRemark('F'), 'Ann');
      expect(await b.getFriendStatusMessage('F'), isNull);
      expect(await b.getFriendAvatarPath('F'), isNull);
      expect(await b.getFriendAvatarHash('F'), isNull);
      expect(await b.getFriendRemark('F'), isNull);
      expect(store.keys().every((k) => k.endsWith('_$prefixA')), isTrue);
    });

    test('a null avatar path or remark removes the slot', () async {
      await a.setFriendAvatarPath('F', '/f.png');
      await a.setFriendRemark('F', 'Ann');
      await a.setFriendAvatarPath('F', null);
      await a.setFriendRemark('F', '');
      expect(await a.getFriendAvatarPath('F'), isNull);
      expect(await a.getFriendRemark('F'), isNull);
      expect(store.keys(), isEmpty);
    });

    test('clear wipes the friend families of one identity only', () async {
      await a.setFriendRemark('F', 'Ann');
      await b.setFriendRemark('F', 'Bob');
      await a.clear();
      expect(await a.getFriendRemark('F'), isNull);
      expect(await b.getFriendRemark('F'), 'Bob');
    });
  });

  group('network-level settings', () {
    test('auto-download is always off and never stored', () async {
      // DitMesh has no file feature: 0 makes Tim2Tox refuse every transfer.
      expect(await a.getAutoDownloadSizeLimit(), 0);
      await a.setAutoDownloadSizeLimit(12);
      expect(await a.getAutoDownloadSizeLimit(), 0);
      expect(await b.getAutoDownloadSizeLimit(), 0);
      expect(store.keys(), isEmpty);
    });

    test('downloads directory is global and clears on null', () async {
      await a.setDownloadsDirectory('/dl');
      expect(await b.getDownloadsDirectory(), '/dl');
      await b.setDownloadsDirectory(null);
      expect(await a.getDownloadsDirectory(), isNull);
      expect(store.keys(), isEmpty);
    });

    test('clear never touches the global settings', () async {
      await a.setDownloadsDirectory('/dl');
      await a.setCurrentBootstrapNode('node.tox', 33445, 'PK');
      await a.clear();
      expect(await a.getDownloadsDirectory(), '/dl');
      expect((await a.getCurrentBootstrapNode())?.host, 'node.tox');
    });

    test('bootstrap adapter shares the slots and reads them back', () async {
      final boot = Tim2ToxBootstrapAdapter(store);
      expect(await boot.getBootstrapHost(), isNull);
      expect(await boot.getBootstrapPort(), isNull);
      expect(await boot.getBootstrapPublicKey(), isNull);
      await boot.setBootstrapNode(
        host: 'node.example',
        port: 3389,
        publicKey: 'PUB',
      );
      expect(await boot.getBootstrapHost(), 'node.example');
      expect(await boot.getBootstrapPort(), 3389);
      expect(await boot.getBootstrapPublicKey(), 'PUB');
      final node = await a.getCurrentBootstrapNode();
      expect(node?.host, 'node.example');
      expect(node?.port, 3389);
      expect(node?.pubkey, 'PUB');
      expect(store.keys(), {
        'current_bootstrap_host',
        'current_bootstrap_port',
        'current_bootstrap_pubkey',
      });
    });

    test('a bootstrap node needs both host and key; port defaults', () async {
      await store.setString('current_bootstrap_host', 'h');
      expect(await a.getCurrentBootstrapNode(), isNull);
      await store.setString('current_bootstrap_pubkey', 'PK');
      expect((await a.getCurrentBootstrapNode())?.port, 33445);
      expect(await a.getBootstrapNodeMode(), 'auto');
    });
  });

  group('blacklist', () {
    test('is keyed by the first 16 chars of the explicit Tox id', () async {
      final toxId = '${'c' * 64}${'0' * 12}';
      await a.setBlackList({'Y', 'X'}, toxId);
      expect(await a.getBlackList(toxId), {'X', 'Y'});
      expect(await b.getBlackList(toxId), {'X', 'Y'}, reason: 'explicit scope');
      expect(store.keys(), {'black_list_${'C' * 16}'});
      expect(await a.getBlackList(), isEmpty, reason: 'own prefix is separate');
    });

    test('falls back to the own prefix when no id is given', () async {
      await a.addToBlackList(['B', 'A']);
      await a.addToBlackList(['C']);
      expect(await a.getBlackList(), {'A', 'B', 'C'});
      expect(await b.getBlackList(), isEmpty);
      await a.removeFromBlackList(['B', 'Z']);
      expect(await a.getBlackList(), {'A', 'C'});
      expect(store.getStringList('black_list_$prefixA'), ['A', 'C']);
    });

    test('an unscoped adapter without an id has no blacklist', () async {
      final global = Tim2ToxPreferencesAdapter(store, accountPrefix: '');
      await global.setBlackList({'X'});
      expect(await global.getBlackList(), isEmpty);
      expect(store.keys(), isEmpty);
      await global.setBlackList({'X'}, 'd' * 76);
      expect(await global.getBlackList('d' * 76), {'X'});
    });
  });

  group('receive options', () {
    test('group and c2c options are scoped; zero removes the slot', () async {
      await a.setGroupReceiveMessageOpt('g', 2);
      await a.setC2CReceiveMessageOpt('F', 1);
      expect(await a.getGroupReceiveMessageOpt('g'), 2);
      expect(await a.getC2CReceiveMessageOpt('F'), 1);
      expect(await b.getGroupReceiveMessageOpt('g'), 0);
      await a.setGroupReceiveMessageOpt('g', 0);
      await a.setC2CReceiveMessageOpt('F', 0);
      expect(await a.getGroupReceiveMessageOpt('g'), 0);
      expect(store.keys(), isEmpty);
    });

    test('an explicit Tox id picks the scope', () async {
      final toxId = '${'e' * 64}${'0' * 12}';
      await a.setGroupReceiveMessageOpt('g', 3, toxId);
      expect(await b.getGroupReceiveMessageOpt('g', toxId), 3);
      expect(store.keys(), {'group_recv_opt_g_${'E' * 16}'});
      final global = Tim2ToxPreferencesAdapter(store, accountPrefix: '');
      await global.setGroupReceiveMessageOpt('g', 3);
      expect(await global.getGroupReceiveMessageOpt('g'), 0);
    });
  });
}
