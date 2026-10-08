import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

/// Records every exclusion and whether the directory existed at that time
/// (setting the iOS resource value needs an existing item).
class _RecordingExclusion implements BackupExclusion {
  final List<String> paths = [];
  final List<bool> existed = [];

  @override
  Future<void> exclude(String path) async {
    paths.add(path);
    existed.add(Directory(path).existsSync());
  }
}

class _ThrowingExclusion implements BackupExclusion {
  @override
  Future<void> exclude(String path) => throw StateError('boom');
}

class _Logs implements ChatLogger {
  final List<ChatLogRecord> records = [];

  @override
  void log(ChatLogRecord record) => records.add(record);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MethodChannelBackupExclusion.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_backup_excl_');
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  group('MethodChannelBackupExclusion', () {
    test('sends the directory path to the native side', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      await MethodChannelBackupExclusion().exclude('/x/ditmesh');
      expect(calls, hasLength(1));
      expect(calls.single.method, MethodChannelBackupExclusion.methodName);
      expect(calls.single.arguments, '/x/ditmesh');
    });

    test('a native error is logged, not thrown', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'SET_FAILED', message: 'nope');
      });
      final logs = _Logs();
      await MethodChannelBackupExclusion(logger: logs).exclude('/x');
      expect(logs.records.single.level, ChatLogLevel.error);
      expect(logs.records.single.error, isA<PlatformException>());
    });

    test('a missing native handler is logged, not thrown', () async {
      final logs = _Logs();
      await MethodChannelBackupExclusion(logger: logs).exclude('/x');
      expect(logs.records.single.error, isA<MissingPluginException>());
    });
  });

  group('BackupExclusion.forPlatform', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('uses the channel on iOS only', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          BackupExclusion.forPlatform(),
          platform == TargetPlatform.iOS
              ? isA<MethodChannelBackupExclusion>()
              : isA<NoBackupExclusion>(),
          reason: platform.name,
        );
      }
    });
  });

  group('IdentityPaths', () {
    test('ensureDirectories excludes the existing parent of the root', () async {
      final exclusion = _RecordingExclusion();
      final paths = IdentityPaths(
        p.join(tempRoot.path, 'ditmesh', 'identity'),
        backupExclusion: exclusion,
      );
      expect(paths.backupExclusionRoot, p.join(tempRoot.path, 'ditmesh'));
      await paths.ensureDirectories();
      expect(exclusion.paths, [p.join(tempRoot.path, 'ditmesh')]);
      expect(exclusion.existed, [isTrue]);
    });

    test('an exclusion failure does not fail ensureDirectories', () async {
      final paths = IdentityPaths(
        p.join(tempRoot.path, 'ditmesh', 'identity'),
        backupExclusion: _ThrowingExclusion(),
      );
      await paths.ensureDirectories();
      expect(Directory(paths.profileDirectory).existsSync(), isTrue);
    });

    test('the default (tests, desktop) excludes nothing', () async {
      final paths = IdentityPaths(p.join(tempRoot.path, 'identity'));
      expect(paths.backupExclusion, isA<NoBackupExclusion>());
      await paths.ensureDirectories();
    });
  });

  group('identity service', () {
    late FakeChatEngine engine;
    late _RecordingExclusion exclusion;
    late IdentityPaths paths;

    setUp(() {
      engine = FakeChatEngine();
      exclusion = _RecordingExclusion();
      paths = IdentityPaths(
        p.join(tempRoot.path, 'ditmesh', 'identity'),
        backupExclusion: exclusion,
      );
    });

    tearDown(() => engine.dispose());

    Tim2ToxIdentityService newService(IdentityPaths paths) =>
        Tim2ToxIdentityService(
          paths: paths,
          engine: engine,
          crypto: FakeProfileCrypto(),
          verifier: PasswordVerifier(MemorySecureStore(), iterations: 10),
        );

    // Existing installs are covered by inspect (startup, any state) and on
    // connect: Tim2ToxEngine.start runs ensureDirectories (the fake engine
    // does not, so that path is not asserted).
    test('inspect excludes an existing locked identity (upgrade)', () async {
      // Installed before the exclusion: no recording exclusion yet.
      final old = newService(
        IdentityPaths(p.join(tempRoot.path, 'ditmesh', 'identity')),
      );
      await old.create(displayName: 'W1AW', password: 'pw');
      await old.dispose();
      expect(exclusion.paths, isEmpty);

      final secure = MemorySecureStore();
      final upgraded = Tim2ToxIdentityService(
        paths: paths,
        engine: engine,
        crypto: FakeProfileCrypto(),
        verifier: PasswordVerifier(secure, iterations: 10),
      );
      // identity.json carries hasPassword, so a fresh verifier store still
      // reports locked; the user never unlocks.
      expect(await upgraded.inspect(), IdentityState.locked);
      expect(exclusion.paths, [p.join(tempRoot.path, 'ditmesh')]);
      expect(exclusion.existed, [isTrue]);
      // Once per service, not on every inspect.
      expect(await upgraded.inspect(), IdentityState.locked);
      expect(exclusion.paths, hasLength(1));
      await upgraded.dispose();
    });

    test('inspect with no identity on disk creates nothing', () async {
      final svc = newService(paths);
      expect(await svc.inspect(), IdentityState.none);
      expect(exclusion.paths, isEmpty);
      expect(Directory(paths.backupExclusionRoot).existsSync(), isFalse);
      // A later create still excludes (via ensureDirectories).
      await svc.create(displayName: 'W1AW');
      expect(exclusion.paths.toSet(), {paths.backupExclusionRoot});
      await svc.dispose();
    });

    test('inspect excludes an existing container without an identity', () async {
      Directory(paths.backupExclusionRoot).createSync(recursive: true);
      final svc = newService(paths);
      expect(await svc.inspect(), IdentityState.none);
      expect(exclusion.paths, [paths.backupExclusionRoot]);
      await svc.dispose();
    });

    test('an exclusion failure does not fail inspect', () async {
      Directory(paths.backupExclusionRoot).createSync(recursive: true);
      final svc = newService(
        IdentityPaths(paths.root, backupExclusion: _ThrowingExclusion()),
      );
      expect(await svc.inspect(), IdentityState.none);
      await svc.dispose();
    });

    test('create excludes the identity container', () async {
      final svc = newService(paths);
      await svc.create(displayName: 'W1AW');
      expect(exclusion.paths, isNotEmpty);
      expect(exclusion.paths.toSet(), {paths.backupExclusionRoot});
      expect(exclusion.existed, everyElement(isTrue));
      await svc.dispose();
    });

    test('a restore on a fresh install excludes before staging', () async {
      final source = newService(
        IdentityPaths(p.join(tempRoot.path, 'source', 'identity')),
      );
      await source.create(displayName: 'DL1ABC');
      final bytes = await source.exportBackup();
      await source.dispose();

      final restored = newService(paths);
      await restored.importBackup(bytes);
      expect(exclusion.paths.first, paths.backupExclusionRoot);
      expect(exclusion.existed.first, isTrue);
      // The staging directory lived inside the excluded container and is gone.
      expect(
        Directory(paths.backupExclusionRoot)
            .listSync()
            .map((e) => p.basename(e.path)),
        ['identity'],
      );
      await restored.dispose();
    });
  });
}
