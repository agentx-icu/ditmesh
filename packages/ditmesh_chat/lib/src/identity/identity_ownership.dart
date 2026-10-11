part of 'tim2tox_identity_service.dart';

/// Proof that `tox_profile.tox` is the open identity's savedata, required
/// before anything may rewrite it.
///
/// identity.json, the password verifier and the profile are written
/// separately, so a crash window (a delete that left identity.json, then a
/// create that died before rewriting it) or a hand-copied file can pair one
/// identity's metadata with another identity's savedata. Native Tim2Tox
/// reports the self address only after login, but its init already
/// re-encrypts a plaintext profile under the staged passphrase (or replaces
/// an unreadable one with a new identity) and its teardown saves
/// unconditionally. The engine's post-login check is therefore too late to
/// keep the other identity's file intact; this check runs before native
/// ever opens it, and before unlock repairs the verifier or identity.json.
///
/// Checked when an identity is opened or unlocked, before a session starts,
/// before Dart re-encrypts or re-keys a stopped profile, and before an
/// export packages it. Scope: a mismatch already on disk when an operation
/// begins. A running session owns the file it was started on: native
/// autosaves it at any moment, so a file swapped in under a live session
/// cannot be protected from Dart. Another process replacing the file
/// DURING an operation (between this read and native's reopen, under a
/// running session, or while `create` mints the profile) is out of scope:
/// the tree is owner-only (IdentityPaths.ensureDirectories) and nothing
/// can lock it against the same user's processes. `create` deliberately
/// does not verify: its failure cleanup deletes the tree, which would turn
/// such a race from a re-encryption into a deletion.
extension _IdentityOwnership on Tim2ToxIdentityService {
  /// Throws `identity_mismatch` unless [plaintext] is [toxId]'s savedata
  /// (`invalid_profile` when it is not a Tox savedata at all).
  void _requireOwnedBy(String toxId, Uint8List plaintext) {
    final key = _crypto.extractPublicKey(plaintext).toUpperCase();
    final expected = toxId.toUpperCase();
    if (key.length < 64 ||
        expected.length < 64 ||
        key.substring(0, 64) != expected.substring(0, 64)) {
      throw const ChatException(
        'identity_mismatch',
        'The profile on disk belongs to another identity',
      );
    }
  }

  /// Before a session starts: the profile exists, opens with [password]
  /// (`wrong_password` otherwise) and is [toxId]'s. Reads only; whatever
  /// it throws, nothing has touched the file.
  Future<void> _requireProfileOwned(String toxId, String? password) async {
    final file = File(_paths.profileFile);
    if (!await file.exists()) {
      // Native init would mint a new identity in its place.
      throw const ChatException('no_identity', 'No identity on disk');
    }
    _requireBytesOwned(toxId, await file.readAsBytes(), password);
  }

  /// [bytes] (plaintext, or encrypted under [password]) are [toxId]'s
  /// savedata. Throws like [_requireProfileOwned].
  void _requireBytesOwned(String toxId, Uint8List bytes, String? password) {
    if (!_crypto.isEncrypted(bytes)) return _requireOwnedBy(toxId, bytes);
    if (password == null) {
      throw const ChatException(
        'wrong_password',
        'Profile is encrypted and no password is available',
      );
    }
    final plain = _crypto.decrypt(bytes, password);
    try {
      _requireOwnedBy(toxId, plain);
    } finally {
      // Best effort: the secret key's Dart-heap copy (see ProfileCrypto).
      plain.fillRange(0, plain.length, 0);
    }
  }

  /// Whether the plaintext profile [bytes] is the open identity's, so the
  /// session password may encrypt it. Logs and answers false otherwise:
  /// another identity's file is left exactly as it is.
  bool _ownsPlaintextProfile(Uint8List bytes) {
    final record = _record;
    if (record == null) return false;
    try {
      _requireOwnedBy(record.toxId, bytes);
      return true;
    } on Object catch (e, st) {
      _logger.error('[Identity] profile left as is: not provably ours', e, st);
      return false;
    }
  }
}
