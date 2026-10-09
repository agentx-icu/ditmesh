import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../i18n/key_value_store.dart';
import '../notifications/notification_prefs.dart';
import '../ui/chat/morse_playback_settings.dart';
import '../ui/chat/conversation_playback_preferences.dart';
import '../ui/chat/input_mode.dart';
import '../ui/chat/first_chat_progress.dart';
import '../ui/listen/listen_preferences.dart';
import '../ui/listen/listen_settings.dart';
import '../ui/reference/reference_playback_settings.dart';
import 'app_settings.dart';

/// Restores preferences before providers are exposed and saves changes through
/// the same store as language/window settings. Conversation mutes are scoped
/// by the full identity public key, as are guide and conversation overrides.
/// Global playback defaults seed each conversation before its first override.
final class AppPreferences implements IdentityDataStore {
  AppPreferences(
    this._store, {
    required String backendLabel,
    required IdentityService identity,
  }) : _identity = identity {
    settings = AppSettings(backendLabel: backendLabel, store: _store);
    final n = _read('notifications');
    notifications = NotificationPrefs(
      enabled: _bool(n, 'enabled', true),
      showText: _bool(n, 'showText', true),
      showPattern: _bool(n, 'showPattern', true),
      sound: _bool(n, 'sound', true),
    );
    final c = _read('chat.playback');
    final wpm = _number(c, 'wpm', 15).clamp(5.0, 40.0);
    playback = MorsePlaybackSettings(
      wpm: wpm,
      farnsworthWpm: _number(c, 'farnsworthWpm', 8).clamp(5.0, wpm),
      toneHz: _number(c, 'toneHz', 700).clamp(400.0, 1000.0),
      trainingMode: _bool(c, 'trainingMode', false),
      inputMode: InputMode.values.firstWhere(
        (v) => v.name == c['inputMode'],
        // Includes the retired typed-text mode ("keyboard").
        orElse: () => InputMode.straightKey,
      ),
      autoPlay: _bool(c, 'autoPlay', false),
      listenOnly: _bool(c, 'listenOnly', false),
      originalRhythm: _bool(c, 'originalRhythm', false),
    );
    final r = _read('reference.playback');
    reference = ReferencePlaybackSettings(
      wpm: _number(r, 'wpm', 15),
      farnsworthWpm: r['farnsworthWpm'] is num
          ? _number(r, 'farnsworthWpm', 8)
          : null,
      toneHz: _number(r, 'toneHz', 700),
    );
    final l = _read('listen.decoder');
    final block = _number(l, 'blockSize', 256).toInt();
    listen = ListenPreferences(
      ListenSettings(
        blockSize: ListenSettings.blockSizes.contains(block) ? block : 256,
        minElementMs: _number(l, 'minElementMs', 12).clamp(4, 40).toInt(),
        autoTune: _bool(l, 'autoTune', true),
        manualHz: _number(l, 'manualHz', 700).clamp(400.0, 1000.0),
      ),
    );
    _watch(notifications, _saveNotifications);
    conversations = ConversationPlaybackPreferences();
    _watch(conversations, () {
      final key = _identityKey;
      if (key != null && !_replacing) {
        _saveJson('chat.conversations.$key', conversations.toJson());
      }
    });
    firstChat = FirstChatProgress();
    _watch(firstChat, () {
      final key = _identityKey;
      if (key != null && !_replacing) {
        _saveJson('chat.guide.$key', {'dismissed': firstChat.dismissed});
      }
    });
    _watch(playback, () => _saveJson('chat.playback', playback.toJson()));
    _watch(
      reference,
      () => _saveJson('reference.playback', {
        'wpm': reference.wpm,
        'farnsworthWpm': reference.farnsworthWpm,
        'toneHz': reference.toneHz,
      }),
    );
    _watch(
      listen,
      () => _saveJson('listen.decoder', {
        'blockSize': listen.settings.blockSize,
        'minElementMs': listen.settings.minElementMs,
        'autoTune': listen.settings.autoTune,
        'manualHz': listen.settings.manualHz,
      }),
    );
    _onIdentity(identity.current);
    _identitySub = identity.identityChanges.listen(_onIdentity);
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
  }

  final KeyValueStore _store;
  final IdentityService _identity;
  late final AppSettings settings;
  late final NotificationPrefs notifications;
  late final MorsePlaybackSettings playback;
  late final ConversationPlaybackPreferences conversations;
  late final FirstChatProgress firstChat;
  late final ReferencePlaybackSettings reference;
  late final ListenPreferences listen;
  final Map<ChangeNotifier, VoidCallback> _listeners = {};
  StreamSubscription<Identity?>? _identitySub;
  Future<void> _pending = Future<void>.value();
  final Map<String, ({String? value, Object version})> _dirty = {};
  final Map<String, Object> _saveErrors = {};
  bool _replacing = false;
  bool _hydrating = false;
  bool _disposed = false;
  String? _identityKey;

  static bool _bool(Map<String, Object?> m, String k, bool fallback) =>
      m[k] is bool ? m[k]! as bool : fallback;
  static double _number(Map<String, Object?> m, String k, double fallback) {
    final value = m[k];
    return value is num && value.isFinite ? value.toDouble() : fallback;
  }

  Map<String, Object?> _read(String key) {
    try {
      final raw = _store.getString(key);
      final value = raw == null ? null : jsonDecode(raw);
      return value is Map<String, Object?> ? value : {};
    } on FormatException {
      return {};
    }
  }

  void _watch(ChangeNotifier model, VoidCallback callback) {
    _listeners[model] = callback;
    model.addListener(callback);
  }

  void _saveJson(String key, Map<String, Object?> values) =>
      _save(key, jsonEncode(values));

  void _save(String key, String value) {
    if (_hydrating || _disposed) return;
    _change(key, value);
  }

  void _change(String key, String? value) {
    final write = (value: value, version: Object());
    _dirty[key] = write;
    _enqueue(key, write);
  }

  void _enqueue(String key, ({String? value, Object version}) write) {
    _pending = _pending.then((_) async {
      try {
        final value = write.value;
        if (value == null) {
          await _store.remove(key);
        } else {
          await _store.setString(key, value);
        }
        if (identical(_dirty[key]?.version, write.version)) {
          _dirty.remove(key);
          _saveErrors.remove(key);
        }
      } on Object catch (error, stack) {
        if (identical(_dirty[key]?.version, write.version)) {
          _saveErrors[key] = error;
        }
        debugPrint('[AppPreferences] save failed for $key: $error\n$stack');
      }
    });
  }

  Future<void> _drain() async {
    Future<void> pending;
    do {
      pending = _pending;
      await pending;
    } while (!identical(pending, _pending));
  }

  void _saveNotifications() {
    if (_hydrating || _disposed) return;
    final values = notifications.toJson()..remove('muted');
    _saveJson('notifications', values);
    final key = _identityKey;
    if (key != null && !_replacing) {
      _save(
        'notifications.muted.$key',
        jsonEncode(notifications.mutedConversations.toList()..sort()),
      );
    }
  }

  void _onIdentity(Identity? identity) {
    if (_disposed) return;
    final key = identity?.publicKey.toUpperCase();
    _replacing = false;
    if (key == _identityKey) return;
    final old = _identityKey;
    _identityKey = key;
    if (key == null && old != null) {
      _change('notifications.muted.$old', null);
      _change('chat.guide.$old', null);
      _change('chat.conversations.$old', null);
    }
    Iterable<String> muted = const [];
    try {
      final storageKey = 'notifications.muted.$key';
      final raw = key == null
          ? null
          : _dirty.containsKey(storageKey)
          ? _dirty[storageKey]?.value
          : _store.getString(storageKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is List) muted = decoded.whereType<String>();
    } on FormatException {
      // A malformed mute list cannot disable all notifications.
    }
    _hydrating = true;
    notifications.replaceMuted(muted);
    final guideKey = 'chat.guide.$key';
    Map<String, Object?> guide = {};
    try {
      final raw = _dirty.containsKey(guideKey)
          ? _dirty[guideKey]?.value
          : _store.getString(guideKey);
      final doc = raw == null ? null : jsonDecode(raw);
      if (doc is Map<String, Object?>) guide = doc;
    } on FormatException {
      // An invalid guide preference starts with the guide available.
    }
    firstChat.restore(_bool(guide, 'dismissed', false));
    Map<String, Object?> chatValues = {};
    if (key != null) {
      final storageKey = 'chat.conversations.$key';
      try {
        final raw = _dirty.containsKey(storageKey)
            ? _dirty[storageKey]?.value
            : _store.getString(storageKey);
        final decoded = raw == null ? null : jsonDecode(raw);
        if (decoded is Map<String, Object?>) chatValues = decoded;
      } on FormatException {
        /* Invalid overrides use the global defaults. */
      }
    }
    conversations.restore(chatValues);
    _hydrating = false;
  }

  @override
  Future<void> flush() async {
    await Future.wait([settings.flush(), _drain()]);
    // Retry retained snapshots, including removals, once per flush. A save to
    // another key cannot erase a failure or commit its optimistic model value.
    for (final entry in _dirty.entries.toList()) {
      _enqueue(entry.key, entry.value);
    }
    await _drain();
    if (_dirty.isNotEmpty) {
      throw StateError('Could not save app preferences: $_saveErrors');
    }
  }

  @override
  Future<void> prepareForReplacement() async {
    _replacing = true;
    try {
      await flush();
    } on Object {
      _replacing = false;
      rethrow;
    }
    // Only a committed null identity event clears old account data. If the
    // backend aborts replacement, republishing the old identity resumes saves.
  }

  void dispose() {
    _disposed = true;
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    unawaited(_identitySub?.cancel());
    settings.dispose();
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
      entry.key.dispose();
    }
  }
}
