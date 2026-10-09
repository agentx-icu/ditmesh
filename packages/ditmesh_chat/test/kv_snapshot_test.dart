import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/kv_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// [KvSnapshot]: the preference rollback a restore relies on.

/// Holds a double under 'ratio', which no typed getter accepts.
class _DoubleStore extends MemoryKeyValueStore {
  bool ratioRemoved = false;
  @override
  Set<String> keys() => {...super.keys(), if (!ratioRemoved) 'ratio'};
  @override
  String? getString(String key) =>
      key == 'ratio' ? throw TypeError() : super.getString(key);
  @override
  List<String>? getStringList(String key) =>
      key == 'ratio' ? throw TypeError() : super.getStringList(key);
  @override
  bool? getBool(String key) =>
      key == 'ratio' ? throw TypeError() : super.getBool(key);
  @override
  int? getInt(String key) =>
      key == 'ratio' ? throw TypeError() : super.getInt(key);
  @override
  Future<void> remove(String key) async {
    if (key == 'ratio') ratioRemoved = true;
    return super.remove(key);
  }
}

class _FailingStore extends MemoryKeyValueStore {
  final Set<String> failWrites = {};
  @override
  Future<void> setString(String key, String value) async {
    if (failWrites.contains(key)) throw StateError('write $key failed');
    return super.setString(key, value);
  }
}

void main() {
  test('restores all four types and removes keys added since', () async {
    final store = MemoryKeyValueStore();
    await store.setString('s', 'a');
    await store.setStringList('l', ['x', 'y']);
    await store.setBool('b', true);
    await store.setInt('i', 7);
    final snapshot = KvSnapshot.capture(store);

    await store.setString('s', 'changed');
    await store.setStringList('l', []);
    await store.setBool('b', false);
    await store.remove('i');
    await store.setString('new', 'added');

    await snapshot.restore(store);
    expect(store.getString('s'), 'a');
    expect(store.getStringList('l'), ['x', 'y']);
    expect(store.getBool('b'), isTrue);
    expect(store.getInt('i'), 7);
    expect(store.getString('new'), isNull);
    expect(store.keys().toSet(), {'s', 'l', 'b', 'i'});
  });

  test('a value no getter reads is left untouched, never removed', () async {
    final store = _DoubleStore();
    await store.setString('s', 'a');
    final snapshot = KvSnapshot.capture(store);
    await store.setString('s', 'b');
    await snapshot.restore(store);
    expect(store.getString('s'), 'a');
    expect(store.ratioRemoved, isFalse);
  });

  test('a failed write does not stop the rest; the first error is thrown', () async {
    final store = _FailingStore();
    await store.setString('a', '1');
    await store.setString('b', '2');
    await store.setString('c', '3');
    final snapshot = KvSnapshot.capture(store);
    await store.setString('a', 'x');
    await store.setString('b', 'x');
    await store.setString('c', 'x');
    await store.setString('extra', 'x');
    store.failWrites.addAll({'a', 'b'});
    await expectLater(
      snapshot.restore(store),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'write a failed'),
      ),
    );
    expect(store.getString('c'), '3', reason: 'later entries still restored');
    expect(store.getString('extra'), isNull, reason: 'added keys still removed');
  });
}
