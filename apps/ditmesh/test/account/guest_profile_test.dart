import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/startup/startup_controller.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/guest_profile.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/training/training_doc_store.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:path/path.dart' as p;

Future<Directory> _tmp() async {
  final d = await Directory.systemTemp.createTemp('ditmesh_guest_');
  addTearDown(() => d.delete(recursive: true));
  return d;
}

Future<void> _writeGuestProgress(String guestDir, int lesson) =>
    FileTrainerStore.inDataDirectory(
      guestDir,
    ).save(TrainerProgress(currentLesson: lesson));

void main() {
  group('GuestMigration', () {
    test('moves progress, records completion, retry is a no-op', () async {
      final root = await _tmp();
      final guest = p.join(root.path, 'guest');
      final identity = p.join(root.path, 'id');
      await _writeGuestProgress(guest, 7);
      final m = GuestMigration(
        guestDirectory: guest,
        identityDirectory: identity,
        generation: 'g1',
      );
      final now = DateTime(2026, 10, 3);
      expect(await m.run(identityKey: 'AB', now: now), MigrationOutcome.done);
      final moved = await FileTrainerStore.inDataDirectory(identity).load();
      expect(moved!.currentLesson, 7);
      expect(await Directory(p.join(guest, 'training')).exists(), isFalse);
      expect(
        await m.run(identityKey: 'AB', now: now),
        MigrationOutcome.alreadyDone,
      );
    });

    test(
      'an unreadable guest file fails before commit; guest data stays',
      () async {
        final root = await _tmp();
        final guest = p.join(root.path, 'guest');
        final identity = p.join(root.path, 'id');
        final file = File(p.join(guest, 'training', 'progress.json'));
        await file.create(recursive: true);
        await file.writeAsString('{broken');
        final m = GuestMigration(
          guestDirectory: guest,
          identityDirectory: identity,
          generation: 'g1',
        );
        await expectLater(
          m.run(identityKey: 'AB', now: DateTime(2026)),
          throwsA(anything),
        );
        expect(await file.exists(), isTrue, reason: 'guest data intact');
        expect(await Directory(p.join(identity, 'training')).exists(), isFalse);
      },
    );

    test(
      'an existing identity training dir is moved aside, never lost',
      () async {
        final root = await _tmp();
        final guest = p.join(root.path, 'guest');
        final identity = p.join(root.path, 'id');
        await _writeGuestProgress(guest, 4);
        await FileTrainerStore.inDataDirectory(
          identity,
        ).save(TrainerProgress(currentLesson: 20));
        await GuestMigration(
          guestDirectory: guest,
          identityDirectory: identity,
          generation: 'g1',
        ).run(identityKey: 'CD', now: DateTime(2026, 1, 1));
        final now = await FileTrainerStore.inDataDirectory(identity).load();
        expect(now!.currentLesson, 4);
        final aside = Directory(identity)
            .listSync()
            .whereType<Directory>()
            .where(
              (d) => p.basename(d.path).startsWith('training.before-guest'),
            );
        expect(aside, hasLength(1));
        final kept =
            jsonDecode(
                  File(
                    p.join(aside.single.path, 'progress.json'),
                  ).readAsStringSync(),
                )
                as Map<String, Object?>;
        expect(kept['currentLesson'], 20);
      },
    );
  });

  group('GuestMigration recovery', () {
    test('a crash after the commit resumes without redoing the copy', () async {
      final root = await _tmp();
      final guest = p.join(root.path, 'guest');
      final identity = p.join(root.path, 'id');
      await _writeGuestProgress(guest, 6);
      // Simulate: journal written, staged copy committed, bookkeeping lost.
      await Directory(p.join(identity, 'training')).create(recursive: true);
      await File(
        p.join(guest, 'training', 'progress.json'),
      ).copy(p.join(identity, 'training', 'progress.json'));
      await File(p.join(guest, 'migration-journal.json')).writeAsString(
        jsonEncode({'state': 'committing', 'key': 'AB', 'generation': 'g1'}),
      );
      // Newer identity activity after the commit must survive the resume.
      await FileTrainerStore.inDataDirectory(
        identity,
      ).save(TrainerProgress(currentLesson: 12));
      final m = GuestMigration(
        guestDirectory: guest,
        identityDirectory: identity,
        generation: 'g1',
      );
      expect(
        await m.run(identityKey: 'AB', now: DateTime(2026)),
        MigrationOutcome.done,
      );
      final now = await FileTrainerStore.inDataDirectory(identity).load();
      expect(now!.currentLesson, 12);
      expect(await GuestMigration.hasJournal(guest), isFalse);
    });

    test(
      'new guest data after a migration is not hidden by its marker',
      () async {
        final root = await _tmp();
        final store = GuestStore(root: () async => p.join(root.path, 'guest'));
        final identity = p.join(root.path, 'id');
        final guestDir = await store.directory();
        Future<void> migrate() async => GuestMigration(
          guestDirectory: guestDir,
          identityDirectory: identity,
          generation: await store.generation(),
        ).run(identityKey: 'AB', now: DateTime(2026));
        await _writeGuestProgress(guestDir, 3);
        await migrate();
        await _writeGuestProgress(guestDir, 8);
        expect(await store.hasProgress(), isTrue);
        await migrate();
        final moved = await FileTrainerStore.inDataDirectory(identity).load();
        expect(moved!.currentLesson, 8);
      },
    );

    test(
      'saved recordings move with the guest data; identity media stay',
      () async {
        final root = await _tmp();
        final guest = p.join(root.path, 'guest');
        final identity = p.join(root.path, 'id');
        await _writeGuestProgress(guest, 2);
        Future<void> put(String dir, String name, String body) async {
          final f = File(p.join(dir, 'media', 'recordings', name));
          await f.create(recursive: true);
          await f.writeAsString(body);
        }

        await put(guest, 'rec_a.wav', 'guest-a');
        await put(guest, 'current.wav', 'guest-working');
        await put(guest, 'rec_same.wav', 'guest-same');
        // Identity media live in the identity root, beside `identity` (the
        // backed-up data directory).
        await put(root.path, 'rec_same.wav', 'identity-same');
        await put(root.path, 'current.wav', 'identity-working');
        // The guest's saved selection refers to its colliding recording.
        final doc = File(
          p.join(guest, 'training', 'docs', 'audio_materials.json'),
        );
        await doc.create(recursive: true);
        await doc.writeAsString(
          jsonEncode({
            'v': 1,
            'materials': [
              {'id': 'x', 'file': 'media/recordings/rec_same.wav'},
              {'id': 'y', 'file': 'media/recordings/rec_a.wav'},
            ],
          }),
        );
        await GuestMigration(
          guestDirectory: guest,
          identityDirectory: identity,
          generation: 'g1',
        ).run(identityKey: 'AB', now: DateTime(2026));
        String read(String name) => File(
          p.join(root.path, 'media', 'recordings', name),
        ).readAsStringSync();
        expect(read('rec_a.wav'), 'guest-a');
        expect(read('rec_same.wav'), 'identity-same');
        expect(read('current.wav'), 'identity-working');
        // The colliding guest recording kept under a new name, and the
        // migrated reference follows it.
        final migrated =
            jsonDecode(
                  File(
                    p.join(identity, 'training', 'docs', 'audio_materials.json'),
                  ).readAsStringSync(),
                )
                as Map<String, Object?>;
        final refs = [
          for (final m in migrated['materials']! as List)
            (m as Map)['file'] as String,
        ];
        expect(refs[1], 'media/recordings/rec_a.wav');
        expect(refs[0], isNot('media/recordings/rec_same.wav'));
        expect(read(p.posix.basename(refs[0])), 'guest-same');
        expect(Directory(p.join(guest, 'media')).existsSync(), isFalse);
        expect(
          Directory(
            p.join(root.path, 'media', 'recordings.guest-staging'),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test('clearing guest data also removes guest recordings', () async {
      final root = await _tmp();
      final store = GuestStore(root: () async => p.join(root.path, 'guest'));
      final f = File(
        p.join(await store.directory(), 'media', 'recordings', 'rec_x.wav'),
      );
      await f.create(recursive: true);
      await store.clear();
      expect(f.existsSync(), isFalse);
    });

    test('settings-only guest data counts as data to move', () async {
      final root = await _tmp();
      final store = GuestStore(root: () async => p.join(root.path, 'guest'));
      expect(await store.hasProgress(), isFalse);
      await FileTrainingSettingsStore.inDataDirectory(
        await store.directory(),
      ).save(const TrainingSettings(planMinutes: 15));
      expect(await store.hasProgress(), isTrue);
    });
  });

  group('StartupController guest mode', () {
    late Directory root;
    late GuestStore store;
    late FakeIdentityService identity;
    var released = 0;

    StartupController controller() => StartupController(
      identity,
      guest: GuestHooks(
        store: store,
        releaseGuestController: () async => released++,
      ),
      now: () => DateTime(2026, 10, 3),
    );

    setUp(() async {
      root = await Directory.systemTemp.createTemp('ditmesh_guest_start_');
      store = GuestStore(root: () async => p.join(root.path, 'guest'));
      identity = FakeIdentityService(
        connectDelay: Duration.zero,
        dataDirectoryPath: p.join(root.path, 'ids'),
      );
      released = 0;
    });
    tearDown(() => root.delete(recursive: true));

    test('guest mode is remembered across restarts', () async {
      final c = controller();
      await c.ensureStarted();
      expect(c.phase, StartupPhase.onboarding);
      await c.enterGuest();
      expect(c.phase, StartupPhase.guest);
      expect(c.guestMode.value, isTrue);
      expect(identity.current, isNull, reason: 'no Tox identity created');
      c.dispose();

      final again = controller();
      await again.ensureStarted();
      expect(again.phase, StartupPhase.guest);
      await again.leaveGuest();
      expect(again.phase, StartupPhase.onboarding);
      expect(await store.isActive(), isFalse);
      again.dispose();
    });

    test('a locked identity stays locked while learning as a guest', () async {
      identity = FakeIdentityService.withProfile(
        identity: Identity(toxId: 'A' * 76, displayName: 'Op'),
        password: 'pw',
        connectDelay: Duration.zero,
        dataDirectoryPath: p.join(root.path, 'ids'),
      );
      final c = controller();
      await c.ensureStarted();
      expect(c.phase, StartupPhase.locked);
      await c.enterGuest();
      expect(c.phase, StartupPhase.guest);
      expect(identity.current, isNull);
      await c.leaveGuest();
      expect(c.phase, StartupPhase.locked);
      c.dispose();
    });

    test('creating an identity from guest mode moves the progress', () async {
      final c = controller();
      await c.ensureStarted();
      await c.enterGuest();
      await _writeGuestProgress(await store.directory(), 9);
      await c.createIdentity(displayName: 'Op');
      expect(c.phase, StartupPhase.backupRequired);
      expect(c.migrationError, isNull);
      expect(released, 1, reason: 'guest controller flushed first');
      final dir = await identity.dataDirectory();
      final moved = await FileTrainerStore.inDataDirectory(dir).load();
      expect(moved!.currentLesson, 9);
      expect(await store.hasProgress(), isFalse);
      expect(c.guestMode.value, isFalse);
      c.dispose();
    });

    test('guest mode resumes without inspecting the identity', () async {
      await store.setActive(true);
      final counting = _CountingIdentity();
      final c = StartupController(
        counting,
        guest: GuestHooks(store: store, releaseGuestController: () async {}),
      );
      await c.ensureStarted();
      expect(c.phase, StartupPhase.guest);
      expect(counting.inspections, 0);
      await c.leaveGuest();
      expect(counting.inspections, 1);
      expect(c.phase, StartupPhase.onboarding);
      c.dispose();
    });

    test(
      'restoring from guest mode offers the guest progress choice',
      () async {
        final c = controller();
        await c.ensureStarted();
        await c.enterGuest();
        await _writeGuestProgress(await store.directory(), 4);
        await c.leaveGuest();
        final bytes =
            await FakeIdentityService(
              connectDelay: Duration.zero,
              dataDirectoryPath: p.join(root.path, 'other'),
            ).let((other) async {
              await other.create(displayName: 'Old');
              return other.exportBackup();
            });
        await c.restoreFromBackup(bytes);
        expect(c.guestChoicePending, isTrue);
        await c.useGuestProgress();
        final moved = await FileTrainerStore.inDataDirectory(
          await identity.dataDirectory(),
        ).load();
        expect(moved!.currentLesson, 4);
        c.dispose();
      },
    );

    test('a failed migration keeps guest data and can be retried', () async {
      final c = controller();
      await c.ensureStarted();
      await c.enterGuest();
      final guestDir = await store.directory();
      final file = File(p.join(guestDir, 'training', 'progress.json'));
      await file.create(recursive: true);
      await file.writeAsString('{broken');
      await c.createIdentity(displayName: 'Op');
      expect(c.migrationError, isNotNull);
      expect(await file.exists(), isTrue);
      await _writeGuestProgress(guestDir, 5);
      await c.retryMigration();
      expect(c.migrationError, isNull);
      final moved = await FileTrainerStore.inDataDirectory(
        await identity.dataDirectory(),
      ).load();
      expect(moved!.currentLesson, 5);
      c.dispose();
    });
  });

  group('TrainingControllerHost guest profile', () {
    test('serves the guest controller only while guest mode is on', () async {
      final identity = FakeIdentityService(connectDelay: Duration.zero);
      final mode = ValueNotifier<bool>(false);
      var made = 0;
      final host = TrainingControllerHost(
        identity,
        guestMode: mode,
        guestFactory: () async {
          made++;
          final c = TrainingController(
            progressStore: InMemoryTrainerStore(),
            settingsStore: InMemoryTrainingSettingsStore(),
            profileKey: GuestProfile.profileKey,
          );
          await c.load();
          return c;
        },
      );
      await expectLater(host.controller(), throwsStateError);
      mode.value = true;
      final c = await host.controller();
      expect(c.profileKey, 'guest');
      expect(await host.controller(), same(c));
      mode.value = false;
      await expectLater(host.controller(), throwsStateError);
      expect(made, 1);
      await host.dispose();
    });
  });

  test('clearing guest data drops a stale migration journal', () async {
    final root = await _tmp();
    final store = GuestStore(root: () async => p.join(root.path, 'guest'));
    final dir = await store.directory();
    await _writeGuestProgress(dir, 2);
    await File(p.join(dir, 'migration-journal.json')).writeAsString(
      jsonEncode({'state': 'committing', 'key': 'AB', 'generation': 'old'}),
    );
    await store.clear();
    expect(await GuestMigration.hasJournal(dir), isFalse);
    // New data of a new generation migrates normally.
    await _writeGuestProgress(dir, 9);
    final identity = p.join(root.path, 'id');
    await GuestMigration(
      guestDirectory: dir,
      identityDirectory: identity,
      generation: await store.generation(),
    ).run(identityKey: 'AB', now: DateTime(2026));
    final moved = await FileTrainerStore.inDataDirectory(identity).load();
    expect(moved!.currentLesson, 9);
  });

  test('a host suspension flushes a running document transaction', () async {
    final identity = FakeIdentityService(connectDelay: Duration.zero);
    final mode = ValueNotifier<bool>(true);
    final docs = InMemoryTrainingDocStore();
    final host = TrainingControllerHost(
      identity,
      guestMode: mode,
      guestFactory: () async {
        final c = TrainingController(
          progressStore: InMemoryTrainerStore(),
          settingsStore: InMemoryTrainingSettingsStore(),
          profileKey: GuestProfile.profileKey,
          docs: docs,
        );
        await c.load();
        return c;
      },
    );
    final c = await host.controller();
    final txn = c.docTransaction(() async {
      await c.readDoc('x');
      await c.writeDoc('x', {'v': 1});
    });
    await host.suspendLearning();
    await txn;
    expect(docs.docs.containsKey('x'), isTrue);
    host.resumeLearning();
    await host.dispose();
  });

  test(
    'a completed but uncleaned migration is finished before reuse',
    () async {
      final root = await _tmp();
      final store = GuestStore(root: () async => p.join(root.path, 'guest'));
      final dir = await store.directory();
      await _writeGuestProgress(dir, 3);
      final gen = await store.generation();
      // Marker written, cleanup crashed; a pending marker is left too.
      await File(p.join(dir, 'migrated-ab-$gen.json')).writeAsString('{}');
      await File(p.join(dir, 'pending-AB')).writeAsString('1');
      await store.finishCompletedMigrations();
      expect(await store.hasProgress(), isFalse);
      expect(await File(p.join(dir, 'pending-AB')).exists(), isFalse);
      expect(await store.generation(), isNot(gen));
    },
  );
}

extension<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

/// Counts identity inspections (guest resume must not inspect).
final class _CountingIdentity implements IdentityService {
  int inspections = 0;

  @override
  Stream<Identity?> get identityChanges => const Stream<Identity?>.empty();

  @override
  Identity? get current => null;

  @override
  Future<IdentityState> inspect() async {
    inspections++;
    return IdentityState.none;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
