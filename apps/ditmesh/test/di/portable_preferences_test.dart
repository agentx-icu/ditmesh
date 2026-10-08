import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/di/portable_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh_chat_api/testing.dart';

/// Fails every write while [fail] is set.
final class _FlakyStore implements KeyValueStore {
  final InMemoryKeyValueStore _inner = InMemoryKeyValueStore();
  bool fail = false;

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      fail ? Future.error(StateError('disk full')) : _inner.setString(key, value);

  @override
  Future<void> remove(String key) =>
      fail ? Future.error(StateError('disk full')) : _inner.remove(key);
}

Uint8List _doc(Map<String, Object?> m) => Uint8List.fromList(utf8.encode(jsonEncode(m)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeIdentityService identity;

  setUp(() => identity = FakeIdentityService(connectDelay: Duration.zero));
  tearDown(() => identity.dispose());

  test('export carries explicit portable keys only', () async {
    final prefs = AppPreferences(InMemoryKeyValueStore(), backendLabel: 'x', identity: identity);
    addTearDown(prefs.dispose);
    final doc = jsonDecode(utf8.decode(prefs.exportPortable())) as Map;
    expect(doc.keys, containsAll(['chat.playback', 'reference.playback', 'listen.decoder', 'notifications', 'appearance']));
    expect(doc.keys.where((k) => '$k'.contains('window') || '$k'.contains('key')), isEmpty);
  });

  test('apply goes through the validating setters; unknown fields are ignored', () async {
    final store = InMemoryKeyValueStore();
    final prefs = AppPreferences(store, backendLabel: 'x', identity: identity);
    addTearDown(prefs.dispose);
    final locale = LocaleController(store);
    addTearDown(locale.dispose);
    await prefs.applyPortable(
      _doc({
        'chat.playback': {'wpm': 99, 'toneHz': 650, 'inputMode': 'nonsense', 'autoPlay': true},
        'listen.decoder': {'blockSize': 333, 'manualHz': 5000},
        'notifications': {'sound': false, 'muted': ['c2c_X']},
        'appearance': {'style': UiStyle.values.last.name, 'mode': 'dark'},
        'locale': {'language': 'de'},
        'window': {'x': -5000},
      }),
      locale: locale,
    );
    expect(prefs.playback.wpm, 40, reason: 'clamped');
    expect(prefs.playback.toneHz, 650);
    expect(prefs.playback.autoPlay, isTrue);
    expect(prefs.listen.settings.blockSize, 256, reason: 'invalid size kept');
    expect(prefs.listen.settings.manualHz, 1000);
    expect(prefs.notifications.sound, isFalse);
    expect(prefs.notifications.mutedConversations, {'c2c_X'});
    expect(prefs.settings.style, UiStyle.values.last);
    expect(prefs.settings.themeMode, ThemeMode.dark);
    expect(locale.locale?.languageCode, 'de');
    // Persisted: a fresh instance reads the same values.
    final again = AppPreferences(store, backendLabel: 'x', identity: identity);
    addTearDown(again.dispose);
    expect(again.playback.toneHz, 650);
  });

  test('a failed save puts the previous values back', () async {
    final store = _FlakyStore();
    final prefs = AppPreferences(store, backendLabel: 'x', identity: identity);
    addTearDown(prefs.dispose);
    final before = prefs.playback.toneHz;
    store.fail = true;
    await expectLater(
      prefs.applyPortable(_doc({'chat.playback': {'toneHz': 900}})),
      throwsA(anything),
    );
    expect(prefs.playback.toneHz, before);
    store.fail = false;
    await prefs.flush();
    expect(jsonDecode(store.getString('chat.playback') ?? '{}')['toneHz'] ?? before, before);
  });

  test('a malformed document changes nothing', () async {
    final prefs = AppPreferences(InMemoryKeyValueStore(), backendLabel: 'x', identity: identity);
    addTearDown(prefs.dispose);
    final before = prefs.exportPortable();
    await prefs.applyPortable(Uint8List.fromList(utf8.encode('not json')));
    expect(prefs.exportPortable(), before);
  });
}
