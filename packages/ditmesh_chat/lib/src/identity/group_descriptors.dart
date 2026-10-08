import '../adapters/key_value_store.dart';
import '../adapters/prefs_adapter.dart';

/// The group membership of one identity as a portable document
/// (`groups/bindings.json` in an encrypted backup): the Tim2Tox group ids,
/// their NGC chat ids, kinds and names, plus the groups the user left and
/// the ones whose history is kept. Tim2Tox rebinds and rejoins every group
/// from exactly these preferences on start, so a restore that cleared them
/// would lose the groups and could not reopen their restored history.
///
/// Deliberately not carried: queued and pending invitations (a restored
/// identity never replays them), avatars (device paths) and friend caches.
abstract final class GroupDescriptors {
  /// Tim2Tox's own key for groups whose history is kept after leaving.
  static const String _historyRetainedKey = 'groups_history_retained_v1';

  /// Null when the identity has no group state at all (the archive then
  /// carries no entry, as before).
  static Future<Map<String, Object?>?> export(
    KeyValueStore store,
    String accountPrefix,
  ) async {
    if (accountPrefix.isEmpty) return null;
    final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: accountPrefix);
    final ids = (await prefs.getGroups()).toList()..sort();
    final quit = (await prefs.getQuitGroups()).toList()..sort();
    final retained =
        (await prefs.getStringSet(prefs.accountScopedKey(_historyRetainedKey)))
            .toList()
          ..sort();
    if (ids.isEmpty && quit.isEmpty && retained.isEmpty) return null;
    return {
      'groups': [
        for (final id in ids)
          {
            'id': id,
            'chatId': await prefs.getGroupChatId(id) ?? '',
            'type': await prefs.getGroupType(id) ?? '',
            'name': await prefs.getGroupName(id) ?? '',
          },
      ],
      'quit': quit,
      'historyRetained': retained,
    };
  }

  /// Writes [doc] (from [export]) into the identity's preference slots;
  /// unknown or malformed fields are ignored. The caller clears the
  /// identity's preferences first and runs stopped, so the next connect()
  /// reads these.
  static Future<void> restore(
    KeyValueStore store,
    String accountPrefix,
    Object? doc,
  ) async {
    if (accountPrefix.isEmpty || doc is! Map) return;
    final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: accountPrefix);
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().where((s) => s.isNotEmpty).toList() : const [];
    final ids = <String>{};
    final groups = doc['groups'];
    if (groups is List) {
      for (final g in groups) {
        if (g is! Map) continue;
        final id = g['id'];
        if (id is! String || id.isEmpty) continue;
        ids.add(id);
        final chatId = g['chatId'];
        if (chatId is String && chatId.isNotEmpty) {
          await prefs.setGroupChatId(id, chatId);
        }
        final type = g['type'];
        if (type is String && type.isNotEmpty) await prefs.setGroupType(id, type);
        final name = g['name'];
        if (name is String && name.isNotEmpty) await prefs.setGroupName(id, name);
      }
    }
    if (ids.isNotEmpty) await prefs.setGroups(ids);
    final quit = strings(doc['quit']);
    if (quit.isNotEmpty) await prefs.setQuitGroups(quit.toSet());
    final retained = strings(doc['historyRetained']);
    if (retained.isNotEmpty) {
      await prefs.setStringList(
        prefs.accountScopedKey(_historyRetainedKey),
        retained,
      );
    }
  }
}
