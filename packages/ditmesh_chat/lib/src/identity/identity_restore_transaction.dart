part of 'tim2tox_identity_service.dart';

const _restoreJournalName = 'restore.json';
const _restoreCommitName = 'committed';
const _restoreFinalizedName = 'finalized';
const _restoreVerifierName = 'verifier-started';
const _pendingAppRestoreScope = 'previous-app-identity';

const _restoreRecoveryPending = ChatException(
  'identity_recovery_pending',
  'Could not recover an interrupted identity restore',
);

/// A restore has a single durable commit point covering the root and its
/// scoped preferences. Passwords and verifier values stay outside the journal.
final class _RestoreJournal {
  _RestoreJournal({
    required this.hadRoot,
    required this.oldToxId,
    required this.toxId,
    required this.encrypted,
    required this.preferences,
  });

  final bool hadRoot;
  final String? oldToxId;
  final String toxId;
  final bool encrypted;
  final KvSnapshot? preferences;

  bool get canStageVerifier =>
      !hadRoot ||
      (oldToxId != null && !PasswordVerifier.sharesKey(oldToxId!, toxId));

  bool ownsKey(String key) => _ownsRestoreKey(key, oldToxId, toxId);

  static File file(Directory stage) =>
      File(p.join(stage.path, _restoreJournalName));

  Future<void> write(Directory stage) => writeBytesAtomic(
    file(stage),
    Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'hadRoot': hadRoot,
          'oldToxId': oldToxId,
          'toxId': toxId,
          'encrypted': encrypted,
          'preferences': preferences?.toJson(),
        }),
      ),
    ),
  );

  static Future<_RestoreJournal> read(Directory stage) async {
    final doc = jsonDecode(await file(stage).readAsString());
    if (doc is! Map<String, dynamic> ||
        doc['version'] != 1 ||
        doc['hadRoot'] is! bool ||
        doc['toxId'] is! String ||
        (doc['oldToxId'] != null && doc['oldToxId'] is! String) ||
        doc['encrypted'] is! bool ||
        !doc.containsKey('preferences')) {
      throw const FormatException('Invalid restore journal');
    }
    final oldToxId = doc['oldToxId'] as String?;
    final toxId = doc['toxId'] as String;
    final prefs = doc['preferences'];
    return _RestoreJournal(
      hadRoot: doc['hadRoot'] as bool,
      oldToxId: oldToxId,
      toxId: toxId,
      encrypted: doc['encrypted'] as bool,
      preferences: prefs == null
          ? null
          : KvSnapshot.fromJson(
              prefs,
              (key) => _ownsRestoreKey(key, oldToxId, toxId),
            ),
    );
  }
}

bool _ownsRestoreKey(String key, String? oldToxId, String toxId) =>
    [oldToxId, toxId].whereType<String>().any(
      (id) =>
          id.length >= 16 &&
          Tim2ToxPreferencesAdapter.ownsPreferenceKey(
            key,
            id.substring(0, 16).toUpperCase(),
          ),
    );

extension _IdentityRestoreTransaction on Tim2ToxIdentityService {
  Future<void> _replaceIdentityFromBackup(
    IdentityRecord record,
    String? password,
    Future<void> Function(IdentityPaths staged) writeStaged, {
    Future<void> Function()? restorePreferences,
  }) async {
    if (!await _recoverInterruptedImport(requireCleanup: true)) {
      throw _restoreRecoveryPending;
    }
    final authenticated = _record;
    final authenticatedPassword = _sessionPassword;
    final old = authenticated ?? await IdentityRecord.read(_paths.identityFile);
    final root = Directory(_paths.root);
    await PosixPermissions.createPrivateDirectory(root.parent.path);
    await _paths.excludeFromBackup();
    final stage = await root.parent.createTemp(IdentityPaths.importStagePrefix);
    final previous = Directory(IdentityPaths.previousInStage(stage));
    final staged = IdentityPaths(p.join(stage.path, 'identity'));
    var commit = false;
    try {
      // All archive writes finish before touching the installed account.
      await staged.ensureDirectories();
      await writeStaged(staged);
      if (old != null) {
        await writeBytesAtomic(
          File(p.join(staged.root, _pendingAppRestoreScope)),
          Uint8List.fromList(utf8.encode(old.toIdentity().publicKey)),
        );
      }
      await _prepareForReplacement();
      await _disconnectImpl();
      _requireTeardownConfirmed();
      final store = _store;
      final journal = _RestoreJournal(
        hadRoot: await root.exists(),
        oldToxId: old?.toxId,
        toxId: record.toxId,
        encrypted: record.hasPassword,
        preferences: store == null
            ? null
            : KvSnapshot.capture(
                store,
                includes: (key) =>
                    _ownsRestoreKey(key, old?.toxId, record.toxId),
              ),
      );
      final stageVerifier =
          journal.canStageVerifier &&
          !await _verifier.hasPassword(record.toxId);
      await journal.write(stage);
      PosixDirectorySync.sync(stage.parent.path);
      if (journal.hadRoot) await _moveRestoreDirectory(root, previous.path);
      await _moveRestoreDirectory(Directory(staged.root), root.path);
      if (old != null) await _clearPreferences(old.toxId);
      await _clearPreferences(record.toxId);
      await restorePreferences?.call();
      if (stageVerifier) {
        // A vacant separate key has no previous verifier to preserve.
        await _writeRestoreMarker(stage, _restoreVerifierName);
        await _setRestoreVerifier(record.toxId, password);
      }
      await _writeRestoreMarker(stage, _restoreCommitName);
      commit = true;
      if (!stageVerifier) {
        // Preserve any verifier until committed. Older plain profiles can
        // depend on a shared verifier for their entire protection.
        await _setRestoreVerifier(record.toxId, password);
      }
      await _removeReplacedVerifier(journal);
      await _writeRestoreMarker(stage, _restoreFinalizedName);
    } on Object catch (error, stack) {
      try {
        if (await _RestoreJournal.file(stage).exists()) {
          if (commit) {
            // The installed tree and scoped preferences are already complete.
            // Retry reconciliation on startup before making them available.
            throw _restoreRecoveryPending;
          }
          await _resolveRestoreStage(stage);
        } else {
          await stage.delete(recursive: true);
        }
        _restoreAuthentication(authenticated, authenticatedPassword);
      } on Object catch (e, st) {
        _blockRestoreAccess();
        _logger.error('[Backup] restore recovery is pending', e, st);
        throw _restoreRecoveryPending;
      }
      Error.throwWithStackTrace(error, stack);
    }
    await _cleanFinalizedRestore(stage);
    _forgetIdentity();
    _sessionPassword = password;
    _publish(record);
  }

  Future<void> _recoverJournaledImports({required bool requireCleanup}) async {
    final bool cleaned;
    try {
      final pending = [
        for (final stage in await _paths.importStages())
          if (await _RestoreJournal.file(stage).exists()) stage,
      ];
      if (pending.isEmpty) return;
      if (pending.length != 1) throw _restoreRecoveryPending;
      cleaned = await _resolveRestoreStage(pending.single);
    } on Object catch (e, st) {
      _blockRestoreAccess();
      _logger.error('[Backup] could not recover interrupted restore', e, st);
      throw _restoreRecoveryPending;
    }
    if (!cleaned && requireCleanup) throw _restoreRecoveryPending;
  }

  void _blockRestoreAccess() {
    _recoveryBlocked = true;
    _forgetIdentity();
  }

  Future<bool> _resolveRestoreStage(Directory stage) async {
    if (await File(p.join(stage.path, _restoreFinalizedName)).exists()) {
      if (!_paths.profileExists) throw _restoreRecoveryPending;
      return _cleanFinalizedRestore(stage);
    }
    _requireTeardownConfirmed();
    final journal = await _RestoreJournal.read(stage);
    if (await File(p.join(stage.path, _restoreCommitName)).exists()) {
      if (!_paths.profileExists ||
          (await IdentityRecord.read(_paths.identityFile))?.toxId !=
              journal.toxId) {
        throw _restoreRecoveryPending;
      }
      // Ciphertext proves its own password and unlock repairs a verifier,
      // including an interruption before the same-ID verifier was replaced.
      if (!journal.encrypted) await _verifier.removePassword(journal.toxId);
      await _removeReplacedVerifier(journal);
      await _writeRestoreMarker(stage, _restoreFinalizedName);
      return _cleanFinalizedRestore(stage);
    } else {
      final before = journal.preferences;
      if (before != null) {
        final store = _store;
        if (store == null) throw _restoreRecoveryPending;
        await before.restore(store, includes: journal.ownsKey);
      }
      if (journal.canStageVerifier &&
          await File(p.join(stage.path, _restoreVerifierName)).exists()) {
        await _verifier.removePassword(journal.toxId);
      }
      await _rollbackRestoreTree(stage, hadRoot: journal.hadRoot);
    }
    await _discardCompletedRestore(stage);
    return true;
  }

  Future<bool> _cleanFinalizedRestore(Directory stage) async {
    try {
      await _discardCompletedRestore(stage);
      return true;
    } on Object catch (e, st) {
      // The installed profile and its verifier can already be used. Retry
      // cleanup before another restore, without revisiting the verifier.
      _logger.error('[Backup] could not remove completed staging', e, st);
      return !await _RestoreJournal.file(stage).exists();
    }
  }

  Future<void> _rollbackRestoreTree(
    Directory stage, {
    required bool hadRoot,
  }) async {
    final previous = Directory(IdentityPaths.previousInStage(stage));
    final root = Directory(_paths.root);
    final staged = Directory(p.join(stage.path, 'identity'));
    final previousExists = await previous.exists();
    final rootExists = await root.exists();
    if (previousExists || (!hadRoot && rootExists)) {
      if (rootExists) {
        if (await staged.exists()) throw _restoreRecoveryPending;
        await _moveRestoreDirectory(root, staged.path);
      }
      if (previousExists) await _moveRestoreDirectory(previous, root.path);
    } else if (hadRoot && !rootExists) {
      throw _restoreRecoveryPending;
    }
  }

  Future<void> _removeReplacedVerifier(_RestoreJournal journal) async {
    final oldToxId = journal.oldToxId;
    if (oldToxId == null ||
        PasswordVerifier.sharesKey(oldToxId, journal.toxId)) {
      return;
    }
    try {
      await _verifier.removePassword(oldToxId);
    } on Object catch (e, st) {
      _logger.error('[Backup] could not remove the old verifier', e, st);
    }
  }

  Future<void> _setRestoreVerifier(String toxId, String? password) =>
      password == null
      ? _verifier.removePassword(toxId)
      : _verifier.setPassword(toxId, password);
}

Future<void> _writeRestoreMarker(Directory stage, String name) =>
    writeBytesAtomic(File(p.join(stage.path, name)), Uint8List(0));

Future<void> _moveRestoreDirectory(Directory source, String target) async {
  await source.rename(target);
  PosixDirectorySync.sync(p.dirname(target));
  PosixDirectorySync.sync(source.parent.path);
}

Future<void> _discardCompletedRestore(Directory stage) async {
  // Keep the journal through cleanup of both trees. If deletion is
  // interrupted, the next launch must never recover a committed previous tree
  // as an unmarked restore from an older version.
  for (final name in ['previous', 'identity']) {
    final tree = Directory(p.join(stage.path, name));
    if (await tree.exists()) await tree.delete(recursive: true);
  }
  PosixDirectorySync.sync(stage.path);
  await _RestoreJournal.file(stage).delete();
  PosixDirectorySync.sync(stage.path);
  await stage.delete(recursive: true);
}
