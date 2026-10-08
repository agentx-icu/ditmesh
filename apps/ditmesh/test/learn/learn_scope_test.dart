import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/learn/learn_scope.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'helpers/l10n.dart';

final class _ReplaceableIdentity implements PersistentIdentityService {
  final StreamController<Identity?> changes =
      StreamController<Identity?>.broadcast(sync: true);
  final Set<IdentityDataStore> stores = {};

  @override
  final Identity current = Identity(
    toxId: 'A'.padRight(76, '0'),
    displayName: 'A',
  );

  @override
  Stream<Identity?> get identityChanges => changes.stream;

  @override
  void registerDataStore(IdentityDataStore store) => stores.add(store);

  @override
  void unregisterDataStore(IdentityDataStore store) => stores.remove(store);

  @override
  Future<void> persist() => Future.wait(stores.map((store) => store.flush()));

  Future<void> abortReplacement() async {
    await Future.wait(stores.map((store) => store.prepareForReplacement()));
    // A failed import/delete restores the existing identity without a null
    // event, leaving the authenticated page mounted.
    changes.add(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

void main() {
  testWidgets('host controller reloads after an aborted identity replacement', (
    tester,
  ) async {
    final identity = _ReplaceableIdentity();
    final progressStore = InMemoryTrainerStore(
      TrainerProgress(currentLesson: 2),
    );
    final host = TrainingControllerHost(
      identity,
      factory: (_) async {
        final controller = TrainingController(
          progressStore: progressStore,
          settingsStore: InMemoryTrainingSettingsStore(),
        );
        await controller.load();
        return controller;
      },
    );
    addTearDown(host.dispose);
    addTearDown(identity.changes.close);
    TrainingController? displayed;
    await tester.pumpWidget(
      Provider<IdentityService>.value(
        value: identity,
        child: l10nApp(
          home: LearnScope(
            controllerFactory: host.controllerFor,
            builder: (_, controller, _) {
              displayed = controller;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final previous = displayed!;
    await previous.setLesson(3);

    await identity.abortReplacement();
    await tester.pumpAndSettle();

    expect(displayed, isNot(same(previous)));
    expect(displayed!.currentLesson, 3);
    await displayed!.setLesson(4);
    expect((await progressStore.load())!.currentLesson, 4);
    await tester.pumpWidget(const SizedBox());
  });
}
