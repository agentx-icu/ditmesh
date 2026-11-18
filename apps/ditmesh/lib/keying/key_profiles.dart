import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../i18n/key_value_store.dart';
import 'key_profile.dart';

/// The device's saved key profiles and which one is in use (F12), in the
/// app's device-local store under [storageKey] (versioned). Never part of a
/// backup: hardware bindings belong to this device.
final class KeyProfiles extends ChangeNotifier {
  KeyProfiles(this._store) {
    _load();
  }

  static const String storageKey = 'keying.profiles';

  /// The profile surfaces use when none is provided (tests, other scopes).
  /// Listening also works from `didChangeDependencies`.
  static KeyProfile of(BuildContext context, {bool listen = true}) =>
      Provider.of<KeyProfiles?>(context, listen: listen)?.active ??
      KeyProfile.defaults;

  final KeyValueStore _store;
  final List<KeyProfile> _saved = [];
  String _selected = KeyProfile.defaults.id;
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;

  /// Saved profiles, oldest first (the built-in default is not listed).
  List<KeyProfile> get saved => List.unmodifiable(_saved);

  KeyProfile get active =>
      _saved.where((p) => p.id == _selected).firstOrNull ??
      KeyProfile.defaults;

  void _load() {
    final raw = _store.getString(storageKey);
    if (raw == null) return;
    try {
      final doc = jsonDecode(raw);
      if (doc is! Map || doc['v'] != KeyProfile.version) return;
      final list = doc['profiles'];
      for (final e in list is List ? list : const []) {
        final p = KeyProfile.fromJson(e);
        if (p == null) continue;
        try {
          // A stored profile that no longer validates is left out rather
          // than applied with ambiguous keys.
          p.validate();
          _saved.add(p);
        } on KeyProfileException {
          continue;
        }
      }
      final selected = doc['selected'];
      if (selected is String) _selected = selected;
    } on Object {
      // A broken preference (bad JSON, wrong types) never blocks keying:
      // what loaded so far stays, the rest falls back to the defaults.
    }
  }

  /// Calculate each mutation from the last committed state. A failed write
  /// leaves both the active bindings and the next queued mutation untouched.
  Future<void> _change(String? Function(List<KeyProfile>) update) {
    final op = _pending.then((_) async {
      final saved = List<KeyProfile>.of(_saved);
      final selected = update(saved);
      if (selected == null) return;
      final doc = jsonEncode({
        'v': KeyProfile.version,
        'selected': selected,
        'profiles': [for (final p in saved) p.toJson()],
      });
      await _store.setString(storageKey, doc);
      _saved
        ..clear()
        ..addAll(saved);
      _selected = selected;
      if (!_disposed) notifyListeners();
    });
    _pending = op.catchError((Object _) {});
    return op;
  }

  /// Validates and stores [profile] (new or replacing the same id) and
  /// makes it active. Throws [KeyProfileException] when it is invalid.
  Future<void> save(KeyProfile profile) => _change((saved) {
    profile.validate();
    final i = saved.indexWhere((p) => p.id == profile.id);
    if (i >= 0) {
      saved[i] = profile;
    } else {
      saved.add(profile);
    }
    return profile.id;
  });

  Future<void> select(String id) => _change((saved) {
    if (id == KeyProfile.defaults.id || saved.any((p) => p.id == id)) return id;
    return null;
  });

  Future<void> delete(String id) => _change((saved) {
    saved.removeWhere((p) => p.id == id);
    return _selected == id ? KeyProfile.defaults.id : _selected;
  });

  /// Back to Space / left Ctrl / right Ctrl; saved profiles are kept.
  Future<void> useDefaults() => select(KeyProfile.defaults.id);

  Future<void> flush() async {
    Future<void> pending;
    do {
      pending = _pending;
      await pending;
    } while (!identical(pending, _pending));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
