import 'dart:async';
import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';
import 'package:tencent_cloud_chat_sdk/native_im/tools.dart';

import 'message_mapper.dart';

/// The group operations that Tim2Tox still exposes only through the Tencent
/// SDK's `Dart*` compat bindings (implemented by `libtim2tox_ffi`, see
/// tim2tox `ffi/dart_compat_*.cpp`), called the same way
/// `FfiChatService.quitGroup` calls `DartQuitGroup`:
///
///   * member listing (NGC and conference) → `DartGetGroupMemberList`
///   * group invite                        → `DartInviteUserToGroup`
///
/// Both need `NativeLibrarySetup.ensure()` to have run so the bindings load
/// `libtim2tox_ffi`. They deliberately bypass `TIMGroupManager`, whose
/// wrappers refuse with "sdk not init" unless `TIMManager.initSDK` ran — and
/// initSDK would install the SDK's own native message listeners, i.e. the
/// second inbound path toxee needs `BinaryReplacementHistoryHook` to
/// reconcile. ditmesh keeps one path.
class GroupBindings {
  GroupBindings._();

  static const Duration timeout = Duration(seconds: 15);

  /// Members of a group. Deduplicated by public key: the NGC peer enumeration
  /// underneath is keyed by ephemeral peer ids, and a peer that churned can
  /// surface twice (the same collapse tim2tox's platform performs).
  static Future<List<GroupMember>> members(
    String groupId, {
    required String selfKey,
    required String? Function(String publicKey) nameOf,
  }) async {
    NativeLibraryManager.registerPort();
    final userData = Tools.generateUserData('ditmesh_getGroupMemberList');
    final completer = Completer<V2TimValueCallback<V2TimGroupMemberInfoResult>>();
    NativeLibraryManager.addTimValueCallback2Map<V2TimGroupMemberInfoResult>(
      userData,
      completer,
    );
    final jsonParam = jsonEncode({
      'group_get_members_info_list_param_group_id': groupId,
      'group_get_members_info_list_param_option': {
        'group_member_get_info_option_role_flag': 0,
      },
      'group_get_members_info_list_param_next_seq': 0,
    });
    final pJson = Tools.string2PointerChar(jsonParam);
    final pUser = Tools.string2PointerVoid(userData);
    try {
      final rc = NativeLibraryManager.bindings.DartGetGroupMemberList(pJson, pUser);
      if (rc != 0) {
        NativeLibraryManager.removeTimCallbackFromMap(userData);
        throw ChatException('group_not_found', 'Member list refused (rc=$rc)');
      }
      final result = await completer.future.timeout(timeout, onTimeout: () {
        NativeLibraryManager.removeTimCallbackFromMap(userData);
        throw const ChatException('timeout', 'Member list timed out');
      });
      if (result.code != 0) {
        throw ChatException('group_not_found', result.desc);
      }
      final byKey = <String, GroupMember>{};
      for (final m in result.data?.memberInfoList ?? const <V2TimGroupMemberFullInfo>[]) {
        if (m.userID.isEmpty) continue;
        final key = ConversationIds.normalizeKey(m.userID);
        final nick = m.nickName ?? '';
        byKey.putIfAbsent(
          key,
          () => GroupMember(
            publicKey: key,
            displayName: nick.isNotEmpty
                ? nick
                : nameOf(key) ?? ConversationIds.shortKey(key),
            isSelf: key == selfKey,
            online: m.isOnline ?? true,
          ),
        );
      }
      return byKey.values.toList();
    } finally {
      Tools.freePointers([pJson, pUser]);
    }
  }

  /// Invites [friendPublicKey] (must be online) to [groupId]. Returns false
  /// when Tox refused (typically: the friend is not connected).
  static Future<bool> invite(String groupId, String friendPublicKey) async {
    NativeLibraryManager.registerPort();
    final userData = Tools.generateUserData('ditmesh_inviteUserToGroup');
    final completer =
        Completer<V2TimValueCallback<List<V2TimGroupMemberOperationResult>>>();
    NativeLibraryManager.addTimValueCallback2Map<
        List<V2TimGroupMemberOperationResult>>(userData, completer);
    final pJson = Tools.string2PointerChar(jsonEncode({
      'group_invite_member_param_group_id': groupId,
      'group_invite_member_param_identifier_array': [friendPublicKey],
      'group_invite_member_param_user_data': null,
    }));
    final pUser = Tools.string2PointerVoid(userData);
    try {
      final rc = NativeLibraryManager.bindings.DartInviteUserToGroup(pJson, pUser);
      if (rc != 0) {
        NativeLibraryManager.removeTimCallbackFromMap(userData);
        return false;
      }
      final result = await completer.future.timeout(timeout, onTimeout: () {
        NativeLibraryManager.removeTimCallbackFromMap(userData);
        return V2TimValueCallback<List<V2TimGroupMemberOperationResult>>(
          code: -1,
          desc: 'timeout',
        );
      });
      if (result.code != 0) return false;
      return (result.data ?? const []).any((op) => op.result == 1);
    } finally {
      Tools.freePointers([pJson, pUser]);
    }
  }
}
