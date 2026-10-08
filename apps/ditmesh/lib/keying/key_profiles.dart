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

  Future<void> _persist() {
    final doc = jsonEncode({
      'v': KeyProfile.version,
      'selected': _selected,
      'profiles': [for (final p in _saved) p.toJson()],
    });
    final op = _pending.then((_) => _store.setString(storageKey, doc));
    _pending = op.catchError((Object _) {});
    return op;
  }

  /// Validates and stores [profile] (new or replacing the same id) and
  /// makes it active. Throws [KeyProfileException] when it is invalid.
  Future<void> save(KeyProfile profile) async {
    profile.validate();
    final i = _saved.indexWhere((p) => p.id == profile.id);
    if (i >= 0) {
      _saved[i] = profile;
    } else {
      _saved.add(profile);
    }
    _selected = profile.id;
    notifyListeners();
    await _persist();
  }

  Future<void> select(String id) {
    if (id != KeyProfile.defaults.id && !_saved.any((p) => p.id == id)) {
      return Future<void>.value();
    }
    _selected = id;
    notifyListeners();
    return _persist();
  }

  Future<void> delete(String id) {
    _saved.removeWhere((p) => p.id == id);
    if (_selected == id) _selected = KeyProfile.defaults.id;
    notifyListeners();
    return _persist();
  }

  /// Back to Space / left Ctrl / right Ctrl; saved profiles are kept.
  Future<void> useDefaults() => select(KeyProfile.defaults.id);

  Future<void> flush() async {
    Future<void> pending;
    do {
      pending = _pending;
      await pending;
    } while (!identical(pending, _pending));
  }
}
