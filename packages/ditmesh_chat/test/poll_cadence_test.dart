import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Counts event drains; the queue is always empty.
class _CountingFfi extends FakeTim2ToxFfi {
  int polls = 0;

  @override
  int Function(int, ffi.Pointer<ffi.Int8>, int) get pollText => (_, _, _) {
    polls++;
    return 0;
  };
}

Duration _interval({
  bool av = false,
  bool files = false,
  bool known = false,
  bool shared = false,
  Duration since = const Duration(seconds: 10),
  Duration? idle,
}) => idle == null
    ? FfiChatService.computePollInterval(
        avSessionActive: av,
        hasActiveFileTransfer: files,
        hasKnownInstances: known,
        isSharedInstance: shared,
        timeSinceActivity: since,
      )
    : FfiChatService.computePollInterval(
        avSessionActive: av,
        hasActiveFileTransfer: files,
        hasKnownInstances: known,
        isSharedInstance: shared,
        timeSinceActivity: since,
        idleInterval: idle,
      );

const _ms = Duration(milliseconds: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('poll interval policy', () {
    test('keeps the upstream priorities and default idle cadence', () {
      expect(_interval(av: true, files: true, shared: true), _ms * 20);
      expect(_interval(files: true), _ms * 50);
      expect(_interval(known: true), _ms * 50);
      expect(_interval(shared: true), _ms * 50);
      expect(_interval(since: const Duration(seconds: 1)), _ms * 200);
      expect(_interval(), _ms * 1000);
    });

    test('an integrator idle cadence applies only when quiet', () {
      final idle = DitmeshFfiChatService.idleCadence;
      expect(_interval(idle: idle), idle);
      expect(_interval(since: _ms * 1999, idle: idle), _ms * 200);
      expect(_interval(known: true, idle: idle), _ms * 50);
      expect(_interval(av: true, idle: idle), _ms * 20);
    });
  });

  group('session cadence on the default native instance', () {
    late Directory root;
    late _CountingFfi ffi;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('ditmesh_poll_');
      ffi = _CountingFfi();
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    Future<FfiChatService> start(bool ditmesh) async {
      final svc = ditmesh
          ? DitmeshFfiChatService(
              ffiForTesting: ffi,
              historyDirectory: root.path,
            )
          : FfiChatService(ffiForTesting: ffi, historyDirectory: root.path);
      svc
        ..debugBeginSessionForTest()
        ..debugNativePendingInvitesOverride = () => const [];
      await svc.startPolling();
      return svc;
    }

    Future<int> pollsDuring(Duration window) async {
      final before = ffi.polls;
      await Future<void>.delayed(window);
      return ffi.polls - before;
    }

    test(
      'upstream treats instance 0 as shared and polls every 50 ms',
      () async {
        final svc = await start(false);
        try {
          expect(svc.pollDefaultInstanceAsShared, isTrue);
          expect(
            await pollsDuring(const Duration(seconds: 1)),
            greaterThan(12),
          );
        } finally {
          await svc.dispose();
        }
      },
    );

    test('DitMesh backs off to 200 ms, then the idle cadence, and wakes on '
        'outbound activity', () async {
      final svc = await start(true);
      try {
        expect(svc.pollDefaultInstanceAsShared, isFalse);
        expect(svc.idlePollInterval, DitmeshFfiChatService.idleCadence);
        // Active window right after login: 200 ms.
        expect(
          await pollsDuring(const Duration(seconds: 1)),
          inInclusiveRange(3, 7),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        // Quiet: 500 ms.
        expect(
          await pollsDuring(const Duration(milliseconds: 1500)),
          inInclusiveRange(1, 4),
        );
        // A send re-arms the idle timer at the active cadence.
        final before = ffi.polls;
        svc.notePollActivity();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(ffi.polls, greaterThan(before));
      } finally {
        await svc.dispose();
      }
    });
  });
}
