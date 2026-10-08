import 'dart:async';

import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import '../logging/chat_logger.dart';

/// The process-global custom-callback hook of the patched Tencent SDK
/// (`NativeLibraryManager.customCallbackHandler`), owned by ditmesh.
///
/// `libtim2tox_ffi` posts a handful of notifications through the SDK's Dart
/// send port that have no `V2Tim*` listener: the `friendAddResult` of
/// `tim2tox_ffi_add_friend`, and the `DartNotifyGroup*` family. toxee routes
/// them in `Tim2ToxSdkPlatform._handleCustomCallback`; ditmesh installs no
/// platform, so without this class the hook stays `null` and the SDK drops
/// every one of them. The visible symptom of the first: `addFriend` never
/// resolves and `FfiChatService` reports "timed out waiting for native
/// result" after 30 s, on success and on failure alike (found by the native
/// smoke test on macOS, 2026-09-30).
///
/// Only the [target] session (the one `Tim2ToxEngine.start` opened) is fed;
/// the group notifications are additionally checked with
/// `ownsNativeSessionNotification`, exactly as toxee does, so a late
/// notification from a previous session cannot mutate the new one.
class NativeCustomCallbacks {
  NativeCustomCallbacks(this._logger);

  final ChatLogger _logger;

  /// The live session, or null between sessions (callbacks are dropped).
  FfiChatService? target;

  /// Notifications stamped with the emitting native session (see
  /// `Tim2ToxSdkPlatform._sessionScopedNativeNotifications`).
  static const Set<String> sessionScoped = {
    'groupQuitNotification',
    'groupJoinNotification',
    'groupJoinFailedNotification',
    'groupInviteNotification',
    'groupChatIdStored',
    'groupTypeStored',
  };

  /// Registers the SDK's receive port and points the hook at [handle].
  /// Idempotent; a hook installed by someone else is replaced, since ditmesh
  /// is the only Tim2Tox consumer in this process.
  void install() {
    NativeLibraryManager.registerPort();
    NativeLibraryManager.customCallbackHandler = handle;
  }

  /// Removes the hook if it is still ours.
  void uninstall() {
    target = null;
    // Tear-offs of the same method compare equal (not identical).
    if (NativeLibraryManager.customCallbackHandler == handle) {
      NativeLibraryManager.customCallbackHandler = null;
    }
  }

  /// The hook body (public so tests can drive it without a native port).
  Future<void> handle(
    String callbackName,
    Map<String, dynamic> data,
    Map<String, ApiCallback> apiCallbackMap,
  ) async {
    final svc = target;
    if (svc == null) {
      _logger.info('[NativeCallbacks] $callbackName dropped: no live session');
      return;
    }
    if (sessionScoped.contains(callbackName) && !_owns(svc, callbackName, data)) {
      return;
    }
    try {
      await _dispatch(svc, callbackName, data);
    } catch (e, st) {
      _logger.error('[NativeCallbacks] $callbackName failed', e, st);
    }
  }

  bool _owns(FfiChatService svc, String name, Map<String, dynamic> data) {
    bool owned;
    try {
      owned = svc.ownsNativeSessionNotification(data);
    } catch (e, st) {
      _logger.error('[NativeCallbacks] $name: ownership check failed', e, st);
      return false;
    }
    if (!owned) {
      _logger.info(
        '[NativeCallbacks] $name dropped: not this session '
        '(instance_id=${data['instance_id']}, '
        'session_epoch=${data['session_epoch']})',
      );
    }
    return owned;
  }

  Future<void> _dispatch(
    FfiChatService svc,
    String name,
    Map<String, dynamic> data,
  ) async {
    switch (name) {
      case 'friendAddResult':
        // Resolves the completer FfiChatService.addFriend registered, so the
        // caller sees the real V2TIMFriendOperationResult (0 = success;
        // e.g. 6770 = tox_friend_add refused the address).
        final userId = data['user_id'] as String?;
        if (userId == null) {
          _logger.info('[NativeCallbacks] friendAddResult without user_id');
          return;
        }
        svc.handleFriendAddResultCallback(
          userId: userId,
          resultCode: _int(data['result_code']),
          resultInfo: (data['result_info'] as String?) ?? '',
        );
      case 'groupQuitNotification':
        final groupId = data['group_id'] as String?;
        if (groupId != null) {
          await svc.cleanupGroupState(
            groupId,
            keepHistory: data['reason'] == 'kicked',
          );
        }
      case 'groupJoinNotification':
        final groupId = data['group_id'] as String?;
        if (groupId != null) await svc.registerJoinedGroupState(groupId);
      case 'groupJoinFailedNotification':
        final groupId = data['group_id'] as String?;
        if (groupId != null && groupId.isNotEmpty) {
          await svc.handleGroupJoinFailed(
            groupId,
            (data['chat_id'] as String?) ?? '',
            (data['reason'] as String?) ?? 'unknown',
            established: data['established'] == true,
            inviteId: (data['invite_id'] as String?) ?? '',
          );
        }
      case 'groupInviteNotification':
        svc.notifyPendingGroupInvitesChanged();
      case 'groupChatIdStored':
      case 'groupTypeStored':
        // toxee writes these into its preferences service; ditmesh keeps the
        // native side authoritative and pulls (same routine the engine runs
        // after startPolling).
        await svc.syncGroupIdentitiesFromNative();
      default:
        // clearHistoryMessage and anything newer: ditmesh clears history
        // through FfiChatService itself and has no Tencent-side store to
        // mirror into.
        _logger.info('[NativeCallbacks] $name ignored');
    }
  }

  static int _int(Object? raw) => switch (raw) {
        final int v => v,
        final num v => v.toInt(),
        _ => int.tryParse(raw?.toString() ?? '') ?? -1,
      };
}
