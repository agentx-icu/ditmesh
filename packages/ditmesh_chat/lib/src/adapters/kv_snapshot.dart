import 'key_value_store.dart';

/// Every entry of a [KeyValueStore] at one moment, so a multi-step update
/// (a restore: files renamed, then preferences rewritten) can be undone when
/// a later step fails. The store has no generic getter, so each value is
/// read with the typed getter that accepts it.
final class KvSnapshot {
  KvSnapshot._(this._values, this._unreadable);

  final Map<String, Object> _values;

  /// Keys whose type no getter accepts (e.g. a double): left untouched.
  final Set<String> _unreadable;

  static KvSnapshot capture(
    KeyValueStore store, {
    bool Function(String)? includes,
  }) {
    final values = <String, Object>{};
    final unreadable = <String>{};
    for (final key in store.keys()) {
      if (includes != null && !includes(key)) continue;
      final value = _read(store, key);
      if (value != null) {
        values[key] = value;
      } else {
        unreadable.add(key);
      }
    }
    return KvSnapshot._(values, unreadable);
  }

  Map<String, Object> toJson() => {
    'values': _values,
    'unreadable': _unreadable.toList(),
  };

  static KvSnapshot fromJson(Object? json, bool Function(String) includes) {
    if (json is! Map<String, dynamic> ||
        json['values'] is! Map<String, dynamic> ||
        json['unreadable'] is! List) {
      throw const FormatException('Invalid preferences snapshot');
    }
    final values = <String, Object>{};
    for (final entry in (json['values'] as Map<String, dynamic>).entries) {
      if (!includes(entry.key)) {
        throw const FormatException('Out-of-scope preferences key');
      }
      values[entry.key] = switch (entry.value) {
        final String value => value,
        final bool value => value,
        final int value => value,
        final List value when value.every((element) => element is String) =>
          List<String>.from(value),
        _ => throw const FormatException('Invalid preferences value'),
      };
    }
    final unreadable = <String>{};
    for (final key in json['unreadable'] as List) {
      if (key is! String || !includes(key) || values.containsKey(key)) {
        throw const FormatException('Invalid unreadable preferences key');
      }
      unreadable.add(key);
    }
    return KvSnapshot._(values, unreadable);
  }

  static Object? _read(KeyValueStore store, String key) {
    for (final get in <Object? Function()>[
      () => store.getString(key),
      () => store.getStringList(key),
      () => store.getBool(key),
      () => store.getInt(key),
    ]) {
      try {
        final value = get();
        if (value != null) return value;
      } on TypeError {
        // Stored under another type; try the next getter.
      }
    }
    return null;
  }

  /// Puts every captured entry back and removes keys added since. Keeps
  /// going past a failed write so as much as possible is restored, then
  /// rethrows the first failure.
  Future<void> restore(
    KeyValueStore store, {
    bool Function(String)? includes,
  }) async {
    Object? first;
    StackTrace? firstStack;
    Future<void> attempt(Future<void> Function() op) async {
      try {
        await op();
      } catch (e, st) {
        first ??= e;
        firstStack ??= st;
      }
    }

    for (final key in store.keys().toList()) {
      if (includes != null && !includes(key)) continue;
      if (!_values.containsKey(key) && !_unreadable.contains(key)) {
        await attempt(() => store.remove(key));
      }
    }
    for (final MapEntry(:key, :value) in _values.entries) {
      await attempt(
        () => switch (value) {
          final String v => store.setString(key, v),
          final List<String> v => store.setStringList(key, v),
          final bool v => store.setBool(key, v),
          final int v => store.setInt(key, v),
          _ => Future<void>.value(),
        },
      );
    }
    if (first != null) Error.throwWithStackTrace(first!, firstStack!);
  }
}
