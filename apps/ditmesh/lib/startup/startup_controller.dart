import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import '../training/guest_profile.dart';

/// Where the app is in its identity lifecycle. The [StartupGate] renders one
/// screen per phase; everything behind [ready] is the normal shell.
enum StartupPhase {
  /// `inspect()` is running (also the very first frame).
  inspecting,

  /// No identity on disk: welcome → create / restore.
  onboarding,

  /// Encrypted profile on disk: unlock screen.
  locked,

  /// Plain profile found; `open()` is running.
  opening,

  /// Identity was just created; the mandatory backup wizard is showing.
  backupRequired,

  /// Identity loaded. Connection runs in the background.
  ready,

  /// `inspect()` / `open()` threw; retry screen.
  failed,

  /// Learning without an identity (functional spec §8): the shell runs on
  /// the guest learning profile; chat asks for an identity. No Tox identity
  /// is created, opened, unlocked or connected in this phase.
  guest,
}

/// Guest-data hooks the controller needs; null disables guest learning.
final class GuestHooks {
  const GuestHooks({
    required this.store,
    required this.releaseGuestController,
    this.suspendLearning,
    this.resumeLearning,
  });

  final GuestStore store;

  /// Flushes and closes the guest training controller.
  final Future<void> Function() releaseGuestController;

  /// Flush every cached learning controller and stop serving them while
  /// learning files are replaced; then serve (and reload) again.
  final Future<void> Function()? suspendLearning;
  final void Function()? resumeLearning;
}

/// Drives the startup sequence (`inspect → onboarding | unlock | open`) and
/// the identity-level actions that change which screen the gate shows.
///
/// Mirrors toxee's `StartupSessionUseCase` policy without its account
/// registry: one identity per device, no auto-login of an encrypted profile
/// (the password is never cached across launches), connection never blocks
/// the UI.
///
/// Holds no user-facing text: failures are kept as the thrown object (a
/// `ChatException` with a stable code, or anything else) and the widgets
/// translate them with `describeChatError(s, error)`.
class StartupController extends ChangeNotifier {
  StartupController(
    this._identity, {
    GuestHooks? guest,
    DateTime Function()? now,
    this.chatEnabled = true,
  }) : _guest = guest,
       _now = now ?? DateTime.now {
    _identitySub = _identity.identityChanges.listen(_onIdentityChanged);
  }

  final IdentityService _identity;
  final GuestHooks? _guest;

  /// False in the offline build (`AppFeatures.chat`): no identity is ever
  /// inspected or created; learning always runs on the local (guest)
  /// learning profile.
  final bool chatEnabled;
  final DateTime Function() _now;

  /// True while the guest learning profile is in use; the training host
  /// listens to it.
  final ValueNotifier<bool> guestMode = ValueNotifier<bool>(false);

  Object? _migrationError;

  /// Moving guest progress to a just-created identity failed; the identity
  /// exists, the guest data is intact, [retryMigration] tries again.
  Object? get migrationError => _migrationError;

  bool _guestChoicePending = false;

  /// A backup was restored while guest progress exists: the restored
  /// progress is used; the learner may switch to the guest progress.
  bool get guestChoicePending => _guestChoicePending;

  bool get guestAvailable => _guest != null;
  late final StreamSubscription<Identity?> _identitySub;

  /// Sentinel for [_set]: "leave the error as it is".
  static const Object _keepError = Object();

  StartupPhase _phase = StartupPhase.inspecting;
  Object? _error;
  Object? _connectionError;
  bool _started = false;
  bool _disposed = false;

  StartupPhase get phase => _phase;

  /// What `inspect()` / `open()` threw for [StartupPhase.failed]; null in
  /// every other phase.
  Object? get error => _error;

  /// Last `connect()` failure, if any. Cleared by a successful [reconnect].
  Object? get connectionError => _connectionError;

  IdentityService get identity => _identity;

  /// Runs `inspect()` once per controller. Safe to call from `initState`: the
  /// first notification happens after an await, never synchronously.
  Future<void> ensureStarted() {
    if (_started) return Future.value();
    _started = true;
    return _inspect();
  }

  /// Re-runs the inspection after [StartupPhase.failed].
  Future<void> retry() => _inspect();

  Future<void> _inspect() async {
    _set(StartupPhase.inspecting, error: null);
    if (!chatEnabled) {
      await _enterOfflineProfile();
      return;
    }
    // Guest mode resumes before anything touches an identity on disk: no
    // identity metadata or profile is read, decrypted or opened.
    if (await _guestWasActive()) {
      _cameFromGuest = true;
      _set(StartupPhase.guest);
      return;
    }
    try {
      final state = await _identity.inspect();
      switch (state) {
        case IdentityState.none:
          _set(StartupPhase.onboarding);
        case IdentityState.locked:
          _set(StartupPhase.locked);
        case IdentityState.ready:
          _set(StartupPhase.opening);
          await _identity.open();
          // Leaving guest mode into a plain identity: offer the guest
          // progress like restore / unlock do, never merge it.
          final fromGuest = _cameFromGuest;
          _cameFromGuest = false;
          // Let a pending guest save land before deciding.
          if (fromGuest) await _guest?.releaseGuestController();
          _guestChoicePending = fromGuest && await _guestHasProgress();
          _becomeReady();
          unawaited(_resumeInterruptedMigration());
      }
    } on Object catch (e) {
      _set(StartupPhase.failed, error: e);
    }
  }

  /// The learner came through guest mode on the way to create / restore /
  /// unlock; consumed by those actions.
  bool _cameFromGuest = false;

  Future<bool> _guestWasActive() async {
    final guest = _guest;
    if (guest == null) return false;
    try {
      final active = await guest.store.isActive();
      if (active) await guest.store.finishCompletedMigrations();
      guestMode.value = active;
      return active;
    } on Object {
      return false;
    }
  }

  /// The offline build's only profile: the guest learning profile, made
  /// active before the training host serves it. Never touches an identity.
  Future<void> _enterOfflineProfile() async {
    final guest = _guest;
    if (guest != null) {
      try {
        await guest.store.finishCompletedMigrations();
        await guest.store.setActive(true);
      } on Object {
        // Still usable this session.
      }
    }
    guestMode.value = true;
    _set(StartupPhase.guest);
  }

  /// "Try learning first": learn on the guest profile. Never touches an
  /// identity on disk (an encrypted one stays locked).
  Future<void> enterGuest() async {
    final guest = _guest;
    if (guest == null) return;
    try {
      await guest.store.finishCompletedMigrations();
      await guest.store.setActive(true);
    } on Object {
      // Guest mode still works this session; it just won't be remembered.
    }
    _cameFromGuest = true;
    guestMode.value = true;
    _set(StartupPhase.guest);
  }

  /// Back to creating / restoring / unlocking an identity: inspects the
  /// identity on disk only now that the learner asked for it.
  Future<void> leaveGuest() async {
    if (!chatEnabled) return; // there is no identity to go to
    guestMode.value = false;
    try {
      await _guest?.store.setActive(false);
    } on Object {
      // Not remembered; the next launch may start in guest mode again.
    }
    await _inspect();
  }

  /// Deletes the guest's learning data (the learner asked for it); the
  /// Learn tab reloads a fresh guest profile.
  Future<void> clearGuestData() async {
    final guest = _guest;
    if (guest == null) return;
    try {
      await guest.suspendLearning?.call();
      await guest.releaseGuestController();
      await guest.store.clear();
    } finally {
      // Learn must come back even when a flush reported an old failure.
      guest.resumeLearning?.call();
    }
  }

  /// Moves guest data to the open identity with every learning controller
  /// suspended (no late guest write, no stale identity controller writing
  /// over the moved files), then reloads them.
  Future<void> _migrateGuest({bool suspended = false}) async {
    final guest = _guest;
    final identity = _identity.current;
    if (guest == null || identity == null) return;
    guestMode.value = false;
    try {
      if (!suspended) await guest.suspendLearning?.call();
      await guest.releaseGuestController();
      final guestDir = await guest.store.directory();
      final pending = File(p.join(guestDir, 'pending-${identity.publicKey}'));
      if (!await guest.store.hasProgress() &&
          !await GuestMigration.hasJournal(guestDir)) {
        await guest.store.setActive(false);
        if (await pending.exists()) await pending.delete();
        _migrationError = null;
        return;
      }
      // Remembered across restarts until the migration completes.
      await pending.writeAsString('1', flush: true);
      await GuestMigration(
        guestDirectory: guestDir,
        identityDirectory: await _identity.dataDirectory(),
        generation: await guest.store.generation(),
      ).run(identityKey: identity.publicKey, now: _now());
      await guest.store.setActive(false);
      await pending.delete();
      _migrationError = null;
    } on Object catch (e) {
      _migrationError = e;
    } finally {
      if (!suspended) guest.resumeLearning?.call();
      _notify();
    }
  }

  /// On launch with an identity: finish a migration that was interrupted,
  /// or show its retry banner again.
  Future<void> _resumeInterruptedMigration() async {
    final guest = _guest;
    final identity = _identity.current;
    if (guest == null || identity == null) return;
    try {
      final dir = await guest.store.directory();
      if (await GuestMigration.hasJournal(dir) ||
          await File(p.join(dir, 'pending-${identity.publicKey}')).exists()) {
        await _migrateGuest();
      }
    } on Object {
      // Nothing to resume.
    }
  }

  /// Retries a failed guest migration; idempotent.
  Future<void> retryMigration() => _migrateGuest();

  /// After a restore / unlock: replace that identity's learning data with
  /// the guest's (the previous data is moved aside, never merged).
  Future<void> useGuestProgress() async {
    _guestChoicePending = false;
    await _migrateGuest();
  }

  /// After a restore / unlock: keep its progress; guest data stays apart.
  Future<void> keepRestoredProgress() async {
    _guestChoicePending = false;
    try {
      await _guest?.store.setActive(false);
    } on Object {
      // Harmless: only the guest-mode resume flag.
    }
    _notify();
  }

  /// Decrypts the profile. Throws (typically `ChatException('wrong_password')`)
  /// so the unlock screen can render the error inline.
  Future<void> unlock(String password) async {
    await _identity.unlock(password);
    final fromGuest = _cameFromGuest;
    _cameFromGuest = false;
    guestMode.value = false;
    // Unlocking from guest mode keeps the identity's own progress; the
    // learner may switch to the guest progress explicitly.
    _guestChoicePending = fromGuest && await _guestHasProgress();
    _becomeReady();
    unawaited(_resumeInterruptedMigration());
  }

  /// Creates the identity and moves to the mandatory backup wizard.
  Future<Identity> createIdentity({
    required String displayName,
    String? password,
  }) async {
    final guest = _guest;
    final migrate =
        guest != null && (_cameFromGuest || await _guestHasProgress());
    _cameFromGuest = false;
    // Freeze learning before the identity exists: its controller must not
    // load (and later save) empty progress before the guest data arrives.
    try {
      if (migrate) await guest.suspendLearning?.call();
      final identity = await _identity.create(
        displayName: displayName,
        password: password,
      );
      // Guest progress moves with the learner to the new identity.
      if (migrate) await _migrateGuest(suspended: true);
      _set(StartupPhase.backupRequired);
      return identity;
    } finally {
      if (migrate) guest.resumeLearning?.call();
    }
  }

  /// The wizard's "I understand" step was completed.
  void completeBackupWizard() {
    if (_phase != StartupPhase.backupRequired) return;
    _becomeReady();
  }

  /// Restores an identity from backup bytes. The user evidently has a backup,
  /// so the wizard is skipped. Throws `wrong_password` / `invalid_backup`.
  Future<Identity> restoreFromBackup(
    Uint8List bytes, {
    String? password,
  }) async {
    final identity = await _identity.importBackup(bytes, password: password);
    final fromGuest = _cameFromGuest;
    _cameFromGuest = false;
    guestMode.value = false;
    // Restored progress is used; guest scores are never silently merged.
    _guestChoicePending = fromGuest && await _guestHasProgress();
    _becomeReady();
    return identity;
  }

  /// Restores a complete encrypted backup (F10). Same gate behaviour as
  /// [restoreFromBackup]; the report lists what came back and what did not.
  /// Throws `wrong_passphrase`, `wrong_password`, `invalid_backup`, ...
  Future<RestoreReport> restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase, {
    String? identityPassword,
  }) async {
    final backups = switch (_identity) {
      final EncryptedBackupService b => b,
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
    final fromGuest = _cameFromGuest;
    _cameFromGuest = false;
    guestMode.value = false;
    _guestChoicePending = fromGuest && await _guestHasProgress();
    _becomeReady();
    return report;
  }

  /// Retries the background connection, e.g. from the connection chip.
  Future<void> reconnect() => _connectInBackground();

  /// Irreversibly deletes the identity; the gate falls back to onboarding via
  /// the identity stream.
  Future<void> deleteIdentity() async {
    await _identity.deleteIdentity();
    if (_phase != StartupPhase.onboarding) _set(StartupPhase.onboarding);
  }

  Future<bool> _guestHasProgress() async {
    try {
      return await _guest?.store.hasProgress() ?? false;
    } on Object {
      return false;
    }
  }

  void _becomeReady() {
    _set(StartupPhase.ready);
    unawaited(_connectInBackground());
  }

  Future<void> _connectInBackground() async {
    try {
      await _identity.connect();
      if (_connectionError != null) {
        _connectionError = null;
        _notify();
      }
    } on Object catch (e) {
      _connectionError = e;
      _notify();
    }
  }

  void _onIdentityChanged(Identity? identity) {
    // Events arrive asynchronously. An import emits null (the old identity
    // ends) and then the restored one; by the time that null is delivered,
    // the restore may already have made us ready. Act on what is current.
    if (identity != null || _identity.current != null) return;
    if (_phase == StartupPhase.ready || _phase == StartupPhase.backupRequired) {
      _set(StartupPhase.onboarding);
    }
  }

  void _set(StartupPhase phase, {Object? error = _keepError}) {
    // `_keepError` means "leave as is"; null clears; anything else sets.
    final nextError = identical(error, _keepError) ? _error : error;
    if (phase == _phase && identical(nextError, _error)) return;
    _phase = phase;
    _error = nextError;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _identitySub.cancel().ignore();
    guestMode.dispose();
    super.dispose();
  }
}
