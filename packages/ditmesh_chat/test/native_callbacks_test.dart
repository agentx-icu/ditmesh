import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/engine/native_callbacks.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// The custom-callback hook ditmesh installs in place of Tim2ToxSdkPlatform.
/// Driven directly (no native port); the service underneath is a real
/// `FfiChatService` over the fake FFI, so the callbacks land in the same
/// completers and group state the native session would fill.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late FfiChatService svc;
  late MemoryChatLogger logger;
  late NativeCustomCallbacks router;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_cb_');
    ffi = FakeTim2ToxFfi();
    svc = await newEngineService(ffi, MemoryKeyValueStore(), tempRoot, 'id');
    logger = MemoryChatLogger();
    router = NativeCustomCallbacks(logger)..target = svc;
  });

  tearDown(() async {
    router.target = null;
    await svc.dispose();
    await tempRoot.delete(recursive: true);
  });

  test('friendAddResult resolves the pending addFriend with the native code',
      () async {
    final pending = svc.addFriend(kPeerToxId, requestMessage: 'CQ');
    expect(ffi.addedFriends, [kPeerToxId]);
    await router.handle('friendAddResult', {
      'user_id': kPeerToxId,
      'result_code': 6770,
      'result_info': 'Friend add requires full Tox address',
    }, {});
    final result = await pending.timeout(const Duration(seconds: 2));
    expect(result.isSuccess, isFalse);
    expect(result.resultCode, 6770);
    expect(result.resultInfo, contains('full Tox address'));
  });

  test('friendAddResult success (code 0, string-typed) resolves too', () async {
    final pending = svc.addFriend(kPeerToxId, requestMessage: 'CQ');
    await router.handle('friendAddResult', {
      'user_id': kPeerToxId,
      'result_code': '0',
      'result_info': '',
    }, {});
    final result = await pending.timeout(const Duration(seconds: 2));
    expect(result.isSuccess, isTrue);
  });

  test('without a live session every callback is dropped, none throws',
      () async {
    router.target = null;
    await router.handle('friendAddResult', {'user_id': kPeerToxId}, {});
    await router.handle('groupJoinNotification', {'group_id': 'g1'}, {});
    expect(svc.knownGroups, isEmpty);
    expect(
      logger.records.map((r) => r.message),
      everyElement(contains('dropped: no live session')),
    );
  });

  test('a session-scoped notification from another epoch is dropped',
      () async {
    ffi.sessionEpoch = 3;
    await router.handle('groupJoinNotification', {
      'group_id': 'g_old',
      'instance_id': 0,
      'session_epoch': 2,
    }, {});
    expect(svc.knownGroups, isNot(contains('g_old')));
    expect(
      logger.records.map((r) => r.message),
      anyElement(contains('not this session')),
    );
  });

  test('a session-scoped notification from the live epoch is applied',
      () async {
    ffi.sessionEpoch = 3;
    await router.handle('groupJoinNotification', {
      'group_id': 'g_live',
      'instance_id': 0,
      'session_epoch': 3,
    }, {});
    expect(svc.knownGroups, contains('g_live'));
  });

  test('unknown callbacks are ignored with a log line, not an error', () async {
    await router.handle('clearHistoryMessage', {'conv_id': 'x'}, {});
    expect(
      logger.records.map((r) => r.message),
      anyElement(contains('clearHistoryMessage ignored')),
    );
    expect(logger.records.where((r) => r.level == ChatLogLevel.error), isEmpty);
  });

  test('uninstall clears only our own hook', () {
    Future<void> foreign(String n, Map<String, dynamic> d,
            Map<String, ApiCallback> m) async {}
    NativeLibraryManager.customCallbackHandler = foreign;
    router.uninstall();
    expect(NativeLibraryManager.customCallbackHandler, same(foreign));

    NativeLibraryManager.customCallbackHandler = router.handle;
    router.uninstall();
    expect(NativeLibraryManager.customCallbackHandler, isNull);
    expect(router.target, isNull);
  });
}
