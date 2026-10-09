import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'rhythm_transport.dart';

/// [FfiChatService] with a case-insensitive blacklist check.
///
/// Tim2Tox's S29 filter ([FfiChatService.isBlocked]) compares the stored
/// key with the inbound id case-sensitively ([FfiChatService.normalizeToxId]
/// keeps the caller's case), while Tox keys are hex and reach it from
/// several paths. DitMesh stores one canonical upper-case key per blocked
/// peer; this override makes every Tim2Tox inbound path (C2C text, files,
/// avatars) match it whatever case the id arrives in, without editing
/// `third_party` or Tim2Tox's global id normalisation.
class DitmeshFfiChatService extends FfiChatService {
  DitmeshFfiChatService({
    super.preferencesService,
    super.loggerService,
    super.bootstrapService,
    super.historyDirectory,
    super.queueFilePath,
    super.fileRecvPath,
    super.avatarsPath,
    super.scratchFileService,
    // Tests only (Tim2ToxFfi.forTesting binding fakes); production leaves
    // it unset.
    super.ffiForTesting,
  });

  Set<String> _canonical = const <String>{};
  late final RhythmTransport _rhythm = RhythmTransport(this);

  bool supportsRecordedPeer(String peer) => _rhythm.supportsPeer(peer);

  @override
  void onFriendWireState(String peer, bool online) =>
      _rhythm.presence(peer, online);

  @override
  Future<String?> sendTextExtension(
    String peer,
    String text,
    String? metadata, {
    String? durableId,
    required ChatMessageContentKind kind,
  }) => _rhythm.send(peer, text, metadata, durableId: durableId, kind: kind);

  @override
  bool consumeCustomExtension(String peer, String payload, {String? groupId}) =>
      _rhythm.consume(peer, payload, groupId: groupId);

  @override
  void onGroupExtensionSent(
    String groupId,
    String text,
    String? metadata,
    String? alias,
  ) => _rhythm.groupSent(groupId, text, metadata, alias);

  @override
  ChatMessage enrichGroupExtension(ChatMessage row) => _rhythm.enrich(row);

  static String _canon(String id) {
    final trimmed = id.trim().toUpperCase();
    return trimmed.length > 64 ? trimmed.substring(0, 64) : trimmed;
  }

  @override
  bool isBlocked(String peerId) =>
      _canonical.isNotEmpty &&
      peerId.isNotEmpty &&
      _canonical.contains(_canon(peerId));

  @override
  Future<void> refreshBlockedUsers() async {
    await super.refreshBlockedUsers();
    _canonical = {for (final id in blockedUsers) _canon(id)};
  }
}
