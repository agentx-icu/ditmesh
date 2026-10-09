import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh_chat_api/testing.dart';

void main() {
  test(
    'original rhythm default survives restart and seeds new conversations',
    () async {
      final identity = FakeIdentityService();
      await identity.create(displayName: 'first');
      final store = InMemoryKeyValueStore();
      var prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.playback.originalRhythm = true;
      await prefs.flush();
      prefs.dispose();
      prefs = AppPreferences(store, backendLabel: 'test', identity: identity);
      expect(prefs.playback.originalRhythm, isTrue);
      expect(
        prefs.conversations
            .forConversation('new', prefs.playback)
            .originalRhythm,
        isTrue,
      );
      prefs.dispose();
      await identity.dispose();
    },
  );
  test(
    'listening source and repeat persist per conversation and account',
    () async {
      final identity = FakeIdentityService();
      final first = await identity.create(displayName: 'first');
      final store = InMemoryKeyValueStore();
      var prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.playback.wpm = 19;
      final ann = prefs.conversations.forConversation('ann', prefs.playback);
      ann.wpm = 27;
      ann.originalRhythm = true;
      ann.repeatStart = 1;
      ann.repeatEnd = 3;
      ann.repeatLoop = true;
      expect(
        prefs.conversations.forConversation('bob', prefs.playback).wpm,
        19,
      );
      await prefs.flush();
      prefs.dispose();
      prefs = AppPreferences(store, backendLabel: 'test', identity: identity);
      final restored = prefs.conversations.forConversation(
        'ann',
        prefs.playback,
      );
      expect(restored.wpm, 27);
      expect(restored.originalRhythm, isTrue);
      expect(restored.repeatStart, 1);
      expect(restored.repeatEnd, 3);
      expect(restored.repeatLoop, isTrue);
      await prefs.prepareForReplacement();
      final backup = await identity.exportBackup();
      await identity.deleteIdentity();
      await pumpEventQueue();
      expect(store.getString('chat.conversations.${first.publicKey}'), isNull);
      await identity.importBackup(backup);
      await pumpEventQueue();
      expect(
        prefs.conversations.forConversation('ann', prefs.playback).wpm,
        19,
      );
      // An old editor's settings cannot leak back into the new identity.
      restored.wpm = 31;
      await prefs.flush();
      expect(
        prefs.conversations.forConversation('ann', prefs.playback).wpm,
        19,
      );
      prefs.dispose();
      await identity.dispose();
    },
  );
}
