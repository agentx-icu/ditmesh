part of 'tim2tox_identity_service.dart';

/// Recovery from a restore the process did not survive, and the guard that
/// keeps the profile tree untouched while a native teardown is unconfirmed.
///
/// Both importers commit with two renames: `root → <stage>/previous`, then
/// `<stage>/identity → root`. Death between them leaves no root and the only
/// copy of the previous identity in staging. The tree is rolled back (never
/// rolled forward: the staged restore's preference work is not journaled and
/// the user still has the backup file). Callers hold the mutation lock.
extension _IdentityRecovery on Tim2ToxIdentityService {
  /// Returns false while a previous identity is still waiting in staging:
  /// this attempt failed, or several candidates make the choice ambiguous.
  /// `inspect` / `open` / `unlock` then report no identity as before (the
  /// next start retries), but `create` must not install a new root over it.
  Future<bool> _recoverInterruptedImport() async {
    if (_paths.profileExists) return true;
    final List<Directory> stages;
    try {
      stages = await _paths.interruptedImports();
    } on Object catch (e, st) {
      _logger.error('[Identity] could not look for interrupted restores', e, st);
      return false;
    }
    if (stages.isEmpty) return true;
    if (stages.length > 1) {
      // Ambiguous: never pick, never delete. Left for deleteIdentity.
      _logger.error(
        '[Identity] ${stages.length} interrupted restores found; not recovering',
      );
      return false;
    }
    final stage = stages.single;
    final previous = IdentityPaths(IdentityPaths.previousInStage(stage));
    try {
      final old = await IdentityRecord.read(previous.identityFile);
      final staged = await IdentityRecord.read(
        IdentityPaths(p.join(stage.path, 'identity')).identityFile,
      );
      // Verifier first, tree second: the stage is the durable record that
      // recovery is still owed. Death or a secure-store failure here leaves
      // it in place, and the next start retries the whole thing; moving the
      // tree first would end recovery with a verifier nobody fixes.
      await _reconcileVerifier(previous, old, staged);
      await Directory(previous.root).rename(_paths.root);
      await stage.delete(recursive: true);
      _logger.info(
        '[Identity] recovered the previous identity after an interrupted restore',
      );
      return true;
    } on Object catch (e, st) {
      _logger.error('[Identity] recovery of the previous identity failed', e, st);
      return false;
    }
  }

  /// The restore had already written the incoming identity's verifier
  /// (`replacePassword` commits it before the swap). A different Tox ID
  /// leaves an orphan to remove. The same Tox ID now carries the backup's
  /// password state: an encrypted previous profile proves its own password
  /// and `_unlock` repairs the verifier, but a plaintext one would be
  /// reported locked behind a password it was never protected with.
  Future<void> _reconcileVerifier(
    IdentityPaths previous,
    IdentityRecord? old,
    IdentityRecord? staged,
  ) async {
    if (staged != null && (old == null || staged.toxId != old.toxId)) {
      await _verifier.removePassword(staged.toxId);
      return;
    }
    if (old == null) return;
    final bytes = await File(previous.profileFile).readAsBytes();
    if (_crypto.isEncrypted(bytes)) return;
    await _verifier.removePassword(old.toxId);
    if (old.hasPassword) {
      // Its old verifier hash is gone with the overwrite; the file is plain.
      await old.copyWith(hasPassword: false).write(previous.identityFile);
    }
  }

  /// Nothing may snapshot, replace, rewrite or delete the profile tree while
  /// a stopped session's native instance might still write into it (see
  /// [ChatEngine.nativeTeardownConfirmed]). Checked after [_disconnectImpl]
  /// at every such site, because a stop that failed earlier is not retried
  /// when `_started` is already false.
  void _requireTeardownConfirmed() {
    if (_engine.nativeTeardownConfirmed) return;
    throw const ChatException(
      'teardown_unconfirmed',
      'The previous Tox session has not fully stopped',
    );
  }

  /// Encrypts `tox_profile.tox` in place when a session password is held and
  /// the file is plaintext. No-op otherwise. Atomic rename.
  Future<void> _encryptProfileAtRest() async {
    final password = _sessionPassword;
    if (password == null || password.isEmpty) return;
    final file = File(_paths.profileFile);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || _crypto.isEncrypted(bytes)) return;
    if (!_engine.nativeTeardownConfirmed) {
      // A zombie native save could overwrite the ciphertext with plaintext
      // behind our back; retried on the next disconnect or stop.
      _logger.error(
        '[Identity] profile left as is: native teardown unconfirmed',
      );
      return;
    }
    await _writeAtomic(file, _crypto.encrypt(bytes, password));
  }

  static Future<void> _writeAtomic(File target, Uint8List bytes) =>
      writeBytesAtomic(target, bytes);
}
