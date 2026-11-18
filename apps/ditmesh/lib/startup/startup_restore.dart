part of 'startup_controller.dart';

extension _StartupRestore on StartupController {
  Future<Identity> _restoreFromBackup(Uint8List bytes, String? password) async {
    final identity = await _identity.importBackup(bytes, password: password);
    await _applyRestoredPreferences(_identity.current);
    await _finishRestore();
    return identity;
  }

  Future<({RestoreReport report, bool preferencesFailed})>
  _restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase,
    String? identityPassword,
  ) async {
    final backups = switch (_identity) {
      final EncryptedBackupService service => service,
      _ => throw const ChatException(
        'unsupported_backup_version',
        'This backend cannot read encrypted backups',
      ),
    };
    final report = await backups.restoreEncryptedBackup(
      bytes,
      passphrase,
      identityPassword: identityPassword,
    );
    final owner = report.restoredIdentity ?? _identity.current;
    final preferencesApplied = await _applyRestoredPreferences(
      owner,
      fallback: report.preferences,
    );
    await _finishRestore();
    return (report: report, preferencesFailed: !preferencesApplied);
  }

  Future<bool> _applyRestoredPreferences(
    Identity? owner, {
    Uint8List? fallback,
  }) async {
    final apply = _applyBackupPreferences;
    if (apply == null || owner == null) return fallback == null;
    try {
      if (_identity case final IdentityRestoreRecovery recovery) {
        final clear = _clearRestoredIdentityPreferences;
        if (clear == null) return false;
        final applied = await recovery.finishPendingAppRestore(
          owner,
          clearPreviousPreferences: (key) => clear(owner, key),
          applyPreferences: (doc) => apply(owner, doc),
        );
        return applied ?? true;
      }
      return fallback == null ||
          (identical(owner, _identity.current) && await apply(owner, fallback));
    } on Object {
      return false;
    }
  }

  Future<void> _finishRestore() async {
    final fromGuest = _cameFromGuest;
    _cameFromGuest = false;
    guestMode.value = false;
    // Restored progress is used; guest scores are never silently merged.
    _guestChoicePending = fromGuest && await _guestHasProgress();
    _becomeReady();
  }
}
