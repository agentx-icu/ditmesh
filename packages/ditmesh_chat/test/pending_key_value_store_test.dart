import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/adapters/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store whose int writes park on a completer and whose bool writes fail.
class _SlowStore extends MemoryKeyValueStore {
  Completer<void>? holdSetInt;
  bool failSetBool = false;

  @override
  Future<void> setInt(String key, int value) async {
    final hold = holdSetInt;
    if (hold != null) await hold.future;
    await super.setInt(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    if (failSetBool) throw StateError('disk full');
    await super.setBool(key, value);
  }
}

void main() {
  group('MemoryKeyValueStore', () {
    test('round-trips every type and lists its keys', () async {
      final store = MemoryKeyValueStore();
      await store.setBool('b', true);
      await store.setInt('i', 3);
      await store.setString('s', 'x');
      await store.setStringList('l', ['a']);
      expect(store.getBool('b'), isTrue);
      expect(store.getInt('i'), 3);
      expect(store.getString('s'), 'x');
      expect(store.getStringList('l'), ['a']);
      expect(store.keys(), {'b', 'i', 's', 'l'});
      // Lists are copied on both sides.
      store.getStringList('l')!.add('mutated');
      expect(store.getStringList('l'), ['a']);
      await store.remove('b');
      expect(store.getBool('b'), isNull);
    });
  });

  group('PendingKeyValueStore', () {
    test('reads delegate immediately and writes are tracked', () async {
      final inner = _SlowStore();
      final store = PendingKeyValueStore(inner);
      await store.setBool('b', false);
      await store.setString('s', 'x');
      await store.setStringList('l', ['a']);
      expect(store.getBool('b'), isFalse);
      expect(store.getString('s'), 'x');
      expect(store.getStringList('l'), ['a']);
      expect(store.getInt('i'), isNull);
      expect(store.keys(), {'b', 's', 'l'});
      await store.remove('s');
      expect(store.keys(), {'b', 'l'});
      await store.flush();
    });

    test('flush waits for a write that is still in flight', () async {
      final inner = _SlowStore()..holdSetInt = Completer<void>();
      final store = PendingKeyValueStore(inner);
      final write = store.setInt('i', 1);
      var flushed = false;
      final flush = store.flush().then((_) => flushed = true);
      await pumpEventQueue();
      expect(flushed, isFalse, reason: 'the int write is parked');
      expect(inner.getInt('i'), isNull);

      inner.holdSetInt!.complete();
      await write;
      await flush;
      expect(flushed, isTrue);
      expect(store.getInt('i'), 1);
    });

    test('a failed write still settles so flush cannot hang', () async {
      final inner = _SlowStore()..failSetBool = true;
      final store = PendingKeyValueStore(inner);
      await expectLater(store.setBool('b', true), throwsStateError);
      await expectLater(store.flush(), completes);
      expect(store.getBool('b'), isNull);
    });

    test('flush with nothing pending returns at once', () async {
      final store = PendingKeyValueStore(MemoryKeyValueStore());
      await expectLater(store.flush(), completes);
    });
  });

  group('SharedPreferencesStore', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');

    test('typed getters read the platform cache', () async {
      SharedPreferences.resetStatic();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method.startsWith('getAll')) {
              return <String, Object>{
                'flutter.b': true,
                'flutter.i': 42,
                'flutter.s': 'str',
                'flutter.l': <Object?>['x', 'y'],
              };
            }
            return true;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        SharedPreferences.resetStatic();
      });
      final store = await SharedPreferencesStore.open();
      expect(store.getBool('b'), isTrue);
      expect(store.getInt('i'), 42);
      expect(store.getString('s'), 'str');
      expect(store.getStringList('l'), ['x', 'y']);
      expect(store.keys(), {'b', 'i', 's', 'l'});
      expect(store.getBool('missing'), isNull);
      // A successful platform write lands in the cache.
      await store.setInt('n', 7);
      expect(store.getInt('n'), 7);
      await store.remove('n');
      expect(store.getInt('n'), isNull);
    });
  });
}
