part of 'tim2tox_identity_service.dart';

extension _IdentityProfile on Tim2ToxIdentityService {
  Future<Identity> _create(String displayName, String? password) async {
    if (_paths.profileExists) {
      throw const ChatException(
        'identity_exists',
        'An identity already exists',
      );
    }
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ChatException('invalid_name', 'Display name is empty');
    }
    String? createdId;
    try {
      await _paths.ensureDirectories();
      final protected = password != null && password.isNotEmpty;
      // Native writes the new profile encrypted from its first save.
      final toxId = await _engine.createProfile(
        paths: _paths,
        displayName: name,
        statusMessage: '',
        passphrase: protected ? password : null,
      );
      createdId = toxId;
      final record = IdentityRecord(
        toxId: toxId,
        displayName: name,
        hasPassword: protected,
      );
      if (protected) {
        final file = File(_paths.profileFile);
        final bytes = await file.readAsBytes();
        // Never encrypt twice; encrypt here only if the engine did not.
        final encrypted = _crypto.isEncrypted(bytes)
            ? null
            : _crypto.encrypt(bytes, password);
        await _verifier.replacePassword(toxId, password, () async {
          if (encrypted != null) await writeBytesAtomic(file, encrypted);
          await record.write(_paths.identityFile);
        });
      } else {
        await record.write(_paths.identityFile);
      }
      _sessionPassword = protected ? password : null;
      _publish(record);
      _logger.info('[Identity] created ${toxId.substring(0, 8)}…');
      return record.toIdentity();
    } catch (_) {
      try {
        if (createdId != null) await _verifier.removePassword(createdId);
      } finally {
        await _paths.deleteAll();
      }
      rethrow;
    }
  }

  Future<void> _changePassword(String? oldPassword, String? newPassword) async {
    final record = _requireRecord();
    if (await _verifier.hasPassword(record.toxId) &&
        (oldPassword == null ||
            !await _verifier.verify(record.toxId, oldPassword))) {
      throw const ChatException('wrong_password', 'Incorrect password');
    }
    final setting = newPassword != null && newPassword.isNotEmpty;
    final updated = record.copyWith(hasPassword: setting);
    final file = File(_paths.profileFile);
    final before = await file.readAsBytes();
    Uint8List? replacement;
    if (!_started) {
      final plain = _crypto.isEncrypted(before)
          ? _crypto.decrypt(before, oldPassword ?? _sessionPassword ?? '')
          : before;
      // Derive before touching either durable store. An encryption error
      // leaves the previous ciphertext and verifier untouched.
      replacement = setting ? _crypto.encrypt(plain, newPassword) : plain;
    }
    // Running: the live native session holds the passphrase and rewrites
    // the file on every save, so it is re-keyed (and written) natively.
    final previousLive = _sessionPassword;
    var rekeyed = false;

    /// Undoes the profile side of a failed change. If even re-keying back
    /// fails, the running session (and so the file) now carries the NEW
    /// password: keep memory on that truth so the disconnect safety net and
    /// the next unlock agree with the file, and report it.
    Future<void> undoProfile() async {
      if (replacement != null) await writeBytesAtomic(file, before);
      if (!rekeyed) return;
      rekeyed = false;
      if (!_engine.rekeyProfilePassphrase(previousLive)) {
        _sessionPassword = setting ? newPassword : null;
        throw const ChatException(
          'rekey_rollback_failed',
          'The running profile kept the new password',
        );
      }
    }

    Future<void> commitFiles() async {
      try {
        if (replacement != null) {
          await writeBytesAtomic(file, replacement);
        } else if (_started) {
          if (!_engine.rekeyProfilePassphrase(setting ? newPassword : null)) {
            throw const ChatException(
              'rekey_failed',
              'Could not re-encrypt the running profile',
            );
          }
          rekeyed = true;
        }
        await updated.write(_paths.identityFile);
      } catch (_) {
        await undoProfile();
        rethrow;
      }
    }

    if (setting) {
      await _verifier.replacePassword(record.toxId, newPassword, commitFiles);
    } else {
      // Leave the old verifier in place until BOTH files describe the
      // unprotected profile. A process exit during removal can still unlock
      // with the old password; it never leaves hasPassword without a verifier.
      try {
        await commitFiles();
        await _verifier.replacePassword(record.toxId, null, () async {});
      } catch (_) {
        await undoProfile();
        await record.write(_paths.identityFile);
        rethrow;
      }
    }
    _sessionPassword = setting ? newPassword : null;
    _publish(updated);
  }

  Future<Identity> _updateProfile(String? name, String? status) async {
    final record = _requireRecord();
    final updated = record.copyWith(
      displayName: name?.trim().isEmpty ?? true ? null : name!.trim(),
      statusMessage: status,
    );
    await updated.write(_paths.identityFile);
    // The durable mirror is authoritative on the next connect, even when a
    // live native update fails after the file commit.
    _publish(updated);
    await _engine.updateSelfProfile(updated.displayName, updated.statusMessage);
    return updated.toIdentity();
  }
}
