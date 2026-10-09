import '../adapters/key_value_store.dart';

/// Per-identity conversation metadata the UI owns and Tim2Tox does not:
/// pinned conversations, drafts, hidden (deleted) conversations, and the
/// group invites queued for friends that were offline.
///
/// Keys are suffixed with the identity's 16-char account prefix — the same
/// scoping as `Tim2ToxPreferencesAdapter`, so `clear()` on either wipes both.
class ConversationMetaStore {
  ConversationMetaStore(this._store, {required String accountPrefix})
      : _prefix = accountPrefix;

  final KeyValueStore _store;
  final String _prefix;

  static const _kPinned = 'ditmesh_pinned_conversations';
  static const _kHidden = 'ditmesh_hidden_conversations';
  static const _kDraftPrefix = 'ditmesh_draft';
  static const _kQueuedInvites = 'ditmesh_queued_group_invites';
  static const _kWithdrawals = 'ditmesh_pending_withdrawals';

  String _scoped(String key) => _prefix.isEmpty ? key : '${key}_$_prefix';

  Set<String> _set(String key) =>
      _store.getStringList(_scoped(key))?.toSet() ?? <String>{};

  Future<void> _setSet(String key, Set<String> value) =>
      _store.setStringList(_scoped(key), value.toList()..sort());

  // ---- pinned --------------------------------------------------------------

  Set<String> get pinned => _set(_kPinned);

  bool isPinned(String conversationId) => pinned.contains(conversationId);

  Future<void> setPinned(String conversationId, bool value) {
    final s = pinned;
    if (value) {
      s.add(conversationId);
    } else {
      s.remove(conversationId);
    }
    return _setSet(_kPinned, s);
  }

  // ---- hidden (deleted until the next message) ------------------------------

  Set<String> get hidden => _set(_kHidden);

  Future<void> hide(String conversationId) =>
      _setSet(_kHidden, hidden..add(conversationId));

  Future<void> unhide(String conversationId) {
    final s = hidden;
    if (!s.remove(conversationId)) return Future<void>.value();
    return _setSet(_kHidden, s);
  }

  // ---- drafts ---------------------------------------------------------------

  String draft(String conversationId) =>
      _store.getString(_scoped('${_kDraftPrefix}_$conversationId')) ?? '';

  Future<void> setDraft(String conversationId, String text) {
    final key = _scoped('${_kDraftPrefix}_$conversationId');
    return text.isEmpty ? _store.remove(key) : _store.setString(key, text);
  }

  // ---- queued group invites (friend was offline) ----------------------------

  /// `groupId\tfriendPublicKey` entries.
  Set<String> get queuedInvites => _set(_kQueuedInvites);

  Future<void> queueInvite(String groupId, String friendPublicKey) =>
      _setSet(_kQueuedInvites, queuedInvites..add('$groupId\t$friendPublicKey'));

  Future<void> dequeueInvite(String groupId, String friendPublicKey) {
    final s = queuedInvites;
    if (!s.remove('$groupId\t$friendPublicKey')) return Future<void>.value();
    return _setSet(_kQueuedInvites, s);
  }

  // ---- queued rows a refused send still has to withdraw --------------------

  /// `peer\tmessageId` entries: rows queued for someone no longer a friend
  /// whose withdrawal could not be persisted yet (retried per session).
  Set<String> get withdrawals => _set(_kWithdrawals);

  Future<void> addWithdrawal(String peer, String messageId) =>
      _setSet(_kWithdrawals, withdrawals..add('$peer\t$messageId'));

  Future<void> removeWithdrawal(String entry) {
    final s = withdrawals;
    if (!s.remove(entry)) return Future<void>.value();
    return _setSet(_kWithdrawals, s);
  }

  /// Group ids with an invite waiting for [friendPublicKey].
  List<String> queuedGroupsFor(String friendPublicKey) => [
        for (final e in queuedInvites)
          if (e.endsWith('\t$friendPublicKey')) e.substring(0, e.indexOf('\t')),
      ];

  /// Every non-empty draft of this identity, by conversation id.
  Map<String, String> allDrafts() {
    final head = '${_kDraftPrefix}_';
    final tail = _prefix.isEmpty ? '' : '_$_prefix';
    final out = <String, String>{};
    for (final key in _store.keys()) {
      if (!key.startsWith(head) || !key.endsWith(tail)) continue;
      final id = key.substring(head.length, key.length - tail.length);
      final text = _store.getString(key);
      if (id.isNotEmpty && text != null && text.isNotEmpty) out[id] = text;
    }
    return out;
  }

  /// The portable part of this identity's metadata (backup, F10): pins,
  /// hidden conversations and drafts. Queued group invites are left out on
  /// purpose: a restored identity never replays them. So are [withdrawals]:
  /// a restore never rebuilds the outbox they act on; instead the backup
  /// leaves the rows they name out of its review items
  /// (`BackupSnapshot.withoutWithdrawn`).
  Map<String, Object?> exportPortable() => {
    'pinned': pinned.toList()..sort(),
    'hidden': hidden.toList()..sort(),
    'drafts': allDrafts(),
  };

  /// Writes [doc] (from [exportPortable]); unknown or malformed fields are
  /// ignored. The caller clears the identity first.
  Future<void> importPortable(Object? doc) async {
    if (doc is! Map) return;
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    final pins = strings(doc['pinned']);
    if (pins.isNotEmpty) await _setSet(_kPinned, pins.toSet());
    final hidden = strings(doc['hidden']);
    if (hidden.isNotEmpty) await _setSet(_kHidden, hidden.toSet());
    final drafts = doc['drafts'];
    if (drafts is Map) {
      for (final e in drafts.entries) {
        if (e.key is String && e.value is String) {
          await setDraft(e.key as String, e.value as String);
        }
      }
    }
  }

  /// Forgets everything about one conversation.
  Future<void> forget(String conversationId) async {
    await setPinned(conversationId, false);
    await setDraft(conversationId, '');
    await unhide(conversationId);
  }

  /// Removes every key of this identity.
  Future<void> clear() async {
    if (_prefix.isEmpty) return;
    final suffix = '_$_prefix';
    for (final k in _store.keys().where((k) => k.endsWith(suffix)).toList()) {
      await _store.remove(k);
    }
  }
}
