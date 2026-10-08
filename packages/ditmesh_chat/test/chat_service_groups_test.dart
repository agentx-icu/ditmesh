import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

int _write(String s, ffi.Pointer<ffi.Int8> buf, int cap) {
  final bytes = utf8.encode(s);
  if (bytes.length + 1 > cap) return -(bytes.length + 1);
  final out = buf.cast<ffi.Uint8>().asTypedList(bytes.length + 1);
  out.setAll(0, bytes);
  out[bytes.length] = 0;
  return bytes.length;
}

/// [FakeTim2ToxFfi] plus the group bindings Tim2Tox's `createGroup`,
/// `joinGroup`, `acceptGroupInvite`, `rejectGroupInvite` and
/// `sharedGroupName` reach. `quitGroup` and the member/invite compat
/// bindings go through `NativeLibraryManager`, which needs the real
/// library, so leaving and inviting stay with the native smoke tests.
class GroupFfi extends FakeTim2ToxFfi {
  final List<(String name, String type)> createdGroups = [];
  bool createSucceeds = true;
  String nextGroupId = 'tox_1';

  int joinRc = 1;
  final List<(String id, String secret)> joins = [];
  final List<(String id, String password)> passwordJoins = [];

  final List<String> rejected = [];
  final Map<String, String> sharedNames = {};
  List<PendingGroupInvite> pendingInvites = [];

  @override
  int Function(
    ffi.Pointer<pkgffi.Utf8>,
    ffi.Pointer<pkgffi.Utf8>,
    ffi.Pointer<ffi.Int8>,
    int,
  )
  get createGroup => (name, type, buf, cap) {
    createdGroups.add((name.toDartString(), type.toDartString()));
    if (!createSucceeds) return 0;
    return _write(nextGroupId, buf, cap);
  };

  /// Native forgets an invite the moment its accept is dispatched.
  int _join(String id) {
    if (joinRc == 1) pendingInvites.removeWhere((i) => i.id == id);
    return joinRc;
  }

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>)
  get joinGroup => (id, msg) {
    joins.add((id.toDartString(), msg.toDartString()));
    return _join(id.toDartString());
  };

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>)
  get joinGroupWithPassword => (id, password) {
    passwordJoins.add((id.toDartString(), password.toDartString()));
    return _join(id.toDartString());
  };

  // Create/join also sync the known-group set and the retired-id floor to
  // native. The base class would look those symbols up in the process; a
  // no-op keeps the test hermetic (and the real one frees its buffer only
  // on success, so a lookup failure would leak it).
  @override
  int Function(int, ffi.Pointer<pkgffi.Utf8>) get updateKnownGroupsNative =>
      (_, _) => 0;

  @override
  int Function(int, int) get setRetiredGroupIdMaxNative => (_, _) => 0;

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>) get rejectGroupInvite => (id) {
    final inviteId = id.toDartString();
    rejected.add(inviteId);
    pendingInvites.removeWhere((i) => i.id == inviteId);
    return 1;
  };

  @override
  int Function(int, ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<ffi.Int8>, int)
  get getGroupNameNative => (_, id, buf, cap) {
    final name = sharedNames[id.toDartString()];
    return name == null ? 0 : _write(name, buf, cap);
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const prefix = '1111111111111111';

  late Directory tempRoot;
  late GroupFfi ffi;
  late MemoryKeyValueStore store;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late MemoryChatLogger logger;
  late int inviteReads;
  late Tim2ToxChatService chat;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_groups_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = GroupFfi();
    store = MemoryKeyValueStore();
    engineService = await newEngineService(ffi, store, tempRoot, 'identity');
    inviteReads = 0;
    engineService.debugNativePendingInvitesOverride = () {
      inviteReads++;
      return ffi.pendingInvites;
    };
    engine = FakeChatEngine();
    identity = FakeIdentityService.withProfile(
      identity: const Identity(toxId: kSelfToxId, displayName: 'me'),
      connectDelay: Duration.zero,
    );
    await identity.open();
    logger = MemoryChatLogger();
    chat = Tim2ToxChatService(
      engine: engine,
      identity: identity,
      store: store,
      logger: logger,
      pollInterval: const Duration(milliseconds: 50),
    );
  });

  tearDown(() async {
    await chat.dispose();
    await engine.dispose();
    await identity.dispose();
    await engineService.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Future<void> bind() async {
    engine.bind(engineService);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  PendingGroupInvite invite(String id, {String kind = 'group'}) =>
      PendingGroupInvite(
        id: id,
        inviterUserId: 'b' * 64,
        kind: kind,
        groupName: kind == 'group' ? 'DX net' : '',
        receivedAt: DateTime(2026, 10, 3),
      );

  group('createGroup', () {
    test('trims the name, records it locally and lists the group', () async {
      await bind();
      final events = <List<Group>>[];
      final sub = chat.groupChanges.listen(events.add);
      final g = await chat.createGroup('  Net 40m ', kind: GroupKind.conference);
      expect(ffi.createdGroups, [('Net 40m', 'conference')]);
      expect(g.id, 'tox_1');
      expect(g.name, 'Net 40m');
      expect(g.kind, GroupKind.conference);
      expect(g.chatId, isNull, reason: 'conferences have no chat id');
      expect(chat.groups.map((x) => x.id), ['tox_1']);
      expect(chat.conversations.map((c) => c.id), contains('group_tox_1'));
      final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
      expect(await prefs.getGroupName('tox_1'), 'Net 40m');
      expect(await prefs.getGroupType('tox_1'), 'conference');
      expect(await prefs.getGroups(), {'tox_1'});
      await pumpEventQueue();
      expect(events.last.map((x) => x.id), ['tox_1']);
      await sub.cancel();
    });

    test('rejects an empty name before touching Tox', () async {
      await bind();
      await expectLater(chat.createGroup('   '), throwsCode('invalid_name'));
      expect(ffi.createdGroups, isEmpty);
      expect(chat.groups, isEmpty);
    });

    test('surfaces a native refusal', () async {
      await bind();
      ffi.createSucceeds = false;
      await expectLater(chat.createGroup('CQ'), throwsCode('create_group_failed'));
      expect(chat.groups, isEmpty);
    });

    test('defaults to an NGC group', () async {
      await bind();
      final g = await chat.createGroup('CQ');
      expect(ffi.createdGroups.single.$2, 'group');
      expect(g.kind, GroupKind.group);
    });
  });

  group('joinGroup', () {
    test('validates the chat id before calling Tox', () async {
      await bind();
      await expectLater(chat.joinGroup('nope'), throwsCode('invalid_chat_id'));
      await expectLater(chat.joinGroup('c' * 63), throwsCode('invalid_chat_id'));
      expect(ffi.joins, isEmpty);
    });

    test('hands Tox the lowercase id and records the membership', () async {
      await bind();
      await chat.joinGroup(' ${'C' * 64} ');
      expect(ffi.joins, [('c' * 64, '')]);
      expect(ffi.passwordJoins, isEmpty);
      // Tim2Tox records the membership at dispatch (the contract only
      // promises the group "appears"; the name arrives with the DHT
      // discovery and is the chat id until then).
      expect(chat.groups.map((g) => g.id), ['c' * 64]);
      expect(chat.groups.single.name, 'c' * 64, reason: 'no name known yet');
      final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
      expect(await prefs.getGroups(), {'c' * 64});
    });

    test('passes a password through the password binding', () async {
      await bind();
      await chat.joinGroup('D' * 64, password: 'secret');
      expect(ffi.joins, isEmpty);
      expect(ffi.passwordJoins, [('d' * 64, 'secret')]);
    });

    test('maps "already joined" and a refusal to contract codes', () async {
      await bind();
      ffi.joinRc = 2;
      await expectLater(chat.joinGroup('E' * 64), throwsCode('already_joined'));
      ffi.joinRc = 0;
      await expectLater(chat.joinGroup('E' * 64), throwsCode('join_failed'));
      expect(chat.groups, isEmpty);
    });
  });

  group('invites', () {
    test('pending native invites map to contract rows', () async {
      ffi.pendingInvites = [invite('inv_1'), invite('conf_1', kind: 'conference')];
      await bind();
      final rows = chat.groupInvites;
      expect(rows.map((i) => i.inviteId), ['inv_1', 'conf_1']);
      expect(rows.first.fromPublicKey, 'B' * 64, reason: 'normalised key');
      expect(rows.first.groupName, 'DX net');
      expect(rows.first.kind, GroupKind.group);
      expect(rows.last.kind, GroupKind.conference);
      expect(await chat.groupInviteChanges.first, hasLength(2));
    });

    test('an unchanged invite list does not re-emit', () async {
      ffi.pendingInvites = [invite('inv_1')];
      await bind();
      final events = <List<GroupInvite>>[];
      final sub = chat.groupInviteChanges.listen(events.add);
      await pumpEventQueue();
      final before = events.length;
      final readsBefore = inviteReads;
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(
        inviteReads,
        greaterThanOrEqualTo(readsBefore + 2),
        reason: 'polling kept reading the invites',
      );
      expect(events.length, before, reason: 'several ticks, same invites');
      await sub.cancel();
    });

    test('accept joins through Tox and drops the invite', () async {
      ffi.pendingInvites = [invite('inv_1')];
      await bind();
      await chat.acceptGroupInvite('inv_1');
      expect(ffi.joins, [('inv_1', '')]);
      expect(ffi.pendingInvites, isEmpty, reason: 'native dropped it');
      expect(chat.groupInvites, isEmpty, reason: 'refreshed on accept');
    });

    test('accept with a password uses the password binding', () async {
      ffi.pendingInvites = [invite('inv_1')];
      await bind();
      await chat.acceptGroupInvite('inv_1', password: 'pw');
      expect(ffi.passwordJoins, [('inv_1', 'pw')]);
    });

    test('a refused accept keeps the invite and reports accept_failed', () async {
      ffi.pendingInvites = [invite('inv_1')];
      await bind();
      ffi.joinRc = 0;
      await expectLater(chat.acceptGroupInvite('inv_1'), throwsCode('accept_failed'));
      expect(chat.groupInvites.map((i) => i.inviteId), ['inv_1']);
    });

    test('reject forgets the invite natively and in the list', () async {
      ffi.pendingInvites = [invite('inv_1'), invite('inv_2')];
      await bind();
      await chat.rejectGroupInvite('inv_1');
      expect(ffi.rejected, ['inv_1']);
      expect(chat.groupInvites.map((i) => i.inviteId), ['inv_2']);
    });
  });

  group('names and refusals', () {
    test('the name shared on the wire wins over the local record', () async {
      final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
      await prefs.setGroupName('tox_1', 'Local');
      ffi.sharedNames['tox_1'] = '  Shared  ';
      engineService.debugAddKnownGroupForTest('tox_1');
      await bind();
      expect(chat.groups.single.name, 'Shared');
      expect(
        chat.conversations.firstWhere((c) => c.id == 'group_tox_1').title,
        'Shared',
      );
    });

    test('a refused join is logged and the list is refreshed', () async {
      engineService.debugAddKnownGroupForTest('tox_7');
      await bind();
      expect(chat.groups.map((g) => g.id), ['tox_7']);
      await engineService.handleGroupJoinFailed(
        'tox_7',
        'c' * 64,
        'invalid_password',
        established: true,
      );
      await pumpEventQueue();
      final warning = logger.records.firstWhere(
        (r) => r.level == ChatLogLevel.warning,
      );
      expect(warning.message, contains('tox_7'));
      expect(warning.message, contains('invalidPassword'));
      // An established group refused on reconnect is kept.
      expect(chat.groups.map((g) => g.id), ['tox_7']);
    });
  });
}
