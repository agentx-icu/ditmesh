import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

typedef _EventCallback =
    ffi.Void Function(
      ffi.Int32,
      ffi.Pointer<pkgffi.Utf8>,
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32,
      ffi.Pointer<ffi.Void>,
    );

/// Run the real Dart init/restore path while native entry points stay inert.
class _InitFfi extends FakeTim2ToxFfi {
  final List<PendingGroupInvite> invites = [];

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>) get initWithPath =>
      (_) => 1;

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>) get setFileRecvDir =>
      (_) => 1;

  @override
  void Function(
    ffi.Pointer<ffi.NativeFunction<_EventCallback>>,
    ffi.Pointer<ffi.Void>,
  )
  get setCallback => (_, _) {};

  @override
  int Function() get ircIsLibraryLoaded =>
      () => 0;

  @override
  int Function(
    ffi.Pointer<pkgffi.Utf8>,
    ffi.Pointer<pkgffi.Utf8>,
    ffi.Pointer<pkgffi.Utf8>,
    ffi.Pointer<pkgffi.Utf8>,
    int,
    ffi.Pointer<pkgffi.Utf8>,
  )
  get restoreGroupInvite => (id, inviter, kind, name, time, cookie) {
    invites.add(
      PendingGroupInvite(
        id: id.toDartString(),
        inviterUserId: inviter.toDartString(),
        kind: kind.toDartString(),
        groupName: name.toDartString(),
        receivedAt: DateTime.fromMillisecondsSinceEpoch(time),
        cookieHex: cookie.toDartString(),
      ),
    );
    return 1;
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const provider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory root;
  late IdentityPaths paths;
  late MemoryKeyValueStore store;
  final services = <FfiChatService>[];

  Future<FfiChatService> start(_InitFfi native) async {
    final service = FfiChatService(
      ffiForTesting: native,
      preferencesService: Tim2ToxPreferencesAdapter(
        store,
        accountPrefix: '1111111111111111',
      ),
      historyDirectory: paths.historyDirectory,
      queueFilePath: paths.offlineQueueFile,
      fileRecvPath: paths.fileRecvDirectory,
      avatarsPath: paths.avatarsDirectory,
    )..debugNativePendingInvitesOverride = () => native.invites;
    services.add(service);
    await service.init(profileDirectory: paths.profileDirectory);
    return service;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('transport_persistence_');
    paths = IdentityPaths('${root.path}/identity');
    await paths.ensureDirectories();
    store = MemoryKeyValueStore();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(provider, (_) async => root.path);
  });

  tearDown(() async {
    for (final service in services) {
      await service.dispose();
    }
    services.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(provider, null);
    await root.delete(recursive: true);
  });

  test(
    'group membership, unread and read state restore through real init',
    () async {
      final prefs = Tim2ToxPreferencesAdapter(
        store,
        accountPrefix: '1111111111111111',
      );
      await prefs.setGroups({'tox_1'});
      await prefs.setGroupName('tox_1', 'CQ net');
      final first = await start(_InitFfi());
      first.ingestInboundGroupText(gid: 'tox_1', from: kPeerKey, text: 'CQ');
      await first.flushPendingHistory();
      expect(first.getUnreadOf('tox_1'), 1);
      await first.dispose();
      final second = await start(_InitFfi());
      expect(second.knownGroups, contains('tox_1'));
      expect(await prefs.getGroupName('tox_1'), 'CQ net');
      expect(second.getHistory('tox_1').single.text, 'CQ');
      expect(second.getUnreadOf('tox_1'), 1);
      await second.markConversationRead('tox_1');
      await second.dispose();
      final third = await start(_InitFfi());
      expect(third.getUnreadOf('tox_1'), 0);
      expect(third.getHistory('tox_1').single.isRead, isTrue);
    },
  );

  test(
    'unanswered group invite cookie restores into a fresh native session',
    () async {
      final native = _InitFfi();
      final first = await start(native);
      native.invites.add(
        PendingGroupInvite(
          id: 'invite-1',
          inviterUserId: kPeerKey,
          kind: 'group',
          groupName: 'CQ net',
          receivedAt: DateTime.fromMillisecondsSinceEpoch(42),
          cookieHex: 'a' * 64,
        ),
      );
      first.notifyPendingGroupInvitesChanged();
      await first.dispose(); // Drains the upstream invite persistence tail.
      final restartedNative = _InitFfi();
      final restarted = await start(restartedNative);
      expect(restarted.getPendingGroupInvites(), hasLength(1));
      final restored = restarted.getPendingGroupInvites().single;
      expect(restored.id, 'invite-1');
      expect(restored.cookieHex, 'a' * 64);
      expect(restored.receivedAt.millisecondsSinceEpoch, 42);
    },
  );
}
