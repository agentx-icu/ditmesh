import 'package:tim2tox_dart/service/ffi_chat_service.dart';

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
