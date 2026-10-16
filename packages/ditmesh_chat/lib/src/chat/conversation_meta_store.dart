import 'dart:convert';

import '../adapters/key_value_store.dart';

/// A send started from a conversation's draft and not yet followed by any
/// draft write: the message id the send uses, and the stored draft it was
/// sent from (see [ConversationMetaStore.setSendIntent]).
typedef SendIntent = ({String id, String draft});

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
  // Not under `ditmesh_draft`: [allDrafts] must never read one as a draft.
  static const _kSendIntentPrefix = 'ditmesh_send_intent';

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

  /// Also supersedes the conversation's [sendIntent]: whatever the draft is
  /// now, it is no longer the one that send was made from. Both writes are
  /// submitted in one synchronous step, the draft first: the store applies
  /// them in that order, so a crash in between leaves an intent whose
  /// recorded draft no longer matches (which recovery ignores), and a
  /// recovery running meanwhile already sees the intent gone. If the draft
  /// write fails, the intent is put back: the stored draft is still the one
  /// the send was made from.
  Future<void> setDraft(String conversationId, String text) async {
    final key = _scoped('${_kDraftPrefix}_$conversationId');
    final intentKey = _intentKey(conversationId);
    final intent = _store.getString(intentKey);
    final draftWrite =
        text.isEmpty ? _store.remove(key) : _store.setString(key, text);
    // Marked handled now: its error, if any, is only read once the draft
    // write settled (and the draft's own error wins).
    final intentGone =
        intent == null ? null : (_store.remove(intentKey)..ignore());
    try {
      await draftWrite;
    } on Object catch (error, stack) {
      if (intent != null) {
        try {
          await intentGone;
          // Unless a newer send journalled its own intent meanwhile.
          if (_store.getString(intentKey) == null) {
            await _store.setString(intentKey, intent);
          }
        } on Object {
          // The draft write's failure is the one to report.
        }
      }
      Error.throwWithStackTrace(error, stack);
    }
    await intentGone;
  }

  // ---- send intents ---------------------------------------------------------
  //
  // A send commits its row (durable outbox, history) before the composer can
  // clear the draft it was made from; a process killed in between used to
  // bring the sent text back as the draft, inviting a second send. The send
  // journals its message id first; recovery at the next start removes the
  // draft when that id is committed ([reconcileSendIntents]).

  String _intentKey(String conversationId) =>
      _scoped('${_kSendIntentPrefix}_$conversationId');

  SendIntent? sendIntent(String conversationId) =>
      _parseIntent(_store.getString(_intentKey(conversationId)));

  /// Journals that a send with [messageId] is being made from the stored
  /// draft of [conversationId]. Must complete before the send can commit.
  Future<void> setSendIntent(String conversationId, String messageId) =>
      _store.setString(
        _intentKey(conversationId),
        jsonEncode({'id': messageId, 'draft': draft(conversationId)}),
      );

  Future<void> clearSendIntent(String conversationId) =>
      _store.remove(_intentKey(conversationId));

  /// Every stored send intent of this identity, by conversation id.
  Map<String, SendIntent> allSendIntents() {
    final head = '${_kSendIntentPrefix}_';
    final tail = _prefix.isEmpty ? '' : '_$_prefix';
    final out = <String, SendIntent>{};
    for (final key in _store.keys()) {
      if (!key.startsWith(head) || !key.endsWith(tail)) continue;
      final id = key.substring(head.length, key.length - tail.length);
      final intent = _parseIntent(_store.getString(key));
      if (id.isNotEmpty && intent != null) out[id] = intent;
    }
    return out;
  }

  static SendIntent? _parseIntent(String? raw) {
    if (raw == null) return null;
    try {
      final doc = jsonDecode(raw);
      if (doc is Map && doc['id'] is String && doc['draft'] is String) {
        return (id: doc['id'] as String, draft: doc['draft'] as String);
      }
    } on FormatException {
      // Unreadable: treated as absent (recovery then keeps the draft).
    }
    return null;
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
