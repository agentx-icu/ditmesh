import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

const _hex = '0123456789ABCDEF';

Identity _identity({bool hasPassword = false}) => Identity(
  toxId: FakeIdentityService.toxIdForSeed(7),
  displayName: 'Ann',
  hasPassword: hasPassword,
);

void main() {
  late FakeIdentityService service;

  tearDown(() => service.dispose());

  group('fresh install', () {
    setUp(() {
      service = FakeIdentityService(connectDelay: Duration.zero);
    });

    test('inspect reports none and create makes it ready', () async {
      expect(await service.inspect(), IdentityState.none);
      final id = await service.create(displayName: '  Ann ');
      expect(id.displayName, 'Ann');
      expect(id.hasPassword, isFalse);
      expect(id.toxId, hasLength(76));
      expect(id.toxId.split('').every(_hex.contains), isTrue);
      expect(service.current, id);
      expect(await service.inspect(), IdentityState.ready);
    });

    test('tox ids are deterministic per seed and distinct across seeds', () {
      expect(
        FakeIdentityService.toxIdForSeed(3),
        FakeIdentityService.toxIdForSeed(3),
      );
      expect(
        FakeIdentityService.toxIdForSeed(3),
        isNot(FakeIdentityService.toxIdForSeed(4)),
      );
    });

    test('create with a password marks the profile encrypted', () async {
      final id = await service.create(displayName: 'Ann', password: 'pw');
      expect(id.hasPassword, isTrue);
      expect(service.storedPassword, 'pw');
    });

    test('create rejects an empty display name', () {
      expect(
        () => service.create(displayName: '   '),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'invalid_name'),
        ),
      );
    });

    test('open / connect / export without an identity throw no_identity', () {
      final noIdentity = isA<ChatException>().having(
        (e) => e.code,
        'code',
        'no_identity',
      );
      expect(service.open, throwsA(noIdentity));
      expect(service.connect, throwsA(noIdentity));
      expect(service.exportBackup, throwsA(noIdentity));
    });
  });

  group('locked profile', () {
    setUp(() {
      service = FakeIdentityService.withProfile(
        identity: _identity(),
        password: 'secret',
        connectDelay: Duration.zero,
      );
    });

    test('inspect reports locked until unlocked', () async {
      expect(await service.inspect(), IdentityState.locked);
      expect(service.current, isNull);
    });

    test('open() refuses while locked', () {
      expect(
        service.open,
        throwsA(isA<ChatException>().having((e) => e.code, 'code', 'locked')),
      );
    });

    test('wrong password throws wrong_password and stays locked', () async {
      expect(
        () => service.unlock('nope'),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'wrong_password'),
        ),
      );
      expect(await service.inspect(), IdentityState.locked);
    });

    test('correct password unlocks and inspect becomes ready', () async {
      final events = <Identity?>[];
      final sub = service.identityChanges.listen(events.add);
      final id = await service.unlock('secret');
      expect(id.hasPassword, isTrue);
      expect(service.current, isNotNull);
      expect(await service.inspect(), IdentityState.ready);
      await Future<void>.delayed(Duration.zero);
      expect(events, [id]);
      await sub.cancel();
    });

    test(
      'changePassword requires the old password and can remove it',
      () async {
        await service.unlock('secret');
        expect(
          () => service.changePassword(oldPassword: 'bad', newPassword: 'x'),
          throwsA(
            isA<ChatException>().having(
              (e) => e.code,
              'code',
              'wrong_password',
            ),
          ),
        );
        await service.changePassword(oldPassword: 'secret', newPassword: 'new');
        expect(service.storedPassword, 'new');
        await service.changePassword(oldPassword: 'new');
        expect(service.storedPassword, isNull);
        expect(service.current!.hasPassword, isFalse);
      },
    );
  });

  group('ready profile', () {
    setUp(() {
      service = FakeIdentityService.withProfile(
        identity: _identity(),
        connectDelay: Duration.zero,
      );
    });

    test('inspect reports ready and open loads the identity', () async {
      expect(await service.inspect(), IdentityState.ready);
      final id = await service.open();
      expect(id.displayName, 'Ann');
      expect(service.current, id);
    });

    test('updateProfile changes name and status', () async {
      await service.open();
      final id = await service.updateProfile(
        displayName: 'Bob',
        statusMessage: 'QRV',
      );
      expect(id.displayName, 'Bob');
      expect(id.statusMessage, 'QRV');
      expect(service.current, id);
    });

    test('connect goes connecting → online and is idempotent', () async {
      await service.open();
      final seen = <ConnectionStatus>[];
      final sub = service.connectionChanges.listen(seen.add);
      await service.connect();
      await service.connect();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [ConnectionStatus.connecting, ConnectionStatus.online]);
      expect(service.connectionStatus, ConnectionStatus.online);
      await service.disconnect();
      expect(service.connectionStatus, ConnectionStatus.offline);
      await sub.cancel();
    });

    test('connect honours a non-zero delay', () async {
      await service.dispose();
      service = FakeIdentityService.withProfile(
        identity: _identity(),
        connectDelay: const Duration(milliseconds: 20),
      );
      await service.open();
      await service.connect();
      expect(service.connectionStatus, ConnectionStatus.connecting);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(service.connectionStatus, ConnectionStatus.online);
    });

    test('backup round-trips through export/import', () async {
      await service.open();
      await service.changePassword(newPassword: 'pw');
      final bytes = await service.exportBackup();
      expect(bytes, isNotEmpty);

      final other = FakeIdentityService(connectDelay: Duration.zero);
      addTearDown(other.dispose);
      expect(
        () => other.importBackup(bytes),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'wrong_password'),
        ),
      );
      final restored = await other.importBackup(bytes, password: 'pw');
      expect(restored.toxId, service.current!.toxId);
      expect(restored.displayName, 'Ann');
      expect(restored.hasPassword, isTrue);
      expect(await other.inspect(), IdentityState.ready);
    });

    test('importBackup rejects garbage', () {
      expect(
        () => service.importBackup(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'invalid_backup'),
        ),
      );
    });

    test('deleteIdentity wipes the disk and goes offline', () async {
      await service.open();
      await service.connect();
      await service.deleteIdentity();
      expect(service.current, isNull);
      expect(service.hasStoredProfile, isFalse);
      expect(service.connectionStatus, ConnectionStatus.offline);
      expect(await service.inspect(), IdentityState.none);
    });

    test('dataDirectory is a created per-identity temp path', () async {
      await service.open();
      final path = await service.dataDirectory();
      expect(Directory(path).existsSync(), isTrue);
      expect(path, contains(service.current!.publicKey.substring(0, 16)));
    });

    test('inspectError is thrown once for the retry path', () async {
      service.inspectError = StateError('disk unreadable');
      expect(service.inspect, throwsStateError);
      expect(await service.inspect(), IdentityState.ready);
    });
  });
}
