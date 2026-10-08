import 'package:tim2tox_dart/interfaces/draft_preferences_service.dart';
import 'package:tim2tox_dart/interfaces/extended_preferences_service.dart';
import 'package:tim2tox_dart/interfaces/group_identity_preferences_service.dart';

import 'key_value_store.dart';

/// Tim2Tox's host preference interfaces over a [KeyValueStore].
///
/// Modelled on toxee's `SharedPreferencesAdapter`, minus the legacy-key
/// migrations toxee carries: ditmesh has no pre-scoping data to migrate.
///
/// Scoping: every identity-bound key is written as `<key>_<accountPrefix>`
/// where [accountPrefix] is the first 16 hex chars of the Tox ID (the same
/// convention as toxee, so a future profile import from toxee lands on
/// familiar slots). Network-level settings (bootstrap node, downloads
/// directory, auto-download limit) stay global. The generic
/// `getString`/`setString` family takes keys verbatim — Tim2Tox scopes the
/// keys it invents itself through [accountScopedKey]. The older friend-request
/// dismissal family is scoped here because Tim2Tox delegates it to the host.
class Tim2ToxPreferencesAdapter
    implements
        ExtendedPreferencesService,
        DraftPreferencesService,
        GroupIdentityPreferencesService,
        AccountScopedPreferencesService {
  Tim2ToxPreferencesAdapter(this._store, {required String accountPrefix})
    : _accountPrefix = accountPrefix;

  final KeyValueStore _store;
  final String _accountPrefix;

  static const _kGroups = 'groups_list';
  static const _kQuitGroups = 'quit_groups_list';
  static const _kSelfAvatarHash = 'self_avatar_hash';
  static const _kSelfAvatarPath = 'self_avatar_path';
  static const _kLocalFriends = 'local_friends';
  static const _kBootstrapNodeMode = 'bootstrap_node_mode';
  static const _kBootstrapHost = 'current_bootstrap_host';
  static const _kBootstrapPort = 'current_bootstrap_port';
  static const _kBootstrapPubkey = 'current_bootstrap_pubkey';
  static const _kDownloadsDir = 'downloads_directory';
  static const _kDraftPrefix = 'conversation_draft';

  /// `<key>_<prefix>` — the account-scoped slot for [key].
  String _scoped(String key) =>
      _accountPrefix.isEmpty ? key : '${key}_$_accountPrefix';

  @override
  String accountScopedKey(String key) => _scoped(key);

  // Tim2Tox leaves this older preference family to the host to scope.
  String _genericKey(String key) =>
      key == 'dismissed_friend_applications' ? _scoped(key) : key;

  Future<void> _setOrRemove(String scopedKey, String? value) =>
      value == null || value.isEmpty
      ? _store.remove(scopedKey)
      : _store.setString(scopedKey, value);

  Set<String> _scopedSet(String key) =>
      _store.getStringList(_scoped(key))?.toSet() ?? <String>{};

  Future<void> _setScopedSet(String key, Set<String> value) =>
      _store.setStringList(_scoped(key), value.toList()..sort());

  // ---- PreferencesService (verbatim keys) ----------------------------------

  @override
  Future<String?> getString(String key) async => _store.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);

  @override
  Future<bool?> getBool(String key) async => _store.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  @override
  Future<int?> getInt(String key) async => _store.getInt(key);

  @override
  Future<void> setInt(String key, int value) => _store.setInt(key, value);

  @override
  Future<List<String>?> getStringList(String key) async {
    final scoped = _genericKey(key);
    final existing = _store.getStringList(scoped);
    if (existing != null || scoped == key) return existing;
    // ditmesh has one stored identity. The formerly global refusal list
    // belongs to that identity; adopt it once before a new account is created.
    final legacy = _store.getStringList(key);
    if (legacy == null) return null;
    await _store.setStringList(scoped, legacy);
    await _store.remove(key);
    return legacy;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    final scoped = _genericKey(key);
    await _store.setStringList(scoped, value);
    if (scoped != key) await _store.remove(key);
  }

  @override
  Future<void> remove(String key) => _store.remove(key);

  @override
  Future<Set<String>> getStringSet(String key) async =>
      _store.getStringList(key)?.toSet() ?? <String>{};

  @override
  Future<void> setStringSet(String key, Set<String> value) =>
      _store.setStringList(key, value.toList());

  /// Removes every key that belongs to this identity. Never wipes the global
  /// (network-level) settings or another identity's slots.
  @override
  Future<void> clear() async {
    if (_accountPrefix.isEmpty) return;
    // An identity removed before its first connect never ran the migration.
    // Its old refusal list must not be inherited by the next identity.
    await _store.remove('dismissed_friend_applications');
    final suffix = '_$_accountPrefix';
    final doomed = _store.keys().where((key) {
      if (key.endsWith(suffix)) return true;
      for (final family in const [
        'conversation_draft_',
        'pending_read_receipts_',
        'pending_group_read_receipts_',
      ]) {
        if (!key.startsWith(family)) continue;
        final scope = key.substring(family.length).split('_').first;
        if ((scope.length == 64 || scope.length == 76) &&
            scope.toUpperCase().startsWith(_accountPrefix.toUpperCase())) {
          return true;
        }
      }
      return false;
    }).toList();
    for (final k in doomed) {
      await _store.remove(k);
    }
  }

  // ---- Groups --------------------------------------------------------------

  @override
  Future<Set<String>> getGroups() async => _scopedSet(_kGroups);

  @override
  Future<void> setGroups(Set<String> groups) => _setScopedSet(_kGroups, groups);

  @override
  Future<Set<String>> getQuitGroups() async => _scopedSet(_kQuitGroups);

  @override
  Future<void> setQuitGroups(Set<String> groups) =>
      _setScopedSet(_kQuitGroups, groups);

  @override
  Future<void> addQuitGroup(String groupId) =>
      _setScopedSet(_kQuitGroups, _scopedSet(_kQuitGroups)..add(groupId));

  @override
  Future<void> removeQuitGroup(String groupId) =>
      _setScopedSet(_kQuitGroups, _scopedSet(_kQuitGroups)..remove(groupId));

  @override
  Future<String?> getGroupName(String groupId) async =>
      _store.getString(_scoped('group_name_$groupId'));

  @override
  Future<void> setGroupName(String groupId, String name) =>
      _store.setString(_scoped('group_name_$groupId'), name);

  @override
  Future<String?> getGroupAvatar(String groupId) async =>
      _store.getString(_scoped('group_avatar_$groupId'));

  @override
  Future<void> setGroupAvatar(String groupId, String? avatarPath) =>
      _setOrRemove(_scoped('group_avatar_$groupId'), avatarPath);

  @override
  Future<String?> getGroupNotification(String groupId) async =>
      _store.getString(_scoped('group_notification_$groupId'));

  @override
  Future<void> setGroupNotification(String groupId, String? notification) =>
      _setOrRemove(_scoped('group_notification_$groupId'), notification);

  @override
  Future<String?> getGroupIntroduction(String groupId) async =>
      _store.getString(_scoped('group_introduction_$groupId'));

  @override
  Future<void> setGroupIntroduction(String groupId, String? introduction) =>
      _setOrRemove(_scoped('group_introduction_$groupId'), introduction);

  @override
  Future<String?> getGroupOwner(String groupId) async =>
      _store.getString(_scoped('group_owner_$groupId'));

  @override
  Future<void> setGroupOwner(String groupId, String ownerId) =>
      _store.setString(_scoped('group_owner_$groupId'), ownerId);

  @override
  Future<String?> getGroupChatId(String groupId) async =>
      _store.getString(_scoped('group_chat_id_$groupId'));

  @override
  Future<void> setGroupChatId(String groupId, String chatId) =>
      _setOrRemove(_scoped('group_chat_id_$groupId'), chatId);

  // ---- GroupIdentityPreferencesService -------------------------------------

  @override
  Future<String?> getGroupType(String groupId) async =>
      _store.getString(_scoped('group_type_$groupId'));

  @override
  Future<void> setGroupType(String groupId, String groupType) =>
      _setOrRemove(_scoped('group_type_$groupId'), groupType);

  @override
  Future<void> removeGroupIdentity(String groupId) async {
    for (final k in const ['chat_id', 'conference_id', 'type']) {
      await _store.remove(_scoped('group_${k}_$groupId'));
    }
  }

  // ---- Self profile --------------------------------------------------------

  @override
  Future<String?> getSelfAvatarHash() async =>
      _store.getString(_scoped(_kSelfAvatarHash));

  @override
  Future<void> setSelfAvatarHash(String? hash) =>
      _setOrRemove(_scoped(_kSelfAvatarHash), hash);

  @override
  Future<String?> getAvatarPath() async =>
      _store.getString(_scoped(_kSelfAvatarPath));

  @override
  Future<void> setAvatarPath(String? path) =>
      _setOrRemove(_scoped(_kSelfAvatarPath), path);

  // ---- Friends -------------------------------------------------------------

  @override
  Future<String?> getFriendNickname(String friendId) async =>
      _store.getString(_scoped('friend_nickname_$friendId'));

  @override
  Future<void> setFriendNickname(String friendId, String nickname) =>
      _store.setString(_scoped('friend_nickname_$friendId'), nickname);

  @override
  Future<String?> getFriendStatusMessage(String friendId) async =>
      _store.getString(_scoped('friend_status_msg_$friendId'));

  @override
  Future<void> setFriendStatusMessage(String friendId, String statusMessage) =>
      _store.setString(_scoped('friend_status_msg_$friendId'), statusMessage);

  @override
  Future<String?> getFriendAvatarPath(String friendId) async =>
      _store.getString(_scoped('friend_avatar_path_$friendId'));

  @override
  Future<void> setFriendAvatarPath(String friendId, String? path) =>
      _setOrRemove(_scoped('friend_avatar_path_$friendId'), path);

  @override
  Future<String?> getFriendAvatarHash(String friendId) async =>
      _store.getString(_scoped('friend_avatar_hash_$friendId'));

  @override
  Future<void> setFriendAvatarHash(String friendId, String hash) =>
      _store.setString(_scoped('friend_avatar_hash_$friendId'), hash);

  @override
  Future<String?> getFriendRemark(String friendId) async =>
      _store.getString(_scoped('friend_remark_$friendId'));

  @override
  Future<void> setFriendRemark(String friendId, String? remark) =>
      _setOrRemove(_scoped('friend_remark_$friendId'), remark);

  @override
  Future<Set<String>> getLocalFriends() async => _scopedSet(_kLocalFriends);

  @override
  Future<void> setLocalFriends(Set<String> ids) =>
      _setScopedSet(_kLocalFriends, ids);

  // ---- Network-level (global) ----------------------------------------------

  @override
  Future<String> getBootstrapNodeMode() async =>
      _store.getString(_kBootstrapNodeMode) ?? 'auto';

  @override
  Future<({String host, int port, String pubkey})?>
  getCurrentBootstrapNode() async {
    final host = _store.getString(_kBootstrapHost);
    final pubkey = _store.getString(_kBootstrapPubkey) ?? '';
    if (host == null || host.isEmpty || pubkey.isEmpty) return null;
    return (
      host: host,
      port: _store.getInt(_kBootstrapPort) ?? 33445,
      pubkey: pubkey,
    );
  }

  @override
  Future<void> setCurrentBootstrapNode(
    String host,
    int port,
    String pubkey,
  ) async {
    await _store.setString(_kBootstrapHost, host);
    await _store.setInt(_kBootstrapPort, port);
    await _store.setString(_kBootstrapPubkey, pubkey);
  }

  /// Always 0: DitMesh has no file feature. Tim2Tox reads 0 as "take no
  /// files at all" and refuses every incoming transfer (images included)
  /// before it makes a history row, an unread count or a download.
  @override
  Future<int> getAutoDownloadSizeLimit() async => 0;

  /// Ignored, see [getAutoDownloadSizeLimit].
  @override
  Future<void> setAutoDownloadSizeLimit(int sizeInMB) async {}

  @override
  Future<String?> getDownloadsDirectory() async =>
      _store.getString(_kDownloadsDir);

  @override
  Future<void> setDownloadsDirectory(String? path) =>
      _setOrRemove(_kDownloadsDir, path);

  // ---- Blacklist / receive options (per explicit account) -------------------

  /// The blacklist and receive-option families are keyed by the FULL Tox ID
  /// the caller passes (Tim2Tox passes `prefsAccountScopeToxId`). When the
  /// caller has none we fall back to our own prefix rather than a shared
  /// global slot — toxee documents why the global slot is a defect.
  String? _explicitScope(String? userToxId) {
    final t = userToxId?.trim() ?? '';
    if (t.length >= 16) return t.substring(0, 16).toUpperCase();
    return _accountPrefix.isEmpty ? null : _accountPrefix;
  }

  String _blackListKey(String scope) => 'black_list_$scope';

  @override
  Future<Set<String>> getBlackList([String? userToxId]) async {
    final scope = _explicitScope(userToxId);
    if (scope == null) return <String>{};
    return _store.getStringList(_blackListKey(scope))?.toSet() ?? <String>{};
  }

  @override
  Future<void> setBlackList(Set<String> userIDs, [String? userToxId]) async {
    final scope = _explicitScope(userToxId);
    if (scope == null) return;
    await _store.setStringList(_blackListKey(scope), userIDs.toList()..sort());
  }

  @override
  Future<void> addToBlackList(List<String> userIDs, [String? userToxId]) async {
    final current = await getBlackList(userToxId);
    await setBlackList(current..addAll(userIDs), userToxId);
  }

  @override
  Future<void> removeFromBlackList(
    List<String> userIDs, [
    String? userToxId,
  ]) async {
    final current = await getBlackList(userToxId);
    await setBlackList(current..removeAll(userIDs), userToxId);
  }

  Future<int> _recvOpt(String key, String? userToxId) async {
    final scope = _explicitScope(userToxId);
    if (scope == null) return 0;
    return _store.getInt('${key}_$scope') ?? 0;
  }

  Future<void> _setRecvOpt(String key, int opt, String? userToxId) async {
    final scope = _explicitScope(userToxId);
    if (scope == null) return;
    final k = '${key}_$scope';
    if (opt == 0) {
      await _store.remove(k);
    } else {
      await _store.setInt(k, opt);
    }
  }

  @override
  Future<int> getC2CReceiveMessageOpt(String userID, [String? userToxId]) =>
      _recvOpt('c2c_recv_opt_$userID', userToxId);

  @override
  Future<void> setC2CReceiveMessageOpt(
    String userID,
    int opt, [
    String? userToxId,
  ]) => _setRecvOpt('c2c_recv_opt_$userID', opt, userToxId);

  @override
  Future<int> getGroupReceiveMessageOpt(String groupID, [String? userToxId]) =>
      _recvOpt('group_recv_opt_$groupID', userToxId);

  @override
  Future<void> setGroupReceiveMessageOpt(
    String groupID,
    int opt, [
    String? userToxId,
  ]) => _setRecvOpt('group_recv_opt_$groupID', opt, userToxId);

  // ---- DraftPreferencesService ---------------------------------------------

  String _draftKey(String accountToxId, String conversationID) =>
      '${_kDraftPrefix}_${accountToxId.trim().toUpperCase()}_'
      '${conversationID.trim()}';

  @override
  Future<ConversationDraft?> loadConversationDraft({
    required String accountToxId,
    required String conversationID,
  }) async {
    final key = _draftKey(accountToxId, conversationID);
    final text = _store.getString(key);
    if (text == null || text.isEmpty) return null;
    return ConversationDraft(
      conversationID: conversationID.trim(),
      text: text,
      timestamp: _store.getInt('${key}_ts') ?? 0,
    );
  }

  @override
  Future<void> saveConversationDraft({
    required String accountToxId,
    required ConversationDraft draft,
  }) async {
    if (draft.text.isEmpty) {
      return removeConversationDraft(
        accountToxId: accountToxId,
        conversationID: draft.conversationID,
      );
    }
    final key = _draftKey(accountToxId, draft.conversationID);
    await _store.setString(key, draft.text);
    await _store.setInt('${key}_ts', draft.timestamp);
  }

  @override
  Future<void> removeConversationDraft({
    required String accountToxId,
    required String conversationID,
  }) async {
    final key = _draftKey(accountToxId, conversationID);
    await _store.remove(key);
    await _store.remove('${key}_ts');
  }
}
