import 'dart:async';

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/training/group_practice.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_doc_store.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/groups/practice/group_practice_session_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:provider/provider.dart';

import 'learn/helpers/l10n.dart';

final class _PendingWrite {
  final started = Completer<void>();
  final release = Completer<void>();
}

final class _DelayedDocs implements TrainingDocStore {
  final _inner = InMemoryTrainingDocStore();
  _PendingWrite? _next;

  _PendingWrite pauseNextWrite() => _next = _PendingWrite();

  @override
  Future<Map<String, Object?>?> read(String name) => _inner.read(name);

  @override
  Future<void> write(String name, Map<String, Object?> json) async {
    final pending = _next;
    _next = null;
    if (pending != null) {
      pending.started.complete();
      await pending.release.future;
    }
    await _inner.write(name, json);
  }
}

final class _Fixture {
  _Fixture(this.docs, this.controller, this.chat);

  final _DelayedDocs docs;
  final TrainingController controller;
  final FakeChatService chat;
  final navigator = GlobalKey<NavigatorState>();
  late final MaterialPageRoute<void> origin;
  late final Duration popDuration;
  late MaterialPageRoute<void> replacement;

  static Future<_Fixture> mount(WidgetTester tester) async {
    final docs = _DelayedDocs();
    final controller = TrainingController(
      progressStore: InMemoryTrainerStore(),
      settingsStore: InMemoryTrainingSettingsStore(),
      docs: docs,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.updateGroupPractice(
      (book) => book.add(
        GroupPracticeSession(
          id: 'session',
          conversationId: 'group_tox_1',
          title: 'Net',
          role: GroupPracticeRole.participant,
          createdAt: DateTime.utc(2026, 10, 4),
        ),
      ),
    );
    final chat = FakeChatService(selfPublicKey: 'F' * 64);
    addTearDown(chat.dispose);
    final fixture = _Fixture(docs, controller, chat);
    await tester.pumpWidget(
      Provider<ChatService>.value(
        value: chat,
        child: MaterialApp(
          navigatorKey: fixture.navigator,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    fixture.origin = MaterialPageRoute<void>(
      builder: (_) => GroupPracticeSessionPage(
        controller: controller,
        sessionId: 'session',
      ),
    );
    unawaited(fixture.navigator.currentState!.push(fixture.origin));
    await tester.pumpAndSettle();
    fixture.popDuration = fixture.origin.reverseTransitionDuration;
    return fixture;
  }

  Future<_PendingWrite> confirmDelete(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    final pending = docs.pauseNextWrite();
    await tester.tap(find.byKey(const Key('gp-delete-confirm')));
    await tester.pumpAndSettle();
    expect(pending.started.isCompleted, isTrue);
    return pending;
  }

  Future<void> finishDelete(WidgetTester tester, _PendingWrite pending) async {
    pending.release.complete();
    await tester.pump();
    await tester.runAsync(controller.flush);
    await tester.pump();
    // Finish any pop transition without waiting on the deleted page's loader.
    await tester.pump(popDuration);
    final book = GroupPracticeBook.fromJson(await docs.read('group_practice'));
    expect(
      book.byId('session'),
      isNull,
      reason: 'the confirmed delete persists',
    );
  }

  void pushReplacementPage() {
    replacement = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Replacement')),
    );
    unawaited(navigator.currentState!.push(replacement));
  }
}

void main() {
  testWidgets('a delayed delete returns from its still-current page', (
    tester,
  ) async {
    final fixture = await _Fixture.mount(tester);
    final pending = await fixture.confirmDelete(tester);
    expect(fixture.origin.isCurrent, isTrue);
    await fixture.finishDelete(tester, pending);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(GroupPracticeSessionPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed delete cannot pop a page pushed above its origin', (
    tester,
  ) async {
    final fixture = await _Fixture.mount(tester);
    final pending = await fixture.confirmDelete(tester);
    fixture.pushReplacementPage();
    await tester.pumpAndSettle();
    expect(fixture.origin.isActive, isTrue);
    expect(fixture.origin.isCurrent, isFalse);
    await fixture.finishDelete(tester, pending);
    expect(fixture.replacement.isCurrent, isTrue);
    expect(find.text('Replacement'), findsOneWidget);
    fixture.navigator.currentState!.pop();
    await tester.pump();
    expect(
      fixture.origin.isActive,
      isFalse,
      reason: 'returning must not reopen the deleted session loader',
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(GroupPracticeSessionPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a delayed delete cannot pop a new page after leaving its origin',
    (tester) async {
      final fixture = await _Fixture.mount(tester);
      final pending = await fixture.confirmDelete(tester);
      fixture.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      fixture.pushReplacementPage();
      await tester.pumpAndSettle();
      expect(fixture.origin.isActive, isFalse);
      await fixture.finishDelete(tester, pending);
      expect(fixture.replacement.isCurrent, isTrue);
      expect(find.text('Replacement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a delayed delete survives disposal of its Navigator', (
    tester,
  ) async {
    final fixture = await _Fixture.mount(tester);
    final pending = await fixture.confirmDelete(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(fixture.navigator.currentState, isNull);
    await fixture.finishDelete(tester, pending);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation cannot return from a route replacing its origin', (
    tester,
  ) async {
    final fixture = await _Fixture.mount(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    fixture.replacement = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Replacement')),
    );
    fixture.navigator.currentState!.replace(
      oldRoute: fixture.origin,
      newRoute: fixture.replacement,
    );
    await tester.pumpAndSettle();
    final pending = fixture.docs.pauseNextWrite();
    await tester.tap(find.byKey(const Key('gp-delete-confirm')));
    await tester.pumpAndSettle();
    expect(pending.started.isCompleted, isTrue);
    await fixture.finishDelete(tester, pending);
    expect(fixture.replacement.isCurrent, isTrue);
    expect(find.text('Replacement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed delete stays on its page and can be retried', (
    tester,
  ) async {
    final fixture = await _Fixture.mount(tester);
    final pending = await fixture.confirmDelete(tester);
    pending.release.completeError(StateError('write failed'));
    await tester.pumpAndSettle();
    expect(fixture.origin.isCurrent, isTrue);
    expect(find.text(en.learnProgressSaveFailed), findsOneWidget);
    final book = GroupPracticeBook.fromJson(
      await fixture.docs.read('group_practice'),
    );
    expect(book.byId('session'), isNotNull);
    final retry = await fixture.confirmDelete(tester);
    await fixture.finishDelete(tester, retry);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
