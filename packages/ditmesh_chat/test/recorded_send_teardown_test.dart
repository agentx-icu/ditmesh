import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'helpers/fakes.dart';

class LegacyFfi extends FakeTim2ToxFfi {
  int controls = 0;
  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int, int)
  get sendC2CControlNative => (_, _, _, _) {
    controls++;
    return 1;
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'capability timeout must not send plaintext after native teardown',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_rhythm_teardown_',
      );
      final native = LegacyFfi()
        ..friends.add((userId: kPeerKey, nick: 'Legacy Bob', online: true));
      final svc =
          DitmeshFfiChatService(
              historyDirectory: root.path,
              ffiForTesting: native,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      try {
        final send = svc
            .sendTextWithResult(
              kPeerKey,
              'CQ',
              clientMessageID: 'dmr:${'a' * 32}',
              cloudCustomData: RecordingMetadata.encode(
                KeyedRecording(durationsMs: [83]),
              ),
            )
            .then<Object?>((_) => null, onError: (Object e) => e);
        while (native.controls == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await svc.dispose();
        expect(native.uninitCalls, 1);
        final outcome = await send;
        expect(outcome, isA<StateError>());
        expect(native.sentTextPeers, isEmpty);
      } finally {
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
