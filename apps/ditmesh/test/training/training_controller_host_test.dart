import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Just enough [IdentityService] for the host: a switchable current identity
/// and its change stream. Everything else throws through [noSuchMethod].
final class _SwitchableIdentity implements PersistentIdentityService {
  Identity? _current;
  final StreamController<Identity?> _changes =
      StreamController<Identity?>.broadcast(sync: true);

  @override
  Identity? get current => _current;

  @override
  Stream<Identity?> get identityChanges => _changes.stream;

  void switchTo(Identity? identity) {
    _current = identity;
    _changes.add(identity);
  }

  final Set<IdentityDataStore> stores = {};

  @override
  void registerDataStore(IdentityDataStore store) => stores.add(store);

  @override
  void unregisterDataStore(IdentityDataStore store) => stores.remove(store);

  @override
  Future<void> persist() => Future.wait(stores.map((store) => store.flush()));

  Future<void> replaceWith(Identity identity) async {
    await Future.wait(stores.map((store) => store.prepareForReplacement()));
    switchTo(null);
    switchTo(identity);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

final class _BlockingSettingsStore implements TrainingSettingsStore {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();

  @override
  Future<TrainingSettings?> load() async => null;

  @override
  Future<void> clear() async {}

  @override
  Future<void> save(TrainingSettings settings) async {
    entered.complete();
    await release.future;
  }
}

Identity _identity(String key) =>
    Identity(toxId: key.padRight(76, '0'), displayName: key);

TrainingController _controller() => TrainingController(
  progressStore: InMemoryTrainerStore(),
  settingsStore: InMemoryTrainingSettingsStore(),
);

/// Records one scored exercise (any progress write will do).
Future<ReceiveOutcome> _record(TrainingController c, [String id = 'ex']) =>
    c.recordExercise(
      score: SessionScore.evaluate('K', 'K'),
      id: id,
      source: ExerciseSource.chat,
      assistance: const <Assistance>{},
    );

bool _isDisposed(TrainingController c) {
  try {
    c.addListener(() {});
    return false;
  } on FlutterError {
    return true;
  }
}

void main() {
  late _SwitchableIdentity identity;
  late List<Completer<TrainingController>> loads;
  late TrainingControllerHost host;

  setUp(() {
    identity = _SwitchableIdentity();
    loads = [];
    host = TrainingControllerHost(
      identity,
      factory: (_) {
        final c = Completer<TrainingController>();
        loads.add(c);
        return c.future;
      },
    );
  });

  tearDown(() async {
    await host.dispose();
    await identity._changes.close();
  });

  test('registers an identity durability barrier until disposed', () async {
    expect(identity.stores, hasLength(1));
    await host.dispose();
    expect(identity.stores, isEmpty);
  });

  test('caches one controller per identity and shares it', () async {
    identity.switchTo(_identity('A'));
    final f1 = host.controller();
    final f2 = host.controller();
    expect(loads, hasLength(1));
    final c = _controller();
    loads.single.complete(c);
    expect(await f1, same(c));
    expect(await f2, same(c));
    expect(_isDisposed(c), isFalse);
    await host.dispose();
    expect(_isDisposed(c), isTrue, reason: 'the host owns it');
  });

  test('a load that completes after dispose is disposed, not cached', () async {
    identity.switchTo(_identity('A'));
    final pending = host.controller();
    await host.dispose();
    final late = _controller();
    loads.single.complete(late);
    await expectLater(pending, throwsStateError);
    expect(_isDisposed(late), isTrue, reason: 'nobody else owns it');
    await expectLater(host.controller(), throwsStateError);
  });

  test('a load for the previous identity is disposed when the identity '
      'switches during it', () async {
    identity.switchTo(_identity('A'));
    final forA = host.controller();
    identity.switchTo(_identity('B'));
    final forB = host.controller();
    expect(loads, hasLength(2));

    final staleA = _controller();
    loads.first.complete(staleA);
    await expectLater(forA, throwsStateError);
    expect(_isDisposed(staleA), isTrue);

    final freshB = _controller();
    loads.last.complete(freshB);
    expect(await forB, same(freshB));
    expect(_isDisposed(freshB), isFalse);
    // The cache holds B, not the stale A.
    expect(await host.controller(), same(freshB));
    await host.dispose();
    expect(_isDisposed(freshB), isTrue);
  });

  test('identity change after caching rebuilds on the next request', () async {
    identity.switchTo(_identity('A'));
    final forA = host.controller();
    final a = _controller();
    loads.single.complete(a);
    expect(await forA, same(a));

    identity.switchTo(_identity('B'));
    expect(_isDisposed(a), isTrue);
    final forB = host.controller();
    expect(loads, hasLength(2));
    final b = _controller();
    loads.last.complete(b);
    expect(await forB, same(b));
    await host.dispose();
  });

  test('no identity is an error', () async {
    await expectLater(host.controller(), throwsStateError);
    expect(loads, isEmpty);
    await host.dispose();
  });

  test(
    'failed controller loading can be retried for the same identity',
    () async {
      identity.switchTo(_identity('A'));
      final failed = host.controller();
      loads.single.completeError(StateError('temporary read failure'));
      await expectLater(failed, throwsStateError);

      final retry = host.controller();
      expect(loads, hasLength(2));
      final recovered = _controller();
      loads.last.complete(recovered);
      expect(await retry, same(recovered));
      await host.dispose();
    },
  );

  test('restoring the same public key rebuilds training data', () async {
    identity.switchTo(_identity('A'));
    final before = host.controller();
    final stale = _controller();
    loads.single.complete(stale);
    await before;

    await identity.replaceWith(_identity('A'));
    expect(_isDisposed(stale), isTrue);
    final after = host.controller();
    expect(loads, hasLength(2));
    final restored = _controller();
    loads.last.complete(restored);
    expect(await after, same(restored));
  });

  test('replacement stops late writes and waits for earlier writes', () async {
    identity.switchTo(_identity('A'));
    final settings = _BlockingSettingsStore();
    final c = TrainingController(
      progressStore: InMemoryTrainerStore(),
      settingsStore: settings,
    );
    final loading = host.controller();
    loads.single.complete(c);
    await loading;
    final save = c.updateSettings(const TrainingSettings(flashEnabled: true));
    await settings.entered.future;
    var replaced = false;
    final replacement = identity.replaceWith(_identity('A')).then((_) {
      replaced = true;
    });

    expect(_isDisposed(c), isTrue);
    final whileReplacing = host.controller();
    expect(loads, hasLength(1), reason: 'do not reload the old identity');
    await expectLater(whileReplacing, throwsStateError);
    await expectLater(_record(c), throwsStateError);
    expect(replaced, isFalse);
    settings.release.complete();
    await Future.wait(<Future<void>>[save, replacement]);
    expect(replaced, isTrue);
  });

  test(
    'replacement drains a late controller load before deleting data',
    () async {
      identity.switchTo(_identity('A'));
      final loading = host.controller();
      final rejected = expectLater(loading, throwsStateError);
      var replaced = false;
      final replacement = identity.replaceWith(_identity('A')).then((_) {
        replaced = true;
      });
      expect(replaced, isFalse);
      final late = _controller();
      loads.single.complete(late);

      await Future.wait(<Future<void>>[rejected, replacement]);
      expect(_isDisposed(late), isTrue);
      expect(replaced, isTrue);
    },
  );
}
